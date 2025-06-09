#' assign_privatelabel_nests.R
#'
#' contributors: @lachlandeer
#'
#' Assign nest classification (PrivateLabel vs NationalBrand) based on brand-level PL status

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
              help = "Output CSV with brand nest classification [default = %default]",
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
df <- read_csv(opt$data)

# ---- Compute brand nest classification ----
brand_nests <- df %>%
  distinct(country, brand, pl) %>%
  mutate(
    nest = if_else(pl, "PrivateLabel", "NationalBrand")
  ) %>%
  select(country, brand, nest)

# ---- Save output ----
message("💾 Saving brand nests to: ", opt$out)
write_csv(brand_nests, opt$out)
