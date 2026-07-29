LearnerCptIntRegrCV = R6::R6Class(
  "LearnerCptIntRegrCV",
  inherit = LearnerCpt,
  public = list(
    initialize = function() {
      super$initialize(
        id = "changepoint.intregrcv",
        param_set = ps(
          n.folds = p_int(lower = 2L, tags = "train"),
          fold.vec = p_uty(
            tags = "train",
            custom_check = crate(function(x) {
              checkmate::check_integerish(x, any.missing = FALSE, null.ok = TRUE)
            })
          ),
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
    }
  )
)
