test_that("changepoint.mmif is in the dictionary", {
  skip_if_not_installed("mmit")
  skip_if_not_installed("future.apply")

  learner = lrn("changepoint.mmif")
  expect_learner(learner)
  expect_r6(learner, "LearnerCptMMIF")
  expect_equal(learner$id, "changepoint.mmif")
  learner$param_set$set_values(max_depth = Inf)
  expect_identical(learner$param_set$values$max_depth, Inf)
})

test_that("train and predict round trip on the log(lambda) scale", {
  skip_if_not_installed("mmit")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_conflict()
  learner = lrn("changepoint.mmif", Kmax = 3L, n_trees = 3L)
  with_seed(36, learner$train(task))
  expect_setequal(
    names(learner$model),
    c("fit", "feature_names", "Kmax", "label_type")
  )
  expect_s3_class(learner$model$fit, "mmif")
  expect_length(learner$model$fit, 3L)

  p = learner$predict(task)
  expect_prediction(p)
  expect_s3_class(p, "PredictionCpt")
  expect_numeric(p$response, len = task$nrow, any.missing = FALSE)
  # The fixture's intervals conflict, so a constant penalty cannot fit and the model must split.
  expect_gt(length(unique(p$response)), 1L)
})

test_that("predict works on unseen rows via the stored feature columns", {
  skip_if_not_installed("mmit")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_conflict()
  learner = lrn("changepoint.mmif", Kmax = 3L, n_trees = 3L)
  with_seed(36, learner$train(task$clone()$filter(1:8)))

  p = learner$predict(task$clone()$filter(9:10))
  expect_numeric(p$response, len = 2L, any.missing = FALSE)
  # Row 9 carries a small change and row 10 is flat noise, so row 9 needs the smaller penalty.
  expect_lt(p$response[1L], p$response[2L])
})

test_that("a single flat sequence with non-finite features still predicts", {
  skip_if_not_installed("mmit")
  skip_if_not_installed("future.apply")
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
  learner = lrn("changepoint.mmif", Kmax = 3L, n_trees = 3L)
  with_seed(36, learner$train(toy_interval()))

  # Log features of a constant sequence are -Inf/NaN in some trained columns.
  x = cpt_feature_matrix(cpt_extract_data(flat), cols = learner$model$feature_names)
  expect_true(any(!is.finite(x)))

  p = learner$predict(flat)
  expect_numeric(p$response, len = 1L, finite = TRUE)
})

test_that("the learner handles peak tasks", {
  skip_if_not_installed("mmit")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("PeakSegOptimal")
  skip_if_not_installed("PeakError")

  task = toy_peak_interval()
  learner = lrn("changepoint.mmif", Kmax = 3L, n_trees = 3L)
  with_seed(36, learner$train(task))
  expect_equal(learner$model$label_type, "peak")

  p = learner$predict(task)
  expect_numeric(p$response, len = task$nrow, any.missing = FALSE)
})

test_that("predict rejects a task with a different label_type", {
  skip_if_not_installed("mmit")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  learner = lrn("changepoint.mmif", Kmax = 3L, n_trees = 3L)
  with_seed(36, learner$train(toy_interval()))
  expect_error(learner$predict(toy_peak_interval()), "label_type")
})

test_that("training errors when no label gives a finite penalty limit", {
  skip_if_not_installed("mmit")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  # A 1change label past the end of every sequence is violated equally by every model.
  task = toy_interval()
  label = rep(list(data.table::data.table(start = 1000, end = 1001, label = "1change")), task$nrow)
  open = TaskCpt$new(
    id = "open",
    backend = data.table::data.table(signal = cpt_extract_data(task)$sequence, label = label),
    target = "label",
    sequence = "signal",
    label_type = "changepoint"
  )
  learner = lrn("changepoint.mmif", Kmax = 3L)
  expect_error(learner$train(open), "no finite penalty limit")
})

test_that("training does not need both finite target limits", {
  skip_if_not_installed("mmit")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()$filter(c(2L, 4L, 6L, 8L, 10L))
  target_mat = cpt_target_intervals(task, 3L)
  expect_false(any(is.finite(target_mat[, "max.log.lambda"])))

  learner = lrn("changepoint.mmif", Kmax = 3L, n_trees = 3L)
  with_seed(36, learner$train(task))
  p = learner$predict(task)
  expect_numeric(p$response, len = 5L, any.missing = FALSE)
})

test_that("the label-error measure scores the learner", {
  skip_if_not_installed("mmit")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.mmif", Kmax = 3L, n_trees = 3L)
  with_seed(36, learner$train(task))
  p = learner$predict(task)

  score = p$score(msr("changepoint.label_error"), task = task, learner = learner)
  expect_number(score, lower = 0, upper = 1)
})

test_that("training is reproducible under a fixed seed", {
  skip_if_not_installed("mmit")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_conflict()
  learner = lrn("changepoint.mmif", Kmax = 3L)
  p1 = with_seed(36, learner$train(task)$predict(task))
  p2 = with_seed(36, learner$train(task)$predict(task))
  expect_equal(p1$response, p2$response)
  # A different seed grows different trees, so the match above is not vacuous.
  p3 = with_seed(1, learner$train(task)$predict(task))
  expect_false(isTRUE(all.equal(p1$response, p3$response)))
})

test_that("n_features above the usable feature count errors clearly", {
  skip_if_not_installed("mmit")
  skip_if_not_installed("future.apply")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  learner = lrn("changepoint.mmif", Kmax = 3L, n_features = 10000L)
  expect_error(learner$train(toy_conflict()), "n_features")
})
