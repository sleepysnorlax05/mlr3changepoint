#' @title Weakly supervised changepoint detection measure
#'
#' @description
#' This measure is the base class for all weakly supervised changepoint detection measures.
#' Do not use this class directly, but rather inherit from it when implementing a specific measure.
#' It inherits from [mlr3::Measure] and sets the `task_type` to `"changepoint"`.
#' Calling `$score()` on this base class raises an error.
#'
#' A changepoint measure scores a [PredictionCpt], whose `response` is the predicted penalty
#' `log(lambda)` rather than a segmentation. Deriving the segmentation that penalty selects needs
#' the sequences and the complexity cap they were fitted under, so a measure will usually declare
#' the `"requires_task"` and `"requires_learner"` properties and read `Kmax` from the learner.
#'
#' @family Measure
#'
#' @export
MeasureCpt = R6::R6Class(
  "MeasureCpt",
  inherit = mlr3::Measure,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    #'
    #' @param id (`character(1)`)\cr
    #'  Identifier for the measure.
    #' @param param_set ([paradox::ParamSet])\cr
    #'  Set of hyperparameters.
    #' @param range (`numeric(2)`)\cr
    #'  Feasible range for this measure as `c(lower_bound, upper_bound)`.
    #'  Both bounds may be infinite.
    #' @param minimize (`logical(1)`)\cr
    #'  Set to `TRUE` if good predictions correspond to small values,
    #'  and to `FALSE` if they correspond to large values.
    #' @param average (`character(1)`)\cr
    #'  How to average multiple [mlr3::Prediction]s from a [mlr3::ResampleResult].
    #'  One of `"micro"`, `"macro"` or `"custom"`.
    #' @param aggregator (`function(x)`)\cr
    #'  Function to aggregate individual performance scores `x`, used when
    #'  `average` is `"custom"`.
    #' @param properties (`character()`)\cr
    #'  Properties of the measure. A subset of
    #'  [`mlr_reflections$measure_properties`][mlr3::mlr_reflections].
    #' @param predict_type (`character(1)`)\cr
    #'  Required predict type of the [LearnerCpt].
    #' @param task_properties (`character()`)\cr
    #'  Required task properties, a subset of
    #'  [`mlr_reflections$task_properties`][mlr3::mlr_reflections].
    #' @param packages (`character()`)\cr
    #'  Set of required packages. Checked for availability when the measure is
    #'  constructed and loaded on demand before scoring.
    #' @param label (`character(1)`)\cr
    #'  Display name for the measure.
    #' @param man (`character(1)`)\cr
    #'  String of the form `[pkg]::[topic]` pointing to this object's help
    #'  page, which can be opened via the `$help()` method.
    initialize = function(
      id,
      param_set = ps(),
      range = c(-Inf, Inf),
      minimize = NA,
      average = "macro",
      aggregator = NULL,
      properties = character(),
      predict_type = "response",
      task_properties = character(),
      packages = character(),
      label = NA_character_,
      man = NA_character_
    ) {
      super$initialize(
        id = id,
        task_type = "changepoint",
        param_set = param_set,
        range = range,
        minimize = minimize,
        average = average,
        aggregator = aggregator,
        properties = properties,
        predict_type = predict_type,
        task_properties = task_properties,
        packages = c("mlr3changepoint", packages),
        label = label,
        man = man
      )
    }
  ),
  private = list(
    .score = function(prediction, ...) {
      stopf("MeasureCpt is an abstract class that cannot score")
    }
  )
)
