#' compute_brand_prices.R
#'
#' contributors: @lachlandeer
#'
#' Computes volume-weighted brand-level prices per country-week
#'

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)

# ---- CLI Parsing ----
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              default = NULL,
              help = "Input CSV file with cleaned purchase data",
              metavar = "character"),
  make_option(c("-o", "--out"),
              type = "character",
              default = "brand_prices.csv",
              help = "Output file name [default = %default]",
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$data)) {
  print_help(opt_parser)
  stop("Input data must be provided", call. = FALSE)
}

# ---- Load data ----
message("🔄 Loading filtered brand-level data...")
df <- read_csv(opt$data)

# ---- Aggregate at SKU-week level ----
message("📊 Aggregating to SKU-week level...")
sku_weekly <- df %>%
  group_by(country, year_week, brand, barcode) %>%
  summarise(
    total_value = sum(total_value_sales, na.rm = TRUE),
    total_volume = sum(total_volume_sales, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(total_volume >= 100) %>%  # Filter out extremely low-volume SKUs
  mutate(price_per_gram = total_value / total_volume)

# ---- Volume-weighted average price per brand-week-country ----
message("🧮 Calculating volume-weighted brand prices...")
brand_prices <- sku_weekly %>%
  group_by(country, year_week, brand) %>%
  summarise(
    avg_price_per_gram = weighted.mean(price_per_gram, total_volume, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(price_per_100g = avg_price_per_gram * 100)

# ---- Save output ----
message("💾 Saving to: ", opt$out)
write_csv(brand_prices, opt$out)
