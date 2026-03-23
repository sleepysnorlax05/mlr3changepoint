#' @title Object for Change point detection predictions Learner
#' @description
#' A wrapper for both supervised and unsupervised change point detection tasks.
#' @export
LearnerCpt = R6::R6Class(
  "LearnerCpt",
  inherit = mlr3::Learner,
  public = list(
    #' @field train_engine (\code{function}) Engine for training.
    train_engine = NULL,
    #' @field predict_engine (\code{function}) Engine for predicting.
    predict_engine = NULL,

    #' @description Create a new LearnerCpt object.
    #' @param id \code{character(1)} The learner ID.
    #' @param task_type \code{character(1)} The task type, either "cpt_unsup" or "cpt_sup".
    #' @param train_engine \code{function} The training engine function
    #' @param predict_engine \code{function} The prediction engine function
    #' @param param_set \code{ParamSet} The parameter set for the learner.
    #' @param predict_types \code{character} The types of predictions the learner can produce
    #' @param feature_types \code{character} The types of features the learner can handle
    #' @param packages \code{character} Required packages for the learner.
    initialize = function(
      id,
      task_type = "cpt_unsup",
      train_engine,
      predict_engine = NULL,
      param_set = paradox::ps(),
      predict_types = "response",
      feature_types = c("integer", "numeric"),
      packages = character()
    ) {
      self$train_engine = train_engine
      self$predict_engine = predict_engine

      super$initialize(
        id = id,
        task_type = task_type,
        param_set = param_set,
        predict_types = predict_types,
        feature_types = feature_types,
        packages = packages
      )
    }
  ),

  private = list(
    .train = function(task) {
      pv = self$param_set$get_values()

      model = self$train_engine(task, task$row_ids, pv)
      return(model)
    },

    .predict = function(task) {
      if (!is.null(self$predict_engine)) {
        preds = self$predict_engine(self$model, task, task$row_ids)
        return(list(response = preds))
      }
      return(list(response = self$model))
    }
  )
)
