cashflow_from_selection <-
function(df, idx, years,loan_amount, growth = 0) {
  # Validate inputs
  stopifnot(length(idx) >= 1, years >= 0)
  
  # Combine asking prices and cashflows from selected rows
  total_investment <- -sum(df$asking_price[idx],-loan_amount, na.rm = TRUE)
  base_cashflow <- sum(df$cashflows[idx], na.rm = TRUE)
  
  # Create cashflow sequence: initial outlay + future cashflows
  periods <- 0:years
  cashflow <- numeric(length(periods))
  cashflow[1] <- total_investment
  
  if (years > 0) {
    cashflow[-1] <- base_cashflow * (1 + growth)^(0:(years - 1))
  }
  
  # Build resulting dataframe
  data.frame(
    period = periods,
    cashflow = cashflow,
    selected_rows = paste(idx, collapse = ","),
    stringsAsFactors = FALSE
  )
}
