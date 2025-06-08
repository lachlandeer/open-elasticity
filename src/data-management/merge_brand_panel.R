#' merge_brand_panel.R
#'
#' contributors: @lachlandeer
#'
#' Join brand-week share and price data into a single panel

# Libraries
library(optparse)
library(readr)
library(dplyr)

# CLI Options
option_list = list(
    make_option(c("-s", "--shares"),
                type = "character",
                help = "CSV file with brand shares",
                metavar = "character"),
    make_option(c("-p", "--prices"),
                type = "character",
                help = "CSV file with brand prices",
                metavar = "character"),
    make_option(c("-o", "--out"),
                type = "character",
                default = "brand_panel.csv",
                help = "Output CSV file [default = %default]",
                metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$shares) || is.null(opt$prices)) {
  print_help(opt_parser)
  stop("Both --shares and --prices must be provided", call. = FALSE)
}

# Load data
brand_shares <- read_csv(opt$shares, show_col_types = FALSE)
brand_prices <- read_csv(opt$prices, show_col_types = FALSE)

# Merge
brand_panel <- brand_shares %>%
  left_join(brand_prices, by = c("country", "year_week", "brand"))

# Save
write_csv(brand_panel, opt$out)
message("✅ Merged brand panel written to: ", opt$out)
