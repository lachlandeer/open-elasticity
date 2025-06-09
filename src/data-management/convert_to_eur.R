#' convert_prices_to_eur.R
#'
#' contributors: @lachlandeer
#'
#' Convert all brand prices to euros using weekly exchange rates

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)

# ---- CLI Parsing ----
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              help = "CSV file with brand panel data (filtered + burnin applied)",
              metavar = "character"),
  make_option(c("-r", "--rates"),
              type = "character",
              help = "CSV file with weekly exchange rates (EUR base)",
              metavar = "character"),
  make_option(c("-o", "--out"),
              type = "character",
              default = "brand_panel_eur.csv",
              help = "Output file name [default = %default]",
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$data) || is.null(opt$rates)) {
  print_help(opt_parser)
  stop("Both --data and --rates must be provided", call. = FALSE)
}

# ---- Load Inputs ----
brand_panel <- read_csv(opt$data, show_col_types = FALSE)
rates <- read_csv(opt$rates, show_col_types = FALSE)

# ---- Join Exchange Rates ----
# Expecting rates to have columns: year_week, eur_to_usd, eur_to_gbp
brand_panel_converted <- brand_panel %>%
  left_join(rates, by = "year_week") %>%
  mutate(
    price_per_100g = case_when(
      country == "United Kingdom" ~ price_per_100g / eur_gbp,
      country == "United States" ~ price_per_100g / eur_usd,
      TRUE ~ price_per_100g  # Already in EUR
    )
  ) %>%
  select(-eur_usd, -eur_gbp)

# ---- Save Output ----
write_csv(brand_panel_converted, opt$out)
message("✅ Prices converted to EUR and written to: ", opt$out)
