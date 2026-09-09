# Usage from the project root:
# Rscript reproduce.R
# Rscript reproduce.R --raw "/path/to/raw.csv"

main <- function(args = character()) {
  use_raw <- length(args) == 2L && args[1] == "--raw"
  
  if (length(args) != 0L && !use_raw) {
    stop(
      'Usage: Rscript reproduce.R [--raw "/path/to/raw.csv"]',
      call. = FALSE
    )
  }
  
  scripts <- c(
    "src/model_comparison.R",
    "src/evaluate_model.R",
    "src/create_figures.R"
  )
  
  if (use_raw) {
    scripts <- c("src/prepare_data.R", scripts)
  }
  
  missing <- scripts[!file.exists(scripts)]
  if (length(missing) > 0) {
    stop(
      "Missing scripts: ", paste(missing, collapse = ", "),
      ". Run from the project root.",
      call. = FALSE
    )
  }
  
  # Load functions without automatically running each analysis.
  analysis_env <- new.env(parent = globalenv())
  
  for (script in scripts) {
    sys.source(script, envir = analysis_env)
  }
  
  if (use_raw) {
    message("Rebuilding from raw CSV...")
    input_path <- analysis_env$prepare_data(
      raw_path = args[2],
      output_path = "data/processed/trips_clean.rds"
    )
  } else {
    message("Using included checkpoint...")
    input_path <- "artifacts/trips_clean.rds"
  }
  
  if (!file.exists(input_path)) {
    stop("Missing analysis data: ", input_path, call. = FALSE)
  }
  
  message("\nRunning model comparison...")
  analysis_env$run_model_comparison(input_path = input_path)
  
  message("\nRunning test-set evaluation...")
  analysis_env$run_evaluation(input_path = input_path)
  
  message("\nCreating summary and figures...")
  analysis_env$run_figures(input_path = input_path)
  
  expected <- c(
    "results/tables/model_comparison.csv",
    "results/tables/test_metrics.csv",
    "results/tables/data_summary.csv",
    "results/figures/test_predicted_vs_observed.png",
    "results/figures/log_duration_by_vehicle.png",
    "results/figures/distance_vs_duration_loglog.png",
    "results/figures/quadratic_diagnostics.png"
  )
  
  missing_outputs <- expected[!file.exists(expected)]
  if (length(missing_outputs) > 0) {
    stop(
      "Missing outputs: ", paste(missing_outputs, collapse = ", "),
      call. = FALSE
    )
  }
  
  if (any(file.info(expected)$size == 0)) {
    stop("One or more output files are empty.", call. = FALSE)
  }
  
  message("\nReproduction completed: all 7 output files are present.")
}

# Tests source this file without command-line arguments.
if (sys.nframe() == 0L) {
  main(commandArgs(trailingOnly = TRUE))
} else {
  main()
}