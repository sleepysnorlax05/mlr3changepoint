#' @title Label-accuracy changepoint measure
#'
#' @name mlr_measures_changepoint.label_accuracy
#'
#' @description
#' One minus [mlr_measures_changepoint.label_error]: the label-weighted share of label regions the
#' predicted segmentation gets right. It reads `Kmax`, applies measure weights and scores `NA`
#' exactly like the label error.
#'
#' @section Dictionary:
#' This measure can be retrieved via [mlr3::mlr_measures] with the key
#' `"changepoint.label_accuracy"`:
#' ```
#' msr("changepoint.label_accuracy")
#' ```
#'
#' @family Measure
#'
#' @examplesIf mlr3misc::require_namespaces(c("penaltyLearning", "changepoint"), quietly = TRUE)
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
#' prediction$score(msr("changepoint.label_accuracy"), task = task)
#' }
#'
#' @export
MeasureCptLabelAccuracy = R6::R6Class(
  "MeasureCptLabelAccuracy",
  inherit = MeasureCpt,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      super$initialize(
        id = "changepoint.label_accuracy",
        range = c(0, 1),
        minimize = FALSE,
        properties = c("requires_task", "weights", "na_score"),
        packages = c("penaltyLearning", "changepoint", "PeakSegOptimal", "PeakError"),
        label = "Label Accuracy",
        man = "mlr3changepoint::mlr_measures_changepoint.label_accuracy"
      )
    }
  ),
  private = list(
    .score = function(prediction, task, learner = NULL, weights = NULL, ...) {
      1 - cpt_label_error(prediction, task, learner, weights)
    }
  )
)
