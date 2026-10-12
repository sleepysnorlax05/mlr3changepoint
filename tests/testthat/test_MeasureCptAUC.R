test_that("changepoint.auc is in the dictionary", {
  measure = msr("changepoint.auc")
  expect_r6(measure, "MeasureCptAUC")
  expect_equal(measure$range, c(-Inf, Inf))
  expect_false(measure$minimize)
  expect_subset(c("requires_task", "na_score"), measure$properties)
  expect_disjunct("weights", measure$properties)
})

test_that("the AUC is ROChange() on the prediction's label errors", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
  with_seed(36, learner$train(task))
  p = learner$predict(task)

  score = p$score(msr("changepoint.auc"), task = task)
  me = cpt_label_errors(task, 3L, p$row_ids)
  pred = data.table::data.table(problem = p$row_ids, pred.log.lambda = p$response)
  expect_equal(unname(score), penaltyLearning::ROChange(me, pred, problem.vars = "problem")$auc)
})

test_that("the AUC scores peak tasks", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("PeakSegOptimal")
  skip_if_not_installed("PeakError")

  task = toy_peak_interval()
  learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
  with_seed(36, learner$train(task))
  p = learner$predict(task)
  expect_number(unname(p$score(msr("changepoint.auc"), task = task)), finite = TRUE)
})

test_that("the AUC is NA where the curve is undefined", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy()
  measure = msr("changepoint.auc")
  empty = PredictionCpt$new(task, row_ids = integer(0), truth = list(), response = numeric(0), check = FALSE)
  expect_equal(unname(empty$score(measure, task = task)), NA_real_)
  infinite = PredictionCpt$new(task, response = c(Inf, 0))
  expect_equal(unname(infinite$score(measure, task = task)), NA_real_)
  # Row 2 holds a single 0changes label: no region can hold a false negative.
  negative_only = PredictionCpt$new(task, row_ids = 2L, response = 0, extra = list(Kmax = 3L))
  expect_equal(unname(negative_only$score(measure, task = task)), NA_real_)
})

test_that("errors constant in the penalty give a single ROC point", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  # Four points are too few for SegNeigh, so the null model is the only one: one
  # ROC point at (0, 0), which the curve closes to the diagonal.
  task = TaskCpt$new(
    id = "short",
    backend = data.table::data.table(
      signal = list(c(0, 0, 10, 10)),
      label = list(data.table::data.table(start = 1, end = 3, label = "1change"))
    ),
    target = "label", sequence = "signal", label_type = "changepoint"
  )
  p = PredictionCpt$new(task, response = 0, extra = list(Kmax = 1L))
  expect_equal(unname(p$score(msr("changepoint.auc"), task = task)), 0.5)
})

test_that("scoring errors without any Kmax", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy()
  p = PredictionCpt$new(task, response = c(1, 1))
  expect_error(p$score(msr("changepoint.auc"), task = task), "positive integer Kmax per sequence")
})

test_that("sequences without labels are left out of the AUC", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_unlabelled()
  measure = msr("changepoint.auc")
  p = PredictionCpt$new(task, response = c(0, 0, 0), extra = list(Kmax = rep(2L, 3L)))
  labelled = PredictionCpt$new(task, row_ids = 1:2, response = c(0, 0), extra = list(Kmax = c(2L, 2L)))
  expect_equal(p$score(measure, task = task), labelled$score(measure, task = task))

  only = PredictionCpt$new(task, row_ids = 3L, response = 0, extra = list(Kmax = 2L))
  expect_equal(unname(only$score(measure, task = task)), NA_real_)
})
