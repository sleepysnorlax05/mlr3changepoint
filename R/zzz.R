#' @import data.table
#' @import mlr3
#' @import mlr3misc
#' @import paradox
#' @import checkmate
#' @importFrom R6 R6Class
"_PACKAGE"

# nocov start
.onLoad = function(libname, pkgname) {
  register_namespace_callback(pkgname, "mlr3", register_mlr3)
}

.onUnload = function(libpath) {
  unregister_learners()
  unregister_measures()
  unregister_mlr3_reflections()
}

register_learners = function() {
  x = utils::getFromNamespace("mlr_learners", "mlr3")
  x$add("changepoint.intregrcv", function() LearnerCptIntRegrCV$new())
  x$add("changepoint.mmif", function() LearnerCptMMIF$new())
  x$add("changepoint.mmit", function() LearnerCptMMIT$new())
  x$add("changepoint.xgboost.aft", function() LearnerCptXGBoostAFT$new())
}

unregister_learners = function() {
  x = utils::getFromNamespace("mlr_learners", "mlr3")
  x$remove("changepoint.intregrcv")
  x$remove("changepoint.mmif")
  x$remove("changepoint.mmit")
  x$remove("changepoint.xgboost.aft")
}

register_measures = function() {
  x = utils::getFromNamespace("mlr_measures", "mlr3")
  x$add("changepoint.auc", function() MeasureCptAUC$new())
  x$add("changepoint.label_accuracy", function() MeasureCptLabelAccuracy$new())
  x$add("changepoint.label_error", function() MeasureCptLabelError$new())
}

unregister_measures = function() {
  x = utils::getFromNamespace("mlr_measures", "mlr3")
  x$remove("changepoint.auc")
  x$remove("changepoint.label_accuracy")
  x$remove("changepoint.label_error")
}

unregister_mlr3_reflections = function() {
  x = utils::getFromNamespace("mlr_reflections", "mlr3")

  package = NULL
  x$task_types = x$task_types[package != "mlr3changepoint"]
  x$task_col_roles$changepoint = NULL
  x$task_properties$changepoint = NULL
  x$task_feature_types = x$task_feature_types[names(x$task_feature_types) != "lst"]
  x$learner_properties$changepoint = NULL
  x$learner_predict_types$changepoint = NULL
  x$measure_properties$changepoint = NULL
  x$default_measures$changepoint = NULL
}
# nocov end
