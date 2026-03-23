#' @title PredictionCpt
#' @description
#' This is the Prediction class for SUpervised and Unsupervised Change point detection, inheriting from `mlr3::Prediction`.
#' @docType class
#' @importFrom R6 R6Class
#' @export
PredictionCpt = R6::R6Class(
  "PredictionCpt",
  inherit = mlr3::Prediction,
  public = list(
    #' @description Create a new PredictionCpt object.
    #' @param task \code{Task} The task for which predictions are made.
    #' @param row_ids \code{integer} Row IDs corresponding to the predictions.
    #' @param response \code{numeric} The predicted response (e.g., changepoint scores or binary labels).
    #' @param pdata \code{list} or \code{PredictionData} Named list containing row_ids and response.
    initialize = function(
      task = NULL,
      row_ids = pdata$row_ids,
      response = pdata$response,
      pdata = NULL
    ) {
      self$task_type = "cpt_unsup"

      if (!is.null(pdata)) {
        row_ids = pdata$row_ids
        response = pdata$response
      }

      pdata = list(row_ids = row_ids, response = response)

      self$data = pdata
      self$predict_types = "response"
    }
  ),

  active = list(
    #' @field response The predicted response
    response = function() self$data$response
  )
)

#' @export
as_prediction.PredictionDataCpt = function(x, ...) {
  PredictionCpt$new(pdata = x)
}

#' @export
as_prediction_data.PredictionCpt = function(x, ...) {
  list(row_ids = x$row_ids, response = x$response)
}

#' @export
as_prediction_data.PredictionDataCpt = function(x, ...) {
  x
}

#' @export
is_prediction_data.PredictionDataCpt = function(x, ...) {
  inherits(x, "PredictionDataCpt")
}

#' @export
check_prediction_data.PredictionDataCpt = function(pdata, ...) {
  pdata$row_ids = checkmate::assert_atomic_vector(pdata$row_ids)
  pdata$response = checkmate::assert_atomic_vector(pdata$response)
  class(pdata) = c("PredictionDataCpt", "PredictionData")
  pdata
}

#' @export
check_prediction_data.list = function(pdata, ...) {
  if (inherits(pdata, "PredictionDataCpt")) {
    return(pdata)
  }

  pdata$row_ids = checkmate::assert_atomic_vector(pdata$row_ids)
  pdata$response = checkmate::assert_atomic_vector(pdata$response)
  class(pdata) = c("PredictionDataCpt", "PredictionData")
  pdata
}
