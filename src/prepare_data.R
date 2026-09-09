# Rebuild cleaned data from the original CSV.
# The included checkpoint in artifacts/ is never overwritten.

prepare_data <- function(
    raw_path,
    output_path = "data/processed/trips_clean.rds") {
  
  for (package in c("data.table", "dplyr")) {
    if (!requireNamespace(package, quietly = TRUE)) {
      stop("Missing package: ", package,
           ". Run renv::restore() first.", call. = FALSE)
    }
  }
  
  if (!file.exists(raw_path)) {
    stop("Raw CSV not found: ", raw_path, call. = FALSE)
  }
  
  required <- c(
    "ID", "Vehicle Type", "Trip Duration", "Trip Distance",
    "Start Time", "End Time", "Month", "Hour", "Day of Week"
  )
  
  header <- names(data.table::fread(raw_path, nrows = 0))
  missing <- setdiff(required, header)
  
  if (length(missing) > 0) {
    stop("Missing columns: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  
  # English month abbreviations must parse consistently.
  old_locale <- Sys.getlocale("LC_TIME")
  on.exit(Sys.setlocale("LC_TIME", old_locale), add = TRUE)
  
  if (Sys.setlocale("LC_TIME", "C") == "") {
    stop("Could not set the time locale to C.", call. = FALSE)
  }
  
  message("Reading raw CSV; this step may take time...")
  
  # Read only the nine columns used in the original analysis.
  dt <- data.table::fread(
    raw_path,
    select = required,
    nThread = 4,
    showProgress = FALSE
  )
  
  message("Raw observations: ", nrow(dt))
  
  if (nrow(dt) < 200000L) {
    stop("At least 200,000 rows are required for the original sample.",
         call. = FALSE)
  }
  
  # Preserve the original sampling method and seed.
  set.seed(123)
  sampled <- dplyr::sample_n(dt, 200000)
  sampled <- dplyr::select(sampled, dplyr::all_of(required))
  
  rm(dt)
  invisible(gc())
  
  message("Cleaning the 200,000-row sample...")
  
  sampled$`Trip Duration` <- as.numeric(
    gsub(",", "", sampled$`Trip Duration`)
  )
  sampled$duration_min <- sampled$`Trip Duration` / 60
  
  duration_cutoff <- quantile(
    sampled$duration_min, 0.999, na.rm = TRUE
  )
  sampled <- dplyr::filter(
    sampled, duration_min <= duration_cutoff
  )
  
  sampled$`Trip Distance` <- as.numeric(
    gsub(",", "", sampled$`Trip Distance`)
  )
  sampled$distance_km <- sampled$`Trip Distance` / 1000
  
  # As in the original QMD, calculate this cutoff AFTER duration filtering.
  distance_cutoff <- quantile(
    sampled$distance_km, 0.999, na.rm = TRUE
  )
  sampled <- dplyr::filter(
    sampled, distance_km <= distance_cutoff
  )
  
  sampled$vehicle_type <- factor(sampled$`Vehicle Type`)
  sampled$weekday <- factor(
    sampled$`Day of Week`,
    levels = c(1, 2, 3, 4, 5, 6, 0),
    labels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
  )
  sampled$month <- factor(sampled$Month, levels = 1:12)
  sampled$hour <- as.numeric(sampled$Hour)
  
  sampled$start_time <- as.POSIXct(
    sampled$`Start Time`,
    format = "%Y %b %d %I:%M:%S %p",
    tz = "US/Central"
  )
  sampled$end_time <- as.POSIXct(
    sampled$`End Time`,
    format = "%Y %b %d %I:%M:%S %p",
    tz = "US/Central"
  )
  
  cleaned <- dplyr::filter(
    sampled,
    !is.na(duration_min), duration_min > 0,
    !is.na(distance_km), distance_km > 0,
    !is.na(start_time), !is.na(end_time),
    !is.na(vehicle_type), !is.na(hour), !is.na(weekday)
  )
  
  # Compute after removing nonpositive durations to avoid log warnings.
  cleaned$log_duration <- log(cleaned$duration_min)
  
  if (nrow(cleaned) == 0L) {
    stop("Cleaning removed all rows; check the raw data format.",
         call. = FALSE)
  }
  
  dir.create(
    dirname(output_path),
    recursive = TRUE,
    showWarnings = FALSE
  )
  saveRDS(cleaned, output_path)
  
  message("Cleaned observations: ", nrow(cleaned))
  message("Saved to: ", output_path)
  
  invisible(output_path)
}