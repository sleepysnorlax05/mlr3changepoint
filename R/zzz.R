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
  unregister_mlr3_reflections()
}

register_learners = function() {
  x = utils::getFromNamespace("mlr_learners", "mlr3")
  x$add("changepoint.intregrcv", function() LearnerCptIntRegrCV$new())
}

unregister_learners = function() {
  x = utils::getFromNamespace("mlr_learners", "mlr3")
  x$remove("changepoint.intregrcv")
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
}
# nocov end
