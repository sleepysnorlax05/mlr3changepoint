# Reproduces the two figures in PR #37: LearnerCptIntRegrCV on the changepoint
# and peak toy fixtures. Each facet is one sequence, shaded by its label
# regions, with dashed lines at the changes/peaks decoded from the penalty the
# learner predicted for that sequence.
#
# The toy fixtures below match tests/testthat/helper-toydata.R. set.seed(36)
# before training reproduces the tests' `with_seed(36, train)` run, so the
# folds IntervalRegressionCV samples internally are the same valid split.

library(mlr3)
library(mlr3changepoint)
library(data.table)
library(ggplot2)

toy_interval = function(n = 10L) {
  set.seed(36)
  rows = lapply(seq_len(n), function(i) {
    if (i %% 2L) {
      list(
        c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9)),
        data.table(start = c(90, 190), end = c(110, 210), label = "1change")
      )
    } else {
      list(rnorm(100, 0), data.table(start = 1, end = 100, label = "0changes"))
    }
  })
  TaskCpt$new(
    "toy_interval",
    data.table(signal = lapply(rows, `[[`, 1), label = lapply(rows, `[[`, 2)),
    target = "label",
    sequence = "signal",
    label_type = "changepoint"
  )
}

toy_peak_interval = function(n = 10L) {
  set.seed(36)
  rows = lapply(seq_len(n), function(i) {
    if (i %% 2L) {
      list(
        c(rpois(60, 2), rpois(40, 25), rpois(100, 2)),
        data.table(start = c(1, 55), end = c(50, 105), label = c("noPeaks", "peaks"))
      )
    } else {
      list(rpois(200, 2), data.table(start = 10, end = 190, label = "noPeaks"))
    }
  })
  TaskCpt$new(
    "toy_peak_interval",
    data.table(signal = lapply(rows, `[[`, 1), label = lapply(rows, `[[`, 2)),
    target = "label",
    sequence = "signal",
    label_type = "peak"
  )
}

plot_cpt = function(task, Kmax = 3L) {
  lt = task$label_type
  set.seed(36) # reproduces the tests' training run (with_seed(36, train))
  p = lrn("changepoint.intregrcv", Kmax = Kmax, n.folds = 2L, min.observations = 2L)$train(task)$predict(task)
  parts = mlr3changepoint:::cpt_extract_data(task)

  seq_dt = rbindlist(Map(
    function(i, s) data.table(row = i, t = seq_along(s), value = s),
    seq_along(parts$sequence),
    parts$sequence
  ))
  lab_dt = rbindlist(Map(function(i, l) data.table(row = i, l), seq_along(parts$target), parts$target))
  # decode each sequence at its own predicted penalty
  mark_dt = rbindlist(Map(
    function(i, s, ll) {
      d = mlr3changepoint:::cpt_segment(s, ll, Kmax, lt)$predicted
      if (nrow(d)) data.table(row = i, x = if (lt == "changepoint") d$change else c(d$chromStart, d$chromEnd))
    },
    seq_along(parts$sequence),
    parts$sequence,
    p$response
  ))

  ggplot() +
    geom_rect(
      data = lab_dt,
      aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf, fill = .data[["label"]]),
      alpha = 0.3
    ) +
    geom_line(data = seq_dt, aes(t, .data[["value"]]), linewidth = 0.3) +
    geom_vline(data = mark_dt, aes(xintercept = .data[["x"]]), linetype = "dashed") +
    facet_wrap(~row, ncol = 2, scales = "free_y") +
    labs(
      title = paste("Predicted", if (lt == "changepoint") "changepoints" else "peaks", "at the learned penalty"),
      subtitle = paste("log(lambda) =", paste(round(p$response, 2), collapse = ", "))
    )
}

plot_cpt(toy_interval())
plot_cpt(toy_peak_interval())
