# Reproducible Shared Mobility Trip-Duration Analysis

This project restructures a previous STATS 500 analysis into a reproducible
R workflow for STATS 607 Unit 1. It examines trip duration using distance,
hour, weekday, and vehicle type, compares four regression models, and
evaluates a quadratic model on a fixed train/test split.

The original analysis and report are preserved in `original/`.
The Git tag `original` identifies the initial, unmodified submission state.

## Requirements and setup

The project was developed and tested with R 4.5.1 on Apple Silicon macOS.
Git is required to clone the repository. Internet access is needed to
download R packages during setup.

Use a terminal with `Rscript` available, and run all commands from the
repository root. RStudio is optional. Quarto and LaTeX are not required
to generate the designated CSV and PNG outputs.

Restore the package versions recorded in `renv.lock`:

```bash
Rscript -e 'renv::restore(prompt = FALSE)'
```

The project `.Rprofile` activates renv and bootstraps it if necessary.
The lockfile records the R version but does not install R itself.

Check the environment:

```bash
Rscript -e 'cat(R.version.string, "\n"); renv::status()'
```

If packages must be built from source, the relevant compiler tools may
be required. The tested macOS setup used binary package installations.

### Multiple R installations on macOS

If RStudio and the terminal use different R installations, they may
use different renv package libraries even when their R versions match.

For the standard macOS framework installation, select its Rscript
for the current terminal session:

```bash
export PATH="/Library/Frameworks/R.framework/Resources/bin:$PATH"
rehash
```

This adjustment is only needed when that installation exists and is
the R installation intended for this project.

## Reproduce from the included checkpoint

```bash
Rscript reproduce.R
```

This is the instructor-facing reproduction command. It reads
`artifacts/trips_clean.rds` and regenerates all seven designated outputs.
It does not require the original large CSV.

## Rebuild from raw data

```bash
Rscript reproduce.R --raw "/absolute/path/to/Shared_Micromobility_Vehicle_Trips_(2018-2022)_20251204.csv"
```

Replace the example path with the actual CSV location.

This command reads the required raw columns, samples 200,000 rows with
seed 123, applies the cleaning steps, and saves
`data/processed/trips_clean.rds`. It then uses that rebuilt dataset
to regenerate the same designated outputs.

The included checkpoint in `artifacts/` is not overwritten.
Both entry points write to the same `results/` locations.

## Data and provenance

The original report identifies the source as the City of Austin
Open Data Portal's Shared Micromobility Vehicle Trips dataset.

The local CSV used for this reconstruction is named
`Shared_Micromobility_Vehicle_Trips_(2018-2022)_20251204.csv`.
It is approximately 4.34 GB and contains 15,048,635 rows.
It is excluded from Git because of its size.

The included cleaned checkpoint contains 187,524 rows and 18 columns.
It supports reproduction without downloading the full raw dataset.

The reconstruction preserves the original analysis sequence:

1. Randomly sample 200,000 rows with seed 123.
2. Convert duration from seconds to minutes.
3. Remove durations above the sample's 99.9th percentile.
4. Convert distance from meters to kilometres.
5. Remove distances above the 99.9th percentile calculated after
   duration filtering.
6. Construct categorical and timestamp variables.
7. Remove records with invalid required values and nonpositive
   duration or distance.
8. Calculate natural-log duration for retained records.

English month abbreviations are parsed using the C time locale,
with timestamps interpreted in US/Central.

Rebuilding from the local CSV reproduced the checkpoint's trip IDs,
row order, and six analysis variables in the comparison performed
during development. This does not establish byte-for-byte identity
of the two RDS files.

### Data access and reuse

Dataset: City of Austin, *Shared Micromobility Vehicle Trips (2018–2022)*.

Dataset page:
https://data.austintexas.gov/Transportation-and-Mobility/Shared-Micromobility-Vehicle-Trips-2018-2022-/7d8e-dm7r

Dataset ID: `7d8e-dm7r`.

To obtain raw data, open the dataset page and export the full dataset
as CSV, without applying filters. Supply the downloaded file path
to the `--raw` command above.

City of Austin Open Data Terms of Use:
https://data.austintexas.gov/stories/s/City-of-Austin-Open-Data-Terms-of-Use/ranj-cccq/

The portal's licensing summary describes its data as available free
and without restriction. The included checkpoint is derived from
this public dataset. The raw CSV is omitted because of its size,
not because it requires private access.

The current online export has not been verified as identical to
the local CSV used in this project. Changes to source records or
row ordering can change the random sample even with the same seed.
Use the included checkpoint to reproduce the designated results
from the preserved analysis data.

## Designated outputs

| File | Description |
|---|---|
| `results/tables/model_comparison.csv` | AIC, RSE, R-squared and adjusted R-squared for four models |
| `results/tables/test_metrics.csv` | Quadratic-model test RMSE, R-squared and split sizes |
| `results/tables/data_summary.csv` | Duration and distance summary statistics |
| `results/figures/test_predicted_vs_observed.png` | Test predictions against observed log-duration |
| `results/figures/log_duration_by_vehicle.png` | Log-duration boxplots by vehicle type |
| `results/figures/distance_vs_duration_loglog.png` | Log-distance versus log-duration |
| `results/figures/quadratic_diagnostics.png` | Four diagnostic plots for the full-data quadratic model |

Generated outputs are excluded from Git and recreated by the pipeline.
The original PDF report is retained for reference, not regenerated.

## Tests

```bash
Rscript tests/run_tests.R
```

The tests cover two categories:

- Data validation: required columns, missing values, numeric validity,
  allowable ranges, and consistency of log-duration.
- Pipeline integrity: run the checkpoint workflow in a temporary
  directory without existing results, then check output files,
  table contents, split sizes, and PNG signatures.

Temporary test files are removed after the test.
This test uses the active R environment; it does not independently
install dependencies in a fresh environment.

## Repository structure

- `original/`: original QMD and report.
- `src/`: data preparation, model comparison, evaluation and plotting.
- `artifacts/`: included cleaned checkpoint.
- `data/raw/`: optional local raw-data location; data excluded from Git.
- `data/processed/`: regenerated cleaned data; excluded from Git.
- `results/tables/` and `results/figures/`: generated outputs.
- `tests/`: validation and pipeline tests.
- `docs/`: supporting documentation and reflection.
- `reproduce.R`: command-line entry point.
- `renv.lock` and `renv/`: dependency specification and activation files.

## Analysis scope and limitations

The workflow preserves the original model formulas and uses seed 123
for an 80/20 training/test split. The checkpoint produces 150,019
training rows and 37,505 test rows.

Test RMSE is approximately 0.66017 on the natural-log-duration scale,
not in minutes. Test R-squared is approximately 0.50685.

Cleaning thresholds were calculated before the train/test split,
and model comparison used the full cleaned dataset. The reported
test performance therefore preserves the original exploratory
procedure rather than providing a fully independent assessment
of model selection.

The refactor focuses on reproducibility rather than improving the
statistical specification. Diagnostic plots should be inspected;
successful execution does not establish that model assumptions hold.

The four models' R-squared values agree with the original report at
four decimal places. Some reported AIC values differ by approximately
one from the current output; the reason has not yet been established.
Generated tables retain the computed values.