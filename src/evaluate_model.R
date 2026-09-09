# Evaluate the original quadratic model on a fixed train/test split.
# Run from the project root.

run_evaluation <- function(
    input_path = "artifacts/trips_clean.rds",
    output_dir = "results",
    seed = 123) {
  
  # 1. Load and check the checkpoint
  if (!file.exists(input_path)) {
    stop("Missing checkpoint: ", input_path, call. = FALSE)
  }
  
  message("Reading cleaned data...")
  trips <- as.data.frame(readRDS(input_path))
  
  required <- c(
    "log_duration", "distance_km", "hour",
    "weekday", "vehicle_type"
  )
  
  missing_cols <- setdiff(required, names(trips))
  if (length(missing_cols) > 0) {
    stop("Missing columns: ", paste(missing_cols, collapse = ", "),
         call. = FALSE)
  }
  
  if (nrow(trips) < 10L || anyNA(trips[required])) {
    stop("Insufficient observations or missing model values.",
         call. = FALSE)
  }
  
  numeric_cols <- c("log_duration", "distance_km", "hour")
  valid_numeric <- vapply(
    trips[numeric_cols],
    function(x) is.numeric(x) && all(is.finite(x)),
    logical(1)
  )
  
  if (!all(valid_numeric)) {
    stop("Numeric model columns must contain finite numbers.",
         call. = FALSE)
  }
  
  if (any(trips$distance_km <= 0) ||
      any(!trips$hour %in% 0:23)) {
    stop("Distances must be positive and hours must be integers 0-23.",
         call. = FALSE)
  }
  
  trips$weekday <- factor(trips$weekday)
  trips$vehicle_type <- factor(trips$vehicle_type)
  
  # 2. Reproduce the original random split
  set.seed(seed)
  n <- nrow(trips)
  train_idx <- sample(seq_len(n), size = floor(0.8 * n))
  
  train <- trips[train_idx, , drop = FALSE]
  test <- trips[-train_idx, , drop = FALSE]
  
  for (column in c("weekday", "vehicle_type")) {
    unseen <- setdiff(
      as.character(unique(test[[column]])),
      as.character(unique(train[[column]]))
    )
    if (length(unseen) > 0) {
      stop("Test set contains unseen levels in ", column,
           call. = FALSE)
    }
  }
  
  message("Training observations: ", nrow(train))
  message("Test observations: ", nrow(test))
  
  # 3. Fit on training data only
  fit_train <- lm(
    log_duration ~ distance_km + I(distance_km^2) +
      hour + weekday + vehicle_type,
    data = train,
    na.action = na.fail
  )
  
  pred <- predict(fit_train, newdata = test)
  
  if (any(!is.finite(pred))) {
    stop("Predictions contain non-finite values.", call. = FALSE)
  }
  
  # 4. Evaluate on the log-duration scale
  observed <- test$log_duration
  sse <- sum((observed - pred)^2)
  sst <- sum((observed - mean(observed))^2)
  
  if (sst <= 0) {
    stop("Test outcome has no variation; R-squared is undefined.",
         call. = FALSE)
  }
  
  metrics <- data.frame(
    model = "quadratic",
    outcome_scale = "natural log of duration in minutes",
    seed = seed,
    n_train = nrow(train),
    n_test = nrow(test),
    RMSE = sqrt(mean((observed - pred)^2)),
    R2 = 1 - sse / sst
  )
  
  table_dir <- file.path(output_dir, "tables")
  figure_dir <- file.path(output_dir, "figures")
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
  
  write.csv(
    metrics,
    file.path(table_dir, "test_metrics.csv"),
    row.names = FALSE
  )
  
  # 5. Save the prediction plot and always close its graphics device
  figure_path <- file.path(
    figure_dir, "test_predicted_vs_observed.png"
  )
  
  png(figure_path, width = 1500, height = 1200, res = 180)
  tryCatch({
    limits <- range(c(observed, pred))
    
    plot(
      observed, pred,
      xlim = limits, ylim = limits,
      pch = 16, cex = 0.5,
      col = rgb(0, 0, 0, 0.15),
      xlab = "Observed log(duration in minutes)",
      ylab = "Predicted log(duration in minutes)",
      main = "Quadratic model: test-set predictions"
    )
    abline(a = 0, b = 1, col = "red", lwd = 2)
  }, finally = {
    dev.off()
  })
  
  message("Saved test metrics and prediction figure.")
  print(metrics, digits = 5, row.names = FALSE)
  
  invisible(metrics)
}

run_evaluation()