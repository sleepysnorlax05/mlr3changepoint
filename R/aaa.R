# nocov start
register_reflections = function() {
  x = utils::getFromNamespace("mlr_reflections", "mlr3")

  x$loaded_packages = c(x$loaded_packages, "mlr3changepoint")

  # task types
  type = NULL
  x$task_types = x$task_types[type != "changepoint"]
  x$task_types = setkeyv(
    rbind(
      x$task_types,
      list(
        "changepoint",
        "mlr3changepoint",
        "TaskCpt",
        "LearnerCpt",
        "PredictionCpt",
        "PredictionDataCpt",
        "MeasureCpt"
      )
    ),
    "type"
  )

  # column roles
  x$task_col_roles$changepoint = c(x$task_col_roles$regr, "sequence")

  # task properties
  x$task_properties$changepoint = x$task_properties$regr

  # task features types
  x$task_feature_types[["lst"]] = "list"

  # learner properties
  x$learner_properties$changepoint = x$learner_properties$regr

  # learner predict types
  x$learner_predict_types$changepoint = list(response = "response")

  # measure properties + default measure
  x$measure_properties$changepoint = x$measure_properties$regr
  x$default_measures$changepoint = "changepoint.label_error"
}

register_mlr3 = function() {
  register_reflections()
  register_learners()
  register_measures()
}
# nocov end
