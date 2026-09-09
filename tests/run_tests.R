# Run from the project root: Rscript tests/run_tests.R

if (!requireNamespace("testthat", quietly = TRUE)) {
  stop("Missing testthat. Run renv::restore() first.", call. = FALSE)
}

project_root <- normalizePath(".", mustWork = TRUE)
checkpoint <- file.path(project_root, "artifacts", "trips_clean.rds")

if (!file.exists(checkpoint) ||
    !file.exists(file.path(project_root, "reproduce.R"))) {
  stop("Run this script from the project root.", call. = FALSE)
}

# Test 1: Validate the checkpoint's model inputs and transformations.
testthat::test_that("checkpoint satisfies the analysis data contract", {
  trips <- as.data.frame(readRDS(checkpoint))
  
  required <- c(
    "duration_min", "distance_km", "log_duration",
    "hour", "weekday", "vehicle_type"
  )
  
  testthat::expect_true(all(required %in% names(trips)))
  testthat::expect_gt(nrow(trips), 0)
  testthat::expect_false(anyNA(trips[required]))
  
  for (column in c("duration_min", "distance_km",
                   "log_duration", "hour")) {
    testthat::expect_true(is.numeric(trips[[column]]))
    testthat::expect_true(all(is.finite(trips[[column]])))
  }
  
  testthat::expect_true(all(trips$duration_min > 0))
  testthat::expect_true(all(trips$distance_km > 0))
  testthat::expect_true(all(trips$hour %in% 0:23))
  
  testthat::expect_true(all(
    as.character(trips$weekday) %in%
      c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
  ))
  
  testthat::expect_true(is.factor(trips$vehicle_type))
  testthat::expect_gte(nlevels(droplevels(trips$vehicle_type)), 2)
  
  testthat::expect_equal(
    trips$log_duration,
    log(trips$duration_min),
    tolerance = 1e-10
  )
})

# Run the pipeline with copied inputs and no pre-existing results.
check_pipeline <- function(root) {
  work_dir <- tempfile("mobility-pipeline-test-")
  dir.create(work_dir)
  old_dir <- getwd()
  
  on.exit({
    setwd(old_dir)
    unlink(work_dir, recursive = TRUE)
  }, add = TRUE)
  
  dir.create(file.path(work_dir, "artifacts"))
  
  copied <- c(
    file.copy(
      file.path(root, "src"),
      work_dir,
      recursive = TRUE
    ),
    file.copy(
      file.path(root, "reproduce.R"),
      work_dir
    ),
    file.copy(
      file.path(root, "artifacts", "trips_clean.rds"),
      file.path(work_dir, "artifacts")
    )
  )
  
  if (!all(copied)) {
    stop("Could not prepare the temporary test directory.")
  }
  
  setwd(work_dir)
  testthat::expect_false(dir.exists("results"))
  
  source("reproduce.R", local = new.env(parent = globalenv()))
  
  expected <- c(
    "results/tables/model_comparison.csv",
    "results/tables/test_metrics.csv",
    "results/tables/data_summary.csv",
    "results/figures/test_predicted_vs_observed.png",
    "results/figures/log_duration_by_vehicle.png",
    "results/figures/distance_vs_duration_loglog.png",
    "results/figures/quadratic_diagnostics.png"
  )
  
  testthat::expect_true(all(file.exists(expected)))
  testthat::expect_true(all(file.info(expected)$size > 0))
  
  # Check the contents of the generated tables.
  comparison <- read.csv(expected[1])
  metrics <- read.csv(expected[2])
  summary_table <- read.csv(expected[3])
  n <- nrow(as.data.frame(readRDS("artifacts/trips_clean.rds")))
  
  testthat::expect_equal(nrow(comparison), 4L)
  testthat::expect_setequal(
    comparison$model,
    c("baseline", "quadratic", "logdist", "interaction")
  )
  testthat::expect_true(all(comparison$n == n))
  
  for (column in c("AIC", "RSE", "R2", "Adj_R2")) {
    testthat::expect_true(all(is.finite(comparison[[column]])))
  }
  
  testthat::expect_equal(nrow(metrics), 1L)
  testthat::expect_equal(metrics$n_train, floor(0.8 * n))
  testthat::expect_equal(metrics$n_test, n - floor(0.8 * n))
  testthat::expect_true(is.finite(metrics$RMSE))
  testthat::expect_gte(metrics$RMSE, 0)
  testthat::expect_true(is.finite(metrics$R2))
  testthat::expect_lte(metrics$R2, 1)
  
  testthat::expect_setequal(
    summary_table$variable,
    c("duration_min", "distance_km")
  )
  
  # Verify PNG signatures, rather than only checking filenames.
  png_signature <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
  for (path in expected[4:7]) {
    testthat::expect_identical(
      readBin(path, what = "raw", n = 8),
      png_signature
    )
  }
}

testthat::test_that("pipeline regenerates valid outputs from scratch", {
  check_pipeline(project_root)
})

message("All validation tests completed successfully.")