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
