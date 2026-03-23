#' @title Interval Regression Task
#'
#' @description
#' This task handles interval regression problems. Unlike standard regression which
#' possesses a single numeric target, an interval regression task possesses a
#' lower and upper bound representing an interval (e.g., `min.log.lambda` and `max.log.lambda`).
#'
#' @export
TaskInterval = R6::R6Class(
  "TaskInterval",
  inherit = mlr3::Task,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    #'
    #' @param id \code{character(1)} The task ID.
    #' @param backend \code{DataBackend} The data backend containing the features and targets.
    #' @param target \code{character(2)} The names of the two target columns representing the lower and upper bounds of the interval.
    initialize = function(id, backend, target) {
      if (length(target) != 2) {
        stop(
          "Requires two target columns for the lower and upper bounds."
        )
      }

      super$initialize(
        id = id,
        task_type = "interval_regr",
        backend = backend
      )

      self$set_col_roles(target, roles = "target")
    }
  )
)
