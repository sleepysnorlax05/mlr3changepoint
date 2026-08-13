#' @title Cross-Validated Interval Regression Changepoint Learner
#'
#' @name mlr_learners_changepoint.intregrcv
#'
#' @description
#' Learns a penalty function for changepoint detection from weak labels via
#' [penaltyLearning::IntervalRegressionCV()].
#'
#' At train time, each sequence is summarized into a numeric feature vector and
#' the labels are converted into an interval of admissible `log(lambda)`
#' penalties (the segment path is fitted per sequence, scored against the label
#' regions, and the error curve inverted). The interval regression model then
#' maps features to a penalty inside that interval.
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
#' `"changepoint.intregrcv"`:
#' ```
#' lrn("changepoint.intregrcv")
#' ```
#'
#' @family Learner
#'
#' @examples
#' library(data.table)
#'
#' # Alternate change-bearing and flat sequences so the internal
#' # cross-validation folds always see both target interval kinds.
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
#' learner = lrn("changepoint.intregrcv",
#'   Kmax = 3L, n.folds = 2L, min.observations = 2L
#' )
#' \donttest{
#' set.seed(36)
#' learner$train(task)
#' learner$predict(task)
#' }
#'
#' @export
LearnerCptIntRegrCV = R6::R6Class(
  "LearnerCptIntRegrCV",
  inherit = LearnerCpt,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      super$initialize(
        id = "changepoint.intregrcv",
        param_set = ps(
          n.folds = p_int(lower = 2L, tags = "train"),
          verbose = p_int(lower = 0L, upper = 2L, default = 0L, tags = "train"),
          min.observations = p_int(lower = 1L, default = 10L, tags = "train"),
          reg.type = p_fct(c("min", "1sd"), default = "min", tags = "train"),
          initial.regularization = p_dbl(lower = 0, default = 0.001, tags = "train"),
          margin.vec = p_uty(
            default = 1,
            tags = "train",
            custom_check = crate(function(x) {
              checkmate::check_numeric(x, min.len = 1L, any.missing = FALSE)
            })
          ),
          factor.regularization = p_dbl(lower = 1, default = 1.2, special_vals = list(NULL), tags = "train"),
          Kmax = p_int(lower = 2L, tags = c("train", "required"))
        ),
        feature_types = "list",
        packages = "penaltyLearning",
        label = "Cross-Validated Interval Regression",
        man = "mlr3changepoint::mlr_learners_changepoint.intregrcv"
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

      fit = invoke(
        penaltyLearning::IntervalRegressionCV,
        feature.mat = feature_mat,
        target.mat = target_mat,
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
      parts = cpt_extract_data(task)
      # Replay the train-time feature columns: recomputing the non-finite/constant
      # drop on test data could keep a different set than the fitted weights expect.
      feature_mat = cpt_feature_matrix(parts, cols = self$model$feature_names)
      # predict.IntervalRegression returns an n x 1 matrix of log(penalty).
      pred = predict(self$model$fit, feature_mat)
      list(response = as.numeric(pred))
    }
  )
)
