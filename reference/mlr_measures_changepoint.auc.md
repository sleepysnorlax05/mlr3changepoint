# Area-under-the-ROC-curve changepoint measure

Area under the ROC curve that
[`penaltyLearning::ROChange()`](https://rdrr.io/pkg/penaltyLearning/man/ROChange.html)
traces by adding one constant to every predicted penalty `log(lambda)`.
Each shift selects one model per sequence, and the curve plots the false
positive rate against the true positive rate, totalled over all label
regions. The models and their label errors come from the same pipeline
and per-sequence `Kmax` as
[mlr_measures_changepoint.label_error](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_error.md)
(the prediction's recorded cap, else the learner's).
`autoplot(prediction, task = task, type = "roc")` draws the curve.

Changepoint ROC curves need not be monotonic: a curve with loops can
enclose an area above 1 (Hillman and Hocking 2023), so the range is
unbounded.

Sequences without labels add no point to the curve and are left out, as
in the label error. The measure declares `"requires_task"` and
`"na_score"`: an empty prediction, a non-finite predicted penalty, or
labels with no region that can hold a false positive (or none that can
hold a false negative) score `NA`.
[`penaltyLearning::ROChange()`](https://rdrr.io/pkg/penaltyLearning/man/ROChange.html)
is unweighted, so the measure ignores weights.

## Dictionary

This measure can be retrieved via
[mlr3::mlr_measures](https://mlr3.mlr-org.com/reference/mlr_measures.html)
with the key `"changepoint.auc"`:

    msr("changepoint.auc")

## References

Hillman J, Hocking TD (2023). "Optimizing ROC Curves with a Sort-Based
Surrogate Loss for Binary Classification and Changepoint Detection."
*Journal of Machine Learning Research*, 24(70), 1-24.

## See also

Other Measure:
[`MeasureCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/MeasureCpt.md),
[`mlr_measures_changepoint.label_accuracy`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_accuracy.md),
[`mlr_measures_changepoint.label_error`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_error.md)

## Super classes

[`mlr3::Measure`](https://mlr3.mlr-org.com/reference/Measure.html) -\>
[`mlr3changepoint::MeasureCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/MeasureCpt.md)
-\> `MeasureCptAUC`

## Methods

### Public methods

- [`MeasureCptAUC$new()`](#method-MeasureCptAUC-new)

- [`MeasureCptAUC$clone()`](#method-MeasureCptAUC-clone)

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

    MeasureCptAUC$new()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MeasureCptAUC$clone(deep = FALSE)

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
prediction$score(msr("changepoint.auc"), task = task)
#> changepoint.auc 
#>               1 
# }
```
