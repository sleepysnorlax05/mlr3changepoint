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
  pdata$row_ids = assert_row_ids(pdata$row_ids)
  n = length(pdata$row_ids)

  if (!is.null(pdata$truth)) {
    assert_list(pdata$truth, types = "data.table", len = n, any.missing = FALSE)
    for (i in seq_along(pdata$truth)) {
      tt = pdata$truth[[i]]
      assert_names(names(tt), must.include = c("start", "end", "label"))
      assert_numeric(tt$start, any.missing = FALSE, .var.name = "start")
      assert_numeric(tt$end, any.missing = FALSE, .var.name = "end")
      if (!all(tt$start <= tt$end)) {
        stopf("Label region %d has invalid coordinates (start > end).", i)
      }
    }
  }

  if (!is.null(pdata$response)) {
    pdata$response = assert_numeric(unname(pdata$response), len = n)
  }
  if (!is.null(pdata$weights)) {
    pdata$weights = assert_numeric(unname(pdata$weights), any.missing = FALSE, len = n)
  }
  if (!is.null(pdata$extra)) {
    assert_list(pdata$extra, names = "unique")
    if (any(lengths(pdata$extra) != n)) {
      stopf("All elements of 'extra' must have length %i (number of predictions).", n)
    }
  }
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

  if (!is.null(pdata$weights)) {
    pdata$weights = pdata$weights[keep]
  }

  if (!is.null(pdata$extra)) {
    pdata$extra = map(pdata$extra, function(x) x[keep])
  }

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
