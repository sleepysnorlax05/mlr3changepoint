test_that("autoplot.TaskCpt shades changepoint labels with penaltyLearning colours", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("penaltyLearning")

  p = ggplot2::autoplot(toy())
  rects = ggplot2::layer_data(p, 1L)
  # (start, end] regions span [start + 1, end + 1]: (90, 110], (190, 210], (1, 100].
  expect_setequal(rects$xmin, c(91, 191, 2))
  expect_setequal(rects$xmax, c(111, 211, 101))
  expect_setequal(rects$fill, unname(penaltyLearning::change.colors[c("1change", "0changes")]))
  expect_equal(nrow(ggplot2::layer_data(p, 2L)), 400L) # 300 + 100 signal points
})

test_that("autoplot.TaskCpt shades peak labels with the PeakError colours", {
  skip_if_not_installed("ggplot2")

  p = ggplot2::autoplot(toy_peak())
  rects = ggplot2::layer_data(p, 1L)
  # Peak regions cover whole positions start..end.
  expect_setequal(rects$xmin, c(0.5, 54.5, 9.5))
  expect_setequal(rects$fill, unname(cpt_peak_colors[c("noPeaks", "peaks")]))
  expect_equal(nrow(ggplot2::layer_data(p, 2L)), 400L)
})

test_that("autoplot.PredictionCpt marks the changes decoded at each penalty", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy()
  # Tiny penalty: the full 2-change model; huge penalty: no change.
  p = PredictionCpt$new(task, response = c(-100, 100))
  marks = ggplot2::layer_data(ggplot2::autoplot(p, task = task, Kmax = 2L), 3L)
  expect_equal(nrow(marks), 2L)
  expect_equal(marks$xintercept %% 1, c(0.5, 0.5)) # drawn between two positions

  none = PredictionCpt$new(task, response = c(100, 100))
  expect_equal(nrow(ggplot2::layer_data(ggplot2::autoplot(none, task = task, Kmax = 2L), 3L)), 0L)
})

test_that("a change is drawn inside a region exactly when the measure counts it there", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  # A noiseless step puts the only change at X = 50. Row 1's region (50, 60] starts
  # at X, which labelError() does not count; row 2's region (40, 50] ends at X,
  # which it does.
  step = c(rep(0, 50), rep(10, 50))
  task = TaskCpt$new(
    id = "edges",
    backend = data.table::data.table(
      signal = list(step, step),
      label = list(
        data.table::data.table(start = 50, end = 60, label = "1change"),
        data.table::data.table(start = 40, end = 50, label = "1change")
      )
    ),
    target = "label",
    sequence = "signal",
    label_type = "changepoint"
  )
  p = PredictionCpt$new(task, response = c(-100, -100), extra = list(Kmax = c(1L, 1L)))
  expect_equal(unname(p$score(msr("changepoint.label_error"), task = task)), 1 / 2)

  g = ggplot2::autoplot(p, task = task)
  rects = ggplot2::layer_data(g, 1L)
  marks = ggplot2::layer_data(g, 3L)
  expect_equal(marks$xintercept, c(50.5, 50.5))
  inside = rects$xmin < marks$xintercept & marks$xintercept < rects$xmax
  expect_equal(inside, c(FALSE, TRUE))
})

test_that("autoplot.PredictionCpt uses the Kmax a prediction records", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy()
  # At a tiny penalty a row draws its most complex model: as many changes as its cap.
  recorded = PredictionCpt$new(task, response = c(-100, 100), extra = list(Kmax = c(1L, 1L)))
  marks = ggplot2::layer_data(ggplot2::autoplot(recorded, task = task), 3L)
  expect_equal(nrow(marks), 1L)
  # The recorded cap wins over an explicit one.
  expect_equal(nrow(ggplot2::layer_data(ggplot2::autoplot(recorded, task = task, Kmax = 3L), 3L)), 1L)

  bare = PredictionCpt$new(task, response = c(-100, 100))
  expect_equal(nrow(ggplot2::layer_data(ggplot2::autoplot(bare, task = task, Kmax = 3L), 3L)), 3L)
})

test_that("autoplot.PredictionCpt draws decoded peaks as segments at their mean", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("PeakSegOptimal")

  task = toy_peak()
  p = PredictionCpt$new(task, response = c(-100, 100))
  marks = ggplot2::layer_data(ggplot2::autoplot(p, task = task, Kmax = 1L), 3L)
  expect_equal(nrow(marks), 1L)
  s = cpt_extract_data(task)$sequence[[1L]]
  # The segment runs between the centres of the peak's first and last positions.
  expect_equal(marks$y, mean(s[marks$x:marks$xend]))
})

test_that("autoplot.PredictionCpt validates its inputs", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy()
  p = PredictionCpt$new(task, response = c(1, 1))

  expect_error(ggplot2::autoplot(p, task = tsk("iris"), Kmax = 2L), "TaskCpt")
  expect_error(ggplot2::autoplot(p, task = task), "Kmax")

  empty = PredictionCpt$new(task, row_ids = integer(0), truth = list(), response = numeric(0), check = FALSE)
  expect_error(ggplot2::autoplot(empty, task = task, Kmax = 2L), "nothing to plot")

  infinite = PredictionCpt$new(task, response = c(Inf, 0))
  expect_error(ggplot2::autoplot(infinite, task = task, Kmax = 2L), "non-finite predicted penalty .* 1")

  twice = PredictionCpt$new(task, row_ids = c(1L, 1L), response = c(1, 1))
  expect_error(ggplot2::autoplot(twice, task = task, Kmax = 2L), "duplicated row ids")

  task$filter(1L)
  expect_error(ggplot2::autoplot(p, task = task, Kmax = 2L), "subset")
})

test_that("autoplot.PredictionCpt(type = 'roc') draws the curve the AUC integrates", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy()
  p = PredictionCpt$new(task, response = c(0, 0), extra = list(Kmax = c(2L, 2L)))
  g = ggplot2::autoplot(p, task = task, type = "roc")
  curve = ggplot2::layer_data(g, 1L)
  point = ggplot2::layer_data(g, 2L)
  expect_gt(nrow(curve), 1L)
  expect_equal(nrow(point), 1L)
  expect_true(any(curve$x == point$x & curve$y == point$y))
  auc = unname(p$score(msr("changepoint.auc"), task = task))
  expect_equal(ggplot2::get_labs(g)$title, sprintf("AUC = %.3f", auc))

  negative_only = PredictionCpt$new(task, row_ids = 2L, response = 0, extra = list(Kmax = 2L))
  expect_error(ggplot2::autoplot(negative_only, task = task, type = "roc"), "positive and negative")
  expect_error(ggplot2::autoplot(p, task = task, type = "pr"), "Must be element")
})
