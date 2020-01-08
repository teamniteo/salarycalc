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
    avg = round(float(avg_value), 2)
    pbar.update()

    config["eur_to_usd_10_year_avg"] = avg

    pbar.update()
    pbar.close()


def countries(
    driver: webdriver.firefox.webdriver.WebDriver,
    config: ruamel.yaml.comments.CommentedMap,
) -> None:
    """Update the Cost of Living values in config.yaml."""

    pbar = tqdm(total=len(config["countries"]))
    pbar.set_description("Processing countries")

    for country in config["countries"]:
        pbar.update()

        # Load numbeo
        driver.get(
            "https://www.numbeo.com/cost-of-living/compare_countries_result.jsp?"
            f"country1=United+States&country2={country['name']}"
        )

        # Extract Cost of Living Plus Rent Index
        difference_text = driver.find_element_by_css_selector(
            ".table_indices_diff "
            "> tbody:nth-child(1) "
            "> tr:nth-child(3) "
            "> td:nth-child(1)"
        ).text

        # 'Consumer Prices Including Rent in Netherlands are 2.05% lower than
        # in United States'
        difference = float(
            difference_text.split("are")[1].split(" ")[1].replace("%", "")
        )

        numbeo_ratio = 1 - (difference / 100)

        country["cost_of_living"] = round(numbeo_ratio, 2)
        country["compressed_cost_of_living"] = round(
            compress_towards_affordability(numbeo_ratio, config["affordability"]), 2
        )

    pbar.close()


def salaries(
    driver: webdriver.firefox.webdriver.WebDriver,
    config: ruamel.yaml.comments.CommentedMap,
) -> None:
    """Update the baseSalary values in config.yaml."""

    roles = []
    for career in config["careers"]:
        for role in career["roles"]:
            roles.append(role)

    pbar = tqdm(total=len(roles))
    pbar.set_description("Processing roles")

    for role in roles:
        pbar.update()

        # Load numbeo
        driver.get(
            f"https://www.salary.com/tools/salary-calculator/{role['salary_com_key']}"
        )

        # Extract Cost of Living Plus Rent Index
        us_salary_text = driver.find_element_by_css_selector("#top_salary_value").text
        us_salary = int(us_salary_text.replace(",", "").replace("$", ""))
        base_salary = round(us_salary / 12 / config["eur_to_usd_10_year_avg"])
        role["baseSalary"] = base_salary

    pbar.close()


def compress_towards_affordability(cost_of_living, affordability):
    """Decrease differences between expensive and cheap locations."""
    if cost_of_living == affordability:
        return cost_of_living
    elif cost_of_living < affordability:
        return ((cost_of_living - affordability) * 0.33) + affordability
    else:
        return ((cost_of_living - affordability) * 0.67) + affordability


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
            countries(driver, config)
            salaries(driver, config)

        with open("config.yml", "w") as file:
            ruamel.yaml.dump(config, file, indent=4, Dumper=RoundTripDumper)
    print("config.yml saved")


if __name__ == "__main__":  # pragma: no cover
    main()
