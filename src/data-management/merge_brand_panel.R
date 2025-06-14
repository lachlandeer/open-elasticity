#' merge_brand_panel.R
#'
#' contributors:  
#'
#' Join brand-retailer-week share and price data into a single panel

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)

# ---- CLI Options ----
option_list = list(
  make_option(c("-s", "--shares"),
              type = "character",
              help = "CSV file with brand-retailer shares",
              metavar = "character"),
  make_option(c("-p", "--prices"),
              type = "character",
              help = "CSV file with brand-retailer prices",
              metavar = "character"),
  make_option(c("-o", "--out"),
              type = "character",
              default = "brand_retailer_panel.csv",
              help = "Output CSV file [default = %default]",
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$shares) || is.null(opt$prices)) {
  print_help(opt_parser)
  stop("Both --shares and --prices must be provided", call. = FALSE)
}

# ---- Load data ----
message("📥 Reading share and price files...")
brand_shares <- read_csv(opt$shares, show_col_types = FALSE)
brand_prices <- read_csv(opt$prices, show_col_types = FALSE)

# ---- Merge by country, week, brand, retailer ----
message("🔗 Merging brand-retailer share and price data...")
brand_panel <- brand_shares %>%
  left_join(brand_prices, by = c("country", "year_week", "brand", "retailer"))

# ---- Save output ----
message("💾 Saving merged brand-retailer panel to: ", opt$out)
write_csv(brand_panel, opt$out)

