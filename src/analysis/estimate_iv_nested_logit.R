# estimate_iv_nested_logit_model.R
#
# contributors: @lachlandeer
#
# Estimates nested logit IV model with fixed effects and saves the model object

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)
library(fixest)
library(rlist)

# ---- CLI options ----
option_list <- list(
  make_option(c("-d", "--data"), type = "character",
              help = "Input CSV with demand data", metavar = "character"),
  make_option(c("-o", "--out"), type = "character",
              default = "iv_nested_logit_model.rds",
              help = "Output file to save model [default = %default]", metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$data)) {
  print_help(opt_parser)
  stop("Input demand data must be provided.", call. = FALSE)
}

# ---- Load data ----
demand_data <- read_csv(opt$data, show_col_types = FALSE)

# ---- Preprocessing ----
demand_data <- demand_data %>%
  mutate(
    log_within_nest_share = log(within_nest_share)
  )

# ---- Estimate IV Nested Logit ----
iv_model <- feols(
  log_share_diff ~ 1 | brand + retailer + country + year_week |
    price_per_100g + log_within_nest_share ~ price_other_within_nest + log(n_brands_in_nest),
  data = demand_data,
  cluster = ~country^year_week
)

fitstat(iv_model, type = "ivf")

summary(iv_model)

# ---- Save model ----
list.save(iv_model, opt$out)
