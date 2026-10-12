# Label-accuracy changepoint measure

One minus
[mlr_measures_changepoint.label_error](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_error.md):
the label-weighted share of label regions the predicted segmentation
gets right. It reads `Kmax`, applies measure weights and scores `NA`
exactly like the label error.

## Dictionary

This measure can be retrieved via
[mlr3::mlr_measures](https://mlr3.mlr-org.com/reference/mlr_measures.html)
with the key `"changepoint.label_accuracy"`:

    msr("changepoint.label_accuracy")

## See also

Other Measure:
[`MeasureCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/MeasureCpt.md),
[`mlr_measures_changepoint.auc`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.auc.md),
[`mlr_measures_changepoint.label_error`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_error.md)

## Super classes

[`mlr3::Measure`](https://mlr3.mlr-org.com/reference/Measure.html) -\>
[`mlr3changepoint::MeasureCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/MeasureCpt.md)
-\> `MeasureCptLabelAccuracy`

## Methods

### Public methods

- [`MeasureCptLabelAccuracy$new()`](#method-MeasureCptLabelAccuracy-new)

- [`MeasureCptLabelAccuracy$clone()`](#method-MeasureCptLabelAccuracy-clone)

Inherited methods

- [`mlr3::Measure$aggregate()`](https://mlr3.mlr-org.com/reference/Measure.html#method-aggregate)
- [`mlr3::Measure$format()`](https://mlr3.mlr-org.com/reference/Measure.html#method-format)
- [`mlr3::Measure$help()`](https://mlr3.mlr-org.com/reference/Measure.html#method-help)
- [`mlr3::Measure$obs_loss()`](https://mlr3.mlr-org.com/reference/Measure.html#method-obs_loss)
- [`mlr3::Measure$print()`](https://mlr3.mlr-org.com/reference/Measure.html#method-print)
- [`mlr3::Measure$score()`](https://mlr3.mlr-org.com/reference/Measure.html#method-score)

------------------------------------------------------------------------

### Method `new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    MeasureCptLabelAccuracy$new()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MeasureCptLabelAccuracy$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
library(data.table)

# Alternate change-bearing and flat sequences so the learner's internal
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
prediction = learner$predict(task)
prediction$score(msr("changepoint.label_accuracy"), task = task)
#> changepoint.label_accuracy 
#>                          1 
# }
```
