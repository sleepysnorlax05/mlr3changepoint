#' @import data.table
#' @import mlr3
#' @importFrom utils getFromNamespace
NULL

# nocov start
.onLoad = function(libname, pkgname) {
  env = utils::getFromNamespace("mlr_reflections", "mlr3")

  # Register unsupervised task type
  env$task_types = data.table::rbindlist(
    list(
      env$task_types,
      list(
        type = "cpt_unsup",
        package = "mlr3changepoint",
        task = "TaskCptUnsupervised",
        learner = "LearnerCpt",
        prediction = "PredictionCpt",
        prediction_data = "PredictionDataCpt",
        measure = "Measure"
      )
    ),
    fill = TRUE,
    use.names = TRUE
  )

  # Register supervised task type
  env$task_types = data.table::rbindlist(
    list(
      env$task_types,
      list(
        type = "cpt_sup",
        package = "mlr3changepoint",
        task = "TaskCptSupervised",
        learner = "LearnerCpt",
        prediction = "PredictionCpt",
        prediction_data = "PredictionDataCpt",
        measure = "Measure"
      )
    ),
    fill = TRUE,
    use.names = TRUE
  )

  # Register interval regression task type
  env$task_types = data.table::rbindlist(
    list(
      env$task_types,
      list(
        type = "interval_regr",
        package = "mlr3changepoint",
        task = "TaskInterval",
        learner = "LearnerIntRegrCV",
        prediction = "PredictionRegr",
        prediction_data = "PredictionDataRegr",
        measure = "MeasureRegr"
      )
    ),
    fill = TRUE,
    use.names = TRUE
  )

  # Register predict types & properties
  env$learner_predict_types$cpt_unsup = list(response = "response")
  env$learner_properties$cpt_unsup = character(0)

  env$learner_predict_types$cpt_sup = list(response = "response")
  env$learner_properties$cpt_sup = character(0)

  env$learner_predict_types$interval_regr = list(response = "response")
  env$learner_properties$interval_regr = character(0)

  env$default_measures$interval_regr = "regr.mse"

  # Register task properties and column roles
  roles = c(
    "feature",
    "target",
    "name",
    "order",
    "stratum",
    "group",
    "weights_learner"
  )

  env$task_col_roles$cpt_unsup = roles
  env$task_col_roles$cpt_sup = roles
  env$task_col_roles$interval_regr = roles

  env$task_properties$cpt_unsup = character(0)
  env$task_properties$cpt_sup = character(0)
  env$task_properties$interval_regr = character(0)
}
# nocov end
