test_that("predictions carry their Kmax through predict and resample", {
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  learner = lrn("changepoint.xgboost.aft", Kmax = 2L, nrounds = 5L)
  p = learner$train(task)$predict(task)
  expect_equal(p$data$extra$Kmax, rep(2L, task$nrow))

  rr = with_seed(36, resample(task, learner, rsmp("cv", folds = 2L)))
  expect_equal(rr$prediction()$data$extra$Kmax, rep(2L, task$nrow))
  expect_number(rr$aggregate(msr("changepoint.label_error")), lower = 0, upper = 1)
})

test_that("the measure scores a GraphLearner like the bare learner", {
  skip_if_not_installed("mlr3pipelines")
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  measure = msr("changepoint.label_error")
  # Kmax = 1 is far from the n - 2 cap a lost Kmax used to fall back to.
  learner = lrn("changepoint.xgboost.aft", Kmax = 1L, nrounds = 5L)
  graph_learner = as_learner(mlr3pipelines::po("learner", learner))

  bare = learner$train(task)$predict(task)$score(measure, task = task, learner = learner)
  p = graph_learner$train(task)$predict(task)
  expect_equal(p$data$extra$Kmax, rep(1L, task$nrow))
  expect_equal(p$score(measure, task = task, learner = graph_learner), bare)
})

test_that("an AutoTuner tunes Kmax and its prediction carries the chosen cap", {
  skip_if_not_installed("mlr3tuning")
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  task = toy_interval()
  at = mlr3tuning::auto_tuner(
    tuner = mlr3tuning::tnr("grid_search"),
    learner = lrn("changepoint.xgboost.aft", Kmax = to_tune(c(1L, 3L)), nrounds = 5L),
    resampling = rsmp("holdout"),
    measure = msr("changepoint.label_error"),
    term_evals = 2L
  )
  with_seed(36, at$train(task))
  p = at$predict(task)

  tuned = at$tuning_result$learner_param_vals[[1L]]$Kmax
  expect_subset(tuned, c(1L, 3L))
  expect_equal(p$data$extra$Kmax, rep(tuned, task$nrow))
  expect_number(p$score(msr("changepoint.label_error"), task = task), lower = 0, upper = 1)
})

test_that("benchmark results aggregate the measure and convert for mlr3benchmark", {
  skip_if_not_installed("mlr3benchmark")
  skip_if_not_installed("xgboost")
  skip_if_not_installed("penaltyLearning")
  skip_if_not_installed("changepoint")

  learners = list(
    lrn("changepoint.xgboost.aft", id = "aft_k1", Kmax = 1L, nrounds = 5L),
    lrn("changepoint.xgboost.aft", id = "aft_k3", Kmax = 3L, nrounds = 5L)
  )
  design = benchmark_grid(list(toy_interval(), toy_conflict()), learners, rsmp("holdout"))
  bmr = with_seed(36, benchmark(design))
  measure = msr("changepoint.label_error")

  aggr = bmr$aggregate(measure)
  expect_numeric(aggr[["changepoint.label_error"]], lower = 0, upper = 1, any.missing = FALSE, len = 4L)

  ba = mlr3benchmark::as_benchmark_aggr(bmr, measures = measure)
  expect_r6(ba, "BenchmarkAggr")
  expect_equal(nrow(ba$data), 4L)
})
