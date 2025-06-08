#' compute_brand_shares.R
#'
#' contributors: @lachlandeer
#'
#' Compute weekly brand market shares and outside shares

# Libraries
library(optparse)
library(readr)
library(dplyr)

# CLI parsing
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              default = NULL,
              help = "CSV file with cleaned purchase data",
              metavar = "character"),
  make_option(c("-a", "--active"),
              type = "character",
              default = NULL,
              help = "CSV with n_active panelists per country-week",
              metavar = "character"),
  make_option(c("-o", "--out"),
              type = "character",
              default = "brand_shares.csv",
              help = "output CSV with brand-level shares [default = %default]",
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$data) | is.null(opt$active)) {
  print_help(opt_parser)
  stop("Both input data and active panelist file must be provided", call. = FALSE)
}

# ---- Load inputs ----
df_clean <- read_csv(opt$data)
active_by_week <- read_csv(opt$active)

# ---- Step 1: Count buyers per brand per week-country ----
brand_buyers <- df_clean %>%
  group_by(country, year_week, brand) %>%
  summarise(n_brand_buyers = n_distinct(panelist), .groups = "drop")

# ---- Step 2: Merge with active panelist counts ----
brand_shares <- brand_buyers %>%
  left_join(active_by_week, by = c("country", "year_week")) %>%
  mutate(
    share = n_brand_buyers / n_active
  )

# ---- Step 3: Compute outside shares ----
outside_share <- brand_shares %>%
  group_by(country, year_week) %>%
  summarise(
    s_inside = sum(share, na.rm = TRUE),
    s_outside = 1 - s_inside,
    .groups = "drop"
  )

# ---- Step 4: Finalize brand shares panel ----
brand_shares <- brand_shares %>%
  left_join(outside_share, by = c("country", "year_week")) %>%
  mutate(
    log_share_diff = log(share) - log(s_outside)
  )

# ---- Write output ----
write_csv(brand_shares, opt$out)
message("✅ Brand shares written to: ", opt$out)
