#' Extract row-aligned sequence/target parts from a TaskCpt
#'
#' @param task ([TaskCpt]).
#' @return A named `list(ids, sequence, target)`, each aligned to `task$row_ids`.
#' @noRd
cpt_extract_data = function(task) {
  seq_col = task$col_roles$sequence
  target_col = task$target_names
  id_col = task$backend$primary_key

  dt = task$backend$data(
    rows = task$row_ids,
    cols = c(seq_col, target_col, id_col)
  )
  dt = dt[match(task$row_ids, dt[[id_col]]), ]

  ids = dt[[id_col]]
  sequence = dt[[seq_col]]
  target = dt[[target_col]]
  list(ids = ids, sequence = sequence, target = target)
}


#' Build the per-sequence feature matrix for a TaskCpt
#'
#' One row per sequence, with features derived from the sequence signal only, so
#' this is label-type agnostic (identical for changepoint and peak tasks). Wraps
#' [penaltyLearning::featureVector()] over the sequence list-column.
#'
#' On train (`cols = NULL`) it drops non-finite and constant columns, which
#' [penaltyLearning::IntervalRegressionCV()]'s internal feature scaling cannot
#' handle, and the caller stores the kept column names in the model. On predict,
#' pass those stored `cols` back so the matrix matches the fitted model.
#'
#' @param parts (`list`)\cr
#'   Output of `cpt_task_parts()`; uses `parts$sequence` and `parts$ids`.
#' @param cols (`character()` | `NULL`)\cr
#'   `NULL` on train: compute the kept columns and return them. On predict: the
#'   training column names to subset to.
#' @return A numeric matrix, one row per sequence, `rownames` set to `parts$ids`
#'   and columns the kept feature set.
#' @noRd
cpt_feature_matrix = function(parts, cols = NULL) {
  feats = do.call(rbind, lapply(parts$sequence, penaltyLearning::featureVector))
  rownames(feats) = parts$ids

  if (is.null(cols)) {
    finite = apply(feats, 2L, function(x) all(is.finite(x)))
    varies = apply(feats, 2L, function(x) length(unique(x)) > 1L)
    cols = colnames(feats)[finite & varies]
  }
  feats[, cols, drop = FALSE]
}
