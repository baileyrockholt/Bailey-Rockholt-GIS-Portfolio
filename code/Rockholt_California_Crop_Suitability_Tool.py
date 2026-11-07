import csv
import math
from datetime import datetime


COUNTIES = {
    "Butte": ("Sacramento Valley", 680, 18.5, 70),
    "Fresno": ("San Joaquin Valley", 285, 22.5, 95),
    "Imperial": ("Imperial Valley", 75, 25.5, -15),
    "Kern": ("Southern San Joaquin Valley", 165, 23.5, 125),
    "Merced": ("San Joaquin Valley", 325, 21.0, 55),
    "Monterey": ("Central Coast", 490, 15.5, 45),
    "Napa": ("North Coast", 620, 17.0, 80),
    "Riverside": ("Inland Southern California", 260, 22.5, 300),
    "Siskiyou": ("Intermountain Northern California", 510, 10.5, 790),
    "Tulare": ("Southern San Joaquin Valley", 275, 22.0, 105),
    "Ventura": ("South Coast", 395, 18.0, 55),
    "Yolo": ("Sacramento Valley", 475, 19.5, 20),
}


# Format:
# name: (pH range, rainfall range, temperature range, elevation range,
#        preferred regions, water demand, notes)
CROPS = {
    "Alfalfa": ((6.5, 8.0), (100, 650), (17, 30), (0, 1800),
                ["San Joaquin Valley", "Imperial Valley"], "Very high",
                "Widely grown where irrigation supports repeated harvests."),
    "Almonds": ((6.0, 7.5), (250, 650), (16, 25), (0, 700),
                ["San Joaquin Valley", "Sacramento Valley"], "High",
                "Warm interior valleys and dependable irrigation are preferred."),
    "Avocados": ((5.5, 7.0), (300, 850), (17, 24), (0, 650),
                 ["South Coast", "Inland Southern California"], "High",
                 "Mild temperatures, drainage, and low frost risk are important."),
    "Broccoli": ((6.0, 7.4), (250, 700), (11, 20), (0, 1300),
                 ["Central Coast", "Imperial Valley"], "Moderate",
                 "Cool coastal and winter desert production are common."),
    "Carrots": ((5.8, 7.0), (200, 650), (12, 23), (0, 1500),
                ["Southern San Joaquin Valley", "Imperial Valley"], "Moderate",
                "Loose soils and moderate temperatures are preferred."),
    "Cotton": ((5.8, 8.0), (100, 550), (22, 32), (0, 750),
               ["Southern San Joaquin Valley", "San Joaquin Valley"],
               "Moderate to high",
               "Requires a long frost-free season and hot, dry summers."),
    "Lemons": ((5.8, 7.4), (300, 800), (17, 25), (0, 500),
               ["South Coast"], "High",
               "Best suited to mild coastal locations with limited frost."),
    "Lettuce": ((6.0, 7.0), (250, 700), (11, 20), (0, 1200),
                ["Central Coast", "Imperial Valley", "South Coast"], "Moderate",
                "Cool coastal areas dominate, with winter desert production."),
    "Olives": ((6.0, 8.0), (200, 650), (15, 27), (0, 900),
               ["Sacramento Valley", "San Joaquin Valley", "North Coast"],
               "Low to moderate",
               "Mediterranean climates and dry summers are favorable."),
    "Oranges": ((5.8, 7.5), (250, 750), (17, 28), (0, 800),
                ["Southern San Joaquin Valley", "Inland Southern California"],
                "High",
                "Warm conditions, drainage, and frost protection matter."),
    "Pistachios": ((6.0, 8.0), (150, 550), (18, 29), (0, 800),
                   ["Southern San Joaquin Valley", "San Joaquin Valley"],
                   "Moderate to high",
                   "Performs well in hot, dry inland areas with long summers."),
    "Processing Tomatoes": ((5.8, 7.4), (200, 650), (19, 29), (0, 900),
                            ["Sacramento Valley", "San Joaquin Valley"],
                            "Moderate to high",
                            "Common in hot interior valleys with irrigated fields."),
    "Rice": ((5.2, 7.2), (400, 1000), (20, 29), (0, 250),
             ["Sacramento Valley"], "Very high",
             "Requires flat land, suitable soils, and dependable water."),
    "Strawberries": ((5.5, 6.7), (300, 750), (13, 21), (0, 500),
                     ["Central Coast", "South Coast"], "Moderate to high",
                     "Mild coastal temperatures support intensive production."),
    "Wine Grapes": ((5.5, 7.5), (300, 850), (14, 25), (0, 1500),
                    ["North Coast", "Central Coast", "San Joaquin Valley"],
                    "Low to moderate",
                    "Adaptable across coastal, inland, and foothill climates."),
}


WEIGHTS = {"Soil pH": 0.30, "Rainfall": 0.20,
           "Temperature": 0.35, "Elevation": 0.15}


def get_number(prompt, default=None):
    """Read a valid number from the user."""
    while True:
        label = f"{prompt} [{default}]: " if default is not None else f"{prompt}: "
        value = input(label).strip()
        if value == "" and default is not None:
            return float(default)
        try:
            return float(value)
        except ValueError:
            print("Please enter a valid number.")


def range_score(value, preferred_range):
    """Give the highest score near the center of a preferred range."""
    low, high = preferred_range
    midpoint = (low + high) / 2
    half_width = max((high - low) / 2, 0.01)
    distance = abs(value - midpoint) / half_width

    if distance <= 1:
        score = 100 - 18 * distance ** 1.4
    else:
        score = 82 * math.exp(-1.15 * (distance - 1))

    return round(max(0, min(100, score)), 1)


def classify(score):
    if score >= 90:
        return "Excellent"
    if score >= 80:
        return "Good"
    if score >= 70:
        return "Moderate"
    if score >= 55:
        return "Limited"
    return "Poor"


def analyze_crop(name, crop, site):
    ph, rain, temp, elev, regions, water, notes = crop
    factors = {
        "Soil pH": range_score(site["ph"], ph),
        "Rainfall": range_score(site["rainfall"], rain),
        "Temperature": range_score(site["temperature"], temp),
        "Elevation": range_score(site["elevation"], elev),
    }

    environmental = sum(factors[key] * WEIGHTS[key] for key in WEIGHTS)
    regional = 100 if site["region"] in regions else 65
    overall = round(environmental * 0.88 + regional * 0.12, 1)

    return {
        "crop": name,
        "score": overall,
        "class": classify(overall),
        "limit": min(factors, key=factors.get),
        "factors": factors,
        "water": water,
        "notes": notes,
    }


def choose_site():
    names = sorted(COUNTIES)

    print("\nCOUNTY PRESETS")
    for number, name in enumerate(names, 1):
        print(f"{number:>2}. {name}")
    print(f"{len(names) + 1:>2}. Custom site")
    print(" 0. Return")

    while True:
        choice = input("\nSelection: ").strip()
        if choice == "0":
            return None

        try:
            choice = int(choice)
        except ValueError:
            print("Enter a menu number.")
            continue

        if 1 <= choice <= len(names):
            name = names[choice - 1]
            region, rain, temp, elev = COUNTIES[name]
            print(f"\nLoaded {name} County. Press Enter to keep each preset.")
            return {
                "name": name,
                "region": region,
                "ph": get_number("Soil pH", 6.5),
                "rainfall": get_number("Annual rainfall (mm)", rain),
                "temperature": get_number("Average temperature (C)", temp),
                "elevation": get_number("Elevation (m)", elev),
            }

        if choice == len(names) + 1:
            return {
                "name": input("Site name: ").strip() or "Custom Site",
                "region": input("California region: ").strip() or "Other",
                "ph": get_number("Soil pH"),
                "rainfall": get_number("Annual rainfall (mm)"),
                "temperature": get_number("Average temperature (C)"),
                "elevation": get_number("Elevation (m)"),
            }

        print("That selection is not available.")


def display_results(site, results):
    print("\n" + "=" * 70)
    print(f"CROP SUITABILITY RESULTS: {site['name'].upper()}")
    print("=" * 70)
    print(f"Region: {site['region']}")
    print(f"pH: {site['ph']} | Rainfall: {site['rainfall']} mm | "
          f"Temperature: {site['temperature']} C | Elevation: {site['elevation']} m")
    print("\nTOP RECOMMENDATIONS")
    print("-" * 70)

    for rank, result in enumerate(results[:10], 1):
        print(f"{rank:>2}. {result['crop']:<22}"
              f"{result['score']:>6.1f}%   {result['class']}")


def display_details(result):
    print("\n" + "=" * 70)
    print(result["crop"].upper())
    print("=" * 70)
    print(f"Overall score: {result['score']:.1f}%")
    print(f"Classification: {result['class']}")
    print(f"Primary limiting factor: {result['limit']}")
    print(f"Water demand: {result['water']}")
    print("\nFACTOR SCORES")

    for factor, score in result["factors"].items():
        print(f"  {factor:<12}: {score:>5.1f}%")

    print(f"\nNotes: {result['notes']}")


def export_csv(site, results):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_name = site["name"].replace(" ", "_")
    filename = f"{safe_name}_crop_suitability_{timestamp}.csv"

    with open(filename, "w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(["Rank", "Crop", "Score", "Classification",
                         "Limiting Factor", "Water Demand", "pH Score",
                         "Rainfall Score", "Temperature Score", "Elevation Score"])

        for rank, result in enumerate(results, 1):
            f = result["factors"]
            writer.writerow([rank, result["crop"], result["score"],
                             result["class"], result["limit"], result["water"],
                             f["Soil pH"], f["Rainfall"],
                             f["Temperature"], f["Elevation"]])

    print(f"\nExported: {filename}")


def run_analysis():
    site = choose_site()
    if site is None:
        return

    results = [analyze_crop(name, crop, site)
               for name, crop in CROPS.items()]
    results.sort(key=lambda item: item["score"], reverse=True)
    display_results(site, results)

    while True:
        print("\n1. View crop details")
        print("2. Export results to CSV")
        print("3. Return to main menu")
        choice = input("Selection: ").strip()

        if choice == "1":
            for number, result in enumerate(results, 1):
                print(f"{number:>2}. {result['crop']:<22} {result['score']:>5.1f}%")
            try:
                number = int(input("Crop number: "))
                if 1 <= number <= len(results):
                    display_details(results[number - 1])
                else:
                    print("That number is not available.")
            except ValueError:
                print("Enter a valid number.")
        elif choice == "2":
            export_csv(site, results)
        elif choice == "3":
            return
        else:
            print("Choose 1, 2, or 3.")


def browse_crops():
    names = sorted(CROPS)

    while True:
        print("\nCROP DATABASE")
        for number, name in enumerate(names, 1):
            print(f"{number:>2}. {name}")
        print(" 0. Return")

        choice = input("Selection: ").strip()
        if choice == "0":
            return

        try:
            choice = int(choice)
        except ValueError:
            print("Enter a menu number.")
            continue

        if 1 <= choice <= len(names):
            name = names[choice - 1]
            ph, rain, temp, elev, regions, water, notes = CROPS[name]
            print(f"\n{name.upper()}")
            print(f"pH: {ph[0]}-{ph[1]}")
            print(f"Rainfall: {rain[0]}-{rain[1]} mm")
            print(f"Temperature: {temp[0]}-{temp[1]} C")
            print(f"Elevation: {elev[0]}-{elev[1]} m")
            print(f"Preferred regions: {', '.join(regions)}")
            print(f"Water demand: {water}")
            print(f"Notes: {notes}")
        else:
            print("That selection is not available.")


def main():
    while True:
        print("\n" + "=" * 70)
        print("CALIFORNIA CROP SUITABILITY TOOL")
        print("Bailey Rockholt")
        print("=" * 70)
        print("1. Analyze a county or custom site")
        print("2. Browse crop database")
        print("3. Exit")

        choice = input("\nSelection: ").strip()
        if choice == "1":
            run_analysis()
        elif choice == "2":
            browse_crops()
        elif choice == "3":
            print("\nProgram closed.")
            break
        else:
            print("Choose 1, 2, or 3.")


if __name__ == "__main__":
    main()