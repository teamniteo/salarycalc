"""Use a real browser to fetch config.yaml values."""

from datetime import date
from playwright.sync_api import Page
from playwright.sync_api import sync_playwright
from ruamel.yaml import RoundTripDumper
from ruamel.yaml import RoundTripLoader
from tqdm import tqdm

import argparse
import ruamel.yaml
import sys
import time


def usd_to_eur_10_year_average(
    page: Page,
    config: ruamel.yaml.comments.CommentedMap,
) -> None:
    """Update the eur_to_usd_10_year_arg value in config.yaml."""
    pbar = tqdm(total=8)
    pbar.set_description("Processing eur_to_usd_10_year_avg")

    # Load OFX.com
    page.goto(
        "https://www.ofx.com/en-us/forex-news/historical-exchange-rates/yearly-average-rates/"  # noqa: 501
    )
    pbar.update()

    # Swap USD -> EUR to EUR -> USD
    page.locator("button#historical-rate-swap-button").click()
    pbar.update()

    # Select yearly frequency
    page.get_by_label("Yearly").check()
    pbar.update()

    # Choose all-time reporting period
    # There is a bug in their site where you cannot select `All` before
    # you select something else
    # page.get_by_text("All time", exact=True).click()
    pbar.update()

    # Click `Retrieve Data` button
    page.get_by_role("button", name="Retrieve data").click()
    pbar.update()

    # Wait for data to reload
    time.sleep(3)
    pbar.update()

    # Extract the Average Rate
    average_cell = page.get_by_role("cell", name="Average")
    next_cell = average_cell.locator("+ td")
    avg = round(float(next_cell.inner_text()), 6)
    pbar.update()

    config["eur_to_usd_10_year_avg"] = avg

    pbar.update()
    pbar.close()


def countries(
    page: Page,
    config: ruamel.yaml.comments.CommentedMap,
) -> None:
    """Update the Cost of Living values in config.yaml."""

    pbar = tqdm(total=len(config["countries"]))
    pbar.set_description("Processing countries")

    for country in config["countries"]:
        pbar.update()

        # Load numbeo
        page.goto(
            "https://www.numbeo.com/cost-of-living/compare_countries_result.jsp?"
            f"country1=United+States&country2={country['name']}"
        )

        # Extract Cost of Living Plus Rent Index
        difference_text = page.locator(
            ".table_indices_diff "
            "> tbody:nth-child(1) "
            "> tr:nth-child(3) "
            "> td:nth-child(1)"
        ).inner_text()

        # 'Cost of Living Including Rent in Netherlands is 2.05% lower than
        # in United States'
        difference = float(difference_text.split(" is ")[1].split("%")[0])

        if "lower" in difference_text:
            numbeo_ratio = 1 - (difference / 100)
        elif "higher" in difference_text:
            numbeo_ratio = 1 + (difference / 100)
        else:
            raise ValueError("Unknown difference_text")

        country["cost_of_living"] = round(numbeo_ratio, 2)
        country["compressed_cost_of_living"] = round(
            compress_towards_affordability(numbeo_ratio, config["affordability"]), 2
        )

    config["countries_updated"] = date.today().isoformat()
    pbar.close()


def salaries(
    page: Page,
    config: ruamel.yaml.comments.CommentedMap,
) -> None:
    """Update the baseSalary values in config.yaml."""

    roles = []
    for career in config["careers"]:
        for role in career["roles"]:
            roles.append(role)

    pbar = tqdm(total=len(roles))
    pbar.set_description("Processing roles")

    # kill popups
    page.goto("https://www.salary.com/tools/salary-calculator/web-designer-i")

    page.locator("#sal-demoform-popup").get_by_role("img").first.click()
    page.get_by_role("button", name="Close").click()

    for role in roles:
        pbar.update()

        # Load salary.com
        page.goto(
            f"https://www.salary.com/tools/salary-calculator/{role['salary_com_key']}"
        )

        # Extract Cost of Living Plus Rent Index
        us_salary_text = page.locator("#top_salary_value").text_content()
        us_salary = int(us_salary_text.replace(",", "").replace("$", ""))
        base_salary = round(us_salary / 12 / config["eur_to_usd_10_year_avg"])
        role["baseSalary"] = base_salary

    config["careers_updated"] = date.today().isoformat()
    pbar.close()


def compress_towards_affordability(cost_of_living, affordability):
    """Decrease differences between expensive and cheap locations."""
    if cost_of_living == affordability:
        return cost_of_living
    else:
        return ((cost_of_living - affordability) * 0.33) + affordability


def main(argv=sys.argv) -> None:
    """Update salaries."""

    argparse.ArgumentParser(usage=("python3.11 fetch_config_values.py"))

    print("Starting Chrome and loading up config.yml")
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()

        with open("config.yml") as file:
            config = ruamel.yaml.load(file, Loader=RoundTripLoader)

            usd_to_eur_10_year_average(page, config)
            countries(page, config)
            salaries(page, config)

        with open("config.yml", "w") as file:
            ruamel.yaml.dump(config, file, indent=4, Dumper=RoundTripDumper)
    print("config.yml saved")


if __name__ == "__main__":  # pragma: no cover
    main()
