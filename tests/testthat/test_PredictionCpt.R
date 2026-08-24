test_that("PredictionCpt constructs from a task", {
  task = toy()
  p = PredictionCpt$new(task = task, response = c(1.5, 2.5))

  expect_prediction(p)
  expect_s3_class(p, "PredictionCpt")
  expect_equal(p$row_ids, task$row_ids)
  expect_equal(p$response, c(1.5, 2.5))

  tab = as.data.table(p)
  expect_equal(nrow(tab), 2L)
  expect_true(all(vapply(tab$truth, inherits, logical(1), "data.table")))
})

test_that("check_prediction_data rejects a response length mismatch", {
  expect_error(PredictionCpt$new(task = toy(), response = 1.5), "length")
})

test_that("filtered halves combine back with c()", {
  task = toy()
  p = PredictionCpt$new(task = task, response = c(1.5, 2.5))
  ids = task$row_ids

  a = filter_prediction_data(p$data, ids[1L])
  b = filter_prediction_data(p$data, ids[2L])
  cc = c(a, b)

  expect_equal(cc$row_ids, ids)
  expect_equal(cc$response, c(1.5, 2.5))
  expect_prediction(as_prediction(cc))
})

test_that("c() drops duplicates when asked", {
  task = toy()
  p = PredictionCpt$new(task = task, response = c(1.5, 2.5))

  cc = c(p$data, p$data, keep_duplicates = FALSE)
  expect_equal(cc$row_ids, task$row_ids)
  expect_equal(cc$response, c(1.5, 2.5))
})

test_that("missing responses are reported by row id", {
  task = toy()
  p = PredictionCpt$new(task = task, response = c(1.5, NA))
  expect_equal(p$missing, task$row_ids[2L])
})

test_that("empty prediction data starts blank", {
  task = toy()
  learner = LearnerCpt$new(id = "test")
  pdata = create_empty_prediction_data(task, learner)

  expect_s3_class(pdata, "PredictionDataCpt")
  expect_equal(pdata$row_ids, integer())
  expect_equal(pdata$response, numeric())
  expect_equal(is_missing_prediction_data(pdata), integer())
})

test_that("c() passes a single element through and rejects mixed types", {
  task = toy()
  p = PredictionCpt$new(task = task, response = c(1.5, 2.5))

  expect_identical(c(p$data), p$data)

  bare = p$data
  bare$response = NULL
  expect_error(c(p$data, bare), "different")
})

test_that("weights survive the prediction data round trip", {
  task = toy_weighted()
  pdata = as_prediction_data(
    list(response = c(1.5, 2.5)),
    task = task, row_ids = task$row_ids, train_task = task
  )
  expect_equal(pdata$weights, c(1, 2))

  p = as_prediction(pdata)
  expect_prediction(p)
  expect_equal(p$weights, c(1, 2))
  expect_equal(as.data.table(p)$weights, c(1, 2))
})

test_that("filter subsets weights and extra", {
  task = toy_weighted()
  p = PredictionCpt$new(task = task, response = c(1.5, 2.5), weights = c(1, 2),
    extra = list(iters = c(10L, 20L)))

  f = filter_prediction_data(p$data, task$row_ids[2L])
  expect_equal(f$row_ids, task$row_ids[2L])
  expect_equal(f$weights, 2)
  expect_equal(f$extra$iters, 20L)
})

test_that("c() rejects a partial weights or extra", {
  task = toy_weighted()
  weighted = PredictionCpt$new(task = task, response = c(1.5, 2.5), weights = c(1, 2))$data
  plain = PredictionCpt$new(task = task, response = c(1.5, 2.5))$data

  expect_error(c(weighted, plain), "some have 'weights'")
})

test_that("c() keeps weights aligned when dropping duplicates", {
  task = toy_weighted()
  p = PredictionCpt$new(task = task, response = c(1.5, 2.5), weights = c(1, 2))

  cc = c(p$data, p$data, keep_duplicates = FALSE)
  expect_equal(cc$row_ids, task$row_ids)
  expect_equal(cc$weights, c(1, 2))
})

test_that("check_prediction_data validates the truth regions", {
  task = toy()
  valid = data.table(start = 1, end = 100, label = "0changes")

  bad_type = list(data.table(start = "90", end = "110", label = "1change"), valid)
  expect_error(
    PredictionCpt$new(task = task, truth = bad_type, response = c(1.5, 2.5)),
    "start"
  )

  bad_order = list(data.table(start = 200, end = 100, label = "1change"), valid)
  expect_error(
    PredictionCpt$new(task = task, truth = bad_order, response = c(1.5, 2.5)),
    "start > end"
  )
})

test_that("empty prediction data carries weights and survives every method", {
  task = toy_weighted()
  pdata = create_empty_prediction_data(task, LearnerCpt$new(id = "test"))

  expect_equal(pdata$weights, numeric())
  expect_silent(check_prediction_data(pdata))
  expect_equal(filter_prediction_data(pdata, integer())$row_ids, integer())
  expect_equal(is_missing_prediction_data(pdata), integer())
})
