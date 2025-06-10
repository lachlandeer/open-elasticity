#' construct_hausman_iv.R
#'
#' contributors: @lachlandeer
#'
#' Compute Hausman-style IVs: price_other, price_other_within_nest,
#' and numbered country-level robustness IVs.

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)
library(tidyr)
library(purrr)

# ---- CLI Options ----
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              help = "Input brand panel CSV (burned-in, EUR-adjusted, trimmed)",
              metavar = "character"),
  make_option(c("-o", "--out"),
              type = "character",
              default = "brand_panel_iv.csv",
              help = "Output file name with instruments [default = %default]",
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$data)) {
  print_help(opt_parser)
  stop("Input file is required", call. = FALSE)
}

# ---- Load data ----
panel <- read_csv(opt$data, show_col_types = FALSE)

# ---- Generate list of country-week combos ----
country_weeks <- panel %>% distinct(country, year_week)

# ---- Country index for consistent IV names ----
country_index <- panel %>%
  distinct(country) %>%
  arrange(country) %>%
  mutate(iv_id = row_number())

# ---- Function to compute IVs for one country-week ----
compute_iv <- function(this_country, this_week) {
  focal <- panel %>%
    filter(country == this_country, year_week == this_week)

  others <- panel %>%
    filter(country != this_country, year_week == this_week)

  # IV1: avg price across all other countries
  iv1_all <- others %>%
    summarise(price_other = mean(price_per_100g, na.rm = TRUE))

  # IV2: avg price in each other country
  iv2 <- others %>%
    group_by(country) %>%
    summarise(price_avg = mean(price_per_100g, na.rm = TRUE), .groups = "drop") %>%
    inner_join(country_index, by = "country") %>%
    mutate(varname = paste0("price_other_", iv_id)) %>%
    select(varname, price_avg) %>%
    pivot_wider(names_from = varname, values_from = price_avg)

  # IV1-nest: avg price in same nest (all other countries)
  nest_val <- focal$nest[1]
  iv1_nest <- others %>%
    filter(nest == nest_val) %>%
    summarise(price_other_within_nest = mean(price_per_100g, na.rm = TRUE))

  # IV2-nest: avg price in same nest by country
  iv2_nest <- others %>%
    filter(nest == nest_val) %>%
    group_by(country) %>%
    summarise(price_avg = mean(price_per_100g, na.rm = TRUE), .groups = "drop") %>%
    inner_join(country_index, by = "country") %>%
    mutate(varname = paste0("price_other_within_nest_", iv_id)) %>%
    select(varname, price_avg) %>%
    pivot_wider(names_from = varname, values_from = price_avg)

  # Combine
  tibble(country = this_country, year_week = this_week) %>%
    bind_cols(iv1_all, iv1_nest, iv2, iv2_nest)
}

# ---- Compute all IVs ----
iv_data <- country_weeks %>%
  pmap_dfr(~ compute_iv(..1, ..2))

# ---- Merge with panel ----
panel_iv <- panel %>%
  left_join(iv_data, by = c("country", "year_week"))

# ---- Save ----
write_csv(panel_iv, opt$out)
message("✅ IVs added and saved to: ", opt$out)
