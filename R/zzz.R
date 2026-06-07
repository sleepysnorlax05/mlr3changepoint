# nolint start
#' @import data.table
#' @import mlr3
#' @import mlr3misc
#' @import paradox
#' @import checkmate
#' @importFrom R6 R6Class
#' @importFrom utils data head tail
"_PACKAGE"
# nolint end

.onLoad = function(libname, pkgname) {
  register_mlr3()
}

.onUnload = function(libpath) {
  unregister_mlr3_reflections()
}

unregister_mlr3_reflections = function() {
  x = utils::getFromNamespace("mlr_reflections", "mlr3")

  package = NULL
  x$task_types = x$task_types[package != "mlr3changepoint"]
  x$task_col_roles$changepoint = NULL
  x$task_properties$changepoint = NULL
  x$task_feature_types[["lst"]] = NULL
  x$learner_properties$changepoint = NULL
  x$learner_predict_types$changepoint = NULL
}