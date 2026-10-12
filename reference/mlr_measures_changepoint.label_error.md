# Label-error changepoint measure

Proportion of label regions the predicted segmentation gets wrong: the
total false positives plus false negatives across all sequences, divided
by the total number of labels (Hocking et al.'s percent-incorrect-labels
metric).
[mlr_measures_changepoint.label_accuracy](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_accuracy.md)
is its complement.

A
[PredictionCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/PredictionCpt.md)
stores only the predicted penalty `log(lambda)` per sequence, not a
segmentation. This measure re-derives the model path each penalty
selects (via the shared label-error pipeline in `cpt_label_errors()`),
reads off the model at that penalty, and counts its label errors. That
path depends on the complexity cap `Kmax` the penalty was learned under,
which the learners of this package record per sequence in the
prediction's `extra` data (`as.data.table(prediction)$Kmax`). Reading it
from the prediction keeps the score right for wrapped learners (a
`GraphLearner` prefixes parameter ids) and for resampled predictions
whose folds were tuned to different caps. A prediction built without it
as a whole (e.g. by hand) falls back to the `Kmax` the learner passed to
`$score()` was trained with (or, untrained, is set to); scoring errors
if neither gives one.

Sequences without labels can be neither right nor wrong, so they are
left out of the score. The measure declares `"requires_task"` (to read
the sequences and labels) and `"na_score"`, since an empty prediction, a
non-finite predicted penalty, or a test set without any labels scores
`NA`.

## Details

The score micro-averages over sequences:
`sum(w * errors) / sum(w * n_labels)`, where `n_labels` is each
sequence's label-region count and `w` its measure weight. Sequences
carry different label counts, so this weights by labels rather than
averaging per-sequence rates. The mlr3 `average` argument is the
orthogonal resampling-iteration axis and stays at its default.

## Dictionary

This measure can be retrieved via
[mlr3::mlr_measures](https://mlr3.mlr-org.com/reference/mlr_measures.html)
with the key `"changepoint.label_error"`:

    msr("changepoint.label_error")

## See also

Other Measure:
[`MeasureCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/MeasureCpt.md),
[`mlr_measures_changepoint.auc`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.auc.md),
[`mlr_measures_changepoint.label_accuracy`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_accuracy.md)

## Super classes

[`mlr3::Measure`](https://mlr3.mlr-org.com/reference/Measure.html) -\>
[`mlr3changepoint::MeasureCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/MeasureCpt.md)
-\> `MeasureCptLabelError`

## Methods

### Public methods

- [`MeasureCptLabelError$new()`](#method-MeasureCptLabelError-new)

- [`MeasureCptLabelError$clone()`](#method-MeasureCptLabelError-clone)

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

    MeasureCptLabelError$new()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MeasureCptLabelError$clone(deep = FALSE)

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
prediction$score(msr("changepoint.label_error"), task = task)
#> changepoint.label_error 
#>                       0 
# }
```
