test_that("changepoint.label_error is in the dictionary", {
  measure = msr("changepoint.label_error")
  expect_r6(measure, "MeasureCptLabelError")
  expect_equal(measure$id, "changepoint.label_error")
  expect_equal(measure$range, c(0, 1))
  expect_true(measure$minimize)
  expect_subset(c("requires_task", "weights", "na_score"), measure$properties)
  expect_disjunct("requires_learner", measure$properties)
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

test_that("scoring errors when neither the prediction nor the learner gives Kmax", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy()
  p = PredictionCpt$new(task, response = c(1, 1))
  measure = msr("changepoint.label_error")

  expect_error(p$score(measure, task = task), "Kmax")
  # A wrapped learner (e.g. a GraphLearner) exposes Kmax only under a prefixed id.
  expect_error(p$score(measure, task = task, learner = lrn("changepoint.intregrcv")), "Kmax")
})

test_that("each row is decoded under the Kmax its prediction carries", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  # Rows 1 and 3 both hold two changes, each labelled by a 1change region. At
  # log(lambda) = -100 a row selects its most complex model: one change under
  # Kmax = 1 (one of two labels wrong), both changes under Kmax = 2 (none wrong).
  task = toy_interval()
  ids = task$row_ids[c(1L, 3L)]
  p1 = PredictionCpt$new(task, row_ids = ids[1L], response = -100, extra = list(Kmax = 1L))
  p3 = PredictionCpt$new(task, row_ids = ids[2L], response = -100, extra = list(Kmax = 2L))
  p = as_prediction(c(p1$data, p3$data))
  expect_equal(p$data$extra$Kmax, c(1L, 2L))

  # The recorded caps win over the learner's; one cap of 1 or 2 for both rows
  # would give 2/4 or 0/4.
  learner = lrn("changepoint.intregrcv", Kmax = 3L)
  score = p$score(msr("changepoint.label_error"), task = task, learner = learner)
  expect_equal(unname(score), 1 / 4)
})

test_that("a prediction without Kmax falls back to the learner's trained cap", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  ids = task$row_ids[c(1L, 3L)]
  measure = msr("changepoint.label_error")
  recorded = PredictionCpt$new(task, row_ids = ids, response = c(-100, -100), extra = list(Kmax = c(1L, 1L)))
  bare = PredictionCpt$new(task, row_ids = ids, response = c(-100, -100))

  learner = lrn("changepoint.intregrcv", Kmax = 1L)
  expected = recorded$score(measure, task = task)
  expect_equal(bare$score(measure, task = task, learner = learner), expected)

  # A trained learner's model cap wins over a parameter changed after training.
  learner$model = list(Kmax = 1L)
  learner$param_set$values$Kmax = 3L
  expect_equal(bare$score(measure, task = task, learner = learner), expected)
})
