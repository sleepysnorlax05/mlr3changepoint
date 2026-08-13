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
  # IntervalRegressionCV samples its internal folds; the seed keeps every fold
  # holding both a lower and an upper target limit, which the solver requires.
  with_seed(36, learner$train(task))
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
  with_seed(36, learner$train(task$clone()$filter(1:8)))

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
