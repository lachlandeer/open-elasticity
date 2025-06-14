# 🛒 Demand Estimation Workflow: Meat Substitute Products

This repository contains a fully reproducible R-based data analysis pipeline for estimating consumer demand for meat substitute products. The project uses a Nested Logit specification and leverages Snakemake to orchestrate preprocessing, variable construction, and model estimation.

---

## 🧭 Project Overview

This project builds a demand estimation pipeline for scanner data on meat substitutes. It includes:

- Data cleaning and transformation
- Construction of IV instruments (Hausman-style)
- Computation of within-nest shares and other demand variables
- Estimation of a Nested Logit model
- Computation of brand-level elasticities

---

## 📁 Project Structure

```
├── Snakefile             # Main Snakemake workflow
├── paths.yaml            # Path config 
├── rules/                # Modular Snakemake rule files
│   ├── analysis.smk
│   ├── clean.smk
│   ├── data_mgt.smk
│   └── ...
├── src/                  # R scripts for analysis and preprocessing
│   ├── analysis/
│   │   ├── estimate_iv_nested_logit.R
│   │   └── compute_brand_elasticities.R
│   ├── data-management/
│   │   └── [scripts for all stages of data processing]
├── assets/               # DAG and graph visualizations
├── renv/, renv.lock      # R environment (via `renv`)
├── requirements.txt      # Python packages for Snakemake execution
├── dag.pdf               # Full DAG of workflow
├── rulegraph.pdf         # Rule dependency graph
├── filegraph.pdf         # File dependency graph
```

## ⚙️ Setup Instructions

1. **Unzip this repository, open your terminal and navigate to the root directory**

2. **Install Python Environment (for Snakemake)**

```bash
conda create -n demand-pipeline python=3.11
conda activate demand-pipeline
pip install -r requirements.txt
```

3. **Initialize R Environment**

In R:

```r
install.packages("renv")
renv::restore()
```


## 🚀 Running the Pipeline

Run the full workflow after changing to the project's root directory with:

```bash
snakemake --cores 4
```

To target a specific output (e.g., IV model estimation):

```bash
snakemake results/analysis/nested_logit_model.rds
```

You can visualize the DAG with:

```bash
snakemake --dag | dot -Tpdf > dag.pdf
```

---

## 📊 Key Outputs

- `results/analysis/nested_logit_model.rds`: Final IV Nested Logit model object
- `results/analysis/brand_elasticities.csv`: Computed own- and cross-price elasticities
- Visual DAGs: `dag.pdf`, `filegraph.pdf`, `rulegraph.pdf`
