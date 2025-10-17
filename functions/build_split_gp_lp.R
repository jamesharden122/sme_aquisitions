build_split_gp_lp <-
function(
  df,
  idx,                   # integer vector of selected deal rows
  years,                 # projection horizon (years)
  growth = 0,            # annual growth for project CFs
  # Debt terms
  loan_amount,           # loan principal (used in project CF AND amortization)
  annual_rate,           # APR
  debt_years = years,    # debt term in years
  freq = 12,             # payments per year for amortization
  # Equity split
  gp_share = 0.20,
  lp_share = NULL,       # if NULL, set to 1 - gp_share
  lp_payout_ratio = 0.80,
  round_digits = 2
) {
  stopifnot(length(idx) >= 1, years >= 0)

  # If lp_share provided, enforce gp+lp == 1
  if (!is.null(lp_share)) {
    total <- gp_share + lp_share
    if (abs(total - 1) > 1e-8) {
      stop(sprintf("gp_share + lp_share must equal 1. Got %.4f + %.4f = %.4f",
                   gp_share, lp_share, total))
    }
  }

  # 1) Project cashflows using YOUR function (note: loan_amount reduces initial outlay)
  cf_proj <- cashflow_from_selection(
    df          = df,
    idx         = idx,
    years       = years,
    loan_amount = loan_amount,
    growth      = growth
  )

  # 2) Debt schedule (uses same loan_amount by default)
  fin_df <- amortization_schedule(
    loan_amount  = loan_amount,
    annual_rate  = annual_rate,
    years        = debt_years,
    freq         = freq,
    start_date   = NULL,
    round_digits = round_digits
  )

  # 3) Combine and subtract payments
  combined_cf <- combine_cashflow_and_financing(cf_df = cf_proj, fin_df = fin_df)

  # 4) Split GP/LP + LP dividends/retained
  split_gp_lp_cashflows(
    combined_cf,
    gp_share        = gp_share,
    lp_share        = lp_share,
    lp_payout_ratio = lp_payout_ratio,
    round_digits    = round_digits
  )
}
