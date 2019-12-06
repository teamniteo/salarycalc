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

        with open("config.yml", "w") as file:
            ruamel.yaml.dump(config, file, indent=4, Dumper=RoundTripDumper)
    print("config.yml saved")


if __name__ == "__main__":  # pragma: no cover
    main()
