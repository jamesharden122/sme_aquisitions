add_investor_dcf_rows <-
function(df, ret = 0.10) {
  req_cols <- c("period", "adjusted_cashflow", "gp_equity", "lp_equity",
                "lp_dividend", "lp_retained")
  missing <- setdiff(req_cols, names(df))
  if (length(missing) > 0) {
    stop("Data frame is missing required columns: ", paste(missing, collapse = ", "))
  }

  # Ensure numeric types
  num_cols <- c("adjusted_cashflow", "gp_equity", "lp_equity", "lp_dividend", "lp_retained")
  df[num_cols] <- lapply(df[num_cols], as.numeric)

  n <- nrow(df)
  if (n < 1) stop("Data frame must have at least one row.")

  # Period index (handles 0-based or 1-based)
  t <- df$period - min(df$period, na.rm = TRUE)

  # --- LP retained cumulative (full, for reference)
  lp_retained_cum_full <- cumsum(df$lp_retained)

  # --- Adjusted LP retained cumulative (excludes initial investment)
  # i.e., start accumulation from period 2 onward
  lp_retained_adj <- df$lp_retained
  lp_retained_adj[1] <- 0  # exclude period 1 / initial investment
  lp_retained_cum <- cumsum(lp_retained_adj)

  # --- ROI is applied on the prior period's adjusted retained balance
  prior_balance <- c(0, head(lp_retained_cum, -1))
  lp_retained_roi <- ret * pmax(prior_balance, 0)

  # --- Investor cashflow:
  # period 1 → adjusted_cashflow[1]
  # periods 2..n → lp_dividend + lp_retained_roi
  investor_cf <- numeric(n)
  investor_cf[1] <- df$adjusted_cashflow[1]
  if (n >= 2) {
    investor_cf[2:n] <- df$lp_dividend[2:n] + lp_retained_roi[2:n]
  }
  investor_cf_and_ret <- investor_cf
  investor_cf_and_ret[2:n] <- investor_cf_and_ret[2:n]+lp_retained_adj[2:n]
  # --- Bind new columns
  df$lp_retained_cum_full <- lp_retained_cum_full   # original running sum (for reference)
  df$lp_retained_cum      <- lp_retained_cum        # adjusted cumulative excluding initial investment
  df$lp_retained_roi      <- lp_retained_roi
  df$investor_cf          <- investor_cf
  df$investor_cf_and_ret <- investor_cf_and_ret
  df}
