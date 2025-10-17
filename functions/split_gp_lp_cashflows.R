split_gp_lp_cashflows <-
function(
  x, gp_share = 0.20, lp_share = NULL, lp_payout_ratio = 0.80, round_digits = 2
) {
  if (is.data.frame(x)) {
    stopifnot("adjusted_cashflow" %in% names(x))
    cf <- as.numeric(x$adjusted_cashflow)
    period <- if ("period" %in% names(x)) x$period else seq_along(cf) - 1L
  } else {
    cf <- as.numeric(x); period <- seq_along(cf) - 1L
  }
  if (is.null(lp_share)) lp_share <- 1 - gp_share
  stopifnot(gp_share >= 0, lp_share >= 0, abs(gp_share + lp_share - 1) < 1e-8,
            lp_payout_ratio >= 0, lp_payout_ratio <= 1)

  gp_equity <- cf * gp_share
  lp_total  <- cf * lp_share
  lp_dividend <- ifelse(lp_total > 0, lp_total * lp_payout_ratio, 0)
  lp_retained <- lp_total - lp_dividend

  data.frame(
    period             = period,
    adjusted_cashflow  = round(cf, round_digits),
    gp_equity          = round(gp_equity, round_digits),
    lp_equity          = round(lp_total, round_digits),
    lp_dividend        = round(lp_dividend, round_digits),
    lp_retained        = round(lp_retained, round_digits),
    stringsAsFactors = FALSE
  )
}
