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

rule compute_brand_elasticities:
    input:
        script = config["src_analysis"] + "compute_brand_elasticities.R",
        data   = config["out_data"] + "elasticity_data_nested_pl.csv",
        model  = config["out_analysis"] + "iv_nested_logit_model.rds"
    output:
        data = config["out_analysis"] + "brand_elasticities.csv"
    log:
        config["log"] + "analysis/compute_brand_elasticities.txt"
    shell:
        "{runR} {input.script} --data {input.data} --model {input.model} --out {output.data} > {log} 2>&1"
