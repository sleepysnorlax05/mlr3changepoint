test_that("changepoint.xgboost.aft is in the dictionary", {
  learner = lrn("changepoint.xgboost.aft")
  expect_learner(learner)
  expect_r6(learner, "LearnerCptXGBoostAFT")
  expect_equal(learner$id, "changepoint.xgboost.aft")
})

test_that("train and predict round trip on the log(lambda) scale", {
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.xgboost.aft", Kmax = 3L)
  learner$train(task)
  expect_setequal(
    names(learner$model),
    c("fit", "feature_names", "Kmax", "label_type")
  )
  expect_s3_class(learner$model$fit, "xgb.Booster")

  p = learner$predict(task)
  expect_prediction(p)
  expect_s3_class(p, "PredictionCpt")
  expect_numeric(p$response, len = task$nrow, any.missing = FALSE)

  x = cpt_feature_matrix(cpt_extract_data(task), cols = learner$model$feature_names)
  expect_equal(p$response, log(as.numeric(predict(learner$model$fit, x))), tolerance = 1e-6)
})

test_that("predict works on unseen rows via the stored feature columns", {
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.xgboost.aft", Kmax = 3L)
  learner$train(task$clone()$filter(1:8))

  p = learner$predict(task$clone()$filter(9:10))
  expect_numeric(p$response, len = 2L, any.missing = FALSE)
})

test_that("a single flat sequence with non-finite features still predicts", {
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  flat = TaskCpt$new(
    id = "flat",
    backend = data.table::data.table(
      signal = list(rep(5, 100)),
      label = list(data.table::data.table(start = 1, end = 100, label = "0changes"))
    ),
    target = "label",
    sequence = "signal",
    label_type = "changepoint"
  )
  learner = lrn("changepoint.xgboost.aft", Kmax = 3L)
  learner$train(toy_interval())

  # Log features of a constant sequence are -Inf/NaN in some trained columns.
  x = cpt_feature_matrix(cpt_extract_data(flat), cols = learner$model$feature_names)
  expect_true(any(!is.finite(x)))

  p = learner$predict(flat)
  expect_numeric(p$response, len = 1L, finite = TRUE)
})

test_that("resampling combines fold predictions", {
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.xgboost.aft", Kmax = 3L)
  rr = with_seed(36, resample(task, learner, rsmp("holdout")))
  expect_prediction(rr$prediction())
})

test_that("the learner handles peak tasks", {
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("PeakSegOptimal")
  skip_if_not_installed("PeakError")

  task = toy_peak_interval()
  learner = lrn("changepoint.xgboost.aft", Kmax = 3L)
  learner$train(task)
  expect_equal(learner$model$label_type, "peak")

  p = learner$predict(task)
  expect_numeric(p$response, len = task$nrow, any.missing = FALSE)
})

test_that("predict rejects a task with a different label_type", {
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  learner = lrn("changepoint.xgboost.aft", Kmax = 3L)
  learner$train(toy_interval())
  expect_error(learner$predict(toy_peak_interval()), "label_type")
})

test_that("training does not need both finite target limits", {
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()$filter(c(2L, 4L, 6L, 8L, 10L))
  target_mat = cpt_target_intervals(task, 3L)
  expect_false(any(is.finite(target_mat[, "max.log.lambda"])))

  learner = lrn("changepoint.xgboost.aft", Kmax = 3L)
  learner$train(task)
  p = learner$predict(task)
  expect_numeric(p$response, len = 5L, any.missing = FALSE)
})

test_that("the label-error measure scores the learner", {
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.xgboost.aft", Kmax = 3L)
  learner$train(task)
  p = learner$predict(task)

  score = p$score(msr("changepoint.label_error"), task = task, learner = learner)
  expect_number(score, lower = 0, upper = 1)
})
