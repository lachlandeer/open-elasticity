# Rules: data-management
#
# Contributors:  

# --- Build Rules --- #
## clean_purchases_raw: cleans raw purchase data into harmonized panel format
rule clean_purchases_raw:
    input:
        script = config["src_data_mgt"] + "clean_purchases_raw.R",
        data   = config["src_data"] + "purchases.csv"
    output:
        data = config["out"] + "data/cleaned_purchases.csv"
    log:
        config["log"] + "data_cleaning/clean_purchases_raw.txt"
    shell:
        "{runR} {input.script} --data {input.data} \
            --out {output.data} \
            > {log} {logAll}"

## construct_panelist_activity: builds active panelist denominator by country-week
##                              using a rolling window of past weeks (e.g., 26 weeks by default)
rule construct_panelist_activity:
    input:
        script = config["src_data_mgt"] + "construct_panelist_activity.R",
        data   = config["out_data"] + "cleaned_purchases.csv"
    output:
        data = config["out_data"] + "n_active_by_week.csv"
    params:
        window = 26
    log:
        config["log"] + "data_cleaning/construct_panelist_activity.txt"
    shell:
        "{runR} {input.script} --data {input.data} --window {params.window} \
            --out {output.data} > {log} {logAll}"

## filter_to_selected_brands: keeps only brands from the cross-country shortlist
rule filter_to_selected_brands:
    input:
        script = config["src_data_mgt"] + "filter_study_brands.R",
        data = config["out"] + "data/cleaned_purchases.csv",
        keep = config["src_data_specs"] + "country_brand_keep_list.csv"
    output:
        data = config["out_data"] + "cleaned_purchases_filtered.csv"
    log:
        config["log"] + "data_cleaning/filter_to_selected_brands.txt"
    shell:
        "{runR} {input.script} --data {input.data} --keep {input.keep} --out {output.data} > {log} {logAll}"

## compute_brand_shares: Compute weekly brand market shares and outside share
rule compute_brand_shares:
    input:
        script = config["src_data_mgt"] + "compute_brand_shares.R",
        data = config["out_data"] + "cleaned_purchases_filtered.csv",
        active = config["out_data"] + "n_active_by_week.csv"
    output:
        shares = config["out_data"] + "brand_shares.csv"
    log:
        config["log"] + "data_cleaning/compute_brand_shares.txt"
    shell:
        "{runR} {input.script} --data {input.data} --active {input.active} \
            --out {output.shares} > {log} 2>&1"

## compute_brand_prices: aggregates SKU-level prices into brand-week prices
rule compute_brand_prices:
    input:
        script = config["src_data_mgt"] + "compute_brand_prices.R",
        data   = config["out_data"] + "cleaned_purchases_filtered.csv"
    output:
        data = config["out_data"] + "brand_prices.csv"
    log:
        config["log"] + "data_cleaning/compute_brand_prices.txt"
    shell:
        "{runR} {input.script} --data {input.data} \
            --out {output.data} \
            > {log} 2>&1"

## merge_brand_panel: joins brand share and price data into a panel
rule merge_brand_panel:
    input:
        script = config["src_data_mgt"] + "merge_brand_panel.R",
        shares = config["out_data"] + "brand_shares.csv",
        prices = config["out_data"] + "brand_prices.csv"
    output:
        data = config["out_data"] + "brand_panel.csv"
    log:
        config["log"] + "data_cleaning/merge_brand_panel.txt"
    shell:
        "{runR} {input.script} --shares {input.shares} \
            --prices {input.prices} \
            --out {output.data} \
            > {log} 2>&1"

## assign_brand_nests: creates a nest classification for each brand
rule assign_brand_nests:
    input:
        script = config["src_data_mgt"] + "assign_privatelabel_nests.R",
        data = config["out_data"] + "cleaned_purchases_filtered.csv"
    output:
        nests = config["out_data"] + "brand_nests.csv"
    log:
        config["log"] + "data_cleaning/assign_brand_nests.txt"
    shell:
        "{runR} {input.script} \
            --data {input.data} \
            --out {output.nests} \
            > {log} 2>&1"

## merge_private_label: appends private label classification to trimmed brand panel
rule merge_private_label:
    input:
        script   = config["src_data_mgt"] + "merge_private_label.R",
        data     = config["out_data"] + "brand_panel_burnin_eur_trimmed.csv",
        # data     = config["out_data"] + "brand_panel_burnin_eur.csv",
        pl_info  = config["out_data"] + "brand_nests.csv"
    output:
        merged   = config["out_data"] + "brand_panel_burnin_eur_trimmed_characteristics.csv"
    log:
        config["log"] + "data_cleaning/merge_private_label.txt"
    shell:
        "{runR} {input.script} --data {input.data} --pl_file {input.pl_info} --out {output.merged} > {log} 2>&1"

## merge_private_label_elasticities: appends private label classification to trimmed (start only) 
##                            brand panel for elasticity computation 
rule merge_private_label_elasticities:
    input:
        script   = config["src_data_mgt"] + "merge_private_label.R",
        data     = config["out_data"] + "brand_panel_burnin_eur_trimmed_start.csv",
        # data     = config["out_data"] + "brand_panel_burnin_eur.csv",
        pl_info  = config["out_data"] + "brand_nests.csv"
    output:
        merged   = config["out_data"] + "brand_panel_burnin_eur_trimmed_start_characteristics.csv"
    log:
        config["log"] + "data_cleaning/merge_private_label_start.txt"
    shell:
        "{runR} {input.script} --data {input.data} --pl_file {input.pl_info} --out {output.merged} > {log} 2>&1"

## compute_within_nest_share: compute within-nest shares for nested logit models
rule compute_within_nest_share:
    input:
        script = config["src_data_mgt"] + "compute_within_nest_share.R",
        data   = config["out_data"] + "demand_data.csv"
    output:
        data = config["out_data"] + "demand_data_nested_pl.csv"
    log:
        config["log"] + "data_cleaning/compute_within_nest_share.txt"
    shell:
        "{runR} {input.script} --data {input.data} --out {output.data} > {log} 2>&1"

## compute_within_nest_share: compute within-nest shares for nested logit models
rule compute_within_nest_share_elasticity:
    input:
        script = config["src_data_mgt"] + "compute_within_nest_share.R",
        data   = config["out_data"] + "brand_panel_burnin_eur_trimmed_start_characteristics.csv"
    output:
        data = config["out_data"] + "elasticity_data_nested_pl.csv"
    log:
        config["log"] + "data_cleaning/compute_within_nest_share_elasticity.txt"
    shell:
        "{runR} {input.script} --data {input.data} --out {output.data} > {log} 2>&1"


## filter_burnin_weeks: drops early burn-in weeks from the panel
rule filter_burnin_weeks:
    input:
        script = config["src_data_mgt"] + "filter_burnin_weeks.R",
        data   = config["out_data"] + "brand_panel.csv"
    output:
        filtered = config["out_data"] + "brand_panel_filter_burnin.csv"
    params:
        burnin_weeks = 26
    log:
        config["log"] + "data_cleaning/filter_burnin_weeks.txt"
    shell:
        "{runR} {input.script} --data {input.data} \
            --burnin_weeks {params.burnin_weeks} \
            --out {output.filtered} > {log} 2>&1"

## get_exchange_rates: fetches EUR→USD and EUR→GBP weekly exchange rates from 2014–2023
rule get_exchange_rates:
    input:
        script = config["src_data_mgt"] + "get_exchange_rates.R"
    output:
        rates = config["out_data"] + "exchange_rates_eur.csv"
    log:
        config["log"] + "data_cleaning/get_exchange_rates.txt"
    shell:
        "{runR} {input.script} > {log} 2>&1"

## convert_prices_to_eur: Converts brand-level prices into EUR using weekly exchange rates
rule convert_prices_to_eur:
    input:
        script = config["src_data_mgt"] + "convert_to_eur.R",
        data = config["out_data"] + "brand_panel_filter_burnin.csv",
        rates = config["out_data"] + "exchange_rates_eur.csv"
    output:
        data = config["out_data"] + "brand_panel_burnin_eur.csv",
    log:
        config["log"] + "data_cleaning/convert_prices_to_eur.txt"
    shell:
        "{runR} {input.script} --data {input.data} --rates {input.rates} --out {output.data} > {log} 2>&1"

## trim_common_weeks:  Trim to common country-week to include common weeks across all countries
##                     for demand estimation 
rule trim_common_weeks:
    input:
        script = config["src_data_mgt"] + "trim_common_weeks.R",
        data   = config["out_data"] + "brand_panel_burnin_eur.csv"
    output:
        trimmed = config["out_data"] + "brand_panel_burnin_eur_trimmed.csv"
    log:
        config["log"] + "data_cleaning/trim_by_common_weeks.txt"
    shell:
        "{runR} {input.script} --data {input.data} --out {output.trimmed} > {log} 2>&1"

## trim_common_weeks_elasticity:  Trim to common country-week to include weeks starting from first
##                                common week to end for brand elasticity computation 
rule trim_common_weeks_elasticity:
    input:
        script = config["src_data_mgt"] + "trim_common_weeks_start.R",
        data   = config["out_data"] + "brand_panel_burnin_eur.csv"
    output:
        trimmed = config["out_data"] + "brand_panel_burnin_eur_trimmed_start.csv"
    log:
        config["log"] + "data_cleaning/trim_by_common_weeks_start.txt"
    shell:
        "{runR} {input.script} --data {input.data} --out {output.trimmed} > {log} 2>&1"

## construct_hausman_iv: generates Hausman-style instruments based on average prices in other countries
rule construct_hausman_iv:
    input:
        script = config["src_data_mgt"] + "construct_hausman_iv.R",
        data   = config["out_data"] + "brand_panel_burnin_eur_trimmed_characteristics.csv"
    output:
        iv_data = config["out_data"] + "demand_data.csv"
    log:
        config["log"] + "data_cleaning/construct_hausman_iv.txt"
    shell:
        "{runR} {input.script} --data {input.data} --out {output.iv_data} > {log} 2>&1"

