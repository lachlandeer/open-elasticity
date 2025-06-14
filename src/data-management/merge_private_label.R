#' merge_private_label.R
#'
#' contributors:  
#'
#' Merges private label flag into the brand panel data.

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)

# ---- CLI options ----
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              help = "CSV with panel data",
              metavar = "character"),
  make_option(c("-p", "--pl_file"),
              type = "character",
              help = "CSV with brand-country-level private label indicator",
              metavar = "character"),
  make_option(c("-o", "--out"),
              type = "character",
              default = "brand_panel_with_pl.csv",
              help = "Output file with PL merged [default = %default]",
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$data) || is.null(opt$pl_file)) {
  print_help(opt_parser)
  stop("Both --data and --pl_file must be provided", call. = FALSE)
}

# ---- Load inputs ----
panel <- read_csv(opt$data, show_col_types = FALSE)
pl_info <- read_csv(opt$pl_file, show_col_types = FALSE)

# ---- Merge ----
panel <- panel %>%
  left_join(pl_info, by = c("country", "year_week", "brand"))

# ---- Check and warn if any PL values are missing ----
missing_pl <- panel %>% 
    filter(is.na(nest))

if (nrow(missing_pl) > 0) {
  warning("⚠️ Some PL values are missing. Check country-brand combinations.")
}

# ---- Save output ----
write_csv(panel, opt$out)
message("✅ Private label flag merged and saved to: ", opt$out)
