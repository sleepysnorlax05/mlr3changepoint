
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mlr3changepoint

<!-- badges: start -->

[![r-cmd-check](https://github.com/sleepysnorlax05/mlr3changepoint/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/sleepysnorlax05/mlr3changepoint/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/github/sleepysnorlax05/mlr3changepoint/graph/badge.svg?token=AGF9QGIRKY)](https://codecov.io/github/sleepysnorlax05/mlr3changepoint)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![StackOverflow](https://img.shields.io/badge/stackoverflow-mlr3-orange.svg)](https://stackoverflow.com/questions/tagged/mlr3)
[![Mattermost](https://img.shields.io/badge/chat-mattermost-orange.svg)](https://lmmisld-lmu-stats-slds.srv.mwn.de/mlr_invite/)
<!-- badges: end -->

*mlr3changepoint* extends the [mlr3](https://github.com/mlr-org/mlr3)
ecosystem with **weakly supervised change point detection**. It
registers a new `"changepoint"` task type together with the surrounding
infrastructure — tasks, learners, and prediction objects — so that
change point detectors can be trained, resampled, and benchmarked with
the standard mlr3 machinery.

Unlike classical, fully supervised detection, *weak supervision* means
the targets are **labelled regions** of a sequence rather than a label
for every observation. Each label is an interval `(start, end, label)`
marking a stretch of the sequence that should contain a given number of
changes (e.g. `"1change"`) or a peak. This is the setup used by
[penaltyLearning](https://cran.r-project.org/package=penaltyLearning)
and related peak-detection work.

> **Note** This package is under active development as part of Google
> Summer of Code 2026. The API is experimental and may change.

## Installation

*mlr3changepoint* is not yet on CRAN. Install the development version
from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("sleepysnorlax05/mlr3changepoint")
```

## Feature Overview

The package adds a `"changepoint"` task type to mlr3’s reflections,
supporting two flavours of weak labels, selected via `label_type`:

- `"changepoint"` — regions annotated with the number of changes they
  contain (penaltyLearning-style).
- `"peak"` — regions annotated as peak or background (peak-detection
  style).

The current building blocks:

| Class | Role | Status |
|:---|:---|:---|
| `TaskCpt` | Weakly supervised change point task — one row per labelled sequence | Available |
| `LearnerCpt` | Abstract base class for change point learners | Base class |
| `PredictionCpt` / `MeasureCpt` | Prediction container and evaluation measures | Planned |

## Task Structure

A `TaskCpt` stores **one row per labelled sequence** and uses two
special column roles:

- a **`sequence`** column holding the raw signal (a list column, one
  numeric vector per sequence);
- a **`target`** list column, where each entry is a
  `data.table(start, end, label)` of labelled regions.

`task$truth()` returns the labelled regions and `task$label_type`
reports whether the task carries `"changepoint"` or `"peak"` labels.

## Example

``` r
library(mlr3changepoint)
#> Loading required package: mlr3
#> Warning: package 'mlr3' was built under R version 4.4.3
library(data.table)

# one row per sequence: the first has two labelled changes, the second none
set.seed(36)
toy = data.table(
  seq = list(
    c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9)),
    rnorm(100, 0)
  ),
  label = list(
    data.table(start = c(90, 190), end = c(110, 210), label = c("1change", "1change")),
    data.table(start = 1, end = 100, label = "0changes")
  )
)

task = TaskCpt$new(
  id = "toy", backend = toy,
  target = "label", sequence = "seq", label_type = "changepoint"
)
task
#> 
#> ── <TaskCpt> (2x1) ─────────────────────────────────────────────────────────────────────────────────
#> • Target: label
#> • Properties: -

# the weak labels: one set of regions per sequence
task$truth()
#>                label
#> 1: <data.table[2x3]>
#> 2: <data.table[1x3]>

# which kind of labels this task carries
task$label_type
#> [1] "changepoint"
```

## Bugs, Questions, Feedback

*mlr3changepoint* is a free and open source software project that
encourages participation and feedback. If you have any issues,
questions, suggestions, or feedback, please do not hesitate to open an
issue in the [issue
tracker](https://github.com/sleepysnorlax05/mlr3changepoint/issues). In
order to reproduce issues please use a
[reprex](https://reprex.tidyverse.org/).

For general questions about the mlr3 ecosystem, the
[mlr3book](https://mlr3book.mlr-org.com/) and the [mlr-org community
channels](https://stackoverflow.com/questions/tagged/mlr3) are good
starting points.

## Related Work

Change point detection has a rich ecosystem in R. *mlr3changepoint*
builds on and interfaces several of these packages rather than replacing
them:

- [changepoint](https://cran.r-project.org/package=changepoint) —
  mainstream and specialised methods for detecting single and multiple
  change points (PELT, binary segmentation, and more).
- [binsegRcpp](https://cran.r-project.org/package=binsegRcpp) —
  efficient C++ binary segmentation, log-linear on average and quadratic
  in the worst case.
- [fpop](https://cran.r-project.org/package=fpop) — optimal partitioning
  with functional pruning for fast segmentation of univariate signals
  into piecewise-constant profiles.
- [dust](https://github.com/vrunge/dust) — optimal partitioning with the
  DUST (“DUality Simple Test”) pruning rule, a recent alternative to
  PELT and FPOP.
- [penaltyLearning](https://cran.r-project.org/package=penaltyLearning)
  — supervised penalty learning for change point detection, and the
  source of the labelled-region (weak supervision) setup used here.
- [rupturesRcpp](https://cran.r-project.org/package=rupturesRcpp) —
  object-oriented Rcpp interface to popular offline change-point
  algorithms (an R counterpart to Python’s `ruptures`).
- the **PeakSeg** family
  ([PeakSegOptimal](https://cran.r-project.org/package=PeakSegOptimal),
  PeakSegDisk, PeakSegJoint) — optimal peak detection via up-down
  constrained changepoint models, used for the `"peak"` label type.

## Acknowledgements

*mlr3changepoint* is developed as part of [Google Summer of Code
2026](https://summerofcode.withgoogle.com/) under the [R Project for
Statistical Computing](https://www.r-project.org/). Special thanks to
mentors Toby Hocking, Marc Becker and Tung Lam Nguyen for their
guidance, and to the [mlr-org](https://github.com/mlr-org) team for
designing and maintaining the mlr3 ecosystem that this package extends.
