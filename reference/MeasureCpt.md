# Weakly supervised changepoint detection measure

This measure is the base class for all weakly supervised changepoint
detection measures. Do not use this class directly, but rather inherit
from it when implementing a specific measure. It inherits from
[mlr3::Measure](https://mlr3.mlr-org.com/reference/Measure.html) and
sets the `task_type` to `"changepoint"`. Calling `$score()` on this base
class raises an error.

A changepoint measure scores a
[PredictionCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/PredictionCpt.md),
whose `response` is the predicted penalty `log(lambda)` rather than a
segmentation. Deriving the segmentation that penalty selects needs the
sequences and the complexity cap they were fitted under, so a measure
will usually declare the `"requires_task"` property and read `Kmax` from
the prediction's `extra` data, where the learners of this package record
it per sequence.

## See also

Other Measure:
[`mlr_measures_changepoint.auc`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.auc.md),
[`mlr_measures_changepoint.label_accuracy`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_accuracy.md),
[`mlr_measures_changepoint.label_error`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_error.md)

## Super class

[`mlr3::Measure`](https://mlr3.mlr-org.com/reference/Measure.html) -\>
`MeasureCpt`

## Methods

### Public methods

- [`MeasureCpt$new()`](#method-MeasureCpt-new)

- [`MeasureCpt$clone()`](#method-MeasureCpt-clone)

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

    MeasureCpt$new(
      id,
      param_set = ps(),
      range = c(-Inf, Inf),
      minimize = NA,
      average = "macro",
      aggregator = NULL,
      properties = character(),
      predict_type = "response",
      task_properties = character(),
      packages = character(),
      label = NA_character_,
      man = NA_character_
    )

#### Arguments

- `id`:

  (`character(1)`)  
  Identifier for the measure.

- `param_set`:

  ([paradox::ParamSet](https://paradox.mlr-org.com/reference/ParamSet.html))  
  Set of hyperparameters.

- `range`:

  (`numeric(2)`)  
  Feasible range for this measure as `c(lower_bound, upper_bound)`. Both
  bounds may be infinite.

- `minimize`:

  (`logical(1)`)  
  Set to `TRUE` if good predictions correspond to small values, and to
  `FALSE` if they correspond to large values.

- `average`:

  (`character(1)`)  
  How to average multiple
  [mlr3::Prediction](https://mlr3.mlr-org.com/reference/Prediction.html)s
  from a
  [mlr3::ResampleResult](https://mlr3.mlr-org.com/reference/ResampleResult.html).
  One of `"micro"`, `"macro"` or `"custom"`.

- `aggregator`:

  (`function(x)`)  
  Function to aggregate individual performance scores `x`, used when
  `average` is `"custom"`.

- `properties`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Properties of the measure. A subset of
  [`mlr_reflections$measure_properties`](https://mlr3.mlr-org.com/reference/mlr_reflections.html).

- `predict_type`:

  (`character(1)`)  
  Required predict type of the
  [LearnerCpt](https://sleepysnorlax05.github.io/mlr3changepoint/reference/LearnerCpt.md).

- `task_properties`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Required task properties, a subset of
  [`mlr_reflections$task_properties`](https://mlr3.mlr-org.com/reference/mlr_reflections.html).

- `packages`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Set of required packages. Checked for availability when the measure is
  constructed and loaded on demand before scoring.

- `label`:

  (`character(1)`)  
  Display name for the measure.

- `man`:

  (`character(1)`)  
  String of the form `[pkg]::[topic]` pointing to this object's help
  page, which can be opened via the `$help()` method.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MeasureCpt$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
