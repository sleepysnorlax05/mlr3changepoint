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
  # Backends do not guarantee row order; realign to task$row_ids.
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
#'   Output of `cpt_extract_data()`; uses `parts$sequence` and `parts$ids`.
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
    if (length(cols) == 0L) {
      stopf("no usable features: every feature column is non-finite or constant across sequences")
    }
  }
  feats[, cols, drop = FALSE]
}

#' Segment one sequence into the whole model path
#'
#' Fits the label-type solver for a single sequence and returns the path in one
#' canonical shape shared by both branches:
#' - `models`: one row per model with `complexity` (segment/peak count) and
#'   `loss` (the solver cost), the `(loss, complexity)` table
#'   [penaltyLearning::modelSelection()] consumes.
#' - `predicted`: the detected changes/peaks, one row per model change, keyed by
#'   the same `complexity`. Columns are branch-specific (`change` for
#'   changepoint; `chromStart`/`chromEnd` for peak) because the downstream error
#'   function (`cpt_model_errors()`) is the branch point that reads them.
#'
#' @param signal (`numeric()`)\cr One sequence signal.
#' @param Kmax (`integer(1)`)\cr Maximum number of changes (changepoint) or peaks
#'   (peak) to search for; caps model complexity for both train and predict.
#' @param label_type (`character(1)`)\cr `"changepoint"` or `"peak"`.
#' @return `list(models, predicted)` as described above.
#' @noRd
cpt_segment_path = function(signal, Kmax, label_type) {
  # Both solvers fail with obscure errors on missing values; catch that here once.
  if (anyNA(signal)) {
    stopf("sequence contains missing values")
  }
  switch(
    label_type,
    changepoint = cpt_path_changepoint(signal, Kmax),
    peak = cpt_path_peak(signal, Kmax),
    stopf("unknown label_type: %s", label_type)
  )
}

#' Mean-change path via `changepoint::cpt.mean(method = "SegNeigh")`
#' @noRd
cpt_path_changepoint = function(signal, Kmax) {
  n = length(signal)

  # L2 cost of a segmentation given its interior changepoints (segment ends).
  seg_loss = function(ends) {
    bounds = c(0L, ends, n)
    starts = head(bounds, -1L) + 1L
    stops = bounds[-1L]
    sum(vapply(
      seq_along(starts),
      function(j) {
        v = signal[starts[j]:stops[j]]
        sum((v - mean(v))^2)
      },
      numeric(1L)
    ))
  }

  # Null model (no change) is always in the path.
  models = list(data.table(complexity = 1L, loss = seg_loss(integer())))
  predicted = list(data.table(complexity = integer(), change = numeric()))

  # SegNeigh errors when Q exceeds n - 2; clamp so a short sequence just yields a
  # shorter path.
  Q = min(as.integer(Kmax), n - 2L)
  if (Q >= 1L) {
    fit = withCallingHandlers(
      changepoint::cpt.mean(signal, method = "SegNeigh", Q = Q, penalty = "None"),
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
      models[[k + 1L]] = data.table(complexity = k + 1L, loss = seg_loss(ends))
      predicted[[k + 1L]] = data.table(complexity = k + 1L, change = as.numeric(ends))
    }
  }

  list(models = rbindlist(models), predicted = rbindlist(predicted))
}

#' Peak path via `PeakSegOptimal::PeakSegPDPAchrom()`
#' @noRd
cpt_path_peak = function(signal, Kmax) {
  # PeakSegPDPA models Poisson counts: reject real-valued or negative input
  # instead of silently rounding it into a different dataset.
  if (any(signal != round(signal))) {
    stopf("peak detection requires integer counts")
  }
  count = as.integer(signal)
  if (any(count < 0L)) {
    stopf("peak detection requires non-negative counts")
  }
  n = length(count)

  # Synthesize the 0-based chromStart / 1-based chromEnd genomic coordinates
  # PeakSegPDPAchrom() expects from the plain sequence vector.
  count_df = data.table(
    count = count,
    chromStart = 0:(n - 1L),
    chromEnd = 1:n
  )

  fit = PeakSegOptimal::PeakSegPDPAchrom(
    count_df,
    max.peaks = as.integer(Kmax)
  )
  loss = as.data.table(fit$loss)
  segs = as.data.table(fit$segments)

  # The PDPA path includes equality-constrained infeasible models; drop them
  # before model selection.
  loss = loss[loss[["feasible"]], ]
  keep = loss[["peaks"]]

  is_peak = segs[["status"]] == "peak" & segs[["peaks"]] %in% keep
  peakseg = segs[is_peak, ]

  models = data.table(
    complexity = loss[["peaks"]],
    loss = loss[["PoissonLoss"]]
  )

  predicted = data.table(
    complexity = peakseg[["peaks"]],
    chromStart = peakseg[["chromStart"]],
    chromEnd = peakseg[["chromEnd"]]
  )

  list(models = models, predicted = predicted)
}

#' Score a model path against labels into the canonical `model.errors` schema
#'
#' The branch point: both label types are normalized to the one schema
#' `penaltyLearning::targetIntervals()` understands, i.e. per model per problem
#' with `min.log.lambda`, `max.log.lambda`, `fp`, `fn`, `errors`.
#'
#' @param sm (`data.table`)\cr Combined [penaltyLearning::modelSelection()] output
#'   across problems, carrying `problem`, `complexity`, `min.log.lambda`,
#'   `max.log.lambda`.
#' @param predicted (`data.table`)\cr Combined `predicted` geometry across
#'   problems (see `cpt_segment_path()`), keyed by `problem` and `complexity`.
#' @param regions (`data.table`)\cr Combined labels across problems, columns
#'   `problem`, `start`, `end`, `label`.
#' @param label_type (`character(1)`)\cr `"changepoint"` or `"peak"`.
#' @return A `data.table` in the canonical `model.errors` schema.
#' @noRd
cpt_model_errors = function(sm, predicted, regions, label_type) {
  switch(
    label_type,
    changepoint = cpt_errors_changepoint(sm, predicted, regions),
    peak = cpt_errors_peak(sm, predicted, regions),
    stopf("unknown label_type: %s", label_type)
  )
}

#' Changepoint errors: `penaltyLearning::labelError()` scores all models at once
#' @noRd
cpt_errors_changepoint = function(sm, predicted, regions) {
  labels = copy(regions)
  setnames(labels, "label", "annotation")

  le = penaltyLearning::labelError(
    models = sm,
    labels = labels,
    changes = predicted,
    change.var = "change",
    label.vars = c("start", "end"),
    model.vars = "complexity",
    problem.vars = "problem",
    annotations = penaltyLearning::change.labels
  )
  as.data.table(le$model.errors)
}

#' Peak errors: `PeakError::PeakError()` is per-model and per-region, so loop and
#' sum fp/fn across regions, then attach each model's log.lambda interval.
#' @noRd
cpt_errors_peak = function(sm, predicted, regions) {
  # PeakError coordinates: chromStart 0-based, chromEnd 1-based. The mapping from
  # TaskCpt (start, end) is passed through here; the region convention is a task
  # design decision, not this helper's to reinterpret.
  out = lapply(unique(sm[["problem"]]), function(p) {
    sm_p = sm[sm[["problem"]] == p, ]
    reg_p = regions[regions[["problem"]] == p, ]
    pred_p = predicted[predicted[["problem"]] == p, ]

    # PeakError() needs plain data.frames (data.tables error inside it), and
    # rep() keeps the chrom column valid for 0-row inputs (the 0-peak model).
    reg_df = data.frame(
      chrom = rep("chr", nrow(reg_p)),
      chromStart = reg_p[["start"]],
      chromEnd = reg_p[["end"]],
      annotation = reg_p[["label"]]
    )

    rows = lapply(seq_len(nrow(sm_p)), function(i) {
      cx = sm_p[["complexity"]][i]
      pk = pred_p[pred_p[["complexity"]] == cx, ]
      peak_df = data.frame(
        chrom = rep("chr", nrow(pk)),
        chromStart = pk[["chromStart"]],
        chromEnd = pk[["chromEnd"]]
      )
      pe = PeakError::PeakError(peak_df, reg_df)
      data.table(
        problem = p,
        complexity = cx,
        min.log.lambda = sm_p[["min.log.lambda"]][i],
        max.log.lambda = sm_p[["max.log.lambda"]][i],
        fp = sum(pe$fp),
        fn = sum(pe$fn),
        errors = sum(pe$fp) + sum(pe$fn)
      )
    })
    rbindlist(rows)
  })
  rbindlist(out)
}

#' Compute the log(penalty) target interval matrix for a TaskCpt
#'
#' The train-time label pipeline, tying the helpers together: fit the model
#' path per sequence (`cpt_segment_path()`), attach each model's selectable
#' penalty interval via [penaltyLearning::modelSelection()], score the models
#' against the labels (`cpt_model_errors()`), and invert the error curves with
#' [penaltyLearning::targetIntervals()] into the interval of log(lambda)
#' values reaching minimal label error per sequence.
#'
#' @param task ([TaskCpt]).
#' @param Kmax (`integer(1)`)\cr See `cpt_segment_path()`.
#' @return A numeric matrix, one row per sequence aligned to `task$row_ids`
#'   (`rownames` set to the sequence ids), columns `min.log.lambda` and
#'   `max.log.lambda`: the `target.mat` shape
#'   [penaltyLearning::IntervalRegressionCV()] consumes.
#' @noRd
cpt_target_intervals = function(task, Kmax) {
  problem = NULL # silence the R CMD check / lintr note on the := columns
  label_type = task$label_type
  parts = cpt_extract_data(task)
  ids = parts$ids

  sm_list = list()
  predicted_list = list()
  for (i in seq_along(parts$sequence)) {
    path = cpt_segment_path(parts$sequence[[i]], Kmax, label_type)
    ms = as.data.table(
      penaltyLearning::modelSelection(as.data.frame(path$models), complexity = "complexity")
    )

    ms[, problem := ids[i]]
    sm_list[[i]] = ms

    # Append even 0-row tables: they carry the branch-specific geometry columns,
    # so rbindlist() keeps the schema when no sequence has any predicted change.
    pr = as.data.table(path$predicted)
    pr[, problem := ids[i]]
    predicted_list[[i]] = pr
  }

  sm = rbindlist(sm_list)
  predicted = rbindlist(predicted_list)
  regions = rbindlist(Map(
    function(id, tab) data.table(problem = id, tab),
    ids,
    parts$target
  ))

  me = cpt_model_errors(sm, predicted, regions, label_type)
  ti = as.data.table(penaltyLearning::targetIntervals(me, problem.vars = "problem"))

  ti = ti[match(ids, ti$problem), ]
  target = as.matrix(ti[, c("min.log.lambda", "max.log.lambda")])
  rownames(target) = as.character(ids)
  target
}

#' Segment one sequence at a single learned penalty (predict-side)
#'
#' Rebuilds the same model path as training (`cpt_segment_path()`), maps each
#' model to the penalty interval where it is optimal via
#' [penaltyLearning::modelSelection()], and returns the model whose interval
#' contains `log_lambda`.
#'
#' @param signal (`numeric()`)\cr One sequence signal.
#' @param log_lambda (`numeric(1)`)\cr The penalty predicted by the regressor,
#'   on the log(lambda) scale.
#' @param Kmax (`integer(1)`)\cr See `cpt_segment_path()`; predict inherits the
#'   training complexity cap, so a penalty implying more changes saturates.
#' @param label_type (`character(1)`)\cr `"changepoint"` or `"peak"`.
#' @return `list(complexity, predicted)`: the selected model's complexity and
#'   its geometry rows from the path (zero rows = nothing detected).
#' @noRd
cpt_segment = function(signal, log_lambda, Kmax, label_type) {
  path = cpt_segment_path(signal, Kmax, label_type)

  ms = as.data.table(
    penaltyLearning::modelSelection(as.data.frame(path$models), complexity = "complexity")
  )

  # The intervals tile (-Inf, Inf) half-open as [min, max), so exactly one
  # model matches; <= on both ends would double-match at interval boundaries.
  hit = ms[["min.log.lambda"]] <= log_lambda & log_lambda < ms[["max.log.lambda"]]
  k = ms[["complexity"]][hit]

  predicted = path$predicted[path$predicted[["complexity"]] == k, ]

  list(
    complexity = k,
    predicted = predicted
  )
}
