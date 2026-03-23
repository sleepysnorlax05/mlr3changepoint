# Load packages
devtools::load_all(".")
source("tests/load_packages.R")

# Load data
data(neuroblastomaProcessed, package = "penaltyLearning")

feat_mat = neuroblastomaProcessed$feature.mat

target_mat = neuroblastomaProcessed$target.mat

err = data.table::as.data.table(neuroblastomaProcessed$error)
err$profile.id = as.character(err$profile.id)
err$chromosome = as.character(err$chromosome)

dt_neuro = data.table::as.data.table(cbind(feat_mat, target_mat))

# Initiate Task:
# Data: neuroblastomaProcessed

task_neuro = TaskInterval$new(
  id = "neuroblastoma",
  backend = dt_neuro,
  target = c("min.L", "max.L")
)

ggsave(
  autoplot(task_neuro),
  filename = "tests/plots/hard/task_neuro.png",
  width = 10,
  height = 8
)

# Initiate Learner
learner_intregcv = LearnerIntRegrCV$new()

# 5-Fold CV
set.seed(36)
cv = rsmp("cv", folds = 5)
rr = resample(task_neuro, learner_intregcv, cv)

runtime = rr$score(msr("time_train"))[, c("iteration", "time_train")]
print(runtime)

total_runtime = sum(runtime$time_train)
cat("Total Training Time:", total_runtime, "seconds\n")

preds_intregcv = rr$prediction()

# Extract the rownames
rn = rownames(neuroblastomaProcessed$feature.mat)[preds_intregcv$row_ids]

# The rownames are formatted like "1.1" -> "profile_id.chromosome_id"
# We can use tstrsplit to split them into the two separate columns
split_ids = data.table::tstrsplit(rn, "\\.", type.convert = as.character)

pred_df = data.table::data.table(
  profile.id = split_ids[[1]],
  chromosome = split_ids[[2]],
  pred.log.lambda = preds_intregcv$response
)

# Compute ROC
roc = penaltyLearning::ROChange(err, pred_df, c("profile.id", "chromosome"))

# Constant Baseline
pred_constant = data.table::data.table(
  profile.id = split_ids[[1]],
  chromosome = split_ids[[2]],
  pred.log.lambda = 0
)

roc_constant = penaltyLearning::ROChange(
  err,
  pred_constant,
  c("profile.id", "chromosome")
)

# BIC Baseline: log.lambda = log(n) where n is the number of observations in the training set
pred_bic = data.table::data.table(
  profile.id = split_ids[[1]],
  chromosome = split_ids[[2]],
  pred.log.lambda = dt_neuro$log.n[preds_intregcv$row_ids]
)

roc_bic = penaltyLearning::ROChange(
  err,
  pred_bic,
  c("profile.id", "chromosome")
)

roc_cv = roc$roc
roc_cv$Model = sprintf("IntervalRegressionCV (AUC: %.3f)", roc$auc)

roc_const_data = roc_constant$roc
roc_const_data$Model = sprintf("Constant (AUC: %.3f)", roc_constant$auc)

roc_bic_data = roc_bic$roc
roc_bic_data$Model = sprintf("BIC (AUC: %.3f)", roc_bic$auc)

roc_combined = rbind(roc_cv, roc_const_data, roc_bic_data)

roc_combined = rbind(roc_cv, roc_const_data, roc_bic_data)

# Plot ROC
roc_plot = ggplot2::ggplot(
  roc_combined,
  ggplot2::aes(x = FPR, y = TPR, color = Model)
) +
  ggplot2::geom_path(linewidth = 0.8) +
  ggplot2::geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    color = "darkgray"
  ) +
  ggplot2::theme_minimal() +
  ggplot2::coord_equal() +
  ggplot2::labs(
    title = "ROC Curve",
    x = "False Positive Rate (FPR)",
    y = "True Positive Rate (TPR)"
  ) +
  ggplot2::theme(
    legend.title = ggplot2::element_blank(),
    legend.position = "bottom",
  )

ggsave(
  roc_plot,
  filename = "tests/plots/hard/roc_plot.png",
  width = 10,
  height = 8
)
