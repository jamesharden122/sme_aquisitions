combine_cashflow_and_financing <-
function(cf_df, fin_df) {
  stopifnot("cashflow" %in% names(cf_df), "payment" %in% names(fin_df))

  # Coerce to plain data.frame (avoid tibble/vctrs surprises)
  cf_df  <- as.data.frame(cf_df,  stringsAsFactors = FALSE)
  fin_df <- as.data.frame(fin_df, stringsAsFactors = FALSE)

  # Ensure a clean, consistent column order in financing (keep payment + everything else stable)
  fin_cols <- names(fin_df)
  # put "period" (if any) first, then "payment", then the rest
  fin_df <- fin_df[, unique(c(intersect("period", fin_cols), "payment", setdiff(fin_cols, c("period", "payment")))), drop = FALSE]

  # --- helper to make a zero row with same columns & types ---
  make_zero_row <- function(template) {
    zr <- lapply(template, function(col) {
      if (is.numeric(col)) return(0)
      if (inherits(col, "Date")) return(as.Date(NA))
      if (inherits(col, "POSIXt")) return(as.POSIXct(NA))
      return(NA)
    })
    zr <- as.data.frame(zr, stringsAsFactors = FALSE)
    names(zr) <- names(template)
    zr
  }

  # Ensure period starts at 0 for project CF
  cf_df <- cf_df[order(cf_df$period), , drop = FALSE]
  cf_df$period <- 0:(nrow(cf_df) - 1)

  # Insert a zero row at top of financing schedule (exact same structure)
  zero_row <- make_zero_row(fin_df)
  fin_df_mod <- rbind(zero_row, fin_df)   # same columns, same order
  fin_df_mod$period <- 0:(nrow(fin_df_mod) - 1)

  # Align lengths by padding with exact-structure copies
  max_period <- max(nrow(cf_df), nrow(fin_df_mod))

  if (nrow(cf_df) < max_period) {
    need <- max_period - nrow(cf_df)
    cf_pad <- cf_df[rep(NA_integer_, need), , drop = FALSE]
    cf_pad$period <- nrow(cf_df):(max_period - 1)
    # numeric columns -> 0, others -> NA
    num_cols_cf <- vapply(cf_pad, is.numeric, logical(1))
    cf_pad[num_cols_cf] <- lapply(cf_pad[num_cols_cf], function(x) { x[is.na(x)] <- 0; x })
    cf_df <- rbind(cf_df, cf_pad)
  }

  if (nrow(fin_df_mod) < max_period) {
    need <- max_period - nrow(fin_df_mod)
    fin_pad <- fin_df_mod[rep(NA_integer_, need), , drop = FALSE]
    fin_pad$period <- nrow(fin_df_mod):(max_period - 1)
    num_cols_fin <- vapply(fin_pad, is.numeric, logical(1))
    fin_pad[num_cols_fin] <- lapply(fin_pad[num_cols_fin], function(x) { x[is.na(x)] <- 0; x })
    fin_df_mod <- rbind(fin_df_mod, fin_pad)
  }

  # Merge and subtract (use only period + payment from financing)
  debt_slice <- fin_df_mod[, c("period", "payment"), drop = FALSE]
  combined <- merge(cf_df, debt_slice, by = "period", all = TRUE)

  # Replace NAs with 0 in numeric columns only
  num_cols <- vapply(combined, is.numeric, logical(1))
  for (nm in names(combined)[num_cols]) {
    combined[[nm]][is.na(combined[[nm]])] <- 0
  }

  combined$adjusted_cashflow <- combined$cashflow - combined$payment
  combined
}
