# Learners

This chapter explains what the four learners share, where they differ
and which hyperparameters they take. Every learner predicts one penalty,
`log(lambda)`, per sequence.

``` r

library(mlr3)
library(mlr3changepoint)
library(data.table)
```

## The shared pipeline

All four learners train the same way up to the regressor.

1.  Features.
    [`penaltyLearning::featureVector()`](https://rdrr.io/pkg/penaltyLearning/man/featureVector.html)
    summarises each sequence as a numeric vector: its length and
    statistics such as quantiles and variance estimates of the signal
    and its differences. Training drops columns that are not finite or
    are constant, and prediction uses the same columns.
2.  Model path. For each sequence, a solver fits the best model of each
    complexity up to `Kmax`. Changepoint tasks use
    `changepoint::cpt.mean(method = "SegNeigh")`, which minimises the
    square loss for 0 to `Kmax` changes. Peak tasks use
    [`PeakSegOptimal::PeakSegPDPAchrom()`](https://rdrr.io/pkg/PeakSegOptimal/man/PeakSegPDPAchrom.html),
    which minimises the Poisson loss for 0 to `Kmax` peaks.
3.  Model selection.
    [`penaltyLearning::modelSelection()`](https://rdrr.io/pkg/penaltyLearning/man/modelSelection.html)
    finds the range of `log(lambda)` over which each model is selected.
4.  Label errors.
    [`penaltyLearning::labelError()`](https://rdrr.io/pkg/penaltyLearning/man/labelError.html)
    for changepoint labels, or
    [`PeakError::PeakError()`](https://rdrr.io/pkg/PeakError/man/PeakError.html)
    for peak labels, counts the false positives and false negatives of
    each model.
5.  Target intervals.
    [`penaltyLearning::targetIntervals()`](https://rdrr.io/pkg/penaltyLearning/man/targetIntervals.html)
    gives each sequence the interval of `log(lambda)` values with the
    fewest label errors. If the fewest errors are reached on several
    separate intervals, it keeps the widest. One end of the interval may
    be infinite.
6.  Regression. The regressor maps the features to the target intervals.

At prediction time, the learner computes the same features and returns
the regressor’s `log(lambda)`. The measures and
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
rebuild the model path and pick the model that penalty selects.

## The four learners

| Learner | Regressor | Package |
|----|----|----|
| `changepoint.intregrcv` | Linear model with L1 regularisation and a squared hinge loss on the intervals, with the regularisation chosen by cross-validation | penaltyLearning |
| `changepoint.xgboost.aft` | Gradient boosted trees with the accelerated failure time loss for interval-censored targets | xgboost |
| `changepoint.mmit` | Maximum margin interval tree | mmit |
| `changepoint.mmif` | Forest of maximum margin interval trees grown on bootstrap samples and random feature subsets | mmit |

The linear model needs training labels that give at least one finite
lower limit and at least one finite upper limit. Without them it stops
with an error. The three tree-based learners train as long as one limit
is finite.

## Hyperparameters

Every learner requires `Kmax`. It caps model complexity: the largest
number of changes (changepoint labels) or peaks (peak labels) on each
model path, at training and at prediction. A penalty that would select a
more complex model selects instead the best model with at most `Kmax`
changes or peaks at that penalty. This is often, but not always, the
`Kmax` model: when the `Kmax` model lowers the loss only a little, a
simpler one can win. Set it at least as large as the number of changes a
labelled sequence needs. A larger `Kmax` makes each path slower to
compute.

| Learner | Other hyperparameters |
|----|----|
| `changepoint.intregrcv` | `n.folds`, `min.observations`, `reg.type`, `initial.regularization`, `factor.regularization`, `margin.vec`, `verbose` |
| `changepoint.xgboost.aft` | `nrounds` (100), `eta`, `max_depth`, `min_child_weight`, `aft_loss_distribution`, `aft_loss_distribution_scale`, `nthread` (1) |
| `changepoint.mmit` | `max_depth`, `margin` |
| `changepoint.mmif` | `max_depth`, `margin`, `n_trees`, `n_features` |

Each learner’s reference page links to the function it wraps, which
documents these. The parameter set lists them too.

``` r

lrn("changepoint.xgboost.aft")$param_set$ids()
#> [1] "nrounds"                     "aft_loss_distribution"      
#> [3] "aft_loss_distribution_scale" "eta"                        
#> [5] "max_depth"                   "min_child_weight"           
#> [7] "nthread"                     "Kmax"
```

## Predictions record Kmax

A predicted penalty only makes sense with the model path it was learned
on. Each prediction therefore records `Kmax` for every sequence in its
extra data. The measures read it from there, which keeps scores right
after [`resample()`](https://mlr3.mlr-org.com/reference/resample.html),
inside an `AutoTuner` and in a `GraphLearner`.

## Side by side

The toy task has ten sequences. The odd ones change mean twice and carry
two `1change` labels, and the even ones are flat with one `0changes`
label.

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
task = TaskCpt$new(
  id = "toy", backend = data.table(signal = signal, label = label),
  target = "label", sequence = "signal", label_type = "changepoint"
)
```

The MMIT and MMIF learners need the mmit package, so this chunk adds
them only when it is installed.

``` r

learners = list(
  lrn("changepoint.intregrcv", Kmax = 3L, n.folds = 2L, min.observations = 2L),
  lrn("changepoint.xgboost.aft", Kmax = 3L)
)
if (requireNamespace("mmit", quietly = TRUE)) {
  learners = c(learners, lrns(c("changepoint.mmit", "changepoint.mmif"), Kmax = 3L))
}
```

Each learner trains on the task and predicts on it. The table has one
column of predicted `log(lambda)` per learner.

``` r

set.seed(1)
predictions = list()
response = data.table(row_id = task$row_ids)
for (learner in learners) {
  predictions[[learner$id]] = learner$train(task)$predict(task)
  response[[learner$id]] = round(predictions[[learner$id]]$response, 2)
}
response
#>     row_id changepoint.intregrcv changepoint.xgboost.aft changepoint.mmit
#>      <int>                 <num>                   <num>            <num>
#>  1:      1                 -2.15                    3.58             6.15
#>  2:      2                  3.62                    3.58             6.15
#>  3:      3                 -2.17                    3.58             6.15
#>  4:      4                  3.06                    3.58             6.15
#>  5:      5                 -1.93                    3.58             6.15
#>  6:      6                  3.67                    3.58             6.15
#>  7:      7                 -2.12                    3.58             6.15
#>  8:      8                  2.82                    3.58             6.15
#>  9:      9                 -2.06                    3.58             6.15
#> 10:     10                  3.14                    3.58             6.15
#>     changepoint.mmif
#>                <num>
#>  1:             6.04
#>  2:             6.04
#>  3:             6.04
#>  4:             6.04
#>  5:             6.04
#>  6:             6.04
#>  7:             6.04
#>  8:             6.04
#>  9:             6.04
#> 10:             6.04
```

The penalties differ between learners, but each one only has to fall
inside its sequence’s target interval. The label error shows which ones
do.

``` r

errors = numeric()
for (id in names(predictions)) {
  errors[id] = predictions[[id]]$score(msr("changepoint.label_error"), task = task)
}
errors
#>   changepoint.intregrcv changepoint.xgboost.aft        changepoint.mmit 
#>                       0                       0                       0 
#>        changepoint.mmif 
#>                       0
```

To add a learner, inherit from
[`LearnerCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/LearnerCpt.md)
and return a `log(lambda)` per sequence, with `Kmax` in the extra data.
