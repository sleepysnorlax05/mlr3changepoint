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

cpt_segment_path = function(seq, Kmax, label_type) {
  switch(
    label_type,
    changepoint = cpt_path_changepoint(seq, Kmax),
    peak = cpt_path_peak(seq, Kmax),
    stopf("unknown label_type: %s", label_type)
  )
}

#' Mean-change path via `changepoint::cpt.mean(method = "SegNeigh")`
#' @noRd
cpt_path_changepoint = function(seq, Kmax) {
  n = length(seq)

  # L2 cost of a segmentation given its interior changepoints (segment ends).
  seg_loss = function(ends) {
    bounds = c(0L, ends, n)
    starts = utils::head(bounds, -1L) + 1L
    stops = bounds[-1L]
    sum(vapply(seq_along(starts), function(j) {
      v = seq[starts[j]:stops[j]]
      sum((v - mean(v))^2)
    }, numeric(1L)))
  }

  # Null model (no change) is always in the path.
  models = data.table(complexity = 1L, loss = seg_loss(integer()))
  predicted = data.table(complexity = integer(), change = numeric())

  # SegNeigh errors when Q exceeds n - 2; clamp so a short sequence just yields a
  # shorter path.
  Q = min(as.integer(Kmax), n - 2L)
  if (Q >= 1L) {
    fit = withCallingHandlers(
      changepoint::cpt.mean(seq, method = "SegNeigh", Q = Q, penalty = "None"),
      warning = function(w) {
        if (grepl("SegNeigh|number of segments identified", w$message)) {
          invokeRestart("muffleWarning")
        }
      }
    )
    # cpts.full(): row k holds the k changepoint positions of the (k + 1)-segment
    # model, NA-padded to Q columns.
    cps = changepoint::cpts.full(fit)
    for (k in seq_len(nrow(cps))) {
      ends = cps[k, ]
      ends = ends[!is.na(ends)]
      models = rbind(models, data.table(complexity = k + 1L, loss = seg_loss(ends)))
      predicted = rbind(predicted, data.table(complexity = k + 1L, change = as.numeric(ends)))
    }
  }

  list(models = models, predicted = predicted)
}

#' Peak path via `PeakSegOptimal::PeakSegPDPAchrom()`
#' @noRd
cpt_path_peak = function(seq, Kmax) {
  count = as.integer(round(seq))
  if (any(count < 0L)) {
    stop("peak detection requires non-negative counts")
  }
  n = length(count)

  count.df = data.table::data.table(
    count = count,
    chromStart = 0:(n - 1L),
    chromEnd = 1:n
  )

  fit = PeakSegOptimal::PeakSegPDPAchrom(
    count.df, max.peaks = as.integer(Kmax)
  )
  loss = data.table::as.data.table(fit$loss)
  segs = data.table::as.data.table(fit$segments)

  # The PDPA path includes equality-constrained infeasible models; drop them
  # before model selection.
  loss = loss[loss[["feasible"]], ]
  keep = loss[["peaks"]]

  is_peak = segs[["status"]] == "peak" & segs[["peaks"]] %in% keep
  peakseg = segs[is_peak, ]

  models = data.table::data.table(
    complexity = loss[["peaks"]],
    loss = loss[["PoissonLoss"]]
  )

  predicted = data.table::data.table(
    complexity = peakseg[["peaks"]],
    chromStart = peakseg[["chromStart"]],
    chromEnd = peakseg[["chromEnd"]]
  )

  list(models = models, predicted = predicted)
}