#' compute_within_nest_share.R
#'
#' contributors: @lachlandeer
#'
#' Adds within-nest shares for each brand-week-country observation.

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)

# ---- CLI Parsing ----
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              help = "Input CSV with brand panel data and nest assignments",
              metavar = "character"),
  make_option(c("-o", "--out"),
              type = "character",
              default = "brand_panel_within_nest_share.csv",
              help = "Output file with within-nest shares [default = %default]",
              metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$data)) {
  print_help(opt_parser)
  stop("Input data must be provided", call. = FALSE)
}

# ---- Load data ----
message("📥 Loading data from: ", opt$data)
df <- read_csv(opt$data)

# ---- Compute within-nest shares ----
df_within <- df %>%
  group_by(country, year_week, nest) %>%
  mutate(
    total_share_in_nest = sum(share, na.rm = TRUE),
    within_nest_share = share / total_share_in_nest
  ) %>%
  ungroup() %>%
  select(-total_share_in_nest)

# ---- Save output ----
message("💾 Writing data with within-nest shares to: ", opt$out)
write_csv(df_within, opt$out)
