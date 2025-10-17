# SME Acquisitions — R Pipeline

This repository contains R functions and a small driver script to model GP/LP cashflows for selected deals and to compute investor DCF-related outputs.

## Structure

- `functions/`: User-defined R functions extracted from the original `.RData` session.
  - `build_split_gp_lp.R`
  - `add_investor_dcf_rows.R`
  - `amortization_schedule.R`
  - `cashflow_from_selection.R`
  - `combine_cashflow_and_financing.R`
  - `split_gp_lp_cashflows.R`
- `data/df.csv`: Deal-level dataframe used as input to the pipeline (CSV).
- `main.R`: Loads `data/df.csv`, sources the functions, runs the GP/LP splits for two selections, combines the results, and computes investor DCF-derived columns.
- (Optional) A helper was used during setup to extract user-defined functions from `.RData` into `functions/`.

## Requirements

- R (tested with R 4.5+). Only base R is required for running `main.R`.

## Setup

1. Ensure the input dataframe exists at `data/df.csv` with the expected columns (as produced from your original `df`).
   - If you only have `.RData` containing `df`, you can export it once using R:
     ```r
     load('.RData')         # must contain object `df`
     dir.create('data', showWarnings = FALSE)
     write.csv(df, 'data/df.csv', row.names = FALSE, na = '')
     ```

### Input Data Schema

The pipeline expects, at minimum, the following columns in `data/df.csv`:
- `asking_price`: Numeric asking price per deal row.
- `cashflows`: Numeric baseline annual cashflow per deal row.

Only the rows referenced by `idx` in `build_split_gp_lp` must have valid values for these columns.

## Usage

Run the driver script:

```sh
Rscript main.R
```

This will:
- Read `df` from `data/df.csv`.
- Source the functions under `functions/`.
- Compute two output tables using `build_split_gp_lp` with indices `29` and `32`, combine them, and pass the result to `add_investor_dcf_rows`.
- Print a short summary and the first rows of the final `out_full` dataframe.

## Notes

- Duplicate/case-conflict copies of `add_investor_dcf_rows` were cleaned up; the canonical file is `functions/add_investor_dcf_rows.R`.
- If you modify function implementations, keep file names consistent so `main.R` sources the expected versions.

## Function Reference

- `build_split_gp_lp(df, idx, years, growth = 0, loan_amount, annual_rate, debt_years = years, freq = 12, gp_share = 0.20, lp_share = NULL, lp_payout_ratio = 0.80, round_digits = 2)`:
  - Purpose: End-to-end helper that builds project cashflows, computes a debt amortization schedule, combines them, and splits the result into GP/LP cashflows.
  - Key args: `idx` (row indices of selected deals), `years` (projection horizon in years), `growth` (annual growth on base cashflow), `loan_amount` (principal), `annual_rate` (APR), `debt_years` (term), `freq` (payments per year), `gp_share`/`lp_share` (must sum to 1), `lp_payout_ratio` (fraction of LP equity paid as dividend), `round_digits` (integer rounding precision).
  - Returns: Data frame with columns `period`, `adjusted_cashflow`, `gp_equity`, `lp_equity`, `lp_dividend`, `lp_retained`.

- `cashflow_from_selection(df, idx, years, loan_amount, growth = 0)`:
  - Purpose: Builds the base project cashflow vector from selected rows of `df`.
  - Input columns: `df$asking_price`, `df$cashflows`.
  - Behavior: Sets period 0 outflow to `-(sum(asking_price[idx]) - loan_amount)` and future periods as `base_cashflow * (1 + growth)^t` for `t = 0..years-1`.
  - Returns: Data frame with `period`, `cashflow`, `selected_rows`.

- `amortization_schedule(loan_amount, annual_rate, years, freq = 12, start_date = NULL, round_digits = 2)`:
  - Purpose: Standard amortization schedule at the given frequency.
  - Behavior: Handles zero-interest edge cases, optional `start_date` (adds `due_date`), and attaches a `summary` attribute (payment per period, totals).
  - Returns: Data frame with `period`, `payment`, `interest`, `principal`, `balance` (and `due_date` if `start_date` provided).

- `combine_cashflow_and_financing(cf_df, fin_df)`:
  - Purpose: Aligns project cashflows with the debt schedule and subtracts debt `payment` to produce `adjusted_cashflow`.
  - Requirements: `cf_df` must contain `cashflow`, `fin_df` must contain `payment`. Both are aligned to start at period 0.
  - Returns: Data frame with original `cf_df` columns plus `payment` and `adjusted_cashflow`.

- `split_gp_lp_cashflows(x, gp_share = 0.20, lp_share = NULL, lp_payout_ratio = 0.80, round_digits = 2)`:
  - Purpose: Splits `adjusted_cashflow` between GP and LP, then divides LP into `lp_dividend` and `lp_retained` based on `lp_payout_ratio`.
  - Input: Either a numeric vector of cashflows or a data frame with `adjusted_cashflow` (and optionally `period`). If `lp_share` is `NULL`, it is set to `1 - gp_share`.
  - Returns: Data frame with `period`, `adjusted_cashflow`, `gp_equity`, `lp_equity`, `lp_dividend`, `lp_retained`.

- `add_investor_dcf_rows(df, ret = 0.10)`:
  - Purpose: Adds investor-focused derived columns including cumulative LP retained balances, ROI on retained balances, and investor cashflow series.
  - Requirements: Columns `period`, `adjusted_cashflow`, `gp_equity`, `lp_equity`, `lp_dividend`, `lp_retained` must exist.
  - Returns: Input columns plus `lp_retained_cum_full`, `lp_retained_cum` (excludes initial outlay), `lp_retained_roi`, `investor_cf`, and `investor_cf_and_ret`.

## Main Implementation Details (`main.R`)

- Load input: Reads `data/df.csv` into `df` with strings preserved (`stringsAsFactors = FALSE`). The CSV must at least include `asking_price` and `cashflows` for the selected rows used by the pipeline.
- Source functions: Loads the six canonical function files from `functions/`.
- Run scenarios: Calls `build_split_gp_lp` twice and stacks the results:
  - First call: `idx = c(29)`, `years = 15`, `growth = 0.02`, `loan_amount = 2_000_000`, `annual_rate = 0.06`, `debt_years = 10`, `freq = 1` (annual), `gp_share = 0.20`, `lp_share = 0.80`, `lp_payout_ratio = 0.70`.
  - Second call: `idx = c(32)` with the same parameters.
- Combine + enrich: Binds both outputs (`rbind`) and passes to `add_investor_dcf_rows` to compute investor-derived series.
- Output: Prints row count, column names, and `head(out_full, 10)` for a quick inspection.

Tips:
- Prefer named arguments when calling `build_split_gp_lp` to avoid mis-ordering, especially for `lp_share`, `lp_payout_ratio`, and `round_digits` (which should be an integer like `2`).
- `freq` controls payment cadence: `12` monthly, `4` quarterly, `1` annual, etc.
- `lp_payout_ratio` governs the split between `lp_dividend` (distributed) and `lp_retained` (reinvested) for positive LP equity periods.
