test_that("autoplot.TaskCpt shades changepoint labels with penaltyLearning colours", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("penaltyLearning")

  p = ggplot2::autoplot(toy())
  rects = ggplot2::layer_data(p, 1L)
  # (start, end] regions on half-positions: (90, 110], (190, 210], (1, 100].
  expect_setequal(rects$xmin, c(90.5, 190.5, 1.5))
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

test_that("autoplot.PredictionCpt uses the Kmax a learner prediction records", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  p = lrn("changepoint.xgboost.aft", Kmax = 1L, nrounds = 5L)$train(task)$predict(task)
  marks = ggplot2::layer_data(ggplot2::autoplot(p, task = task), 3L)
  # Kmax = 1 allows at most one change per sequence; an explicit Kmax is ignored.
  expect_lte(nrow(marks), task$nrow)
  expect_equal(
    ggplot2::layer_data(ggplot2::autoplot(p, task = task, Kmax = 3L), 3L)$xintercept,
    marks$xintercept
  )
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
  expect_equal(marks$y, mean(s[(marks$x + 0.5):(marks$xend - 0.5)]))
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
  expect_error(ggplot2::autoplot(infinite, task = task, Kmax = 2L), "no model selected")

  task$filter(1L)
  expect_error(ggplot2::autoplot(p, task = task, Kmax = 2L), "subset")
})
