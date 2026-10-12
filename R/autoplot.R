# Peak label palette from the PeakError::PeakError() example (`ann.colors`).
# PeakError does not export it, unlike penaltyLearning::change.colors, so it is
# copied here once.
cpt_peak_colors = c(
  noPeaks = "#f6f4bf",
  peakStart = "#ffafaf",
  peakEnd = "#ff4c4c",
  peaks = "#a445ee"
)

#' Signal and label layers shared by the TaskCpt and PredictionCpt plots
#'
#' One facet per row id: the signal as a line over its 1-based positions and the
#' label regions as full-height rectangles filled by annotation.
#'
#' @param parts (`list`)\cr Output of `cpt_extract_data()`.
#' @param label_type (`character(1)`)\cr `"changepoint"` or `"peak"`.
#' @return [ggplot2::ggplot()] with the label layer first and the signal second.
#' @noRd
cpt_plot_base = function(parts, label_type) {
  position = value = xmin = xmax = label = NULL # silence R CMD check notes on the aes() columns
  n = length(parts$ids)
  if (n == 0L) {
    stopf("nothing to plot: no rows selected")
  }

  # Draw each region so a mark falls strictly inside it exactly when the measure
  # counts it there, never on an edge. A change at X is drawn at X + 0.5, between
  # positions X and X + 1, and penaltyLearning::labelError() counts it in
  # (start, end] when start < X <= end, so the region spans [start + 1, end + 1].
  # Peak regions cover positions start..end (cpt_errors_peak() passes start - 1 as
  # the 0-based chromStart), so they span [start - 0.5, end + 0.5] and a predicted
  # peak is drawn between the centres of its first and last positions.
  shift = if (label_type == "changepoint") c(1, 1) else c(-0.5, 0.5)

  signal = vector("list", n)
  regions = vector("list", n)
  for (i in seq_len(n)) {
    s = parts$sequence[[i]]
    lab = parts$target[[i]]
    # rep() rather than recycling a length-1 id: data.table() would NA-fill a
    # 0-row label table into one bogus row.
    signal[[i]] = data.table(row_id = rep(parts$ids[i], length(s)), position = seq_along(s), value = s)
    regions[[i]] = data.table(
      row_id = rep(parts$ids[i], nrow(lab)),
      xmin = lab$start + shift[1L],
      xmax = lab$end + shift[2L],
      label = lab$label
    )
  }
  regions = rbindlist(regions)

  colors = switch(
    label_type,
    changepoint = penaltyLearning::change.colors,
    peak = cpt_peak_colors
  )

  p = ggplot2::ggplot() +
    ggplot2::geom_rect(
      data = regions,
      ggplot2::aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = label),
      alpha = 0.5
    ) +
    ggplot2::geom_line(data = rbindlist(signal), ggplot2::aes(x = position, y = value)) +
    ggplot2::facet_wrap("row_id", scales = "free")
  # Without any label the manual scale only warns that it matched no level.
  if (nrow(regions)) {
    p = p + ggplot2::scale_fill_manual(values = colors)
  }
  p
}

#' @title Plot a Changepoint Task
#'
#' @description
#' Draws each sequence of a [TaskCpt] as a line, one facet per row id, with its
#' label regions shaded by annotation. Changepoint labels use
#' [penaltyLearning::change.colors]; peak labels (`noPeaks`, `peakStart`,
#' `peakEnd`, `peaks`) use the palette of the `PeakError::PeakError()` example.
#' Labels outside these vocabularies are drawn grey.
#'
#' Every row with role `"use"` gets a facet, so to plot part of a large task,
#' filter a copy first: `task$clone()$filter(rows)`.
#'
#' @param object ([TaskCpt]).
#' @param theme ([ggplot2::theme()])\cr
#'   The [ggplot2::theme_minimal()] is applied by default.
#' @param ... (ignored).
#' @return [ggplot2::ggplot()].
#'
#' @examplesIf mlr3misc::require_namespaces(c("ggplot2", "penaltyLearning"), quietly = TRUE)
#' library(data.table)
#' set.seed(36)
#' toy = data.table(
#'   seq = list(c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9)), rnorm(100, 0)),
#'   label = list(
#'     data.table(start = c(90, 190), end = c(110, 210), label = c("1change", "1change")),
#'     data.table(start = 1, end = 100, label = "0changes")
#'   )
#' )
#' task = TaskCpt$new(
#'   id = "toy", backend = toy,
#'   target = "label", sequence = "seq", label_type = "changepoint"
#' )
#' ggplot2::autoplot(task)
#'
#' @exportS3Method ggplot2::autoplot
autoplot.TaskCpt = function(object, theme = ggplot2::theme_minimal(), ...) {
  cpt_plot_base(cpt_extract_data(object), object$label_type) + theme
}

#' @title Plot a Changepoint Prediction
#'
#' @description
#' Draws the facets of [autoplot.TaskCpt()] for the predicted sequences plus the
#' segmentation decoded at each sequence's predicted penalty: dashed vertical
#' lines at predicted changes (`label_type = "changepoint"`) or horizontal
#' segments at the mean count of each predicted peak (`label_type = "peak"`).
#' For the `0changes`, `1change`, `noPeaks` and `peaks` labels, a mark missing
#' from a region that requires one, or inside a region that forbids it, is a
#' label error. `peakStart` and `peakEnd` regions are scored on where a peak
#' starts or ends, not on overlap.
#'
#' @details
#' A [PredictionCpt] stores only the predicted `log(lambda)` per sequence, so the
#' segmentation is re-derived the way [mlr_measures_changepoint.label_error] does
#' it: sequences and labels come from `task`, and the complexity cap from the
#' `Kmax` the prediction records per sequence (learners of this package always
#' record it). `Kmax` is only needed for a prediction built by hand without that
#' record. A non-finite predicted penalty selects no model and raises an error,
#' as do duplicated row ids (combined resampling iterations).
#'
#' Every predicted row gets a facet; for many sequences predict on a subset
#' (`learner$predict(task, row_ids = rows)`).
#'
#' @param object ([PredictionCpt]).
#' @param task ([TaskCpt])\cr
#'   Task the prediction was made on; must contain every predicted row.
#' @param type (`character(1)`)\cr
#'   `"segmentation"` (default) draws the decoded marks; `"roc"` draws the ROC curve
#'   [mlr_measures_changepoint.auc] integrates, from [penaltyLearning::ROChange()], with the AUC as
#'   title and a point at the predicted penalties (shift 0).
#' @param Kmax (`integer(1)` | `NULL`)\cr
#'   Complexity cap for a prediction that does not record one; ignored when the
#'   prediction carries `Kmax`.
#' @param theme ([ggplot2::theme()])\cr
#'   The [ggplot2::theme_minimal()] is applied by default.
#' @param ... (ignored).
#' @return [ggplot2::ggplot()].
#'
#' @examplesIf mlr3misc::require_namespaces(c("ggplot2", "penaltyLearning", "changepoint"), quietly = TRUE)
#' library(data.table)
#' set.seed(36)
#' toy = data.table(
#'   seq = list(c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9)), rnorm(100, 0)),
#'   label = list(
#'     data.table(start = c(90, 190), end = c(110, 210), label = c("1change", "1change")),
#'     data.table(start = 1, end = 100, label = "0changes")
#'   )
#' )
#' task = TaskCpt$new(
#'   id = "toy", backend = toy,
#'   target = "label", sequence = "seq", label_type = "changepoint"
#' )
#'
#' p = PredictionCpt$new(task = task, response = c(2.5, 3.0))
#' # A hand-made prediction records no Kmax, so pass it; learner predictions carry their own.
#' ggplot2::autoplot(p, task = task, Kmax = 3L)
#' ggplot2::autoplot(p, task = task, type = "roc", Kmax = 3L)
#'
#' @exportS3Method ggplot2::autoplot
autoplot.PredictionCpt = function(
  object,
  task,
  type = "segmentation",
  Kmax = NULL,
  theme = ggplot2::theme_minimal(),
  ...
) {
  x = xend = y = FPR = TPR = NULL # silence R CMD check notes on the aes() columns
  assert_class(task, "TaskCpt")
  assert_choice(type, c("segmentation", "roc"))
  if (anyDuplicated(object$row_ids)) {
    stopf("the prediction has duplicated row ids; plot one resampling iteration at a time")
  }
  if (length(object$row_ids) == 0L) {
    stopf("nothing to plot: no rows selected")
  }
  response = object$response
  bad = !is.finite(response)
  if (any(bad)) {
    stopf("non-finite predicted penalty selects no model for row ids: %s", str_collapse(object$row_ids[bad]))
  }

  if (type == "roc") {
    roc = cpt_roc(object, task, Kmax = Kmax)
    if (is.null(roc)) {
      stopf("the ROC curve needs both positive and negative labels")
    }
    predicted = roc$thresholds[roc$thresholds$threshold == "predicted", ]
    g = ggplot2::ggplot(roc$roc, ggplot2::aes(x = FPR, y = TPR)) +
      ggplot2::geom_path() +
      ggplot2::geom_point(data = predicted, colour = "deepskyblue", size = 3) +
      ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
      ggplot2::labs(title = sprintf("AUC = %.3f", roc$auc))
    return(g + theme)
  }

  label_type = task$label_type
  parts = cpt_extract_data(task, object$row_ids)
  p = cpt_plot_base(parts, label_type)
  Kmax = cpt_prediction_kmax(object, Kmax = Kmax)

  # Decode each sequence at its own predicted penalty and cap, the model the
  # measure scores. Keep 0-row tables so rbindlist() keeps the columns when
  # nothing is predicted anywhere.
  marks = vector("list", length(response))
  for (i in seq_along(response)) {
    s = parts$sequence[[i]]
    pred = cpt_segment(s, response[i], Kmax[i], label_type)$predicted
    id = rep(parts$ids[i], nrow(pred))
    if (label_type == "changepoint") {
      # A change at X lies between positions X and X + 1.
      marks[[i]] = data.table(row_id = id, x = pred$change + 0.5)
    } else {
      # A peak covers 1-based positions chromStart + 1 .. chromEnd; draw it between
      # the centres of those positions at its mean count, from cumulative sums.
      cs = c(0, cumsum(s))
      marks[[i]] = data.table(
        row_id = id,
        x = pred$chromStart + 1,
        xend = pred$chromEnd,
        y = (cs[pred$chromEnd + 1L] - cs[pred$chromStart + 1L]) / (pred$chromEnd - pred$chromStart)
      )
    }
  }
  marks = rbindlist(marks)

  layer = if (label_type == "changepoint") {
    ggplot2::geom_vline(data = marks, ggplot2::aes(xintercept = x), colour = "deepskyblue", linetype = "dashed")
  } else {
    ggplot2::geom_segment(data = marks, ggplot2::aes(x = x, xend = xend, y = y, yend = y), colour = "deepskyblue")
  }
  p + layer + theme
}
