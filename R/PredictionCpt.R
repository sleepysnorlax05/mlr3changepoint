#' @title Prediction Object for Change Point Detection
#'
#' @description
#' This object wraps the predictions returned by a learner of class [LearnerCpt],
#' i.e. the predicted penalty `log(lambda)` for each sequence.
#' It is the bridge from a [LearnerCpt] to a measure: `$score()` compares the
#' predicted penalties against the true label regions stored in `$truth`.
#'
#' The `task_type` is set to `"changepoint"`.
#'
#' @family Prediction
#'
#' @examples
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
#' p
#' p$response
#' as.data.table(p)
#'
#' @export
PredictionCpt = R6::R6Class(
  "PredictionCpt",
  inherit = mlr3::Prediction,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    #'
    #' @param task ([TaskCpt])\cr
    #'  Task, used to extract defaults for `row_ids` and `truth`.
    #' @param row_ids (`integer()`)\cr
    #'  Row ids of the predicted observations, i.e. the row ids of the test set.
    #' @param truth (`list()` of [data.table::data.table()])\cr
    #'  True label regions, one `data.table(start, end, label)` per observation.
    #' @param response (`numeric()`)\cr
    #'  Predicted penalty `log(lambda)`.
    #'  One element for each observation in the test set.
    #' @param weights (`numeric()`)\cr
    #'  Measure weights, one for each observation in the test set.
    #'  Constructed from the `weights_measure` column of the [TaskCpt], if present.
    #' @param check (`logical(1)`)\cr
    #'  If `TRUE`, performs some argument checks and predict type conversions.
    #' @param extra (`list()`)\cr
    #'  Named list of extra data to store alongside the predictions.
    #'  Each element must have one entry per observation in the test set.
    #' @param raw (any)\cr
    #'  Raw prediction object from the upstream model. Stored as-is, without validation.
    initialize = function(
      task = NULL,
      row_ids = task$row_ids,
      truth = task$truth(row_ids),
      response = NULL,
      weights = NULL,
      check = TRUE,
      extra = NULL,
      raw = NULL
    ) {
      pdata = list(
        row_ids = row_ids,
        truth = truth,
        response = response,
        weights = weights,
        extra = extra,
        raw = raw
      )
      pdata = discard(pdata, is.null)
      class(pdata) = c("PredictionDataCpt", "PredictionData")

      if (check) {
        pdata = check_prediction_data(pdata)
      }
      self$task_type = "changepoint"
      self$man = "mlr3changepoint::PredictionCpt"
      self$data = pdata
      self$predict_types = intersect(names(mlr_reflections$learner_predict_types$changepoint), names(pdata))
    }
  ),

  active = list(
    #' @field response (`numeric()`)\cr
    #' Access the stored predicted penalty `log(lambda)`.
    #' Returns `NA` for observations without a stored prediction.
    response = function(rhs) {
      assert_ro_binding(rhs)
      self$data$response %??% rep(NA_real_, length(self$data$row_ids))
    }
  )
)

#' @export
as.data.table.PredictionCpt = function(x, ...) {
  tab = data.table(row_ids = x$data$row_ids, truth = x$data$truth, response = x$response)

  if (!is.null(x$data$weights)) {
    tab$weights = x$data$weights
  }

  if (!is.null(x$data$extra)) {
    tab = cbind(tab, as.data.table(x$data$extra))
  }

  tab
}
