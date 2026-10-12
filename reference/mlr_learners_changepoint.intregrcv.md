# Cross-Validated Interval Regression Changepoint Learner

Learns a penalty function for changepoint detection from weak labels via
[`penaltyLearning::IntervalRegressionCV()`](https://rdrr.io/pkg/penaltyLearning/man/IntervalRegressionCV.html).

At train time, each sequence is summarized into a numeric feature vector
and the labels are converted into an interval of admissible
`log(lambda)` penalties (the segment path is fitted per sequence, scored
against the label regions, and the error curve inverted). The interval
regression model then maps features to a penalty inside that interval.

At predict time, the learner returns `response`, the predicted
`log(lambda)` per sequence.

The label solvers are chosen by the task's `label_type`: `"changepoint"`
uses
[`changepoint::cpt.mean()`](https://rdrr.io/pkg/changepoint/man/cpt.mean.html),
`"peak"` uses
[`PeakSegOptimal::PeakSegPDPAchrom()`](https://rdrr.io/pkg/PeakSegOptimal/man/PeakSegPDPAchrom.html).

## Dictionary

This learner can be retrieved via
[mlr3::mlr_learners](https://mlr3.mlr-org.com/reference/mlr_learners.html)
with the key `"changepoint.intregrcv"`:

    lrn("changepoint.intregrcv")

## Parameters

`Kmax` (`integer(1)`, required) caps model complexity: the maximum
number of changepoints (`label_type = "changepoint"`) or peaks
(`label_type = "peak"`) the per-sequence segment path is searched over,
applied identically at train and predict time. The learner consumes it
to build the target penalty intervals; it is not forwarded to the
solver. Each prediction records it per sequence in its `extra` data
(`as.data.table(prediction)$Kmax`), so the label-error measure decodes
the predicted penalty under the same cap. The remaining parameters are
passed to
[`penaltyLearning::IntervalRegressionCV()`](https://rdrr.io/pkg/penaltyLearning/man/IntervalRegressionCV.html);
see there for their meaning and defaults.

## See also

Other Learner:
[`LearnerCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/LearnerCpt.md),
[`mlr_learners_changepoint.mmif`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_learners_changepoint.mmif.md),
[`mlr_learners_changepoint.mmit`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_learners_changepoint.mmit.md),
[`mlr_learners_changepoint.xgboost.aft`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_learners_changepoint.xgboost.aft.md)

## Super classes

[`mlr3::Learner`](https://mlr3.mlr-org.com/reference/Learner.html) -\>
[`mlr3changepoint::LearnerCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/LearnerCpt.md)
-\> `LearnerCptIntRegrCV`

## Methods

### Public methods

- [`LearnerCptIntRegrCV$new()`](#method-LearnerCptIntRegrCV-new)

- [`LearnerCptIntRegrCV$clone()`](#method-LearnerCptIntRegrCV-clone)

Inherited methods

- [`mlr3::Learner$base_learner()`](https://mlr3.mlr-org.com/reference/Learner.html#method-base_learner)
- [`mlr3::Learner$configure()`](https://mlr3.mlr-org.com/reference/Learner.html#method-configure)
- [`mlr3::Learner$encapsulate()`](https://mlr3.mlr-org.com/reference/Learner.html#method-encapsulate)
- [`mlr3::Learner$format()`](https://mlr3.mlr-org.com/reference/Learner.html#method-format)
- [`mlr3::Learner$help()`](https://mlr3.mlr-org.com/reference/Learner.html#method-help)
- [`mlr3::Learner$predict()`](https://mlr3.mlr-org.com/reference/Learner.html#method-predict)
- [`mlr3::Learner$predict_newdata()`](https://mlr3.mlr-org.com/reference/Learner.html#method-predict_newdata)
- [`mlr3::Learner$print()`](https://mlr3.mlr-org.com/reference/Learner.html#method-print)
- [`mlr3::Learner$reset()`](https://mlr3.mlr-org.com/reference/Learner.html#method-reset)
- [`mlr3::Learner$selected_features()`](https://mlr3.mlr-org.com/reference/Learner.html#method-selected_features)
- [`mlr3::Learner$train()`](https://mlr3.mlr-org.com/reference/Learner.html#method-train)

------------------------------------------------------------------------

### Method `new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    LearnerCptIntRegrCV$new()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    LearnerCptIntRegrCV$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
library(data.table)

# Alternate change-bearing and flat sequences so the internal
# cross-validation folds always see both target interval kinds.
set.seed(36)
signal = vector("list", 10L)
label = vector("list", 10L)
for (i in 1:10) {
  if (i %% 2 == 1) {
    signal[[i]] = c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9))
    label[[i]] = data.table(
      start = c(90, 190), end = c(110, 210), label = c("1change", "1change")
    )
  } else {
    signal[[i]] = rnorm(100, 0)
    label[[i]] = data.table(start = 1, end = 100, label = "0changes")
  }
}
task = TaskCpt$new(
  id = "toy", backend = data.table(signal = signal, label = label),
  target = "label", sequence = "signal", label_type = "changepoint"
)

learner = lrn("changepoint.intregrcv",
  Kmax = 3L, n.folds = 2L, min.observations = 2L
)
# \donttest{
set.seed(36)
learner$train(task)
#> Loading required namespace: future.apply
#> Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
#> ℹ Please use `linewidth` instead.
#> ℹ The deprecated feature was likely used in the penaltyLearning package.
#>   Please report the issue at
#>   <https://github.com/tdhock/penaltyLearning/issues>.
learner$predict(task)
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
# }
```
