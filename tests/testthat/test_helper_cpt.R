test_that("extracted parts are named and aligned to row_ids", {
  task = toy()
  parts = cpt_extract_data(task)
  expect_named(parts, c("ids", "sequence", "target"))
  expect_equal(parts$ids, task$row_ids)
  expect_list(parts$sequence, len = 2L)
  expect_list(parts$target, len = 2L)
})

test_that("extraction follows task filtering", {
  task = toy()
  task$filter(2L)
  parts = cpt_extract_data(task)
  expect_equal(parts$ids, task$row_ids)
  expect_list(parts$sequence, len = 1L)
})

test_that("feature matrix has one row per sequence", {
  skip_if_not_installed("penaltyLearning")

  parts = cpt_extract_data(toy())
  feats = cpt_feature_matrix(parts)
  expect_matrix(feats, mode = "numeric", nrows = 2L)
  expect_equal(rownames(feats), as.character(parts$ids))
  expect_true(all(is.finite(feats)))
})

test_that("predict-time cols subset the training columns", {
  skip_if_not_installed("penaltyLearning")

  parts = cpt_extract_data(toy())
  train = cpt_feature_matrix(parts)
  keep = colnames(train)[1:3]
  pred = cpt_feature_matrix(parts, cols = keep)
  expect_equal(colnames(pred), keep)
  expect_equal(pred, train[, keep, drop = FALSE])
})

test_that("all-constant sequences error instead of returning no features", {
  skip_if_not_installed("penaltyLearning")

  parts = list(ids = 1:2, sequence = list(rep(0, 5), rep(0, 5)))
  expect_error(cpt_feature_matrix(parts), "no usable features")
})

test_that("cpt_segment_path errors on unknown label_type", {
  expect_error(cpt_segment_path(rnorm(10), 2L, "banana"), "unknown label_type")
})

test_that("missing values error before reaching a solver", {
  expect_error(cpt_segment_path(c(1, NA, 3), 2L, "changepoint"), "missing values")
})

test_that("changepoint path contains the null model and nested changes", {
  skip_if_not_installed("changepoint")

  x = cpt_extract_data(toy())$sequence[[1L]]
  path = cpt_segment_path(x, 3L, "changepoint")

  expect_named(path, c("models", "predicted"))
  expect_named(path$models, c("complexity", "loss"))
  expect_named(path$predicted, c("complexity", "change"))

  # The null (1-segment) model is always present, with the total sum of squares.
  expect_true(1L %in% path$models$complexity)
  expect_equal(
    path$models$loss[path$models$complexity == 1L],
    sum((x - mean(x))^2)
  )

  # More segments never fit worse, and a k-segment model has k - 1 changes.
  expect_true(all(diff(path$models$loss) <= 0))
  changes_per_model = table(path$predicted$complexity)
  expect_equal(
    as.integer(changes_per_model),
    as.integer(names(changes_per_model)) - 1L
  )
})

test_that("a too-short sequence yields the null-model-only path", {
  x = rnorm(2)
  path = cpt_segment_path(x, 3L, "changepoint")
  expect_equal(path$models$complexity, 1L)
  expect_equal(nrow(path$predicted), 0L)
})

test_that("peak path counts peaks per model", {
  skip_if_not_installed("PeakSegOptimal")

  counts = cpt_extract_data(toy_peak())$sequence[[1L]]
  path = cpt_segment_path(counts, 3L, "peak")

  expect_named(path$models, c("complexity", "loss"))
  expect_named(path$predicted, c("complexity", "chromStart", "chromEnd"))

  # The 0-peak model is always present; a k-peak model has k peak rows.
  expect_true(0L %in% path$models$complexity)
  peaks_per_model = table(path$predicted$complexity)
  expect_equal(
    as.integer(peaks_per_model),
    as.integer(names(peaks_per_model))
  )
})

test_that("peak path rejects non-count input", {
  expect_error(cpt_segment_path(c(1.5, 2, 3), 2L, "peak"), "integer counts")
  expect_error(cpt_segment_path(c(-1, 2, 3), 2L, "peak"), "non-negative counts")
})

test_that("cpt_model_errors errors on unknown label_type", {
  dt = data.table::data.table()
  expect_error(cpt_model_errors(dt, dt, dt, "banana"), "unknown label_type")
})

test_that("changepoint targets align to the task and bracket the labels", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy()
  target = cpt_target_intervals(task, 3L)

  expect_matrix(target, mode = "numeric", nrows = 2L, ncols = 2L)
  expect_equal(colnames(target), c("min.log.lambda", "max.log.lambda"))
  expect_equal(rownames(target), as.character(task$row_ids))
  expect_true(all(target[, 1L] < target[, 2L]))

  # Sequence 1 has a labeled real change: penalties large enough to drop it
  # must be excluded, so the upper end is finite.
  expect_true(is.finite(target[1L, "max.log.lambda"]))
  # Sequence 2 is all 0changes: arbitrarily large penalties stay perfect.
  expect_equal(target[2L, "max.log.lambda"], Inf)
})

test_that("peak targets align to the task and bracket the labels", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("PeakSegOptimal")
  skip_if_not_installed("PeakError")

  task = toy_peak()
  target = cpt_target_intervals(task, 3L)

  expect_matrix(target, mode = "numeric", nrows = 2L, ncols = 2L)
  expect_equal(colnames(target), c("min.log.lambda", "max.log.lambda"))
  expect_equal(rownames(target), as.character(task$row_ids))
  expect_true(all(target[, 1L] < target[, 2L]))

  # Sequence 1 has a labeled real peak: dropping it must be excluded.
  expect_true(is.finite(target[1L, "max.log.lambda"]))
  # Sequence 2 is noPeaks: arbitrarily large penalties stay perfect.
  expect_equal(target[2L, "max.log.lambda"], Inf)
})

test_that("sequences too short for any change still get targets", {
  skip_if_not_installed("penaltyLearning")

  backend = data.table::data.table(
    signal = list(rnorm(2), rnorm(2)),
    label = list(
      data.table::data.table(start = 1, end = 2, label = "0changes"),
      data.table::data.table(start = 1, end = 2, label = "0changes")
    )
  )
  task = TaskCpt$new(
    id = "degenerate",
    backend = backend,
    target = "label",
    sequence = "signal",
    label_type = "changepoint"
  )

  # Every path is null-model-only, so no penalty makes an error anywhere.
  target = cpt_target_intervals(task, 3L)
  expect_equal(unname(target[, "min.log.lambda"]), c(-Inf, -Inf))
  expect_equal(unname(target[, "max.log.lambda"]), c(Inf, Inf))
})

test_that("a huge penalty selects the null model", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  x = cpt_extract_data(toy())$sequence[[1L]]
  res = cpt_segment(x, log_lambda = 100, Kmax = 3L, label_type = "changepoint")
  expect_equal(res$complexity, 1L)
  expect_equal(nrow(res$predicted), 0L)
})

test_that("a tiny penalty selects the most complex model in the path", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  x = cpt_extract_data(toy())$sequence[[1L]]
  path = cpt_segment_path(x, 3L, "changepoint")
  res = cpt_segment(x, log_lambda = -100, Kmax = 3L, label_type = "changepoint")
  # Relies on the path losses strictly decreasing (always true for continuous
  # data), so modelSelection() keeps the most complex model.
  expect_equal(res$complexity, max(path$models$complexity))
  expect_equal(nrow(res$predicted), res$complexity - 1L)
})

test_that("a penalty on an interval boundary matches exactly one model", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  x = cpt_extract_data(toy())$sequence[[1L]]
  path = cpt_segment_path(x, 3L, "changepoint")
  ms = penaltyLearning::modelSelection(
    as.data.frame(path$models),
    complexity = "complexity"
  )
  boundary = max(ms$min.log.lambda[is.finite(ms$min.log.lambda)])

  res = cpt_segment(x, log_lambda = boundary, Kmax = 3L, label_type = "changepoint")
  expect_length(res$complexity, 1L)
})

test_that("peak segmentation returns peak geometry at a small penalty", {
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("PeakSegOptimal")

  counts = cpt_extract_data(toy_peak())$sequence[[1L]]
  res = cpt_segment(counts, log_lambda = -100, Kmax = 3L, label_type = "peak")
  expect_gt(res$complexity, 0L)
  expect_equal(nrow(res$predicted), res$complexity)
  expect_named(res$predicted, c("complexity", "chromStart", "chromEnd"))

  res0 = cpt_segment(counts, log_lambda = 100, Kmax = 3L, label_type = "peak")
  expect_equal(res0$complexity, 0L)
  expect_equal(nrow(res0$predicted), 0L)
})
