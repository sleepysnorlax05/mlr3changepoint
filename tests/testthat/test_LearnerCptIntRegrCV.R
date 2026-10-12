test_that("changepoint.intregrcv is in the dictionary", {
  learner = lrn("changepoint.intregrcv")
  expect_learner(learner)
  expect_r6(learner, "LearnerCptIntRegrCV")
  expect_equal(learner$id, "changepoint.intregrcv")
})

test_that("train and predict round trip", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
  # Training is seed-independent: the learner builds deterministic stratified CV
  # folds, so every fold carries both a lower and an upper target limit.
  learner$train(task)
  expect_setequal(
    names(learner$model),
    c("fit", "feature_names", "Kmax", "label_type")
  )

  p = learner$predict(task)
  expect_prediction(p)
  expect_s3_class(p, "PredictionCpt")
  expect_numeric(p$response, len = task$nrow, any.missing = FALSE)
})

test_that("predict works on unseen rows via the stored feature columns", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
  learner$train(task$clone()$filter(1:8))

  p = learner$predict(task$clone()$filter(9:10))
  expect_numeric(p$response, len = 2L, any.missing = FALSE)
})

test_that("resampling combines fold predictions", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
  rr = with_seed(36, resample(task, learner, rsmp("holdout")))
  expect_prediction(rr$prediction())
})

test_that("the learner handles peak tasks", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("PeakSegOptimal")
  skip_if_not_installed("PeakError")

  task = toy_peak_interval()
  learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
  learner$train(task)
  expect_equal(learner$model$label_type, "peak")

  p = learner$predict(task)
  expect_numeric(p$response, len = task$nrow, any.missing = FALSE)
})

test_that("predict rejects a task with a different label_type", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
  learner$train(toy_interval())
  expect_error(learner$predict(toy_peak_interval()), "label_type")
})

test_that("training is stable across seeds", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
  # Deterministic stratified folds: the predicted penalties must not depend on the seed.
  r1 = with_seed(1L, learner$train(task)$predict(task)$response)
  r2 = with_seed(999L, learner$train(task)$predict(task)$response)
  expect_equal(r1, r2)
})

test_that("sequences with an open target are left out of the fit", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  # An 11th sequence whose 1change label lies past its end: every model gets it
  # wrong, so its target is (-Inf, Inf), which IntervalRegressionCV() rejects.
  base = toy_interval()
  parts = cpt_extract_data(base)
  # Its signal looks like the training ones so that its features stay finite.
  extra_signal = with_seed(1, c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9))) # nolint: object_usage_linter.
  signal = c(parts$sequence, list(extra_signal))
  label = c(parts$target, list(data.table::data.table(start = 1000, end = 1001, label = "1change")))
  task = TaskCpt$new(
    id = "open_row",
    backend = data.table::data.table(signal = signal, label = label),
    target = "label",
    sequence = "signal",
    label_type = "changepoint"
  )
  expect_equal(unname(cpt_target_intervals(task, 3L)[11L, ]), c(-Inf, Inf))

  learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
  learner$train(task)
  expect_numeric(learner$predict(task)$response, len = 11L, any.missing = FALSE)
})
