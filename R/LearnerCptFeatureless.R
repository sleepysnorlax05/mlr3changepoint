#' @title Featureless Changepoint Learner
#'
#' @name mlr_learners_changepoint.featureless
#'
#' @description
#' A baseline that ignores the sequences and learns a single constant penalty
#' `log(lambda)` for all of them, the one with the fewest label errors summed
#' over the training sequences.
#'
#' At train time, the segment path is fitted per sequence and scored against its
#' label regions. Each model is selected on an interval of `log(lambda)`, so the
#' total label error is a step function of a constant penalty; the learner
#' evaluates it on every step and keeps the minimum. When several steps reach
#' it, the middle one of them is taken, and the penalty returned is the midpoint
#' of that step (or one unit past the outermost breakpoint for an unbounded
#' step). Sequences without labels do not affect the fit.
#'
#' At predict time, the learner returns `response`, the learned constant
#' `log(lambda)`, for every sequence. A learner that uses features is only worth
#' its features if it beats this baseline, e.g. in [mlr3::benchmark()].
#'
#' The label solvers are chosen by the task's `label_type`:
#' `"changepoint"` uses [changepoint::cpt.mean()], `"peak"` uses
#' [PeakSegOptimal::PeakSegPDPAchrom()].
#'
#' @section Dictionary:
#' This learner can be retrieved via [mlr3::mlr_learners] with the key
#' `"changepoint.featureless"`:
#' ```
#' lrn("changepoint.featureless")
#' ```
#'
#' @section Parameters:
#' `Kmax` (`integer(1)`, required) caps model complexity: the maximum number of
#' changepoints (`label_type = "changepoint"`) or peaks (`label_type = "peak"`)
#' the per-sequence segment path is searched over. The learner uses it to score
#' the label errors at train time. Each prediction records it per sequence in
#' its `extra` data (`as.data.table(prediction)$Kmax`), so the label-error
#' measure decodes the predicted penalty under the same cap.
#'
#' @family Learner
#'
#' @examplesIf mlr3misc::require_namespaces(c("penaltyLearning", "changepoint"), quietly = TRUE)
#' library(data.table)
#'
#' set.seed(36)
#' signal = vector("list", 10L)
#' label = vector("list", 10L)
#' for (i in 1:10) {
#'   if (i %% 2 == 1) {
#'     signal[[i]] = c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9))
#'     label[[i]] = data.table(
#'       start = c(90, 190), end = c(110, 210), label = c("1change", "1change")
#'     )
#'   } else {
#'     signal[[i]] = rnorm(100, 0)
#'     label[[i]] = data.table(start = 1, end = 100, label = "0changes")
#'   }
#' }
#' task = TaskCpt$new(
#'   id = "toy", backend = data.table(signal = signal, label = label),
#'   target = "label", sequence = "signal", label_type = "changepoint"
#' )
#'
#' learner = lrn("changepoint.featureless", Kmax = 3L)
#' \donttest{
#' learner$train(task)
#' learner$model$log_lambda
#' learner$predict(task)
#' }
#'
#' @export
LearnerCptFeatureless = R6::R6Class(
  "LearnerCptFeatureless",
  inherit = LearnerCpt,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      super$initialize(
        id = "changepoint.featureless",
        param_set = ps(
          Kmax = p_int(lower = 1L, tags = c("train", "required"))
        ),
        feature_types = "list",
        packages = c("penaltyLearning", "changepoint", "PeakSegOptimal", "PeakError"),
        label = "Featureless Constant Penalty",
        man = "mlr3changepoint::mlr_learners_changepoint.featureless"
      )
    }
  ),

  private = list(
    .train = function(task) {
      Kmax = self$param_set$get_values(tags = "train")$Kmax
      me = cpt_label_errors(task, Kmax)
      best = cpt_constant_penalty(me)

      list(
        log_lambda = best$log_lambda,
        errors = best$errors,
        Kmax = Kmax,
        label_type = task$label_type
      )
    },

    .predict = function(task) {
      cpt_assert_model_label_type(task, self$model)
      cpt_prediction(rep(self$model$log_lambda, task$nrow), self$model$Kmax)
    }
  )
)

#' Constant log(lambda) with the fewest label errors summed over all sequences
#'
#' Each row of `me` adds its `errors` on its half-open selection interval
#' `[min.log.lambda, max.log.lambda)`, the rule `cpt_is_selected()` applies, so
#' the total is a step function that changes only at the finite interval
#' limits. A sweep over those breakpoints gives its value on every step without
#' re-scoring each candidate against every row.
#'
#' @param me (`data.table`)\cr `cpt_label_errors()` output.
#' @return `list(log_lambda, errors)`: the chosen penalty, a point strictly
#'   inside the chosen step, and the total label errors there.
#' @noRd
cpt_constant_penalty = function(me) {
  lo = me[["min.log.lambda"]]
  hi = me[["max.log.lambda"]]
  err = me[["errors"]]

  breaks = sort(unique(c(lo[is.finite(lo)], hi[is.finite(hi)])))
  # Every model is selected on the whole line, so any penalty scores the same.
  if (length(breaks) == 0L) {
    return(list(log_lambda = 0, errors = sum(err)))
  }

  # Total on (-Inf, breaks[1]), then on each [breaks[i], breaks[i + 1]), the last step unbounded.
  n = length(breaks)
  at_breaks = function(x) {
    out = numeric(n)
    f = is.finite(x)
    if (any(f)) {
      s = rowsum(err[f], match(x[f], breaks))
      out[as.integer(rownames(s))] = s[, 1L]
    }
    out
  }
  start = sum(err[lo == -Inf])
  total = c(start, start + cumsum(at_breaks(lo) - at_breaks(hi)))

  inner = if (n > 1L) (breaks[-n] + breaks[-1L]) / 2 else numeric()
  candidates = c(breaks[1L] - 1, inner, breaks[n] + 1)

  ties = which(total == min(total))
  pick = ties[ceiling(length(ties) / 2)]
  list(log_lambda = candidates[pick], errors = total[pick])
}
