# Main Workflow - Open elasticity: Meat Substitutes
# Contributors: @lachlandeer

import glob

# --- Importing Configuration Files --- #
configfile: "paths.yaml"

# --- PROJECT NAME --- #
PROJ_NAME = "open_elasticity"

# --- Dictionaries --- #
# Identify subset conditions for data
# DATA_SUBSET = glob_wildcards(config["src_data_specs"] + "{fname}.json").fname
# # Models we want to estimate
# MODELS = glob_wildcards(config["src_model_specs"] + "{fname}.json").fname
# # plots we want to build
# PLOTS = glob_wildcards(config["src_figures"] + "{fname}.R").fname
# # tables to generate
# TABLES = glob_wildcards(config["src_table_specs"] + "{fname}.json").fname

# --- Variable Declarations ---- #
runR = "Rscript --no-save --no-restore --verbose"
logAll = "2>&1"

# --- Main Build Rule --- #
## all            : build paper and slides that are the core of the project
rule all:
    input:
        #data = config["out_data"] + "brand_panel.csv",
        # data = config["out_data"] + "brand_panel_filter_burnin.csv",
        # data = config["out_data"] + "brand_panel_burnin_eur.csv",
        data = config["out_analysis"] + "brand_elasticities.csv"
        #model = config["out_analysis"] + "iv_nested_logit_model.rds",
        #demand_data = config["out_data"] + "demand_data_nested_pl.csv",
        # data = config["out_data"] + "brand_panel_burnin_eur_trimmed_start_characteristics.csv",
        #data = config["out_data"] + "elasticity_data_nested_pl.csv"
        #data = config["out_data"] + "brand_panel_burnin_eur_trimmed_characteristics.csv",
        #nests = config["out_data"] + "brand_nests.csv",
        # rates = config["out_data"] + "exchange_rates_eur.csv"
        # prices = config["out_data"] + "brand_prices.csv",
        # shares = config["out_data"] + "brand_shares.csv"
        # config["out"] + "data/cleaned_purchases.csv"
        # paper_pdf     = PROJ_NAME + ".pdf",
        # beamer_slides = PROJ_NAME + "_slides.pdf"

# --- Cleaning Rules --- #
## clean_all      : delete all output and log files for this project
rule clean_all:
    shell:
        "rm -rf out/ log/ *.pdf *.html"

# --- Help Rules --- #
## help_main      : prints help comments for Snakefile in ROOT directory. 
##                  Help for rules in other parts of the workflows (i.e. in rules/)
##                  can be called by `snakemake help_<workflowname>`
rule help_main:
    input: "Snakefile"
    shell:
        "sed -n 's/^##//p' {input}"

# --- Sub Rules --- #
# Include all other Snakefiles that contain rules that are part of the project
# 1. project specific
include: config["rules"] + "data_mgt.smk"
include: config["rules"] + "analysis.smk"
# include: config["rules"] + "figures.smk"
# include: config["rules"] + "tables.smk"
# 2. Other rules
include: config["rules"] + "renv.smk"
include: config["rules"] + "clean.smk"
include: config["rules"] + "dag.smk"
include: config["rules"] + "help.smk"