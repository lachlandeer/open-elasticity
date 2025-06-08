#' clean_purchases_raw.R
#'
#' contributors: @lachlandeer
#'
#' Clean raw purchase data: enforce column types, filter invalid values, and construct ISO year-week variable

# Libraries
library(optparse)
library(readr)
library(dplyr)
library(lubridate)
library(stringr)

# CLI parsing
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              default = NULL,
              help = "Raw purchases CSV file",
              metavar = "character"),
  make_option(c("-o", "--out"),
              type = "character",
              default = "cleaned_purchases.csv",
              help = "Output file name [default = %default]",
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$data)) {
  print_help(opt_parser)
  stop("Input data must be provided", call. = FALSE)
}

# Load data
print("Loading raw data")
df_raw <- read_csv(opt$data, col_types = cols(
  panelist = col_character(),
  date = col_date(format = ""),
  country = col_character(),
  retailer = col_character(),
  brand = col_character(),
  barcode = col_character(),
  total_value_sales = col_double(),
  total_volume_sales = col_double(),
  pl = col_logical()
))

# Clean and transform
print("Cleaning and transforming")
df_clean <- df_raw %>%
  mutate(
    year = isoyear(date),
    week = isoweek(date),
    year_week = paste0(year, "-W", sprintf("%02d", week)),
    brand = str_trim(brand),
    retailer = str_trim(retailer)
  ) %>%
  filter(
    !is.na(total_value_sales),
    !is.na(total_volume_sales),
    total_volume_sales > 0,
    total_value_sales > 0
  )

# Save output
print("Saving cleaned data")
write_csv(df_clean, opt$out)
message("✅ Cleaned data written to: ", opt$out)
