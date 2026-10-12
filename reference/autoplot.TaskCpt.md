# Plot a Changepoint Task

Draws each sequence of a
[TaskCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/TaskCpt.md)
as a line, one facet per row id, with its label regions shaded by
annotation. Changepoint labels use
[penaltyLearning::change.colors](https://rdrr.io/pkg/penaltyLearning/man/change.colors.html);
peak labels (`noPeaks`, `peakStart`, `peakEnd`, `peaks`) use the palette
of the
[`PeakError::PeakError()`](https://rdrr.io/pkg/PeakError/man/PeakError.html)
example. Labels outside these vocabularies are drawn grey.

Every row with role `"use"` gets a facet, so to plot part of a large
task, filter a copy first: `task$clone()$filter(rows)`.

## Usage

``` r
# S3 method for class 'TaskCpt'
autoplot(object, theme = ggplot2::theme_minimal(), ...)
```

## Arguments

- object:

  ([TaskCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/TaskCpt.md)).

- theme:

  ([`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html))  
  The
  [`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
  is applied by default.

- ...:

  (ignored).

## Value

[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html).

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
ggplot2::autoplot(task)
```
