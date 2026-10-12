# Weakly Supervised Task for Change Point Detection

This task is designed for **weakly supervised change point detection**
problems. It inherits from
[mlr3::TaskSupervised](https://mlr3.mlr-org.com/reference/TaskSupervised.html)
and includes additional column roles and properties for change point
detection.

The `task_type` is set to `"changepoint"`.

## Details

The Task table has one row for each labeled sequence, and two special
column roles:

- `sequence`: the column that identifies the sequence (e.g., time
  series)

- `target`: a list column where each entry is a
  `data.table(start, end, label)`

The `label_type` can be either "changepoint" or "peak", depending on the
type of detection problem. This is stored as an extra argument and can
be accessed via the active binding `label_type`.

## Super classes

[`mlr3::Task`](https://mlr3.mlr-org.com/reference/Task.html) -\>
[`mlr3::TaskSupervised`](https://mlr3.mlr-org.com/reference/TaskSupervised.html)
-\> `TaskCpt`

## Active bindings

- `label_type`:

  (`character(1)`)  
  The type of labels, either "changepoint" or "peak".

## Methods

### Public methods

- [`TaskCpt$new()`](#method-TaskCpt-new)

- [`TaskCpt$truth()`](#method-TaskCpt-truth)

- [`TaskCpt$clone()`](#method-TaskCpt-clone)

Inherited methods

- [`mlr3::Task$add_strata()`](https://mlr3.mlr-org.com/reference/Task.html#method-add_strata)
- [`mlr3::Task$cbind()`](https://mlr3.mlr-org.com/reference/Task.html#method-cbind)
- [`mlr3::Task$data()`](https://mlr3.mlr-org.com/reference/Task.html#method-data)
- [`mlr3::Task$divide()`](https://mlr3.mlr-org.com/reference/Task.html#method-divide)
- [`mlr3::Task$droplevels()`](https://mlr3.mlr-org.com/reference/Task.html#method-droplevels)
- [`mlr3::Task$filter()`](https://mlr3.mlr-org.com/reference/Task.html#method-filter)
- [`mlr3::Task$format()`](https://mlr3.mlr-org.com/reference/Task.html#method-format)
- [`mlr3::Task$formula()`](https://mlr3.mlr-org.com/reference/Task.html#method-formula)
- [`mlr3::Task$head()`](https://mlr3.mlr-org.com/reference/Task.html#method-head)
- [`mlr3::Task$help()`](https://mlr3.mlr-org.com/reference/Task.html#method-help)
- [`mlr3::Task$levels()`](https://mlr3.mlr-org.com/reference/Task.html#method-levels)
- [`mlr3::Task$materialize_view()`](https://mlr3.mlr-org.com/reference/Task.html#method-materialize_view)
- [`mlr3::Task$missings()`](https://mlr3.mlr-org.com/reference/Task.html#method-missings)
- [`mlr3::Task$print()`](https://mlr3.mlr-org.com/reference/Task.html#method-print)
- [`mlr3::Task$rbind()`](https://mlr3.mlr-org.com/reference/Task.html#method-rbind)
- [`mlr3::Task$rename()`](https://mlr3.mlr-org.com/reference/Task.html#method-rename)
- [`mlr3::Task$select()`](https://mlr3.mlr-org.com/reference/Task.html#method-select)
- [`mlr3::Task$set_col_roles()`](https://mlr3.mlr-org.com/reference/Task.html#method-set_col_roles)
- [`mlr3::Task$set_levels()`](https://mlr3.mlr-org.com/reference/Task.html#method-set_levels)
- [`mlr3::Task$set_row_roles()`](https://mlr3.mlr-org.com/reference/Task.html#method-set_row_roles)

------------------------------------------------------------------------

### Method `new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    TaskCpt$new(
      id,
      backend,
      target,
      sequence,
      label_type = "changepoint",
      label = NA_character_
    )

#### Arguments

- `id`:

  (`character(1)`)  
  Identifier for the task.

- `backend`:

  ([mlr3::DataBackend](https://mlr3.mlr-org.com/reference/DataBackend.html))  
  The data backend for the task.

- `target`:

  (`character(1)`)  
  The column name for the target variable.

- `sequence`:

  (`character(1)`)  
  The column name for the sequence variable.

- `label_type`:

  (`character(1)`)  
  The type of labels, either "changepoint" or "peak".

- `label`:

  (`character(1)`)  
  Display name for the task.

------------------------------------------------------------------------

### Method `truth()`

True labels for the specified `row_ids`, one entry per sequence.
Defaults to all rows with role `"use"`.

#### Usage

    TaskCpt$truth(rows = NULL)

#### Arguments

- `rows`:

  (positive [`integer()`](https://rdrr.io/r/base/integer.html))  
  Vector of row indices.

#### Returns

A [`list()`](https://rdrr.io/r/base/list.html) of
[`data.table::data.table()`](https://rdrr.io/pkg/data.table/man/data.table.html)s,
each with columns `start`, `end` and `label`.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    TaskCpt$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
library(data.table)
# changepoint detection example
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
task
#> 
#> ── <TaskCpt> (2x1) ─────────────────────────────────────────────────────────────
#> • Target: label
#> • Properties: -
task$truth()
#> [[1]]
#>    start   end   label
#>    <num> <num>  <char>
#> 1:    90   110 1change
#> 2:   190   210 1change
#> 
#> [[2]]
#>    start   end    label
#>    <num> <num>   <char>
#> 1:     1   100 0changes
#> 
task$label_type
#> [1] "changepoint"

# peak detection example
set.seed(36)
toy_peak = data.table(
  seq = list(c(rpois(60, 2), rpois(40, 25), rpois(100, 2))),
  label = list(
    data.table(start = c(1, 55), end = c(50, 105), label = c("noPeaks", "peaks"))
  )
)

task_peak = TaskCpt$new(
  id = "toy_peak", backend = toy_peak,
  target = "label", sequence = "seq", label_type = "peak"
)
task_peak
#> 
#> ── <TaskCpt> (1x1) ─────────────────────────────────────────────────────────────
#> • Target: label
#> • Properties: -
task_peak$truth()
#> [[1]]
#>    start   end   label
#>    <num> <num>  <char>
#> 1:     1    50 noPeaks
#> 2:    55   105   peaks
#> 
task_peak$label_type
#> [1] "peak"
```
