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
- `scripts/extract_user_deps.R`: Helper to extract user-defined dependency functions from `.RData` into `functions/` (already run during setup).

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

