test_that("changepoint.label_error is in the dictionary", {
  measure = msr("changepoint.label_error")
  expect_r6(measure, "MeasureCptLabelError")
  expect_equal(measure$id, "changepoint.label_error")
  expect_equal(measure$range, c(0, 1))
  expect_true(measure$minimize)
  expect_subset(
    c("requires_task", "requires_learner", "weights"),
    measure$properties
  )
})

test_that("scoring a trained learner gives a rate in the unit interval", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
  with_seed(36, learner$train(task))
  p = learner$predict(task)

  score = p$score(msr("changepoint.label_error"), task = task, learner = learner)
  expect_number(score, lower = 0, upper = 1)
})

test_that("the score is the label-weighted micro-average", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_weighted()
  learner = lrn("changepoint.intregrcv", Kmax = 3L)
  rows = task$row_ids
  response = c(1, 1)
  weights = c(1, 2)
  p = PredictionCpt$new(task, response = response, weights = weights)

  score = p$score(msr("changepoint.label_error"), task = task, learner = learner)

  me = cpt_label_errors(task, 3L, rows)
  me$log_lambda = response[match(me$problem, rows)]
  sel = me[cpt_is_selected(me, me$log_lambda), ]
  errors = sel$errors[match(rows, sel$problem)]
  n_labels = vapply(p$truth, nrow, integer(1))
  expect_equal(unname(score), sum(weights * errors) / sum(weights * n_labels))
})

test_that("empty and non-finite predictions score as NA", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy()
  learner = lrn("changepoint.intregrcv", Kmax = 3L)
  measure = msr("changepoint.label_error")

  empty = PredictionCpt$new(
    task, row_ids = integer(0), truth = list(), response = numeric(0), check = FALSE
  )
  expect_equal(unname(empty$score(measure, task = task, learner = learner)), NA_real_)

  infinite = PredictionCpt$new(task, response = c(Inf, 0))
  expect_equal(unname(infinite$score(measure, task = task, learner = learner)), NA_real_)
})

test_that("the measure scores peak tasks", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("PeakSegOptimal")
  skip_if_not_installed("PeakError")

  task = toy_peak_interval()
  learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
  with_seed(36, learner$train(task))
  p = learner$predict(task)

  score = p$score(msr("changepoint.label_error"), task = task, learner = learner)
  expect_number(score, lower = 0, upper = 1)
})
