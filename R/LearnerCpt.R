#' @title Weakly supervised changepoint detection learner
#'
#' @description
#' This learner is the base class for all weakly supervised changepoint detection learners.
#' Do not use this class directly, but rather inherit from it when implementing specific algorithms.
#' It inherits from [mlr3::Learner] and sets the `task_type` to `"changepoint"`.
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
    #'
    #' @param id (`character(1)`)\cr
    #'  Identifier for the learner.
    #' @param param_set ([paradox::ParamSet])\cr
    #'  Set of hyperparameters.
    #' @param predict_types (`character()`)\cr
    #'  Supported predict types. A subset of [`mlr_reflections$learner_predict_types`][mlr3::mlr_reflections].
    #' @param feature_types (`character()`)\cr
    #'  Feature types the learner operates on. A subset of [`mlr_reflections$task_feature_types`][mlr3::mlr_reflections].
    #' @param properties (`character()`)\cr
    #'  Set of learner properties. A subset of [`mlr_reflections$learner_properties`][mlr3::mlr_reflections];
    #'  see [mlr3::Learner] for the list of standardized properties.
    #' @param packages (`character()`)\cr
    #'  Set of required packages.
    #' @param label (`character(1)`)\cr
    #'  Display name for the learner.
    #' @param man (`character(1)`)\cr
    #'  String in the format `[pkg]::[topic]` pointing to the manual page.
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
