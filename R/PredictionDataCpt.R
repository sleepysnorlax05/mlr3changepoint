# mlr3 methods for 'PredictionDataCpt' objects

#' @export
create_empty_prediction_data.TaskCpt = function(task, learner) {
  parts = list(
    row_ids = integer(),
    truth = list()
  )

  if (learner$predict_type == "response") {
    parts$response = numeric()
  } else {
    stopf("Unknown predict_type '%s'", learner$predict_type)
  }

  class(parts) = c("PredictionDataCpt", "PredictionData")
  parts
}

#' @export
check_prediction_data.PredictionDataCpt = function(pdata, ...) {
  n = length(assert_row_ids(pdata$row_ids))
  assert_list(pdata$truth, types = "data.table", len = n, any.missing = FALSE, null.ok = TRUE)
  assert_numeric(pdata$response, len = n, any.missing = FALSE, null.ok = TRUE)
  pdata
}
