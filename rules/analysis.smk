rule estimate_iv_nested_logit_model:
    input:
        script = config["src_analysis"] + "estimate_iv_nested_logit.R",
        data   = config["out_data"] + "demand_data_nested_pl.csv"
    output:
        model = config["out_analysis"] + "iv_nested_logit_model.rds"
    log:
        config["log"] + "analysis/estimate_iv_nested_logit.txt"
    shell:
        "{runR} {input.script} --data {input.data} --out {output.model} > {log} 2>&1"