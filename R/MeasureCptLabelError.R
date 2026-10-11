#' @title Label-error changepoint measure
#'
#' @name mlr_measures_changepoint.label_error
#'
#' @description
#' Percentage of label regions the predicted segmentation gets wrong: the total
#' false positives plus false negatives across all sequences, divided by the
#' total number of labels (Hocking et al.'s percent-incorrect-labels metric).
#'
#' A [PredictionCpt] stores only the predicted penalty `log(lambda)` per
#' sequence, not a segmentation. This measure re-derives the model path each
#' penalty selects (via the shared label-error pipeline in `cpt_label_errors()`),
#' reads off the model at that penalty, and counts its label errors. That path
#' depends on the complexity cap `Kmax` the penalty was learned under, which the
#' learners of this package record per sequence in the prediction's `extra`
#' data (`as.data.table(prediction)$Kmax`). Reading it from the prediction keeps
#' the score right for wrapped learners (a `GraphLearner` prefixes parameter
#' ids) and for resampled predictions whose folds were tuned to different caps.
#' A prediction without it (e.g. built by hand) falls back to the `Kmax` of the
#' learner passed to `$score()`; scoring errors if neither gives one.
#'
#' The measure declares `"requires_task"` (to read the sequences and labels) and
#' `"na_score"`, since an empty prediction, a non-finite predicted penalty, or a
#' test set without labels scores `NA`.
#'
#' @details
#' The score micro-averages over sequences: `sum(w * errors) / sum(w * n_labels)`,
#' where `n_labels` is each sequence's label-region count and `w` its measure
#' weight. Sequences carry different label counts, so this weights by labels
#' rather than averaging per-sequence rates. The mlr3 `average` argument is the
#' orthogonal resampling-iteration axis and stays at its default.
#'
#' @section Dictionary:
#' This measure can be retrieved via [mlr3::mlr_measures] with the key
#' `"changepoint.label_error"`:
#' ```
#' msr("changepoint.label_error")
#' ```
#'
#' @family Measure
#'
#' @examples
#' library(data.table)
#'
#' # Alternate change-bearing and flat sequences so the learner's internal
#' # cross-validation folds always see both target interval kinds.
#' set.seed(36)
#' signal = vector("list", 10L)
#' label = vector("list", 10L)
#' for (i in 1:10) {
#'   if (i %% 2 == 1) {
#'     signal[[i]] = c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9))
#'     label[[i]] = data.table(
#'       start = c(90, 190), end = c(110, 210), label = c("1change", "1change")
#'     )
#'   } else {
#'     signal[[i]] = rnorm(100, 0)
#'     label[[i]] = data.table(start = 1, end = 100, label = "0changes")
#'   }
#' }
#' task = TaskCpt$new(
#'   id = "toy", backend = data.table(signal = signal, label = label),
#'   target = "label", sequence = "signal", label_type = "changepoint"
#' )
#'
#' learner = lrn("changepoint.intregrcv",
#'   Kmax = 3L, n.folds = 2L, min.observations = 2L
#' )
#' \donttest{
#' set.seed(36)
#' learner$train(task)
#' prediction = learner$predict(task)
#' prediction$score(msr("changepoint.label_error"), task = task)
#' }
#'
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
        properties = c("requires_task", "weights", "na_score"),
        packages = c("penaltyLearning", "changepoint", "PeakSegOptimal", "PeakError"),
        label = "Label Error",
        man = "mlr3changepoint::mlr_measures_changepoint.label_error"
      )
    }
  ),
  private = list(
    .score = function(prediction, task, learner = NULL, weights = NULL, ...) {
      rows = prediction$row_ids
      response = prediction$response
      weights = weights %??% rep(1, length(rows))

      if (length(rows) == 0L) {
        return(NA_real_)
      }
      if (any(!is.finite(response))) {
        return(NA_real_)
      }

      # Learner predictions record the Kmax each penalty was learned under per
      # row; a resampled prediction can mix caps across folds. Hand-built
      # predictions fall back to the learner's own Kmax.
      Kmax = prediction$data$extra$Kmax %??% rep(learner$param_set$values$Kmax, length(rows))
      if (!test_integerish(Kmax, lower = 1, any.missing = FALSE, len = length(rows))) {
        stopf(paste0(
          "label-error scoring needs a positive integer Kmax per sequence: ",
          "the prediction records none and the learner sets none"
        ))
      }

      me = list()
      for (k in unique(Kmax)) {
        me[[length(me) + 1L]] = cpt_label_errors(task, k, rows[Kmax == k])
      }
      me = rbindlist(me)
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
