#' @title TaskCptUnsupervised
#' @description
#' This is the Task class for Unsupervised Change point detection.
#' @export
TaskCptUnsupervised = R6::R6Class(
  "TaskCptUnsupervised",
  inherit = mlr3::TaskUnsupervised,
  public = list(
    #' @description Create a new TaskCptUnsupervised object.
    #' @param id \code{character(1)} The task ID.
    #' @param data \code{data.table} The data table containing the sequence column and optionally a position column.
    #' @param sequence_col \code{character(1)} Sequence feature column name.
    #' @param position_col \code{character(1)} Optional column name for position/order
    initialize = function(id, data, sequence_col, position_col = NULL) {
      checkmate::assert_string(id)
      checkmate::assert_data_table(data)
      checkmate::assert_string(sequence_col)

      backend = mlr3::as_data_backend(data)
      super$initialize(id = id, task_type = "cpt_unsup", backend = backend)

      self$col_roles$feature = character()

      self$set_col_roles(sequence_col, roles = "feature")
      if (!is.null(position_col)) {
        self$set_col_roles(position_col, roles = "order")
      }
    }
  )
)
