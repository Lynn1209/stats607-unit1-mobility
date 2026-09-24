# Shared Mobility Trip-Duration Analysis

This is my STATS 607 Unit 1 project, based on my STATS 500 analysis. I reorganized the R code to compare four trip-duration models and make the results easier to reproduce. The original QMD and report are in `original/`, and the Git tag `original` marks the starting version.

## Setup

I tested this project with R 4.5.1 on an Apple Silicon Mac. Install R and Git first. Internet access is needed for package installation. RStudio is optional; Quarto and LaTeX are not needed for the outputs.

Run these commands in a terminal. Cloning requires access if the repository is private.

```bash
git clone https://github.com/Lynn1209/stats607-unit1-mobility.git
cd stats607-unit1-mobility
Rscript -e 'renv::restore(prompt = FALSE)'
```

Run the remaining commands from this project folder. The project activates renv automatically; `renv.lock` records package versions but does not install R. My Mac used binary packages. Other setups may need compiler tools if packages install from source.

## Reproduce the results

Use the included cleaned data:

```bash
Rscript reproduce.R
```

Or rebuild from the raw CSV, replacing the example path:

```bash
Rscript reproduce.R --raw "/absolute/path/to/data.csv"
```

The raw-data option samples 200,000 rows with seed 123, cleans them, and saves `data/processed/trips_clean.rds` before running the analysis. It does not replace the included `artifacts/trips_clean.rds`. Both options create the outputs below.

## Data

The data come from [City of Austin: Shared Micromobility Vehicle Trips (2018–2022)](https://data.austintexas.gov/Transportation-and-Mobility/Shared-Micromobility-Vehicle-Trips-2018-2022-/7d8e-dm7r). Export the full dataset as CSV without filters to use the raw-data option. See the portal's [terms of use](https://data.austintexas.gov/stories/s/City-of-Austin-Open-Data-Terms-of-Use/ranj-cccq/).

My source file was `Shared_Micromobility_Vehicle_Trips_(2018-2022)_20251204.csv`: about 4.34 GB and 15,048,635 rows. It is public data, omitted because of its size. The included cleaned data have 187,524 rows and 18 columns. A newer download may differ; use the included checkpoint for the same analysis data.

## Outputs

| Folder | Files |
|---|---|
| `results/tables/` | `model_comparison.csv`, `test_metrics.csv`, `data_summary.csv` |
| `results/figures/` | `test_predicted_vs_observed.png`, `log_duration_by_vehicle.png`, `distance_vs_duration_loglog.png`, `quadratic_diagnostics.png` |

These contain model comparisons, test performance, data summaries, and plots. They are regenerated and ignored by Git. The original report is kept for reference, not rebuilt.

## Tests

```bash
Rscript tests/run_tests.R
```

Tests check data columns, values, and log-duration calculations. They also run the pipeline in a temporary folder and check the outputs. A fresh local clone produced all seven files and passed 40 assertions on my Mac. I have not tested another operating system.

## Folder guide

- `original/`: original analysis and report.
- `src/`: cleaning and analysis scripts.
- `artifacts/`: included cleaned data.
- `data/`: local raw and rebuilt data, ignored by Git.
- `results/`: generated tables and figures.
- `tests/`: automated checks.
- `docs/`: reflection.
- `reproduce.R`: runs the analysis; `renv.lock` and `renv/`: environment files.

## Notes

Test RMSE is about 0.66017 in log-duration units, not minutes; R-squared is about 0.50685. Cleaning and model comparison used the full dataset, so this is not an independent test of model selection. Some AIC values differ slightly from the original report; that difference remains unresolved.
