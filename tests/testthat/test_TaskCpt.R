test_that("construction works", {
  expect_silent({
    task = toy()
  })
  expect_r6(task, "TaskCpt")
  expect_equal(task$task_type, "changepoint")
  expect_equal(task$nrow, 2L)
})

test_that("sequence column role is set", {
  task = toy()
  expect_equal(task$col_roles$sequence, "seq")
  expect_true("seq" %nin% task$col_roles$feature)
  expect_equal(task$col_roles$target, "label")
})

test_that("label_type is stored and readable", {
  expect_equal(toy("changepoint")$label_type, "changepoint")
  expect_equal(toy("peak")$label_type, "peak")
})

test_that("invalid label_type errors", {
  expect_error(toy("invalid"), "label_type")
})

test_that("truth returns the label tables", {
  truth = toy()$truth()
  expect_list(truth$label, len = 2L)
})

test_that("clone preserves label_type", {
  task = toy("peak")
  expect_equal(task$clone(deep = TRUE)$label_type, "peak")
})
