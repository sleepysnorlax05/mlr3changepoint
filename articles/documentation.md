# Documentation

The documentation covers the three parts of a workflow: the task and its
labels, the learner that predicts a penalty, and the measures and plots
that check it. This page lists the main objects, shows how the package
is organised and explains the idea behind penalty learning. The sidebar
links to each part.

## Main objects and functions

Every learner has the same interface, so code written for one runs with
the others.

| Object or function | What it does |
|----|----|
| `TaskCpt$new()` | Stores one row per sequence: the signal and its labelled regions. |
| `lrn("changepoint.intregrcv")`, `lrn("changepoint.xgboost.aft")`, `lrn("changepoint.mmit")`, `lrn("changepoint.mmif")` | Creates a learner, which predicts a penalty for each sequence. |
| `$train(task)` | Fits the learner to the labelled sequences. |
| `$predict(task)` | Returns a `PredictionCpt` with the predicted `log(lambda)` of each sequence. |
| `msr("changepoint.label_error")`, `msr("changepoint.label_accuracy")`, `msr("changepoint.auc")` | Creates a measure. |
| `$score(measures, task = task)` | Scores a prediction against the labels. |
| `autoplot(task)` | Plots the sequences with their labelled regions. |
| `autoplot(prediction, task = task)` | Adds the changes or peaks selected by the predicted penalties. |
| `autoplot(prediction, task = task, type = "roc")` | Plots the ROC curve. |
| [`resample()`](https://mlr3.mlr-org.com/reference/resample.html), [`benchmark()`](https://mlr3.mlr-org.com/reference/benchmark.html), `auto_tuner()` | Resampling, benchmarking and tuning from mlr3 and mlr3tuning, unchanged. |

## How the package is organised

For one sequence, a solver computes the best model of each complexity k
up to a cap, `Kmax`. The complexity is the number of segments for
changepoint labels and the number of peaks for peak labels. A penalty
\lambda \> 0 selects one of these models:

k^\*(\lambda) = \arg\min\_{k} \\ \text{loss}(k) + \lambda k.

The labels of a sequence are right for some models and wrong for others,
so they define an interval of \log \lambda values with the fewest label
errors: the target interval. A learner computes features x_i of each
sequence i and fits a function f(x_i) that predicts \log \lambda_i
inside its target interval. On a new sequence, the predicted penalty
selects the model.

The package follows the same split.

`mlr3changepoint`

- [Tasks and
  labels](https://sleepysnorlax05.github.io/mlr3changepoint/articles/tasks.md)

  The sequences and their labelled regions

  - [`TaskCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/TaskCpt.md):
    one row per sequence
  - `label_type = "changepoint"`: `0changes`, `1change`, `>0changes`
  - `label_type = "peak"`: `noPeaks`, `peaks`, `peakStart`, `peakEnd`
  - [`autoplot(task)`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/autoplot.TaskCpt.md):
    sequences and labels

- [Learners](https://sleepysnorlax05.github.io/mlr3changepoint/articles/learners.md)

  How to predict a penalty from features

  - [`changepoint.intregrcv`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_learners_changepoint.intregrcv.md):
    linear interval regression
  - [`changepoint.xgboost.aft`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_learners_changepoint.xgboost.aft.md):
    boosted trees
  - [`changepoint.mmit`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_learners_changepoint.mmit.md):
    interval tree
  - [`changepoint.mmif`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_learners_changepoint.mmif.md):
    interval forest
  - [`LearnerCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/LearnerCpt.md):
    base class for new learners

- [Evaluation and
  plots](https://sleepysnorlax05.github.io/mlr3changepoint/articles/evaluation.md)

  How good the predicted penalties are

  - [`PredictionCpt`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/PredictionCpt.md):
    a `log(lambda)` per sequence
  - [`changepoint.label_error`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_error.md)
    and
    [`changepoint.label_accuracy`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.label_accuracy.md)
  - [`changepoint.auc`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/mlr_measures_changepoint.auc.md):
    area under the ROC curve
  - [`autoplot(prediction)`](https://sleepysnorlax05.github.io/mlr3changepoint/reference/autoplot.PredictionCpt.md):
    segmentation or ROC curve
