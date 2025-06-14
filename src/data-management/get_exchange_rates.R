#' get_exchange_rates.R
#'
#' contributors:  
#'
#' Fetches weekly EUR→USD and EUR→GBP exchange rates from Yahoo Finance (2014–2023)

# ---- Libraries ----
library(tidyquant)
library(dplyr)
library(tidyr)
library(readr)
library(lubridate)

# ---- Parameters ----
start_date <- "2014-01-01"
end_date <- "2023-12-31"
tickers <- c("EURUSD=X", "EURGBP=X")

# ---- Fetch weekly FX rates ----
fx_data <- tq_get(tickers,
                  get  = "stock.prices",
                  from = start_date,
                  to   = end_date) %>%
  select(symbol, date, adjusted) %>%
  mutate(
    week = isoweek(date),
    year = isoyear(date),
    year_week = paste0(year, "-W", sprintf("%02d", week))
  ) %>%
  group_by(symbol, year_week) %>%
  summarise(exchange_rate = mean(adjusted, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = symbol, values_from = exchange_rate) %>%
  rename(
    eur_usd = `EURUSD=X`,
    eur_gbp = `EURGBP=X`
  )

# ---- Save to CSV ----
write_csv(fx_data, "out/data/exchange_rates_eur.csv")
message("✅ Exchange rates saved to out/data/exchange_rates_eur.csv")
