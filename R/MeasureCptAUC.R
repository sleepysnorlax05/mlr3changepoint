#' @title Area-under-the-ROC-curve changepoint measure
#'
#' @name mlr_measures_changepoint.auc
#'
#' @description
#' Area under the ROC curve that [penaltyLearning::ROChange()] traces by adding one constant to every
#' predicted penalty `log(lambda)`. Each shift selects one model per sequence, and the curve plots the
#' false positive rate against the true positive rate, totalled over all label regions. The models and
#' their label errors come from the same pipeline and per-sequence `Kmax` as
#' [mlr_measures_changepoint.label_error] (the prediction's recorded cap, else the learner's).
#' `autoplot(prediction, task = task, type = "roc")` draws the curve.
#'
#' Changepoint ROC curves need not be monotonic: a curve with loops can enclose an area above 1
#' (Hillman and Hocking 2023), so the range is unbounded.
#'
#' The measure declares `"requires_task"` and `"na_score"`: an empty prediction, a non-finite predicted
#' penalty, or labels with no region that can hold a false positive (or none that can hold a false
#' negative) score `NA`. [penaltyLearning::ROChange()] is unweighted, so the measure ignores weights.
#'
#' @references
#' Hillman J, Hocking TD (2023). "Optimizing ROC Curves with a Sort-Based Surrogate Loss for Binary
#' Classification and Changepoint Detection." *Journal of Machine Learning Research*, 24(70), 1-24.
#'
#' @section Dictionary:
#' This measure can be retrieved via [mlr3::mlr_measures] with the key
#' `"changepoint.auc"`:
#' ```
#' msr("changepoint.auc")
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
#' prediction$score(msr("changepoint.auc"), task = task)
#' }
#'
#' @export
MeasureCptAUC = R6::R6Class(
  "MeasureCptAUC",
  inherit = MeasureCpt,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      super$initialize(
        id = "changepoint.auc",
        range = c(-Inf, Inf),
        minimize = FALSE,
        properties = c("requires_task", "na_score"),
        packages = c("penaltyLearning", "changepoint", "PeakSegOptimal", "PeakError"),
        label = "Area Under the ROC Curve",
        man = "mlr3changepoint::mlr_measures_changepoint.auc"
      )
    }
  ),
  private = list(
    .score = function(prediction, task, learner = NULL, ...) {
      if (length(prediction$row_ids) == 0L || any(!is.finite(prediction$response))) {
        return(NA_real_)
      }
      roc = cpt_roc(prediction, task, learner = learner)
      if (is.null(roc)) {
        return(NA_real_)
      }
      roc$auc
    }
  )
)
