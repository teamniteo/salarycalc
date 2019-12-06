"""Use a real browser to fetch config.yaml values."""

from ruamel.yaml import RoundTripDumper
from ruamel.yaml import RoundTripLoader
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from tqdm import tqdm

import argparse
import ruamel.yaml
import sys


def usd_to_eur_10_year_average(
    driver: webdriver.firefox.webdriver.WebDriver,
    config: ruamel.yaml.comments.CommentedMap,
) -> None:
    """Update the eur_to_usd_10_year_arg value in config.yaml."""

    pbar = tqdm(total=9)
    pbar.set_description("Processing eur_to_usd_10_year_avg")

    # Load OFX.com
    driver.get(
        "https://www.ofx.com/en-us/forex-news/historical-exchange-rates/yearly-average-rates/"
    )
    pbar.update()

    # Select EUR as base currency
    driver.find_element_by_css_selector(
        "div.historical-rates--camparison--base"
    ).click()
    driver.find_element_by_xpath('//li[text()="EUR Euro"]').click()
    pbar.update()

    # Select USD as target currency
    driver.find_element_by_css_selector(
        "div.historical-rates--camparison--target"
    ).click()
    driver.find_element_by_xpath('//li[text()="USD US Dollar"]').click()
    pbar.update()

    # Select yearly frequency
    driver.find_element_by_id("historicalrates-frequency-yearly").click()
    pbar.update()

    # Choose all-time reporting period
    # There is a bug in their site where you cannot select `All` before
    # you select something else
    driver.find_element_by_xpath(
        '//select[contains(@class, "historical-rates--period")]/..'
    ).click()
    driver.find_element_by_xpath('//li[text()="Last 10 years"]').click()
    driver.find_element_by_xpath(
        '//select[contains(@class, "historical-rates--period")]/..'
    ).click()
    driver.find_element_by_xpath('//li[text()="All"]').click()
    pbar.update()

    # Click `Retrieve Data` button
    driver.find_element_by_css_selector("button.historical-rates--submit").click()
    pbar.update()

    # Wait for data to load
    WebDriverWait(driver, 3).until(
        EC.visibility_of_element_located(
            (By.CSS_SELECTOR, "table.historical-rates--table")
        )
    )
    pbar.update()

    # Extract the Average Rate
    avg_value = driver.find_element_by_css_selector(
        "td.historical-rates--table--average--value"
    ).text
    avg = round(float(avg_value), 4)
    pbar.update()

    config["eur_to_usd_10_year_avg"] = avg

    pbar.update()
    pbar.close()


def cities(
    driver: webdriver.firefox.webdriver.WebDriver,
    config: ruamel.yaml.comments.CommentedMap,
) -> None:
    """Update the locationFactor values in config.yaml."""

    BASE_SF_SALARY = 10000

    pbar = tqdm(total=len(config["cities"]))
    pbar.set_description("Processing cities")

    for city in config["cities"]:
        pbar.update()

        # Load numbeo
        driver.get(
            f"https://www.numbeo.com/cost-of-living/compare_cities.jsp?amount={BASE_SF_SALARY}&displayCurrency=USD&country1=United+States&city1=San+Francisco%2C+CA&country2={city['country']}&city2={city['name']}"
        )

        # Extract equivalent of $10k/month salary in SF
        equivalent_salary_text = driver.find_element_by_css_selector(
            "span.number_amount_nobreak"
        ).text  # '4,801.48$ (4,323.12€)'

        equivalent_salary = float(equivalent_salary_text.split("$")[0].replace(",", ""))

        numbeo_ratio = equivalent_salary / BASE_SF_SALARY

        compressed_ratio = compress_towards_affordability_ratio(
            numbeo_ratio, config["affordability_ratio"]
        )
        normalized_ratio = normalize_against_affordability_ratio(
            compressed_ratio, config["affordability_ratio"]
        )

        city["locationFactor"] = round(normalized_ratio, 2)

    pbar.close()


def compress_towards_affordability_ratio(ratio, affordability_ratio):
    """Decrease differences between expensive and cheap locations.

    We want to slightly underpay people in expensive locations and
    overpay people in cheap locations:
    - in cheap locations, a MacBook costs the same (if not more)
    - people in cheap locations can easily work remotely for a
      company in a more expensive location
    - by overpaying cheap locations, we get access to top talent there
    - by underpaying expensive locations our hiring is harder there so
      the culture fit must be greater
    """
    if ratio == affordability_ratio:
        return ratio
    elif ratio < affordability_ratio:
        return ((ratio - affordability_ratio) * 0.33) + affordability_ratio
    else:
        return ((ratio - affordability_ratio) * 0.67) + affordability_ratio


def normalize_against_affordability_ratio(ratio, affordability_ratio):
    """We want the locationFactors to be normalized against 0.53.

    It makes it easier to see which locations are more expensive
    than our affordability ratio.
    """
    return ratio / affordability_ratio


def main(argv=sys.argv) -> None:
    """Update salaries."""

    argparse.ArgumentParser(usage=("pipenv run python fetch_config_values.py"))

    options = Options()
    options.headless = True

    print("Starting Firefox and loading up config.yml")
    with webdriver.Firefox(options=options) as driver:
        with open("config.yml") as file:
            config = ruamel.yaml.load(file, Loader=RoundTripLoader)

            usd_to_eur_10_year_average(driver, config)
            cities(driver, config)

        with open("config.yml", "w") as file:
            ruamel.yaml.dump(config, file, indent=4, Dumper=RoundTripDumper)
    print("config.yml saved")


if __name__ == "__main__":  # pragma: no cover
    main()
