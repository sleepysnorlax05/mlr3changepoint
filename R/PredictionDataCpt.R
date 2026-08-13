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
  assert_list(dots, "PredictionDataCpt")
  assert_flag(keep_duplicates)
  if (length(dots) == 1) {
    return(dots[[1]])
  }

  types = map(dots, function(x) {
    intersect(names(x), names(mlr_reflections$learner_predict_types$changepoint))
  })

  if (length(unique(types)) > 1) {
    stopf("Cannot combine PredictionDataCpt objects with different types.")
  }

  row_ids = unlist(map(dots, "row_ids"))
  truth = do.call(c, map(dots, "truth"))
  response = unlist(map(dots, "response"))

  if (!keep_duplicates) {
    keep = !duplicated(row_ids, fromLast = TRUE)
    row_ids = row_ids[keep]
    truth = truth[keep]
    response = response[keep]
  }

  pdata = discard(list(row_ids = row_ids, truth = truth, response = response), is.null)
  class(pdata) = c("PredictionDataCpt", "PredictionData")
  pdata
}

#' @export
as_prediction.PredictionDataCpt = function(x, check = TRUE, ...) {
  invoke(PredictionCpt$new, check = check, .args = x)
}
