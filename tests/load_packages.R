# Install and load required packages
req = c(
  # Change point detection
  "mlr3",
  "changepoint",
  "binsegRcpp",
  "penaltyLearning",

  # Data
  "data.table",

  # Plotting
  "ggplot2",
  "mlr3viz",
  "patchwork"
)

for (pkg in req) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE)
}
