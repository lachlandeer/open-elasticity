#' construct_panelist_activity.R
#'
#' contributors:  
#'
#' Creates a table of active panelists per week, using a rolling window.

# Libraries
library(optparse)
library(readr)
library(dplyr)
library(purrr)
library(lubridate)
library(tidyr)

# CLI parsing
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              help = "Path to cleaned purchases data"),
  make_option(c("-w", "--window"),
              type = "integer",
              default = 26,
              help = "Number of weeks for activity window [default = %default]"),
  make_option(c("-o", "--out"),
              type = "character",
              help = "Output file name")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$data) | is.null(opt$out)) {
  print_help(opt_parser)
  stop("Both --data and --out must be specified.", call. = FALSE)
}

# Load cleaned purchase data
df <- read_csv(opt$data, show_col_types = FALSE)

# Extract panelist-week activity
panelist_week <- df %>%
  distinct(country, panelist, year_week)

# Get ordered list of weeks per country
weeks_by_country <- panelist_week %>%
  distinct(country, year_week) %>%
  arrange(country, year_week) %>%
  group_by(country) %>%
  summarise(weeks = list(year_week), .groups = "drop")

# Function to get lookback windows
get_active_windows <- function(weeks_vec, window_size) {
  map(seq_along(weeks_vec), function(i) {
    window_weeks <- weeks_vec[max(1, i - (window_size - 1)):i]
    tibble(
      target_week = weeks_vec[i],
      lookback_weeks = list(window_weeks)
    )
  }) %>%
    bind_rows()
}

# Generate rolling windows using parameter
active_windows <- weeks_by_country %>%
  mutate(windows = map(weeks, get_active_windows, opt$window)) %>%
  select(country, windows) %>%
  unnest(windows)

# Join with panelist-week activity to get active panelists
active_panelists <- active_windows %>%
  unnest(lookback_weeks) %>%
  rename(year_week = lookback_weeks) %>%
  left_join(panelist_week, by = c("country", "year_week")) %>%
  distinct(country, target_week, panelist)

# Count number of active panelists per week
n_active_by_week <- active_panelists %>%
  group_by(country, target_week) %>%
  summarise(n_active = n_distinct(panelist), .groups = "drop") %>%
  rename(year_week = target_week)

# Save result
write_csv(n_active_by_week, opt$out)
message("✅ Active panelists file written to: ", opt$out)
