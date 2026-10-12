test_that("changepoint.featureless is in the dictionary", {
  learner = lrn("changepoint.featureless")
  expect_learner(learner)
  expect_r6(learner, "LearnerCptFeatureless")
  expect_equal(learner$id, "changepoint.featureless")
})

test_that("train and predict give one constant penalty with minimal training error", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_conflict()
  learner = lrn("changepoint.featureless", Kmax = 3L)
  learner$train(task)
  expect_setequal(names(learner$model), c("log_lambda", "errors", "Kmax", "label_type"))
  expect_number(learner$model$log_lambda, finite = TRUE)

  p = learner$predict(task)
  expect_prediction(p)
  expect_s3_class(p, "PredictionCpt")
  expect_equal(p$response, rep(learner$model$log_lambda, task$nrow))
  expect_equal(as.data.table(p)$Kmax, rep(3L, task$nrow))

  # No constant penalty, tried on a fine grid, beats the learned one.
  me = cpt_label_errors(task, 3L)
  total = function(x) sum(me$errors[cpt_is_selected(me, x)])
  expect_equal(total(learner$model$log_lambda), learner$model$errors)
  grid = seq(-10, 20, by = 0.01)
  expect_lte(learner$model$errors, min(vapply(grid, total, numeric(1L))))
})

test_that("the penalty lands inside every target interval when they overlap", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.featureless", Kmax = 3L)
  learner$train(task)
  expect_equal(learner$model$errors, 0)

  target_mat = cpt_target_intervals(task, 3L)
  ll = learner$model$log_lambda
  expect_true(all(target_mat[, "min.log.lambda"] < ll & ll < target_mat[, "max.log.lambda"]))

  score = learner$predict(task)$score(msr("changepoint.label_error"), task = task, learner = learner)
  expect_equal(unname(score), 0)
})

test_that("ties pick the middle step and unbounded steps stay finite", {
  me = data.table::data.table(
    problem = c(1L, 1L, 1L),
    min.log.lambda = c(-Inf, 0, 2),
    max.log.lambda = c(0, 2, Inf),
    errors = c(0, 1, 0)
  )
  # Steps (-Inf, 0), [0, 2), [2, Inf) score 0, 1, 0: the middle tie is the first.
  best = cpt_constant_penalty(me)
  expect_equal(best$errors, 0)
  expect_equal(best$log_lambda, -1)

  me$errors = c(1, 0, 1)
  expect_equal(cpt_constant_penalty(me), list(log_lambda = 1, errors = 0))

  flat = data.table::data.table(problem = 1L, min.log.lambda = -Inf, max.log.lambda = Inf, errors = 1)
  expect_equal(cpt_constant_penalty(flat), list(log_lambda = 0, errors = 1))
})

test_that("unlabelled sequences are ignored at train and still predicted", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  learner = lrn("changepoint.featureless", Kmax = 3L)
  learner$train(toy_unlabelled())
  ref = lrn("changepoint.featureless", Kmax = 3L)
  ref$train(toy())
  expect_equal(learner$model$log_lambda, ref$model$log_lambda)

  p = learner$predict(toy_unlabelled())
  expect_numeric(p$response, len = 3L, any.missing = FALSE)
})

test_that("the learner handles peak tasks", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("PeakSegOptimal")
  skip_if_not_installed("PeakError")

  task = toy_peak_interval()
  learner = lrn("changepoint.featureless", Kmax = 3L)
  learner$train(task)
  expect_equal(learner$model$label_type, "peak")

  p = learner$predict(task)
  expect_numeric(p$response, len = task$nrow, any.missing = FALSE)
  expect_error(learner$predict(toy_interval()), "label_type")
})

test_that("resampling scores the learner", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  rr = resample(toy_interval(), lrn("changepoint.featureless", Kmax = 3L), rsmp("cv", folds = 2L))
  expect_number(rr$aggregate(msr("changepoint.label_error")), lower = 0, upper = 1)
})
