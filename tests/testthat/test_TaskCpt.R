library(data.table)

cpt_toy = function(label_type = "changepoint") {
  backend = data.table(
    seq = list(rnorm(100), rnorm(100)),
    label = list(
      data.table(start = 20, end = 30, label = "1change"),
      data.table(start = 10, end = 90, label = "0changes")
    )
  )
  TaskCpt$new(
    id = "toy",
    backend = backend,
    target = "label",
    sequence = "seq",
    label_type = label_type
  )
}

test_that("construction works", {
  expect_silent({
    task = cpt_toy()
  })
  expect_r6(task, "TaskCpt")
  expect_equal(task$task_type, "changepoint")
  expect_equal(task$nrow, 2L)
})

test_that("sequence column role is set", {
  task = cpt_toy()
  expect_equal(task$col_roles$sequence, "seq")
  expect_true("seq" %nin% task$col_roles$feature)
  expect_equal(task$col_roles$target, "label")
})

test_that("label_type is stored and readable", {
  expect_equal(cpt_toy("changepoint")$label_type, "changepoint")
  expect_equal(cpt_toy("peak")$label_type, "peak")
})

test_that("invalid label_type errors", {
  expect_error(cpt_toy("invalid"), "label_type")
})

test_that("truth returns the label tables", {
  truth = cpt_toy()$truth()
  expect_list(truth$label, len = 2L)
})

test_that("clone preserves label_type", {
  task = cpt_toy("peak")
  expect_equal(task$clone(deep = TRUE)$label_type, "peak")
})
