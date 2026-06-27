test_that("construction sets the changepoint contract", {
  learner = LearnerCpt$new(id = "test")
  expect_r6(learner, c("LearnerCpt", "Learner"))
  expect_equal(learner$task_type, "changepoint")
  expect_equal(learner$predict_types, "response")
  expect_true("mlr3changepoint" %in% learner$packages)
})

test_that("defaults are empty or NA", {
  learner = LearnerCpt$new(id = "test")
  expect_equal(learner$feature_types, character())
  expect_equal(learner$properties, character())
  expect_true(is.na(learner$label))
  expect_true(is.na(learner$man))
})

test_that("constructor forwards arguments for subclasses", {
  learner = LearnerCpt$new(
    id = "fwd",
    properties = "missings",
    packages = "penaltyLearning",
    label = "Demo"
  )
  expect_equal(learner$id, "fwd")
  expect_true("missings" %in% learner$properties)
  expect_true(all(c("mlr3changepoint", "penaltyLearning") %in% learner$packages))
  expect_equal(learner$label, "Demo")
})

test_that("the abstract base cannot train", {
  learner = LearnerCpt$new(id = "test")
  expect_error(learner$train(toy()))
})
