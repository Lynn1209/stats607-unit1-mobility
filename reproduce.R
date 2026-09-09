# Reproduce all designated results from the included checkpoint.
# Run from the project root: Rscript reproduce.R

main <- function() {
  scripts <- c(
    "src/model_comparison.R",
    "src/evaluate_model.R",
    "src/create_figures.R"
  )
  
  required <- c("artifacts/trips_clean.rds", scripts)
  missing <- required[!file.exists(required)]
  
  if (length(missing) > 0) {
    stop(
      "Missing required files: ",
      paste(missing, collapse = ", "),
      ". Run this command from the project root.",
      call. = FALSE
    )
  }
  
  for (script in scripts) {
    message("\nRunning: ", script)
    
    # Each script runs in its own environment.
    source(script, local = new.env(parent = globalenv()))
  }
  
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

main()