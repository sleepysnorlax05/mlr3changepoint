#' @title Extreme Gradient Boosting AFT Changepoint Learner
#'
#' @name mlr_learners_changepoint.xgboost.aft
#'
#' @description
#' Learns a penalty function for changepoint detection from weak labels via
#' gradient boosted trees with the accelerated failure time objective
#' (`objective = "survival:aft"`) of [xgboost::xgb.train()].
#'
#' At train time, each sequence is summarized into a numeric feature vector and
#' the labels are converted into an interval of admissible `log(lambda)`
#' penalties (the segment path is fitted per sequence, scored against the label
#' regions, and the error curve inverted). The AFT loss fits these
#' interval-censored targets directly, so unlike
#' [mlr_learners_changepoint.intregrcv] it also trains when no label gives a
#' finite lower (or upper) penalty limit.
#'
#' At predict time, the learner returns `response`, the predicted `log(lambda)`
#' per sequence.
#'
#' The label solvers are chosen by the task's `label_type`:
#' `"changepoint"` uses [changepoint::cpt.mean()], `"peak"` uses
#' [PeakSegOptimal::PeakSegPDPAchrom()].
#'
#' @section Dictionary:
#' This learner can be retrieved via [mlr3::mlr_learners] with the key
#' `"changepoint.xgboost.aft"`:
#' ```
#' lrn("changepoint.xgboost.aft")
#' ```
#'
#' @section Parameters:
#' `Kmax` (`integer(1)`, required) caps model complexity: the maximum number of
#' changepoints (`label_type = "changepoint"`) or peaks (`label_type = "peak"`)
#' the per-sequence segment path is searched over, applied identically at train
#' and predict time. The learner consumes it to build the target penalty
#' intervals; it is not forwarded to the solver. Each prediction records it per
#' sequence in its `extra` data (`as.data.table(prediction)$Kmax`), so the
#' label-error measure decodes the predicted penalty under the same cap.
#'
#' `nrounds` (`integer(1)`, required) is the number of boosting rounds,
#' initialized to `100`. `nthread` is initialized to `1`. The remaining
#' parameters are passed to [xgboost::xgb.train()] in its `params` list; see
#' there for their meaning and defaults.
#'
#' @family Learner
#'
#' @examplesIf mlr3misc::require_namespaces(c("xgboost", "penaltyLearning", "changepoint"), quietly = TRUE)
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
#' learner = lrn("changepoint.xgboost.aft", Kmax = 3L)
#' \donttest{
#' learner$train(task)
#' learner$predict(task)
#' }
#'
#' @export
LearnerCptXGBoostAFT = R6::R6Class(
  "LearnerCptXGBoostAFT",
  inherit = LearnerCpt,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      super$initialize(
        id = "changepoint.xgboost.aft",
        param_set = ps(
          nrounds = p_int(lower = 1L, init = 100L, tags = c("train", "required")),
          aft_loss_distribution = p_fct(c("normal", "logistic", "extreme"), default = "normal", tags = "train"),
          aft_loss_distribution_scale = p_dbl(lower = 0, default = 1, tags = "train"),
          eta = p_dbl(lower = 0, upper = 1, default = 0.3, tags = "train"),
          max_depth = p_int(lower = 0L, default = 6L, tags = "train"),
          min_child_weight = p_dbl(lower = 0, default = 1, tags = "train"),
          nthread = p_int(lower = 1L, init = 1L, tags = c("train", "threads")),
          Kmax = p_int(lower = 1L, tags = c("train", "required"))
        ),
        feature_types = "list",
        packages = c("xgboost", "penaltyLearning", "changepoint", "PeakSegOptimal", "PeakError"),
        label = "Extreme Gradient Boosting AFT",
        man = "mlr3changepoint::mlr_learners_changepoint.xgboost.aft"
      )
    }
  ),

  private = list(
    .train = function(task) {
      pv = self$param_set$get_values(tags = "train")

      Kmax = pv$Kmax
      nrounds = pv$nrounds
      pv$Kmax = NULL
      pv$nrounds = NULL

      parts = cpt_extract_data(task)
      feature_mat = cpt_feature_matrix(parts)
      target_mat = cpt_target_intervals(task, Kmax)
      if (!any(is.finite(target_mat))) {
        stopf("labels give no finite penalty limit; every target interval is (-Inf, Inf)")
      }

      # survival:aft takes interval-censored labels on the time scale, so exp() maps
      # each log(lambda) limit there: an open lower limit becomes 0 (left-censored)
      # and an open upper limit stays Inf (right-censored).
      dtrain = xgboost::xgb.DMatrix(
        feature_mat,
        label_lower_bound = exp(target_mat[, "min.log.lambda"]),
        label_upper_bound = exp(target_mat[, "max.log.lambda"]),
        nthread = pv$nthread
      )
      pv$objective = "survival:aft"
      fit = xgboost::xgb.train(params = pv, data = dtrain, nrounds = nrounds, verbose = 0)

      list(
        fit = fit,
        feature_names = colnames(feature_mat),
        Kmax = Kmax,
        label_type = task$label_type
      )
    },

    .predict = function(task) {
      cpt_assert_model_label_type(task, self$model)
      parts = cpt_extract_data(task)
      feature_mat = cpt_feature_matrix(parts, cols = self$model$feature_names)
      # The AFT margin is the predicted log(time), which here is log(lambda) itself.
      pred = predict(self$model$fit, feature_mat, outputmargin = TRUE)
      cpt_prediction(pred, self$model$Kmax)
    }
  )
)
