test_that("changepoint.label_accuracy is in the dictionary", {
  measure = msr("changepoint.label_accuracy")
  expect_r6(measure, "MeasureCptLabelAccuracy")
  expect_equal(measure$range, c(0, 1))
  expect_false(measure$minimize)
  expect_subset(c("requires_task", "weights", "na_score"), measure$properties)
})

test_that("the accuracy is one minus the label error", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_weighted()
  learner = lrn("changepoint.intregrcv", Kmax = 3L)
  p = PredictionCpt$new(task, response = c(1, 1), weights = c(1, 2))
  error = p$score(msr("changepoint.label_error"), task = task, learner = learner)
  accuracy = p$score(msr("changepoint.label_accuracy"), task = task, learner = learner)
  expect_equal(unname(accuracy), 1 - unname(error))

  empty = PredictionCpt$new(task, row_ids = integer(0), truth = list(), response = numeric(0), check = FALSE)
  expect_equal(unname(empty$score(msr("changepoint.label_accuracy"), task = task, learner = learner)), NA_real_)
})
