#' @title Weakly supervised changepoint detection learner
#'
#' @description
#' This learner is the base class for all weakly supervised changepoint detection learners.
#' Do not use this class directly, but rather inherit from it when implementing specific algorithms.
#' It inherits from [mlr3::Learner] and sets the `task_type` to `"changepoint"`.
#'
#' @template param_id
#' @template param_param_set
#' @template param_predict_types
#' @template param_feature_types
#' @template param_learner_properties
#' @template param_packages
#' @template param_label
#' @template param_man
#'
#' @family Learner
#'
#' @export
LearnerCpt = R6::R6Class(
  "LearnerCpt",
  inherit = mlr3::Learner,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function(
      id,
      param_set = ps(),
      predict_types = "response",
      feature_types = character(),
      properties = character(),
      packages = character(),
      label = NA_character_,
      man = NA_character_
    ) {
      super$initialize(
        id = id,
        task_type = "changepoint",
        param_set = param_set,
        predict_types = predict_types,
        feature_types = feature_types,
        properties = properties,
        packages = c("mlr3changepoint", packages),
        label = label,
        man = man
      )
    }
  )
)
