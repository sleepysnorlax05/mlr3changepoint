# Load packages
devtools::load_all("..")
source("load_packages.R")

# Load data
data(Lai2005fig4, package = "changepoint")
dt_lai = data.table::as.data.table(Lai2005fig4)

# Initiate Task:
# Data: Lai2005fig4
# Sequence column: GBM29
# Position column: POS.end
task_lai = TaskCptUnsupervised$new(
  id = "lai2005fig4",
  data = dt_lai,
  sequence_col = "GBM29",
  position_col = "POS.end"
)

autoplot(task_lai)

# Train engine with PELT and BIC penalty
pelt_engine = function(task, row_ids, params) {
  y = task$data(rows = row_ids, cols = task$feature_names)[[1]]

  fit = changepoint::cpt.meanvar(
    y,
    method = "PELT",
    penalty = "BIC"
  )
  return(changepoint::cpts(fit))
}

# Create Learner with PELT
learner_pelt = LearnerCpt$new(
  id = "pelt.bic",
  train_engine = pelt_engine
)

# Train & Predict
learner_pelt$train(task_lai)
pred_pelt_lai = learner_pelt$predict(task_lai)

cat("Predicted changepoint locations (PELT):", pred_pelt_lai$response, "\n")

# Train engine with binsegRcpp::binseg, BIC penalty
binseg_engine = function(task, row_ids, params) {
  # Extract features
  y = task$data(rows = row_ids, cols = task$feature_names)[[1]]
  n = length(y)

  # binsegRcpp
  fit = binsegRcpp::binseg(distribution.str = "meanvar_norm", data.vec = y)

  splits_df = fit$splits

  # BIC penalty
  # Formula: BIC = Loss + (k * log(n)). Since it is estimating mean and variance -> 2 parameters per segment and S - 1 change points
  # -> k = 2S + (S - 1) = 3S - 1
  k = 3 * splits_df$segments - 1

  splits_df$BIC = splits_df$loss + k * log(n)

  # Choosing min BIC
  best = splits_df$segments[which.min(splits_df$BIC)]

  if (best <= 1) {
    return(integer(0))
  } else {
    # Extract the exact split segment coordinates
    optimal_coefs = coef(fit, segments = best)
    cpts = optimal_coefs$end[-nrow(optimal_coefs)]
    return(as.integer(cpts))
  }
}

# Create Learner with Binseg
learner_binseg = LearnerCpt$new(
  id = "binseg",
  train_engine = binseg_engine
)

# Train & Predict
learner_binseg$train(task_lai)
pred_binseg_lai = learner_binseg$predict(task_lai)

cat("Predicted changepoint locations (Binseg):", pred_binseg_lai$response, "\n")

plot_pelt_lai = autoplot(pred_pelt_lai, task_lai, type = "trace") +
  ggplot2::ggtitle("PELT Changepoints")
plot_binseg_lai = autoplot(pred_binseg_lai, task_lai, type = "trace") +
  ggplot2::ggtitle("Binseg Changepoints")

# Plot results
lai_plot = plot_pelt_lai +
  plot_binseg_lai +
  plot_layout(guides = "collect", ncol = 1, nrow = 2) +
  plot_annotation(title = "Lai2005fig4: PELT vs Binseg")

ggsave(
  lai_plot,
  filename = "tests/plots/medium/lai_comparison.png",
  width = 10,
  height = 8
)

# Load ftse data
data(ftse100, package = "changepoint")
dt_ftse = data.table::as.data.table(ftse100)

# Rename columns
data.table::setnames(dt_ftse, old = c("V1", "V2"), new = c("Date", "Price"))

# Initiate Task:
# Data: ftse100
# Sequence column: Price
# Position column: Date
task_ftse = TaskCptUnsupervised$new(
  id = "ftse100",
  data = dt_ftse,
  sequence_col = "Price",
  position_col = "Date"
)

ggsave(
  autoplot(task_ftse),
  filename = "tests/plots/medium/task_ftse.png",
  width = 10,
  height = 8
)

# Train & Predict with PELT
learner_pelt$train(task_ftse)
pred_pelt_ftse = learner_pelt$predict(task_ftse)

cat("Predicted changepoint locations (PELT):", pred_pelt_ftse$response, "\n")

# Train & Predict with Binseg
learner_binseg$train(task_ftse)
pred_binseg_ftse = learner_binseg$predict(task_ftse)

cat(
  "Predicted changepoint locations (Binseg):",
  pred_binseg_ftse$response,
  "\n"
)

plot_pelt_ftse = autoplot(pred_pelt_ftse, task_ftse, type = "trace") +
  ggplot2::ggtitle("PELT Changepoints")
plot_binseg_ftse = autoplot(pred_binseg_ftse, task_ftse, type = "trace") +
  ggplot2::ggtitle("Binseg Changepoints")

# Plot results
ftse_plot = plot_pelt_ftse +
  plot_binseg_ftse +
  plot_layout(guides = "collect", ncol = 1, nrow = 2) +
  plot_annotation(title = "FTSE100: PELT vs Binseg")

ggsave(
  ftse_plot,
  filename = "tests/plots/medium/ftse_comparison.png",
  width = 10,
  height = 8
)