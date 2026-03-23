#' @title TaskCptSupervised
#' @description
#' This is the Task class for Supervised Change point detection.
#' @export
TaskCptSupervised = R6::R6Class(
  "TaskCptSupervised",
  inherit = mlr3::TaskSupervised,
  public = list(
    #' @description Create a new TaskCptSupervised object.
    #' @param id \code{character(1)} The task ID.
    #' @param data \code{data.table} The data table containing the sequence and label columns.
    #' @param sequence_col \code{character(1)} Sequence feature column name.
    #' @param label_col \code{character(1)} Label target column name.
    initialize = function(id, data, sequence_col, label_col) {
      checkmate::assert_string(id)
      checkmate::assert_data_table(data)

      if (!(label_col %in% names(data))) {
        stop("Label target column not found in data.")
      }
      if (!(sequence_col %in% names(data))) {
        stop("Sequence feature column not found in data.")
      }

      backend = mlr3::as_data_backend(data)

      super$initialize(
        id = id,
        task_type = "cpt_sup",
        backend = backend,
        target = label_col
      )

      self$set_col_roles(sequence_col, roles = "feature")
    }
  )
)
