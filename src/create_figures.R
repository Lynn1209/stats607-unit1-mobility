# Generate selected EDA figures, model diagnostics, and a summary table.
# Run from the project root.

run_figures <- function(
    input_path = "artifacts/trips_clean.rds",
    output_dir = "results") {
  
  if (!file.exists(input_path)) {
    stop("Missing checkpoint: ", input_path, call. = FALSE)
  }
  
  message("Reading cleaned data...")
  trips <- as.data.frame(readRDS(input_path))
  
  required <- c(
    "duration_min", "log_duration", "distance_km",
    "hour", "weekday", "vehicle_type"
  )
  
  missing_cols <- setdiff(required, names(trips))
  if (length(missing_cols) > 0) {
    stop("Missing columns: ", paste(missing_cols, collapse = ", "),
         call. = FALSE)
  }
  
  if (nrow(trips) == 0L || anyNA(trips[required])) {
    stop("Data are empty or contain missing required values.",
         call. = FALSE)
  }
  
  numeric_cols <- c(
    "duration_min", "log_duration", "distance_km", "hour"
  )
  
  valid_numeric <- vapply(
    trips[numeric_cols],
    function(x) is.numeric(x) && all(is.finite(x)),
    logical(1)
  )
  
  if (!all(valid_numeric)) {
    stop("Numeric columns must contain finite numbers.",
         call. = FALSE)
  }
  
  if (any(trips$duration_min <= 0) ||
      any(trips$distance_km <= 0) ||
      any(!trips$hour %in% 0:23)) {
    stop("Invalid duration, distance, or hour values.",
         call. = FALSE)
  }
  
  trips$weekday <- factor(trips$weekday)
  trips$vehicle_type <- factor(trips$vehicle_type)
  
  figure_dir <- file.path(output_dir, "figures")
  table_dir <- file.path(output_dir, "tables")
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Close the graphics device even if plotting fails.
  save_png <- function(filename, draw,
                       width = 1500, height = 1200) {
    png(
      file.path(figure_dir, filename),
      width = width, height = height, res = 180
    )
    on.exit(dev.off(), add = TRUE)
    draw()
  }
  
  # 1. Summary statistics
  summary_table <- data.frame(
    variable = c("duration_min", "distance_km"),
    n = nrow(trips),
    mean = c(mean(trips$duration_min), mean(trips$distance_km)),
    sd = c(sd(trips$duration_min), sd(trips$distance_km)),
    median = c(median(trips$duration_min), median(trips$distance_km)),
    min = c(min(trips$duration_min), min(trips$distance_km)),
    max = c(max(trips$duration_min), max(trips$distance_km))
  )
  
  write.csv(
    summary_table,
    file.path(table_dir, "data_summary.csv"),
    row.names = FALSE
  )
  
  # 2. Vehicle-type EDA, preserving the original log-scale boxplot
  message("Creating EDA figures...")
  
  save_png("log_duration_by_vehicle.png", function() {
    boxplot(
      log_duration ~ vehicle_type,
      data = trips,
      col = "lightblue",
      main = "Log trip duration by vehicle type",
      xlab = "Vehicle type",
      ylab = "Log(duration in minutes)"
    )
  })
  
  # 3. Distance-duration relationship
  save_png("distance_vs_duration_loglog.png", function() {
    plot(
      log(trips$distance_km),
      trips$log_duration,
      pch = 16, cex = 0.4,
      col = rgb(0, 0, 0, 0.1),
      main = "Trip distance and duration",
      xlab = "Log(distance in km)",
      ylab = "Log(duration in minutes)"
    )
  })
  
  # 4. Diagnostics for the original full-data quadratic model
  message("Fitting quadratic model for diagnostics...")
  
  fit <- lm(
    log_duration ~ distance_km + I(distance_km^2) +
      hour + weekday + vehicle_type,
    data = trips,
    na.action = na.fail
  )
  
  save_png("quadratic_diagnostics.png", function() {
    par(mfrow = c(2, 2))
    plot(
      fit,
      which = c(1, 2, 3, 5),
      ask = FALSE
    )
  }, width = 2000, height = 1600)
  
  message("Saved data_summary.csv and three figures.")
  invisible(summary_table)
}

if (sys.nframe() == 0L)
  run_figures()