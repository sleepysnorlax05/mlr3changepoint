toy = function(label_type = "changepoint") {
  backend = with_seed(36, { # nolint: object_usage_linter.
    data.table::data.table(
      signal = list(
        c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9)),
        rnorm(100, 0)
      ),
      label = list(
        data.table::data.table(
          start = c(90, 190),
          end = c(110, 210),
          label = c("1change", "1change")
        ),
        data.table::data.table(start = 1, end = 100, label = "0changes")
      )
    )
  })
  TaskCpt$new(
    id = "toy",
    backend = backend,
    target = "label",
    sequence = "signal",
    label_type = label_type
  )
}

toy_peak = function() {
  backend = with_seed(36, { # nolint: object_usage_linter.
    data.table::data.table(
      signal = list(
        c(rpois(60, 2), rpois(40, 25), rpois(100, 2)),
        rpois(200, 2)
      ),
      label = list(
        data.table::data.table(
          start = c(1, 55),
          end = c(50, 105),
          label = c("noPeaks", "peaks")
        ),
        data.table::data.table(start = 10, end = 190, label = "noPeaks")
      )
    )
  })
  TaskCpt$new(
    id = "toy_peak",
    backend = backend,
    target = "label",
    sequence = "signal",
    label_type = "peak"
  )
}
