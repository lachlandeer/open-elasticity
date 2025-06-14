#' filter_burnin_weeks.R
#'
#' contributors:  
#'
#' Drops early burn-in weeks from the merged brand panel using a country-specific XX-week window.

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)

# ---- CLI Parsing ----
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              help = "Input CSV file with brand panel data",
              metavar = "character"),
  make_option(c("-w", "--burnin_weeks"),
              type = "integer",
              default = 26,
              help = "Number of burn-in weeks to drop per country [default = %default]",
              metavar = "integer"),
  make_option(c("-o", "--out"),
              type = "character",
              default = "brand_panel_filtered.csv",
              help = "Output file after filtering [default = %default]",
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$data)) {
  print_help(opt_parser)
  stop("Input data must be provided", call. = FALSE)
}

# ---- Load input ----
message("📥 Loading brand panel from: ", opt$data)
df <- read_csv(opt$data)

# ---- Identify valid weeks ----
message("🧮 Filtering first ", opt$burnin_weeks, " weeks per country...")

valid_weeks <- df %>%
  distinct(country, year_week) %>%
  arrange(country, year_week) %>%
  group_by(country) %>%
  mutate(week_index = row_number()) %>%
  filter(week_index > opt$burnin_weeks) %>%
  select(country, year_week)

# ---- Filter data ----
df_filtered <- df %>%
  inner_join(valid_weeks, by = c("country", "year_week"))

# ---- Save ----
message("💾 Writing output to: ", opt$out)
write_csv(df_filtered, opt$out)
