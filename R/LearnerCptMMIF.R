#' @title Max Margin Interval Forest Changepoint Learner
#'
#' @name mlr_learners_changepoint.mmif
#'
#' @description
#' Learns a penalty function for changepoint detection from weak labels via a
#' max margin interval forest, [mmit::mmif()]: [mmit::mmit()] trees grown on
#' bootstrap samples and random feature subsets, with their predictions averaged.
#'
#' At train time, each sequence is summarized into a numeric feature vector and
#' the labels are converted into an interval of admissible `log(lambda)`
#' penalties (the segment path is fitted per sequence, scored against the label
#' regions, and the error curve inverted). The trees fit these interval targets
#' directly with a hinge loss, so unlike [mlr_learners_changepoint.intregrcv] it
#' also trains when no label gives a finite lower (or upper) penalty limit.
#'
#' At predict time, the learner returns `response`, the predicted `log(lambda)`
#' per sequence.
#'
#' The label solvers are chosen by the task's `label_type`:
#' `"changepoint"` uses [changepoint::cpt.mean()], `"peak"` uses
#' [PeakSegOptimal::PeakSegPDPAchrom()].
#'
#' The 'mmit' package is not on CRAN. The upstream sources no longer compile with
#' current C++ toolchains on macOS and Windows, so install the patched copy with
#' `pak::pak("sleepysnorlax05/mmit/Rpackage")`.
#'
#' @section Dictionary:
#' This learner can be retrieved via [mlr3::mlr_learners] with the key
#' `"changepoint.mmif"`:
#' ```
#' lrn("changepoint.mmif")
#' ```
#'
#' @section Parameters:
#' `Kmax` (`integer(1)`, required) caps model complexity: the maximum number of
#' changepoints (`label_type = "changepoint"`) or peaks (`label_type = "peak"`)
#' the per-sequence segment path is searched over. The learner uses it to build
#' the target penalty intervals at train time and does not forward it to the
#' solver. Each prediction records it per sequence in its `extra` data
#' (`as.data.table(prediction)$Kmax`), so the label-error measure decodes the
#' predicted penalty under the same cap.
#'
#' `max_depth` (`integer(1)`, default `Inf` for unlimited depth), `margin`,
#' `n_trees` and `n_features` are passed to [mmit::mmif()]; see there for their
#' meaning. `n_features` defaults to `ceiling(sqrt(p))` for `p` usable features
#' and must be at least 2. As for [mlr_learners_changepoint.mmit], `loss` and
#' `min_sample` are not exposed because they do not change the fitted trees.
#'
#' The trees are grown with `future.apply::future_lapply()`, so they run in
#' parallel under the active `future::plan()`. `future.seed = TRUE` is fixed, so
#' the fit is reproducible under [set.seed()].
#'
#' @family Learner
#'
#' @examplesIf mlr3misc::require_namespaces(c("mmit", "future.apply", "penaltyLearning", "changepoint"), quietly = TRUE)
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
#' learner = lrn("changepoint.mmif", Kmax = 3L)
#' \donttest{
#' set.seed(36)
#' learner$train(task)
#' learner$predict(task)
#' }
#'
#' @export
LearnerCptMMIF = R6::R6Class(
  "LearnerCptMMIF",
  inherit = LearnerCpt,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      super$initialize(
        id = "changepoint.mmif",
        param_set = ps(
          max_depth = p_int(lower = 0L, special_vals = list(Inf), default = Inf, tags = "train"),
          margin = p_dbl(lower = 0, default = 0, tags = "train"),
          n_trees = p_int(lower = 1L, default = 10L, tags = "train"),
          n_features = p_int(lower = 2L, tags = "train"),
          Kmax = p_int(lower = 1L, tags = c("train", "required"))
        ),
        feature_types = "list",
        packages = c("mmit", "future.apply", "penaltyLearning", "changepoint", "PeakSegOptimal", "PeakError"),
        label = "Max Margin Interval Forest",
        man = "mlr3changepoint::mlr_learners_changepoint.mmif"
      )
    }
  ),

  private = list(
    .train = function(task) {
      pv = self$param_set$get_values(tags = "train")

      Kmax = pv$Kmax
      pv$Kmax = NULL

      parts = cpt_extract_data(task)
      feature_mat = cpt_feature_matrix(parts)
      target_mat = cpt_target_intervals(task, Kmax)
      if (!any(is.finite(target_mat))) {
        stopf("labels give no finite penalty limit; every target interval is (-Inf, Inf)")
      }
      # mmif() asserts this deep inside; the usable columns depend on the training rows.
      if (!is.null(pv$n_features) && pv$n_features > ncol(feature_mat)) {
        stopf("n_features (%i) exceeds the %i usable features", pv$n_features, ncol(feature_mat))
      }

      # mmif() grows its trees with future.apply::future_lapply(). future.seed = TRUE
      # gives each tree a parallel-safe RNG stream drawn from the session seed, so
      # set.seed() reproduces the fit; the default FALSE warns about unreliable numbers.
      fit = invoke(
        mmit::mmif,
        feature.mat = cpt_mmit_frame(feature_mat),
        target.mat = target_mat,
        future.seed = TRUE,
        .args = pv
      )

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
      # predict.mmif averages the per-tree mmit predictions on the log(lambda) scale.
      pred = mmit::predict.mmif(self$model$fit, cpt_mmit_frame(feature_mat))
      cpt_prediction(pred, self$model$Kmax)
    }
  )
)
