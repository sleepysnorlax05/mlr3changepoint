# Getting started

This page installs `mlr3changepoint` and runs a first workflow, from
labelled sequences to a trained learner, its predictions and their
scores.

## What the package does

A changepoint model splits a sequence into segments. How many segments
it keeps depends on a penalty: a small penalty keeps many changes and a
large one keeps few. `mlr3changepoint` learns that penalty from labelled
examples, one value per sequence, as a function of features of the
sequence.

The labels are weak. Each one marks a region of a sequence and says how
many changes it should contain, for example `1change` on positions 90 to
110 or `0changes` on a flat stretch. A label does not give the position
of a change or a value for each point. Peaks in count data work the same
way, with labels such as `peaks` and `noPeaks`.

The package adds a `"changepoint"` task type to mlr3, so its tasks,
learners and measures work with
[`resample()`](https://mlr3.mlr-org.com/reference/resample.html),
[`benchmark()`](https://mlr3.mlr-org.com/reference/benchmark.html) and
the tuning packages.

## Installation

The package is on GitHub. Install it with pak or remotes.
`dependencies = TRUE` also installs the solvers and regressors the
learners use, which are suggested packages.

``` r

# install.packages("pak")
pak::pak("sleepysnorlax05/mlr3changepoint", dependencies = TRUE)

# or with remotes
# install.packages("remotes")
remotes::install_github("sleepysnorlax05/mlr3changepoint", dependencies = TRUE)
```

The MMIT and MMIF learners need the mmit package, which is not on CRAN.
The upstream sources no longer compile on macOS and Windows, so the
package points to a patched copy, which both commands above install. To
install it on its own:

``` r

pak::pak("sleepysnorlax05/mmit/Rpackage")
```

## A first workflow

Load mlr3, the package and data.table. ggplot2 provides
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html).

``` r

library(mlr3)
library(mlr3changepoint)
library(data.table)
library(ggplot2)
```

### A task

The toy data has ten sequences. The odd ones change mean twice, at
positions 100 and 200, and carry a `1change` label around each change.
The even ones are flat noise with one `0changes` label.

``` r

set.seed(36)
signal = vector("list", 10L)
label = vector("list", 10L)
for (i in seq_len(10L)) {
  if (i %% 2L == 1L) {
    signal[[i]] = c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9))
    label[[i]] = data.table(start = c(90, 190), end = c(110, 210), label = "1change")
  } else {
    signal[[i]] = rnorm(100, 0)
    label[[i]] = data.table(start = 1, end = 100, label = "0changes")
  }
}
```

A `TaskCpt` has one row per sequence. The `sequence` column holds the
signal, and the target column holds a table of labelled regions for each
sequence.

``` r

task = TaskCpt$new(
  id = "toy", backend = data.table(signal = signal, label = label),
  target = "label", sequence = "signal", label_type = "changepoint"
)
task
#> 
#> ── <TaskCpt> (10x1) ────────────────────────────────────────────────────────────
#> • Target: label
#> • Properties: -
```

[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
draws each sequence in its own panel, with the labelled regions shaded.

``` r

autoplot(task)
```

![Ten panels, one per sequence. Odd sequences step up near position 100
and down near 200, with a shaded 1change region around each step. Even
sequences are flat noise shaded as
0changes.](getting-started_files/figure-html/unnamed-chunk-6-1.png)

### Training and prediction

`changepoint.intregrcv` fits a linear model of the log penalty with
[`penaltyLearning::IntervalRegressionCV()`](https://rdrr.io/pkg/penaltyLearning/man/IntervalRegressionCV.html).
`Kmax = 3` lets each sequence have up to three changes. With only ten
sequences, the internal cross-validation uses two folds and accepts
small training sets.

``` r

learner = lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L)
learner$train(task)
prediction = learner$predict(task)
prediction
#> 
#> ── <PredictionCpt> for 10 observations: ────────────────────────────────────────
#>  row_ids             truth  response Kmax
#>        1 <data.table[2x3]> -2.153109    3
#>        2 <data.table[1x3]>  3.619413    3
#>        3 <data.table[2x3]> -2.173955    3
#>      ---               ---       ---  ---
#>        8 <data.table[1x3]>  2.823117    3
#>        9 <data.table[2x3]> -2.064941    3
#>       10 <data.table[1x3]>  3.137978    3
```

The prediction holds one value per sequence: the predicted
`log(lambda)`. It also records the `Kmax` the learner was trained with,
which the measures and plots need to rebuild the segmentation.

``` r

as.data.table(prediction)
#>     row_ids             truth  response  Kmax
#>       <int>            <list>     <num> <int>
#>  1:       1 <data.table[2x3]> -2.153109     3
#>  2:       2 <data.table[1x3]>  3.619413     3
#>  3:       3 <data.table[2x3]> -2.173955     3
#>  4:       4 <data.table[1x3]>  3.057015     3
#>  5:       5 <data.table[2x3]> -1.930518     3
#>  6:       6 <data.table[1x3]>  3.668863     3
#>  7:       7 <data.table[2x3]> -2.115320     3
#>  8:       8 <data.table[1x3]>  2.823117     3
#>  9:       9 <data.table[2x3]> -2.064941     3
#> 10:      10 <data.table[1x3]>  3.137978     3
```

### Scoring

The label error is the share of labelled regions the segmentation gets
wrong. The AUC is the area under the ROC curve. Both measures rebuild
the segmentation from the sequences, so they need the task.

``` r

prediction$score(msrs(c("changepoint.label_error", "changepoint.auc")), task = task)
#> changepoint.label_error         changepoint.auc 
#>                       0                       1
```

These scores are on the training sequences. The [Evaluation and
plots](https://sleepysnorlax05.github.io/mlr3changepoint/articles/evaluation.md)
chapter scores held-out sequences with
[`resample()`](https://mlr3.mlr-org.com/reference/resample.html).

### Plots

Given the task,
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html) of
a prediction adds the changes selected by each predicted penalty as
dashed lines.

``` r

autoplot(prediction, task = task)
```

![The ten sequences with their labelled regions and dashed vertical
lines at the predicted
changes.](getting-started_files/figure-html/unnamed-chunk-10-1.png)

`type = "roc"` draws the ROC curve instead. The dot marks the predicted
penalties.

``` r

autoplot(prediction, task = task, type = "roc")
```

![ROC curve of the true positive rate against the false positive rate,
with a dot at the predicted
penalties.](getting-started_files/figure-html/unnamed-chunk-11-1.png)

## Next steps

The
[Documentation](https://sleepysnorlax05.github.io/mlr3changepoint/articles/documentation.md)
covers tasks and labels, the learners, and evaluation. [Case
studies](https://sleepysnorlax05.github.io/mlr3changepoint/articles/case-studies.md)
has longer examples on copy-number profiles, peaks in count data and a
benchmark of the learners.
