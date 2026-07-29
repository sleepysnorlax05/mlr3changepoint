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

#' Larger toy task for learner-level tests.
#'
#' `toy()` / `toy_peak()` carry two sequences, which is enough to exercise the
#' cpt_* helpers but not a learner: IntervalRegressionCV needs at least
#' `min.observations` rows, and every CV fold needs at least one finite lower
#' and one finite upper limit. Labelled sequences give a finite upper limit only
#' and unlabelled-change ones a finite lower limit only, so the two kinds are
#' alternated to keep both present in any fold split.
toy_many = function(label_type = "changepoint", n_pairs = 6L) {
  backend = with_seed(36, { # nolint: object_usage_linter.
    parts = lapply(seq_len(n_pairs), function(i) {
      if (label_type == "peak") {
        # Poisson counts: PeakSegPDPAchrom needs non-negative integers.
        with_peak = c(rpois(60, 2), rpois(40, 20 + i), rpois(100, 2))
        flat = rpois(200, 2)
        list(
          signal = list(with_peak, flat),
          label = list(
            data.table::data.table(
              start = c(1, 55),
              end = c(50, 105),
              label = c("noPeaks", "peaks")
            ),
            data.table::data.table(start = 10, end = 190, label = "noPeaks")
          )
        )
      } else {
        with_change = c(rnorm(100, 10 + i), rnorm(100, 30 + i))
        flat = rnorm(200, i)
        list(
          signal = list(with_change, flat),
          label = list(
            # Two labels: the 1change region bounds the penalty from above, the
            # flat 0changes region bounds it from below, so this row carries a
            # finite limit on both ends and any fold split stays solvable.
            data.table::data.table(
              start = c(90, 130),
              end = c(110, 190),
              label = c("1change", "0changes")
            ),
            data.table::data.table(start = 1, end = 200, label = "0changes")
          )
        )
      }
    })
    data.table::data.table(
      signal = unlist(lapply(parts, `[[`, "signal"), recursive = FALSE),
      label = unlist(lapply(parts, `[[`, "label"), recursive = FALSE)
    )
  })
  TaskCpt$new(
    id = "toy_many",
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

toy_weighted = function() {
  task = toy()
  task$cbind(data.table::data.table(w = c(1, 2)))
  task$set_col_roles("w", roles = "weights_measure")
  task
}
