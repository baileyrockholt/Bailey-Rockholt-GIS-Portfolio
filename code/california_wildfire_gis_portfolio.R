# =====================================================================
# California Wildfire Incident Analysis
# Bailey Rockholt
#
# Purpose:
# Clean and analyze California wildfire incident data, identify temporal
# and county-level patterns, create portfolio-ready visualizations, and
# export summary tables for use in ArcGIS Online.
#
# Required packages:
# tidyverse, lubridate, scales
#
# Required input:
# California_Fire_Incidents.csv
#
# Place the CSV in the same folder as this R script before running.
# =====================================================================


# ---------------------------------------------------------------------
# 1. Load required packages
# ---------------------------------------------------------------------

library(tidyverse)
library(lubridate)
library(scales)


# ---------------------------------------------------------------------
# 2. Load the wildfire incident dataset
# ---------------------------------------------------------------------

input_file <- "California_Fire_Incidents.csv"

if (!file.exists(input_file)) {
  stop(
    paste(
      "Input file not found:",
      input_file,
      "\nPlace the CSV in the same folder as this R script."
    )
  )
}

fire_raw <- read.csv(
  input_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

cat("\nDataset successfully loaded.\n")
cat("Original rows:", nrow(fire_raw), "\n")
cat("Original columns:", ncol(fire_raw), "\n")


# ---------------------------------------------------------------------
# 3. Confirm that required fields are present
# ---------------------------------------------------------------------

required_fields <- c(
  "Name",
  "Counties",
  "ArchiveYear",
  "Started",
  "AcresBurned",
  "Fatalities"
)

missing_fields <- setdiff(required_fields, names(fire_raw))

if (length(missing_fields) > 0) {
  stop(
    paste(
      "The following required fields are missing:",
      paste(missing_fields, collapse = ", ")
    )
  )
}

cat("\nAll required fields are present.\n")


# ---------------------------------------------------------------------
# 4. Clean and prepare the data
# ---------------------------------------------------------------------

fire_data <- fire_raw %>%
  mutate(
    # Remove unnecessary spaces from text fields
    Name = str_squish(Name),
    Counties = str_squish(Counties),
    
    # Convert numeric fields safely
    ArchiveYear = suppressWarnings(as.integer(ArchiveYear)),
    AcresBurned = suppressWarnings(as.numeric(AcresBurned)),
    Fatalities = suppressWarnings(as.numeric(Fatalities)),
    
    # Attempt to recognize several common date and date-time formats
    Started_Parsed = parse_date_time(
      Started,
      orders = c(
        "ymd HMS",
        "ymd HM",
        "ymd",
        "mdy HMS",
        "mdy HM",
        "mdy",
        "m/d/Y H:M:S",
        "m/d/Y H:M"
      ),
      quiet = TRUE
    ),
    
    # Create temporal fields
    Start_Date = as.Date(Started_Parsed),
    Start_Year = year(Started_Parsed),
    Start_Month = month(
      Started_Parsed,
      label = TRUE,
      abbr = TRUE
    ),
    Start_Month_Number = month(Started_Parsed),
    
    # Create an analysis field for fatalities.
    # This assumes missing values represent no reported fatalities.
    Fatalities_Analysis = replace_na(Fatalities, 0)
  ) %>%
  filter(
    !is.na(Name),
    Name != "",
    !is.na(Counties),
    Counties != ""
  )


# ---------------------------------------------------------------------
# 5. Data-quality checks
# ---------------------------------------------------------------------

missingness_summary <- tibble(
  Field = c(
    "Name",
    "Counties",
    "ArchiveYear",
    "Started",
    "AcresBurned",
    "Fatalities"
  ),
  Missing_Values = c(
    sum(is.na(fire_data$Name) | fire_data$Name == ""),
    sum(is.na(fire_data$Counties) | fire_data$Counties == ""),
    sum(is.na(fire_data$ArchiveYear)),
    sum(is.na(fire_data$Started_Parsed)),
    sum(is.na(fire_data$AcresBurned)),
    sum(is.na(fire_data$Fatalities))
  )
) %>%
  mutate(
    Percent_Missing = Missing_Values / nrow(fire_data)
  )

cat("\nMissing-data summary:\n")
print(missingness_summary)

write.csv(
  missingness_summary,
  "wildfire_missingness_summary.csv",
  row.names = FALSE
)


# Identify potentially invalid acreage values

invalid_acres <- fire_data %>%
  filter(!is.na(AcresBurned), AcresBurned < 0)

if (nrow(invalid_acres) > 0) {
  warning(
    paste(
      nrow(invalid_acres),
      "records contain negative AcresBurned values."
    )
  )
}


# Remove negative acreage values from acreage-based analysis

fire_data <- fire_data %>%
  mutate(
    AcresBurned_Analysis = if_else(
      AcresBurned >= 0,
      AcresBurned,
      NA_real_
    )
  )


# ---------------------------------------------------------------------
# 6. Overall descriptive statistics
# ---------------------------------------------------------------------

overall_summary <- tibble(
  Total_Incidents = nrow(fire_data),
  Earliest_Archive_Year = min(
    fire_data$ArchiveYear,
    na.rm = TRUE
  ),
  Latest_Archive_Year = max(
    fire_data$ArchiveYear,
    na.rm = TRUE
  ),
  Total_Acres_Burned = sum(
    fire_data$AcresBurned_Analysis,
    na.rm = TRUE
  ),
  Mean_Acres_Per_Incident = mean(
    fire_data$AcresBurned_Analysis,
    na.rm = TRUE
  ),
  Median_Acres_Per_Incident = median(
    fire_data$AcresBurned_Analysis,
    na.rm = TRUE
  ),
  Maximum_Acres_Burned = max(
    fire_data$AcresBurned_Analysis,
    na.rm = TRUE
  ),
  Total_Reported_Fatalities = sum(
    fire_data$Fatalities_Analysis,
    na.rm = TRUE
  ),
  Counties_Represented = n_distinct(
    fire_data$Counties,
    na.rm = TRUE
  )
)

cat("\nOverall wildfire summary:\n")
print(overall_summary)

write.csv(
  overall_summary,
  "wildfire_overall_summary.csv",
  row.names = FALSE
)


# ---------------------------------------------------------------------
# 7. Identify the largest and most fatal incidents
# ---------------------------------------------------------------------

largest_fires <- fire_data %>%
  filter(!is.na(AcresBurned_Analysis)) %>%
  arrange(desc(AcresBurned_Analysis)) %>%
  select(
    Name,
    Counties,
    ArchiveYear,
    Start_Date,
    AcresBurned = AcresBurned_Analysis,
    Fatalities = Fatalities_Analysis
  ) %>%
  slice_head(n = 10)

most_fatal_fires <- fire_data %>%
  filter(Fatalities_Analysis > 0) %>%
  arrange(
    desc(Fatalities_Analysis),
    desc(AcresBurned_Analysis)
  ) %>%
  select(
    Name,
    Counties,
    ArchiveYear,
    Start_Date,
    AcresBurned = AcresBurned_Analysis,
    Fatalities = Fatalities_Analysis
  ) %>%
  slice_head(n = 10)

cat("\nTen largest incidents by acres burned:\n")
print(largest_fires)

cat("\nIncidents with the most reported fatalities:\n")

if (nrow(most_fatal_fires) > 0) {
  print(most_fatal_fires)
} else {
  cat("No incidents with reported fatalities were found.\n")
}

write.csv(
  largest_fires,
  "largest_wildfire_incidents.csv",
  row.names = FALSE
)

write.csv(
  most_fatal_fires,
  "most_fatal_wildfire_incidents.csv",
  row.names = FALSE
)


# ---------------------------------------------------------------------
# 8. Annual wildfire summary
# ---------------------------------------------------------------------

annual_summary <- fire_data %>%
  filter(!is.na(ArchiveYear)) %>%
  group_by(ArchiveYear) %>%
  summarise(
    Total_Fires = n(),
    Total_Acres_Burned = sum(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Average_Acres_Burned = mean(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Median_Acres_Burned = median(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Largest_Fire_Acres = max(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Total_Fatalities = sum(
      Fatalities_Analysis,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  arrange(ArchiveYear)

cat("\nAnnual wildfire summary:\n")
print(annual_summary)

write.csv(
  annual_summary,
  "wildfire_annual_summary.csv",
  row.names = FALSE
)


# ---------------------------------------------------------------------
# 9. Monthly wildfire summary
# ---------------------------------------------------------------------

monthly_summary <- fire_data %>%
  filter(
    !is.na(Start_Month),
    !is.na(Start_Month_Number)
  ) %>%
  group_by(
    Start_Month_Number,
    Start_Month
  ) %>%
  summarise(
    Total_Fires = n(),
    Total_Acres_Burned = sum(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Average_Acres_Burned = mean(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Total_Fatalities = sum(
      Fatalities_Analysis,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  arrange(Start_Month_Number)

cat("\nMonthly wildfire summary:\n")
print(monthly_summary)

write.csv(
  monthly_summary,
  "wildfire_monthly_summary.csv",
  row.names = FALSE
)


# ---------------------------------------------------------------------
# 10. County-level summary for ArcGIS Online
# ---------------------------------------------------------------------

county_summary <- fire_data %>%
  filter(
    !is.na(Counties),
    Counties != ""
  ) %>%
  group_by(Counties) %>%
  summarise(
    Total_Fires = n(),
    Total_Acres_Burned = sum(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Average_Acres_Burned = mean(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Median_Acres_Burned = median(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Largest_Fire_Acres = max(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Total_Fatalities = sum(
      Fatalities_Analysis,
      na.rm = TRUE
    ),
    First_Archive_Year = min(
      ArchiveYear,
      na.rm = TRUE
    ),
    Most_Recent_Archive_Year = max(
      ArchiveYear,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  arrange(desc(Total_Fires))

cat("\nCounty-level wildfire summary:\n")
print(county_summary)

write.csv(
  county_summary,
  "california_wildfire_county_summary.csv",
  row.names = FALSE
)


# ---------------------------------------------------------------------
# 11. County-by-year summary
# ---------------------------------------------------------------------

county_year_summary <- fire_data %>%
  filter(
    !is.na(Counties),
    Counties != "",
    !is.na(ArchiveYear)
  ) %>%
  group_by(
    Counties,
    ArchiveYear
  ) %>%
  summarise(
    Total_Fires = n(),
    Total_Acres_Burned = sum(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Average_Acres_Burned = mean(
      AcresBurned_Analysis,
      na.rm = TRUE
    ),
    Total_Fatalities = sum(
      Fatalities_Analysis,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(Total_Fires),
    desc(Total_Acres_Burned)
  )

write.csv(
  county_year_summary,
  "wildfire_county_year_summary.csv",
  row.names = FALSE
)


# Identify county-year combinations with more than 15 incidents

high_frequency_county_years <- county_year_summary %>%
  filter(Total_Fires > 15) %>%
  arrange(
    desc(Total_Fires),
    desc(Total_Acres_Burned)
  )

cat("\nCounty-year combinations with more than 15 fires:\n")
print(high_frequency_county_years)

write.csv(
  high_frequency_county_years,
  "high_frequency_county_years.csv",
  row.names = FALSE
)


# ---------------------------------------------------------------------
# 12. Chart: wildfire incident count by year
# ---------------------------------------------------------------------

p_year_count <- ggplot(
  annual_summary,
  aes(
    x = ArchiveYear,
    y = Total_Fires
  )
) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.8) +
  scale_x_continuous(
    breaks = scales::pretty_breaks()
  ) +
  scale_y_continuous(
    labels = comma,
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title = "California Wildfire Incidents by Year",
    subtitle = "Number of recorded wildfire incidents by archive year",
    x = "Archive Year",
    y = "Number of Wildfire Incidents",
    caption = "Source: California Fire Incidents dataset"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

ggsave(
  "wildfire_incidents_by_year.png",
  p_year_count,
  width = 9,
  height = 5.5,
  dpi = 300
)


# ---------------------------------------------------------------------
# 13. Chart: total acres burned by year
# ---------------------------------------------------------------------

p_year_acres <- ggplot(
  annual_summary,
  aes(
    x = ArchiveYear,
    y = Total_Acres_Burned
  )
) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.8) +
  scale_x_continuous(
    breaks = scales::pretty_breaks()
  ) +
  scale_y_continuous(
    labels = comma,
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title = "Total Acres Burned by Year",
    subtitle = "Cumulative recorded acreage burned by archive year",
    x = "Archive Year",
    y = "Total Acres Burned",
    caption = "Missing acreage values were excluded rather than imputed"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

ggsave(
  "wildfire_acres_by_year.png",
  p_year_acres,
  width = 9,
  height = 5.5,
  dpi = 300
)


# ---------------------------------------------------------------------
# 14. Chart: wildfire incident count by month
# ---------------------------------------------------------------------

p_month_count <- ggplot(
  monthly_summary,
  aes(
    x = Start_Month,
    y = Total_Fires
  )
) +
  geom_col() +
  scale_y_continuous(
    labels = comma,
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title = "California Wildfire Incidents by Month",
    subtitle = "Seasonal distribution based on recorded incident start dates",
    x = "Month",
    y = "Number of Wildfire Incidents",
    caption = "Records with unrecognized or missing start dates were excluded"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(
  "wildfire_incidents_by_month.png",
  p_month_count,
  width = 9,
  height = 5.5,
  dpi = 300
)


# ---------------------------------------------------------------------
# 15. Chart: top counties by wildfire frequency
# ---------------------------------------------------------------------

top_counties_frequency <- county_summary %>%
  slice_max(
    Total_Fires,
    n = 10,
    with_ties = FALSE
  )

p_county_frequency <- ggplot(
  top_counties_frequency,
  aes(
    x = reorder(Counties, Total_Fires),
    y = Total_Fires
  )
) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(
    labels = comma,
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title = "Top 10 California Counties by Wildfire Frequency",
    subtitle = "Counties with the highest number of recorded incidents",
    x = "County",
    y = "Number of Wildfire Incidents",
    caption = "Based on records available in the source dataset"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(
  "wildfire_county_frequency_chart.png",
  p_county_frequency,
  width = 9,
  height = 6,
  dpi = 300
)


# ---------------------------------------------------------------------
# 16. Chart: top counties by total acres burned
# ---------------------------------------------------------------------

top_counties_acres <- county_summary %>%
  slice_max(
    Total_Acres_Burned,
    n = 10,
    with_ties = FALSE
  )

p_county_acres <- ggplot(
  top_counties_acres,
  aes(
    x = reorder(Counties, Total_Acres_Burned),
    y = Total_Acres_Burned
  )
) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(
    labels = comma,
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title = "Top 10 California Counties by Total Acres Burned",
    subtitle = "Cumulative recorded wildfire acreage by county",
    x = "County",
    y = "Total Acres Burned",
    caption = "Missing acreage values were excluded rather than imputed"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(
  "wildfire_county_acres_burned_chart.png",
  p_county_acres,
  width = 9,
  height = 6,
  dpi = 300
)


# ---------------------------------------------------------------------
# 17. Chart: fire frequency compared with total acreage
# ---------------------------------------------------------------------

p_frequency_acres <- ggplot(
  county_summary,
  aes(
    x = Total_Fires,
    y = Total_Acres_Burned
  )
) +
  geom_point(
    size = 3,
    alpha = 0.75
  ) +
  scale_x_continuous(
    labels = comma
  ) +
  scale_y_continuous(
    labels = comma
  ) +
  labs(
    title = "Wildfire Frequency and Total Acres Burned by County",
    subtitle = "Comparison of incident frequency and cumulative acreage",
    x = "Number of Wildfire Incidents",
    y = "Total Acres Burned",
    caption = "Each point represents one county"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

ggsave(
  "wildfire_frequency_vs_acres.png",
  p_frequency_acres,
  width = 8,
  height = 6,
  dpi = 300
)


# ---------------------------------------------------------------------
# 18. Exploratory annual trend model
# ---------------------------------------------------------------------
#
# This model is included only as an exploratory programming demonstration.
# Wildfire behavior is influenced by weather, vegetation, drought, ignition
# sources, suppression practices, and many other variables. A simple time
# trend should not be interpreted as an operational wildfire forecast.
# ---------------------------------------------------------------------

trend_data <- annual_summary %>%
  filter(
    !is.na(ArchiveYear),
    is.finite(Total_Acres_Burned)
  )

if (nrow(trend_data) >= 3) {
  
  acreage_trend_model <- lm(
    log1p(Total_Acres_Burned) ~ ArchiveYear,
    data = trend_data
  )
  
  next_year <- max(
    trend_data$ArchiveYear,
    na.rm = TRUE
  ) + 1
  
  predicted_log_acres <- predict(
    acreage_trend_model,
    newdata = data.frame(
      ArchiveYear = next_year
    ),
    interval = "prediction"
  )
  
  predicted_acres <- as.data.frame(
    expm1(predicted_log_acres)
  )
  
  trend_prediction <- tibble(
    ArchiveYear = next_year,
    Estimated_Total_Acres = predicted_acres$fit,
    Lower_Prediction_Bound = pmax(
      predicted_acres$lwr,
      0
    ),
    Upper_Prediction_Bound = predicted_acres$upr,
    Model_Type = "Exploratory log-linear time trend"
  )
  
  cat("\nExploratory trend-model summary:\n")
  print(summary(acreage_trend_model))
  
  cat("\nExploratory acreage estimate for", next_year, ":\n")
  print(trend_prediction)
  
  write.csv(
    trend_prediction,
    "exploratory_wildfire_trend_prediction.csv",
    row.names = FALSE
  )
  
  capture.output(
    summary(acreage_trend_model),
    file = "exploratory_trend_model_summary.txt"
  )
  
} else {
  
  cat(
    "\nTrend model not created because fewer than three years",
    "of valid annual data were available.\n"
  )
}


# ---------------------------------------------------------------------
# 19. Create a project output inventory
# ---------------------------------------------------------------------

output_inventory <- tibble(
  File = c(
    "wildfire_missingness_summary.csv",
    "wildfire_overall_summary.csv",
    "largest_wildfire_incidents.csv",
    "most_fatal_wildfire_incidents.csv",
    "wildfire_annual_summary.csv",
    "wildfire_monthly_summary.csv",
    "california_wildfire_county_summary.csv",
    "wildfire_county_year_summary.csv",
    "high_frequency_county_years.csv",
    "wildfire_incidents_by_year.png",
    "wildfire_acres_by_year.png",
    "wildfire_incidents_by_month.png",
    "wildfire_county_frequency_chart.png",
    "wildfire_county_acres_burned_chart.png",
    "wildfire_frequency_vs_acres.png"
  ),
  Description = c(
    "Count and percentage of missing values by field",
    "Overall descriptive statistics",
    "Ten largest incidents by acres burned",
    "Incidents with the most reported fatalities",
    "Annual wildfire statistics",
    "Monthly wildfire statistics",
    "County-level table for ArcGIS Online",
    "County-by-year wildfire summary",
    "County-year combinations with more than 15 incidents",
    "Annual incident-count chart",
    "Annual acreage chart",
    "Monthly incident-count chart",
    "Top counties by wildfire frequency",
    "Top counties by total acres burned",
    "County frequency and acreage comparison"
  )
)

write.csv(
  output_inventory,
  "wildfire_project_output_inventory.csv",
  row.names = FALSE
)


# ---------------------------------------------------------------------
# 20. Completion message
# ---------------------------------------------------------------------

cat("\n============================================================\n")
cat("California wildfire analysis completed successfully.\n")
cat("============================================================\n")

cat("\nCleaned records analyzed:", nrow(fire_data), "\n")
cat("Counties represented:", n_distinct(fire_data$Counties), "\n")
cat(
  "Archive years represented:",
  min(fire_data$ArchiveYear, na.rm = TRUE),
  "through",
  max(fire_data$ArchiveYear, na.rm = TRUE),
  "\n"
)

cat("\nKey outputs created:\n")
cat("- County-level ArcGIS Online summary\n")
cat("- Annual, monthly, and county-by-year summaries\n")
cat("- Missing-data and descriptive-statistics reports\n")
cat("- Largest-fire and fatality tables\n")
cat("- Five portfolio-ready charts\n")
cat("- Exploratory annual trend model when sufficient data exist\n")
cat("\nReview all outputs before publication or interpretation.\n")
