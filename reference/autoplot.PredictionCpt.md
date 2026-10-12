# Plot a Changepoint Prediction

Draws the facets of
[`autoplot.TaskCpt()`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/autoplot.TaskCpt.md)
for the predicted sequences plus the segmentation decoded at each
sequence's predicted penalty: dashed vertical lines at predicted changes
(`label_type = "changepoint"`) or horizontal segments at the mean count
of each predicted peak (`label_type = "peak"`). For the `0changes`,
`1change`, `noPeaks` and `peaks` labels, a mark missing from a region
that requires one, or inside a region that forbids it, is a label error.
`peakStart` and `peakEnd` regions are scored on where a peak starts or
ends, not on overlap.

## Usage

``` r
# S3 method for class 'PredictionCpt'
autoplot(
  object,
  task,
  type = "segmentation",
  Kmax = NULL,
  theme = ggplot2::theme_minimal(),
  ...
)
```

## Arguments

- object:

  ([PredictionCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/PredictionCpt.md)).

- task:

  ([TaskCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/TaskCpt.md))  
  Task the prediction was made on; must contain every predicted row.

- type:

  (`character(1)`)  
  `"segmentation"` (default) draws the decoded marks; `"roc"` draws the
  ROC curve
  [mlr_measures_changepoint.auc](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.auc.md)
  integrates, from
  [`penaltyLearning::ROChange()`](https://rdrr.io/pkg/penaltyLearning/man/ROChange.html),
  with the AUC as title and a point at the predicted penalties (shift
  0).

- Kmax:

  (`integer(1)` \| `NULL`)  
  Complexity cap for a prediction that does not record one; ignored when
  the prediction carries `Kmax`.

- theme:

  ([`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html))  
  The
  [`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
  is applied by default.

- ...:

  (ignored).

## Value

[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html).

## Details

A
[PredictionCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/PredictionCpt.md)
stores only the predicted `log(lambda)` per sequence, so the
segmentation is re-derived the way
[mlr_measures_changepoint.label_error](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_error.md)
does it: sequences and labels come from `task`, and the complexity cap
from the `Kmax` the prediction records per sequence (learners of this
package always record it). `Kmax` is only needed for a prediction built
by hand without that record. A non-finite predicted penalty selects no
model and raises an error, as do duplicated row ids (combined resampling
iterations).

Every predicted row gets a facet; for many sequences predict on a subset
(`learner$predict(task, row_ids = rows)`).

## Examples

``` r
library(data.table)
set.seed(36)
toy = data.table(
  seq = list(c(rnorm(100, 18), rnorm(100, 36), rnorm(100, 9)), rnorm(100, 0)),
  label = list(
    data.table(start = c(90, 190), end = c(110, 210), label = c("1change", "1change")),
    data.table(start = 1, end = 100, label = "0changes")
  )
)
task = TaskCpt$new(
  id = "toy", backend = toy,
  target = "label", sequence = "seq", label_type = "changepoint"
)

p = PredictionCpt$new(task = task, response = c(2.5, 3.0))
# A hand-made prediction records no Kmax, so pass it; learner predictions carry their own.
ggplot2::autoplot(p, task = task, Kmax = 3L)

ggplot2::autoplot(p, task = task, type = "roc", Kmax = 3L)
```
