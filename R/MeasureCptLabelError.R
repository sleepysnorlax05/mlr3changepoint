#' @title Label-error changepoint measure
#'
#' @description
#' Percentage of label regions the predicted segmentation gets wrong: the total
#' false positives plus false negatives across all sequences, divided by the
#' total number of labels (Hocking et al.'s percent-incorrect-labels metric).
#'
#' A [PredictionCpt] stores only the predicted penalty `log(lambda)` per
#' sequence, not a segmentation. This measure re-derives the model path each
#' penalty selects (via the shared label-error pipeline in `cpt_label_errors()`),
#' reads off the model at that penalty, and counts its label errors. It therefore
#' declares `"requires_task"` (to read the sequences and labels) and
#' `"requires_learner"` (to read the `Kmax` complexity cap the path was fit
#' under).
#'
#' @details
#' The score micro-averages over sequences: `sum(w * errors) / sum(w * n_labels)`,
#' where `n_labels` is each sequence's label-region count and `w` its measure
#' weight. Sequences carry different label counts, so this weights by labels
#' rather than averaging per-sequence rates. The mlr3 `average` argument is the
#' orthogonal resampling-iteration axis and stays at its default.
#'
#' @templateVar id changepoint.label_error
#'
#' @family Measure
#' @export
MeasureCptLabelError = R6::R6Class(
  "MeasureCptLabelError",
  inherit = MeasureCpt,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      super$initialize(
        id = "changepoint.label_error",
        range = c(0, 1),
        minimize = TRUE,
        properties = c("requires_task", "requires_learner", "weights"),
        packages = "penaltyLearning",
        label = "Label Error",
        man = "mlr3changepoint::MeasureCptLabelError"
      )
    }
  ),
  private = list(
    .score = function(prediction, task, learner, weights = NULL, ...) {
      rows = prediction$row_ids
      response = prediction$response
      weights = weights %??% rep(1, length(rows))

      if (length(rows) == 0L) {
        return(NA_real_)
      }
      if (any(!is.finite(response))) {
        return(NA_real_)
      }

      Kmax = learner$param_set$values$Kmax
      me = cpt_label_errors(task, Kmax, rows)
      me$log_lambda = response[match(me$problem, rows)]
      sel = me[cpt_is_selected(me, me$log_lambda), ]

      if (!setequal(sel$problem, rows) || anyDuplicated(sel$problem)) {
        stopf(
          "label-error scoring selected %i models for %i sequences",
          nrow(sel),
          length(rows)
        )
      }

      errors = sel$errors[match(rows, sel$problem)]
      n_labels = integer(length(rows))
      for (i in seq_along(rows)) {
        n_labels[i] = nrow(prediction$truth[[i]])
      }

      denom = sum(weights * n_labels)
      if (denom == 0) {
        return(NA_real_)
      }
      sum(weights * errors) / denom
    }
  )
)
