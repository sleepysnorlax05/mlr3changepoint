toy = function(label_type = "changepoint") {
  backend = data.table::data.table(
    seq = list(rnorm(100), rnorm(100)),
    label = list(
      data.table::data.table(start = 20, end = 30, label = "1change"),
      data.table::data.table(start = 10, end = 90, label = "0changes")
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
