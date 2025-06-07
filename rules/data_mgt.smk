# Rules: data-management
#
# Contributors: @lachlandeer, @julianlanger, @bergmul

# --- Build Rules --- #
## gen_regression_vars: creates the set of variables needed to produce MRW results
rule gen_regression_vars:
    input:
        script = config["src_data_mgt"] + "gen_reg_vars.R",
        data   = config["out_data"] + "mrw_renamed.csv"
    output:
        data = config["out_data"] + "mrw_complete.csv",
    params:
        solow_const = 0.05
    log:
        config["log"] + "data_cleaning/gen_reg_vars.txt"
    shell:
        "{runR} {input.script} --data {input.data} --param {params.solow_const} \
            --out {output.data} \
            > {log} {logAll}"