# Fit the four original regression models and export comparison metrics.
# Run from the project root.

run_model_comparison <- function(
    input_path = "artifacts/trips_clean.rds",
    output_dir = "results/tables") {
  
  # 1. Read the checkpoint
  if (!file.exists(input_path)) {
    stop("Missing checkpoint: ", input_path,
         ". Place trips_clean.rds in artifacts/.", call. = FALSE)
  }
  
  message("Reading cleaned data...")
  trips <- as.data.frame(readRDS(input_path))
  
  # 2. Validate the variables needed by the models
  required <- c(
    "log_duration", "distance_km", "hour",
    "weekday", "vehicle_type"
  )
  
  missing_cols <- setdiff(required, names(trips))
  if (length(missing_cols) > 0) {
    stop("Missing columns: ", paste(missing_cols, collapse = ", "),
         call. = FALSE)
  }
  
  if (nrow(trips) == 0L || anyNA(trips[required])) {
    stop("Model data are empty or contain missing values.",
         call. = FALSE)
  }
  
  numeric_cols <- c("log_duration", "distance_km", "hour")
  valid_numeric <- vapply(
    trips[numeric_cols],
    function(x) is.numeric(x) && all(is.finite(x)),
    logical(1)
  )
  
  if (!all(valid_numeric)) {
    stop("Model numeric columns must contain finite numbers.",
         call. = FALSE)
  }
  
  if (any(trips$distance_km <= 0) ||
      any(!trips$hour %in% 0:23)) {
    stop("Distances must be positive and hours must be integers 0–23.",
         call. = FALSE)
  }
  
  # Preserve existing factor levels from the original analysis
  trips$weekday <- factor(trips$weekday)
  trips$vehicle_type <- factor(trips$vehicle_type)
  
  # 3. Fit the original four model specifications
  message("Fitting four models on ", nrow(trips), " observations...")
  
  models <- list(
    baseline = lm(
      log_duration ~ distance_km + hour + weekday + vehicle_type,
      data = trips, na.action = na.fail
    ),
    quadratic = lm(
      log_duration ~ distance_km + I(distance_km^2) +
        hour + weekday + vehicle_type,
      data = trips, na.action = na.fail
    ),
    logdist = lm(
      log_duration ~ log(distance_km + 0.001) +
        hour + weekday + vehicle_type,
      data = trips, na.action = na.fail
    ),
    interaction = lm(
      log_duration ~ distance_km * vehicle_type + hour + weekday,
      data = trips, na.action = na.fail
    )
  )
  
  # 4. Extract comparison metrics
  comparison <- do.call(
    rbind,
    lapply(names(models), function(model_name) {
      model <- models[[model_name]]
      s <- summary(model)
      
      data.frame(
        model = model_name,
        n = nobs(model),
        AIC = AIC(model),
        RSE = s$sigma,
        R2 = s$r.squared,
        Adj_R2 = s$adj.r.squared
      )
    })
  )
  rownames(comparison) <- NULL
  
  # 5. Save results; keep full precision in the CSV
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_path <- file.path(output_dir, "model_comparison.csv")
  write.csv(comparison, output_path, row.names = FALSE)
  
  message("Saved comparison table to: ", output_path)
  print(comparison, digits = 5, row.names = FALSE)
  
  invisible(comparison)
}

if (sys.nframe() == 0L)
  run_model_comparison()