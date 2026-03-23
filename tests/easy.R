# Load packages
devtools::load_all("..")
source("load_packages.R")

# Load data
data(Lai2005fig4, package = "changepoint")
dt_lai = data.table::as.data.table(Lai2005fig4)

head(dt_lai)

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

ggsave(
  autoplot(task_lai),
  filename = "tests/plots/easy/task_lai.png",
  width = 10,
  height = 8
)

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
pred = learner_pelt$predict(task_lai)


cat("Predicted changepoint locations:", pred$response, "\n")

lai_pelt_plot = autoplot(pred, task_lai, type = "trace") +
  ggplot2::ggtitle("PELT Changepoints")

lai_pelt_segments_plot = autoplot(pred, task_lai, type = "segments") +
  ggplot2::ggtitle("PELT Segments")

# Plot results
final_plot = lai_pelt_plot / lai_pelt_segments_plot
ggsave(
  final_plot,
  filename = "tests/plots/easy/pelt_lai.png",
  width = 10,
  height = 8
)