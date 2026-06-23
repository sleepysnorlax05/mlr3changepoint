#' @title Weakly Supervised Task for Change Point Detection
#'
#' @description
#' This task is designed for **weakly supervised change point detection** problems.
#' It inherits from [mlr3::TaskSupervised]
#' and includes additional column roles and properties for change point detection.
#'
#' The `task_type` is set to `"changepoint"`.
#'
#' @details
#' The Task table has one row for each labeled sequence, and two special column roles:
#' - `sequence`: the column that identifies the sequence (e.g., time series)
#' - `target`: a list column where each entry is a `data.table(start, end, label)`
#'
#' The `label_type` can be either "changepoint" or "peak", depending on the type of detection problem.
#' This is stored as an extra argument and can be accessed via the active binding `label_type`.
#'
#' @family Task
#'
#' @examples
#' library(data.table)
#' # one row per sequence; first has two labelled changes, second has none.
#' set.seed(36)
#' toy = data.table(
#'   seq = list(c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9)), rnorm(100, 0)),
#'   label = list(
#'     data.table(start = c(90, 190), end = c(110, 210), label = c("1change", "1change")),
#'     data.table(start = 1, end = 100, label = "0changes")
#'   )
#' )
#'
#' task = TaskCpt$new(
#'   id = "toy", backend = toy,
#'   target = "label", sequence = "seq", label_type = "changepoint"
#' )
#' task
#' task$truth()
#' task$label_type
#'
#' @export
TaskCpt = R6::R6Class(
  "TaskCpt",
  inherit = mlr3::TaskSupervised,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    #'
    #' @param id (`character(1)`)\cr
    #'  Identifier for the task.
    #' @param backend ([mlr3::DataBackend])\cr
    #'  The data backend for the task.
    #' @param target (`character(1)`)\cr
    #'  The column name for the target variable.
    #' @param sequence (`character(1)`)\cr
    #'  The column name for the sequence variable.
    #' @param label_type (`character(1)`)\cr
    #'  The type of labels, either "changepoint" or "peak".
    #' @param label (`character(1)`)\cr
    #'  Display name for the task.
    initialize = function(id, backend, target, sequence, label_type = "changepoint", label = NA_character_) {
      assert_choice(label_type, c("changepoint", "peak"))
      private$.label_type = label_type
      backend = as_data_backend(backend)

      super$initialize(
        id = id,
        task_type = "changepoint",
        backend = backend,
        target = target,
        label = label,
        extra_args = list(sequence = sequence, label_type = label_type)
      )
      self$col_roles$sequence = sequence
      self$col_roles$feature = setdiff(self$col_roles$feature, sequence)
    }
  ),

  active = list(
    #' @field label_type (`character(1)`)\cr
    #'  The type of labels, either "changepoint" or "peak".
    label_type = function() {
      private$.label_type
    }
  ),

  private = list(
    .label_type = NULL
  )
)
