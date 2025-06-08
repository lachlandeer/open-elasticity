#' filter_study_brands.R
#'
#' contributors: @lachlandeer
#'
#' Filter brand-week panel data to include only selected brands per country.
#' Filter brands are specified by the many analyst organizers

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)

# ---- CLI Options ----
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              help = "Input CSV file with brand-week panel data",
              metavar = "character"),
  make_option(c("-k", "--keep"),
              type = "character",
              help = "CSV file with country-brand pairs to keep",
              metavar = "character"),
  make_option(c("-o", "--out"),
              type = "character",
              help = "Output CSV file with filtered data",
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$data) || is.null(opt$keep) || is.null(opt$out)) {
  print_help(opt_parser)
  stop("All input, keep, and output paths must be specified", call. = FALSE)
}

# ---- Load Data ----
message("📥 Loading data and keep-list")
brand_data <- read_csv(opt$data, show_col_types = FALSE)
keep_list <- read_csv(opt$keep, show_col_types = FALSE)

# ---- Filter ----
message("🔍 Filtering brands")
filtered_data <- brand_data %>%
  semi_join(keep_list, by = c("country", "brand"))

# ---- Write Output ----
message("💾 Writing filtered data to: ", opt$out)
write_csv(filtered_data, opt$out)
