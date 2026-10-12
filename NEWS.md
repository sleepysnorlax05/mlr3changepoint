# mlr3changepoint 0.1.0

* Initial CRAN submission.
* New `"changepoint"` task type for weakly supervised changepoint and peak detection, registered with mlr3 when the package loads.
* Every prediction records the `Kmax` it was learned under in its `extra` data, so measures and plots decode the same segmentation, also for wrapped (`GraphLearner`, `AutoTuner`) and resampled learners.
* `autoplot()` methods for `TaskCpt` and `PredictionCpt` draw the sequences with their labelled regions, the segmentation selected by each predicted penalty, or the ROC curve (`type = "roc"`).
* `LearnerCpt` is the abstract base class for changepoint learners.
* `LearnerCptIntRegrCV` (`changepoint.intregrcv`) learns the penalty with `penaltyLearning::IntervalRegressionCV()`.
* `LearnerCptMMIF` (`changepoint.mmif`) learns the penalty with a max margin interval forest from mmit.
* `LearnerCptMMIT` (`changepoint.mmit`) learns the penalty with a max margin interval tree from mmit.
* `LearnerCptXGBoostAFT` (`changepoint.xgboost.aft`) learns the penalty with xgboost's accelerated failure time objective.
* `MeasureCpt` is the abstract base class for changepoint measures.
* `MeasureCptAUC` (`changepoint.auc`) is the area under the ROC curve traced by shifting every predicted penalty.
* `MeasureCptLabelAccuracy` (`changepoint.label_accuracy`) is one minus the label error.
* `MeasureCptLabelError` (`changepoint.label_error`) is the share of labelled regions the predicted segmentation gets wrong.
* `PredictionCpt` holds the predicted `log(lambda)` per sequence.
* `TaskCpt` holds one labelled sequence per row, with `"changepoint"` or `"peak"` labels.
