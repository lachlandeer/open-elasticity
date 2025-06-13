# compute_brand_elasticities.R
# 
# contributors: @lachlandeer
#
# Computes brand-level own-price elasticities using delta method, based on nested logit IV model

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)
library(tibble)
library(purrr)
library(stats)
library(rlist)

# ---- CLI options ----
option_list <- list(
  make_option(c("-d", "--data"), type = "character",
              help = "Input CSV with elasticity data (must include price, share, nest info)", metavar = "character"),
  make_option(c("-m", "--model"), type = "character",
              help = "RDS file with saved IV model", metavar = "character"),
  make_option(c("-o", "--out"), type = "character",
              default = "brand_elasticities.csv",
              help = "Output CSV with brand-level elasticities [default = %default]", metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$data) | is.null(opt$model)) {
  print_help(opt_parser)
  stop("Both --data and --model arguments must be provided.", call. = FALSE)
}

# ---- Load model and data ----
elasticity_data <- read_csv(opt$data, show_col_types = FALSE)
iv_model <- list.load(opt$model)

# ---- Extract parameters and variance-covariance matrix ----
alpha_hat <- coef(iv_model)["fit_price_per_100g"]
sigma_hat <- coef(iv_model)["fit_log_within_nest_share"]
vcov_mat <- vcov(iv_model)[
  c("fit_price_per_100g", "fit_log_within_nest_share"),
  c("fit_price_per_100g", "fit_log_within_nest_share")
]

# ---- Compute brand-level elasticities and SEs ----
brand_elasticity <- elasticity_data %>%
  group_by(country, brand) %>%
  summarise(
    avg_grad_alpha = mean(price_per_100g * (1 - sigma_hat * within_nest_share) * (1 - share), na.rm = TRUE),
    avg_grad_sigma = mean(-alpha_hat * price_per_100g * within_nest_share * (1 - share), na.rm = TRUE),
    avg_elasticity = mean(alpha_hat * price_per_100g * (1 - sigma_hat * within_nest_share) * (1 - share), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rowwise() %>%
  mutate(
    grad = list(c(avg_grad_alpha, avg_grad_sigma)),
    se_elasticity = {
      v <- matrix(unlist(grad), nrow = 2, ncol = 1)
      sqrt(as.numeric(t(v) %*% vcov_mat %*% v))
    },
    abs_t_stat = abs(avg_elasticity / se_elasticity),
    p_value = 2 * (1 - pnorm(abs_t_stat))
  ) %>%
  ungroup()

# ---- Write output ----
write_csv(brand_elasticity, opt$out)
