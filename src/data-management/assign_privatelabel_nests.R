#' assign_privatelabel_nests.R
#'
#' contributors:  
#'
#' Assign nest classification (PrivateLabel vs NationalBrand) based on brand-level PL status.
#' Also computes number of within-nest competitors by country-week.

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)

# ---- CLI Parsing ----
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              help = "Input CSV file with cleaned purchase data",
              metavar = "character"),
  make_option(c("-o", "--out"),
              type = "character",
              default = "brand_nests.csv",
              help = "Output CSV with brand nest classification and nest size info [default = %default]",
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$data)) {
  print_help(opt_parser)
  stop("Input data must be provided", call. = FALSE)
}

# ---- Load data ----
message("📥 Loading data from: ", opt$data)
df <- read_csv(opt$data, show_col_types = FALSE)

# ---- Assign brand nest labels ----
df <- df %>%
  mutate(
    nest = if_else(pl, "PrivateLabel", "NationalBrand")
  )

# ---- Compute within-nest brand counts per country-week ----
nest_counts <- df %>%
  distinct(country, year_week, brand, nest) %>%
  group_by(country, year_week, nest) %>%
  summarise(
    n_brands_in_nest = n_distinct(brand),
    .groups = "drop"
  )

# ---- Merge back into panel ----
brand_nests <- df %>%
  distinct(country, year_week, brand, nest) %>%
  left_join(nest_counts, by = c("country", "year_week", "nest"))

# ---- Save output ----
message("💾 Saving brand nest classifications with nest size to: ", opt$out)
write_csv(brand_nests, opt$out)
