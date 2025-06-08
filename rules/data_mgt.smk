# Rules: data-management
#
# Contributors: @lachlandeer

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
## using a rolling window of past weeks (e.g., 26 weeks by default)
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
