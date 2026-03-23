#' @title Interval Regression Learner using Cross Validation
#'
#' @description
#' Learner for interval regression. This learner performs L1-regularized
#' interval regression and automatically selects the optimal penalty hyperparameter
#' via an internal cross-validation loop.
#'
#' @details
#' Expects a `TaskInterval` with exactly two target columns representing the bounds.
#'
#' @export
LearnerIntRegrCV = R6::R6Class(
  "LearnerIntRegrCV",
  inherit = mlr3::Learner,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      super$initialize(
        id = "interval_regr.cv",
        task_type = "interval_regr",
        feature_types = c("logical", "integer", "numeric"),
        predict_types = "response",
        packages = "penaltyLearning",
        param_set = paradox::ps()
      )
    }
  ),

  private = list(
    .train = function(task) {
      row_ids = task$row_ids

      X = as.matrix(task$data(rows = row_ids, cols = task$feature_names))
      Y = as.matrix(task$data(rows = row_ids, cols = task$target_names))

      fit = penaltyLearning::IntervalRegressionCV(X, Y)

      return(fit)
    },

    .predict = function(task) {
      row_ids = task$row_ids

      X_new = as.matrix(task$data(rows = row_ids, cols = task$feature_names))

      preds = as.numeric(predict(self$model, X_new))

      list(response = preds)
    }
  )
)
