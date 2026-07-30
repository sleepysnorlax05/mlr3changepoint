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

#' @export
is_missing_prediction_data.PredictionDataCpt = function(pdata, ...) {
  miss = logical(length(pdata$row_ids))
  if (!is.null(pdata$response)) {
    miss = miss | is.na(pdata$response)
  }
  pdata$row_ids[miss]
}

#' @export
filter_prediction_data.PredictionDataCpt = function(pdata, row_ids, ...) {
  keep = pdata$row_ids %in% row_ids

  if (!is.null(pdata$truth)) {
    pdata$truth = pdata$truth[keep]
  }

  if (!is.null(pdata$response)) {
    pdata$response = pdata$response[keep]
  }

  pdata$row_ids = pdata$row_ids[keep]

  pdata
}

#' @export
c.PredictionDataCpt = function(..., keep_duplicates = TRUE) {
  dots = list(...)

  if (length(dots) == 0L) {
    return(create_empty_prediction_data.TaskCpt())
  }

  assert_list(dots, "PredictionDataCpt")
  assert()
}