# Portfolio source code

These scripts were supplied by Bailey Rockholt and are retained unchanged. No R history, local machine paths, résumé source files, unpublished research data, or USDA datasets are included here.

## California wildfire analysis in R

File: `california_wildfire_gis_portfolio.R`

This is the recovered analysis workflow supplied with the portfolio materials. It checks required fields, cleans text and dates, excludes negative acreage from acreage analysis, summarizes annual/monthly/county patterns, exports CSV tables, and creates statistical graphics with ggplot2. It also includes a clearly labeled exploratory time-trend model, which is not an operational forecast.

To run locally:

1. Install R and the packages `tidyverse`, `lubridate`, and `scales`.
2. Obtain the original, appropriately licensed `California_Fire_Incidents.csv`.
3. Place it beside the script, set the R working directory to that folder, and run `source("california_wildfire_gis_portfolio.R")`.
4. Review exported tables and charts before using them. Run in a separate output folder because existing files with matching names may be overwritten.

Required fields: `Name`, `Counties`, `ArchiveYear`, `Started`, `AcresBurned`, `Fatalities`.

The raw CSV was not supplied, and R was unavailable in the review environment. This script was read but not executed. Existing portfolio charts are retained as original project evidence; no claim is made that this recovered version reproduced them exactly. Some output filenames differ from the original portfolio assets.

Interpretation considerations:

- County groups use the raw `Counties` field after trimming spaces. Multi-county strings are not split or allocated; inspect join keys before mapping or claiming complete county coverage.
- Missing fatalities are replaced with zero as an explicit assumption, not evidence of confirmed zero deaths.
- Missing or negative acreage is excluded from acreage summaries; all-missing groups can still yield zero sums or non-finite extrema and need review.
- The script does not explicitly deduplicate incidents or restrict the input to 2013–2019. The displayed map and charts cover that period; inspect the dataset used for a new run.
- The source dataset's authoritative citation and license still need confirmation. No dataset source is guessed here.

## California crop suitability prototype in Python

File: `Rockholt_California_Crop_Suitability_Tool.py`

Run with Python 3: `python Rockholt_California_Crop_Suitability_Tool.py`. Uses only Python standard-library modules. Supports 12 county presets, custom site inputs, 15 crop profiles, per-factor explanations, ranked results, and CSV exports.

Scoring uses soil pH (30%), rainfall (20%), temperature (35%), and elevation (15%). The environmental score contributes 88% and a hard-coded regional preference contributes 12% of the overall score. A score is a model output on a 0–100 scale, not a probability, yield estimate, or validated suitability assessment, although the original CLI prints a percent sign.

County values, crop ranges, weights, and classifications are illustrative assumptions without source citations in the supplied file. The tool does not read GIS layers or use live climate, soil, irrigation, frost, or parcel data. Water demand is descriptive and is not a scored factor. Input collection accepts non-finite or implausible numbers; use finite, physically plausible inputs and validate source data before extending the tool.

`crop-suitability-example.csv` is a reproducible software demonstration using the Yolo preset (pH 6.5, rainfall 475 mm, temperature 19.5 C, elevation 20 m). It is not an agronomic recommendation or observed field result.

Review checks passed for module import, preset/crop counts, score-weight normalization, score bounds with finite sample inputs, range-score behavior, limiting-factor labels, and basic CLI menu paths. The sample CSV was generated from the supplied Python implementation.
