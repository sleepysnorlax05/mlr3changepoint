# Case studies

Each case study is a complete example on its own page, from data to
scores. Pick the one closest to your problem.

| Case study | Data | Label type | Learners | Also shows |
|----|----|----|----|----|
| [Neuroblastoma copy-number profiles](https://sleepysnorlax05.github.io/mlr3changepoint/articles/case-study-neuroblastoma.md) | Real copy-number profiles from the neuroblastoma package | `"changepoint"` | All four | Converting genomic coordinates to labels, a BIC baseline and the ROC curve |
| [Peak detection in count data](https://sleepysnorlax05.github.io/mlr3changepoint/articles/case-study-peaks.md) | Simulated Poisson counts | `"peak"` | `changepoint.intregrcv` | `peakStart` and `peakEnd` labels and a train and test split |
| [Benchmarking the learners](https://sleepysnorlax05.github.io/mlr3changepoint/articles/case-study-benchmark.md) | Simulated sequences with different noise levels | `"changepoint"` | All four | Training time against the number of sequences on a log-log scale |
