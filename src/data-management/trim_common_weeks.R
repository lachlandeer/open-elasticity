#' trim_by_common_weeks.R
#'
#' contributors: @lachlandeer
#'
#' Keeps only weeks shared across all countries. Reports dropped weeks and retained share.

# ---- Libraries ----
library(optparse)
library(readr)
library(dplyr)

# ---- CLI ----
option_list = list(
  make_option(c("-d", "--data"),
              type = "character",
              help = "Input CSV with burned-in brand panel",
              metavar = "character"),
  make_option(c("-o", "--out"),
              type = "character",
              default = "brand_panel_trimmed.csv",
              help = "Output file name [default = %default]",
              metavar = "character")
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

if (is.null(opt$data)) {
  print_help(opt_parser)
  stop("Input data must be provided", call. = FALSE)
}

# ---- Load ----
panel <- read_csv(opt$data, show_col_types = FALSE)

# ---- Identify common weeks ----
weeks_per_country <- panel %>%
  distinct(country, year_week)

common_weeks <- weeks_per_country %>%
  group_by(year_week) %>%
  summarise(n_countries = n_distinct(country), .groups = "drop") %>%
  filter(n_countries == n_distinct(weeks_per_country$country)) %>%
  pull(year_week)

# ---- Report trimming diagnostics ----
before_counts <- panel %>%
  group_by(country) %>%
  summarise(
    n_weeks_before = n_distinct(year_week),
    n_obs_before = n(),
    .groups = "drop"
  )

trimmed_panel <- panel %>%
  filter(year_week %in% common_weeks)

after_counts <- trimmed_panel %>%
  group_by(country) %>%
  summarise(
    n_weeks_after = n_distinct(year_week),
    n_obs_after = n(),
    .groups = "drop"
  )

diagnostics <- before_counts %>%
  left_join(after_counts, by = "country") %>%
  mutate(
    weeks_dropped = n_weeks_before - n_weeks_after,
    share_retained = round(n_obs_after / n_obs_before, 3)
  )

print("📉 Weeks dropped and share retained per country:")
print(diagnostics)

# ---- Save output ----
write_csv(trimmed_panel, opt$out)
message("✅ Trimmed panel written to: ", opt$out)
