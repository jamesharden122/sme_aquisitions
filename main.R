#!/usr/bin/env Rscript

## Load `df` from data/df.csv, then load functions and run the pipeline

options(stringsAsFactors = FALSE)

# 1) Load `df` strictly from CSV
csv_dir  <- 'data'
csv_path <- file.path(csv_dir, 'df.csv')
if (!file.exists(csv_path)) {
  stop("data/df.csv not found. Please create it by exporting 'df' to CSV.")
}
df <- utils::read.csv(csv_path, stringsAsFactors = FALSE, check.names = FALSE)

# 2) Source required functions from the functions/ folder (only the canonical files)
func_dir <- 'functions'
if (!dir.exists(func_dir)) stop('functions/ directory not found.')
needed <- c(
  'amortization_schedule.R',
  'cashflow_from_selection.R',
  'combine_cashflow_and_financing.R',
  'split_gp_lp_cashflows.R',
  'build_split_gp_lp.R',
  'add_investor_dcf_rows.R'
)
paths <- file.path(func_dir, needed)
paths <- paths[file.exists(paths)]
if (length(paths) == 0) stop('No function files found to source in functions/.')
invisible(lapply(paths, function(f) source(f, chdir = TRUE)))

# 3) Run computations
out3 <- build_split_gp_lp(df, c(29), 15, 0.02, 2000000, 0.06, 10, 1, 0.20, 0.80, 0.70)
out2 <- build_split_gp_lp(df, c(32), 15, 0.02, 2000000, 0.06, 10, 1, 0.20, 0.80, 0.70)

# Combine the two outputs
out2 <- rbind(out3, out2)

# Compute investor DCF rows on the combined output
out_full <- add_investor_dcf_rows(out2)

# 4) Display a quick summary
cat('Computed out_full with', nrow(out_full), 'rows. Columns:', paste(names(out_full), collapse = ', '), '\n')
print(utils::head(out_full, 10))
