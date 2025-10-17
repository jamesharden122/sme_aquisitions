amortization_schedule <-
function(
  loan_amount,
  annual_rate,
  years,
  freq = 12,         # payments per year (12=monthly, 4=quarterly, 1=annual, 26=biweekly, etc.)
  start_date = NULL, # e.g. as.Date("2025-01-01"); if NULL, no Date column is added
  round_digits = 2   # rounding for money columns
) {
  stopifnot(loan_amount >= 0, years >= 0, freq >= 1)

  n <- as.integer(round(years * freq))
  if (n == 0) {
    return(data.frame(
      period = integer(0), payment = numeric(0), interest = numeric(0),
      principal = numeric(0), balance = numeric(0)
    ))
  }

  r_per <- annual_rate / freq

  # Payment formula; handle zero-rate edge case
  if (r_per == 0) {
    pmt <- if (n > 0) loan_amount / n else 0
  } else {
    pmt <- loan_amount * r_per / (1 - (1 + r_per)^(-n))
  }

  # Pre-allocate vectors
  period    <- seq_len(n)
  payment   <- rep(pmt, n)
  interest  <- numeric(n)
  principal <- numeric(n)
  balance   <- numeric(n)

  bal <- loan_amount

  for (t in period) {
    int_t <- if (r_per == 0) 0 else bal * r_per
    prin_t <- pmt - int_t

    # If rounding would create a tiny negative balance near the end, adjust final row
    if (t == n) {
      prin_t <- bal
      int_t  <- payment[t] - prin_t
      # If zero-rate, ensure payment equals principal on final row
      if (r_per == 0) {
        int_t <- 0
        payment[t] <- prin_t
      }
    }

    # Update balance
    bal <- bal - prin_t
    if (bal < 0 && abs(bal) < 1e-8) bal <- 0

    interest[t]  <- int_t
    principal[t] <- prin_t
    balance[t]   <- bal
  }

  # Optional Date column
  if (!is.null(start_date)) {
    if (!inherits(start_date, "Date")) {
      stop("start_date must be a Date (use as.Date('YYYY-MM-DD')).")
    }
    # Add periods by frequency
    by_str <- switch(
      as.character(freq),
      "12" = "months", "4" = "quarter", "1" = "years",
      "26" = "2 weeks", "52" = "weeks",
      # generic fallback: month approximation
      "months"
    )
    # Generate dates
    if (by_str %in% c("months", "quarter", "years")) {
      dates <- seq(from = start_date, by = by_str, length.out = n)
    } else {
      # weekly/biweekly fallback
      step_days <- if (by_str == "2 weeks") 14L else if (by_str == "weeks") 7L else 30L
      dates <- start_date + seq(0L, by = step_days, length.out = n)
    }
  }

  df <- data.frame(
    period    = period,
    payment   = round(payment,   round_digits),
    interest  = round(interest,  round_digits),
    principal = round(principal, round_digits),
    balance   = round(balance,   round_digits)
  )

  if (!is.null(start_date)) {
    df$due_date <- dates
    # move date next to period
    df <- df[, c("period", "due_date", "payment", "interest", "principal", "balance")]
  }

  attr(df, "summary") <- list(
    loan_amount          = round(loan_amount, round_digits),
    annual_rate          = annual_rate,
    years                = years,
    freq                 = freq,
    payment_per_period   = round(pmt, round_digits),
    total_payments       = round(sum(df$payment), round_digits),
    total_interest       = round(sum(df$interest), round_digits),
    total_principal      = round(sum(df$principal), round_digits)
  )

  df
}
