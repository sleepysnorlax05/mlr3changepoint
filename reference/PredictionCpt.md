# Prediction Object for Change Point Detection

This object wraps the predictions returned by a learner of class
[LearnerCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/LearnerCpt.md),
i.e. the predicted penalty `log(lambda)` for each sequence. It is the
bridge from a
[LearnerCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/LearnerCpt.md)
to a measure: `$score()` compares the predicted penalties against the
true label regions stored in `$truth`.

The `task_type` is set to `"changepoint"`.

## Super class

[`mlr3::Prediction`](https://mlr3.mlr-org.com/reference/Prediction.html)
-\> `PredictionCpt`

## Active bindings

- `response`:

  ([`numeric()`](https://rdrr.io/r/base/numeric.html))  
  Access the stored predicted penalty `log(lambda)`. Returns `NA` for
  observations without a stored prediction.

## Methods

### Public methods

- [`PredictionCpt$new()`](#method-PredictionCpt-new)

- [`PredictionCpt$clone()`](#method-PredictionCpt-clone)

Inherited methods

- [`mlr3::Prediction$filter()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-filter)
- [`mlr3::Prediction$format()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-format)
- [`mlr3::Prediction$help()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-help)
- [`mlr3::Prediction$obs_loss()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-obs_loss)
- [`mlr3::Prediction$print()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-print)
- [`mlr3::Prediction$score()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-score)

------------------------------------------------------------------------

### Method `new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    PredictionCpt$new(
      task = NULL,
      row_ids = task$row_ids,
      truth = task$truth(row_ids),
      response = NULL,
      weights = NULL,
      check = TRUE,
      extra = NULL,
      raw = NULL
    )

#### Arguments

- `task`:

  ([TaskCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/TaskCpt.md))  
  Task, used to extract defaults for `row_ids` and `truth`.

- `row_ids`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row ids of the predicted observations, i.e. the row ids of the test
  set.

- `truth`:

  ([`list()`](https://rdrr.io/r/base/list.html) of
  [`data.table::data.table()`](https://rdrr.io/pkg/data.table/man/data.table.html))  
  True label regions, one `data.table(start, end, label)` per
  observation.

- `response`:

  ([`numeric()`](https://rdrr.io/r/base/numeric.html))  
  Predicted penalty `log(lambda)`. One element for each observation in
  the test set.

- `weights`:

  ([`numeric()`](https://rdrr.io/r/base/numeric.html))  
  Measure weights, one for each observation in the test set. Constructed
  from the `weights_measure` column of the
  [TaskCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/TaskCpt.md),
  if present.

- `check`:

  (`logical(1)`)  
  If `TRUE`, performs some argument checks and predict type conversions.

- `extra`:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  Named list of extra data to store alongside the predictions. Each
  element must have one entry per observation in the test set.

- `raw`:

  (any)  
  Raw prediction object from the upstream model. Stored as-is, without
  validation.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    PredictionCpt$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
library(data.table)
#> 
#> Attaching package: ‘data.table’
#> The following object is masked from ‘package:base’:
#> 
#>     %notin%
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
p
#> 
#> ── <PredictionCpt> for 2 observations: ─────────────────────────────────────────
#>  row_ids             truth response
#>        1 <data.table[2x3]>      2.5
#>        2 <data.table[1x3]>      3.0
p$response
#> [1] 2.5 3.0
as.data.table(p)
#>    row_ids             truth response
#>      <int>            <list>    <num>
#> 1:       1 <data.table[2x3]>      2.5
#> 2:       2 <data.table[1x3]>      3.0
```
