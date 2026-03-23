#' @title Plots for Changepoint Tasks
#'
#' @description
#' Visualizations for `TaskCptUnsupervised`.
#' The argument `type` controls what kind of plot is drawn.
#' Possible choices are:
#'
#' * `"target"` (default): Line plot of the target variable.
#'
#' @param object (`TaskCptUnsupervised`).
#' @param type (`character(1)`)\cr
#'   Type of the plot. See description.
#' @param theme (`ggplot2::theme()`)\cr
#'   The `ggplot2::theme_minimal()` is applied by default to all plots.
#' @param ... (ignored).
#'
#' @return `ggplot2::ggplot()`.
#'
#' @importFrom ggplot2 autoplot
#' @export
autoplot.TaskCptUnsupervised = function(
  object,
  type = "target",
  theme = ggplot2::theme_minimal(),
  ...
) {
  checkmate::assert_choice(type, choices = c("target"), null.ok = FALSE)
  requireNamespace("ggplot2")

  switch(
    type,
    "target" = {
      dt = data.table::copy(object$backend$data(
        rows = seq_len(object$nrow),
        cols = object$backend$colnames
      ))
      target_col = object$feature_names[1]
      feature_col = object$col_roles$order

      if (length(feature_col) == 0) {
        dt[[".index"]] = seq_len(nrow(dt))
        feature_col = ".index"
      } else {
        feature_col = feature_col[1]
      }

      ggplot2::ggplot(
        dt,
        ggplot2::aes(x = .data[[feature_col]], y = .data[[target_col]])
      ) +
        ggplot2::geom_line(color = "blue", alpha = 0.7) +
        theme +
        ggplot2::labs(
          title = sprintf("Task: %s", object$id),
          x = feature_col,
          y = target_col
        )
    },
    stop(sprintf("Unknown plot type '%s'", type))
  )
}

#' @export
plot.TaskCptUnsupervised = function(x, ...) {
  print(autoplot(x, ...))
}

#' @title Plots for Supervised Changepoint Tasks
#'
#' @description
#' Visualizations for `TaskCptSupervised`.
#' The argument `type` controls what kind of plot is drawn.
#' Possible choices are:
#'
#' * `"target"` (default): Line plot of the target variable along with vertical lines for the known changepoints.
#'
#' @param object (`TaskCptSupervised`).
#' @param type (`character(1)`)\cr
#'   Type of the plot. See description.
#' @param theme (`ggplot2::theme()`)\cr
#'   The `ggplot2::theme_minimal()` is applied by default to all plots.
#' @param ... (ignored).
#'
#' @return `ggplot2::ggplot()`.
#'
#' @export
autoplot.TaskCptSupervised = function(
  object,
  type = "target",
  theme = ggplot2::theme_minimal(),
  ...
) {
  checkmate::assert_choice(type, choices = c("target"), null.ok = FALSE)
  requireNamespace("ggplot2")

  switch(
    type,
    "target" = {
      dt = data.table::copy(object$backend$data(
        rows = seq_len(object$nrow),
        cols = object$backend$colnames
      ))
      target_col = object$feature_names[1]
      cpt_col = object$target_names[1]
      feature_col = object$col_roles$order

      if (length(feature_col) == 0) {
        dt[[".index"]] = seq_len(nrow(dt))
        feature_col = ".index"
      } else {
        feature_col = feature_col[1]
      }

      cpts = which(dt[[cpt_col]] == 1)

      p = ggplot2::ggplot(
        dt,
        ggplot2::aes(x = .data[[feature_col]], y = .data[[target_col]])
      ) +
        ggplot2::geom_line(color = "blue", alpha = 0.7)

      if (length(cpts) > 0) {
        p = p +
          ggplot2::geom_vline(
            xintercept = dt[[feature_col]][cpts],
            color = "green",
            linetype = "solid",
            linewidth = 0.8
          )
      }

      p +
        theme +
        ggplot2::labs(
          title = sprintf("Task: %s", object$id),
          x = feature_col,
          y = target_col
        )
    },
    stop(sprintf("Unknown plot type '%s'", type))
  )
}

#' @export
plot.TaskCptSupervised = function(x, ...) {
  print(autoplot(x, ...))
}

#' @title Plots for Interval Regression Tasks
#' @description
#' Visualizations for 'TaskInterval'
#'
#' @param object (`TaskInterval`).
#' @param theme (`ggplot2::theme()`)\cr
#' @param ... (ignored).
#'
#' @return `ggplot2::ggplot()`.
#'
#' @export
autoplot.TaskInterval = function(
  object,
  theme = ggplot2::theme_minimal(),
  ...
) {
  requireNamespace("ggplot2")

  dt = as.data.frame(object$data())
  target_cols = object$target_names

  min_col = target_cols[1]
  max_col = target_cols[2]

  dt[[".row_idx"]] = seq_len(nrow(dt))

  # Interval limits often have -Inf and Inf.
  finite_min = min(dt[[min_col]][is.finite(dt[[min_col]])], na.rm = TRUE)
  finite_max = max(dt[[max_col]][is.finite(dt[[max_col]])], na.rm = TRUE)

  # Extend bounds slightly beyond minimum/maximum
  y_lower_clamp = finite_min - abs(finite_min * 0.1)
  y_upper_clamp = finite_max + abs(finite_max * 0.1)

  dt[[".plot_min"]] = ifelse(
    is.infinite(dt[[min_col]]) & dt[[min_col]] < 0,
    y_lower_clamp,
    dt[[min_col]]
  )
  dt[[".plot_max"]] = ifelse(
    is.infinite(dt[[max_col]]) & dt[[max_col]] > 0,
    y_upper_clamp,
    dt[[max_col]]
  )

  ggplot2::ggplot(dt, ggplot2::aes(x = .data[[".row_idx"]])) +
    ggplot2::geom_linerange(
      ggplot2::aes(ymin = .data[[".plot_min"]], ymax = .data[[".plot_max"]]),
      color = "blue",
      alpha = 0.5,
      linewidth = 1
    ) +
    theme +
    ggplot2::labs(
      title = sprintf("Task: %s (Penalty Intervals)", object$id),
      x = "Profile Index",
      y = "Log Lambda Bound"
    )
}

#' @export
plot.TaskInterval = function(x, ...) {
  print(autoplot(x, ...))
}

#' @title Plots for Changepoint Predictions
#'
#' @description
#' Visualizations for `PredictionCpt`.
#' The argument `type` controls what kind of plot is drawn.
#' Possible choices are:
#'
#' * `"trace"` (default): Line plot of the target variable with vertical dashed lines representing the predicted changepoints.
#' * `"segments"`: Step function representation of predicted changepoint segments.
#'
#' @param object (`PredictionCpt`).
#' @param task (`TaskCptUnsupervised` or `TaskCptSupervised`)\cr
#'   The task, required to extract the original data.
#' @param type (`character(1)`)\cr
#'   Type of the plot. See description.
#' @param theme (`ggplot2::theme()`)\cr
#'   The `ggplot2::theme_minimal()` is applied by default to all plots.
#' @param ... (ignored).
#'
#' @return `ggplot2::ggplot()`.
#'
#' @export
autoplot.PredictionCpt = function(
  object,
  task,
  type = "trace",
  theme = ggplot2::theme_minimal(),
  ...
) {
  checkmate::assert_choice(
    type,
    choices = c("trace", "segments"),
    null.ok = FALSE
  )
  requireNamespace("ggplot2")

  cpts = object$response

  dt = as.data.frame(task$backend$data(
    rows = seq_len(task$nrow),
    cols = task$backend$colnames
  ))
  target_col = task$feature_names[1]
  feature_col = task$col_roles$order

  if (length(feature_col) == 0) {
    dt[[".index"]] = seq_len(nrow(dt))
    feature_col = ".index"
  } else {
    feature_col = feature_col[1]
  }

  switch(
    type,
    "trace" = {
      p = ggplot2::ggplot(dt, ggplot2::aes(x = .data[[feature_col]])) +
        ggplot2::geom_line(
          ggplot2::aes(y = .data[[target_col]]),
          color = "blue",
          alpha = 0.5
        )

      if (length(cpts) > 0) {
        p = p +
          ggplot2::geom_vline(
            xintercept = dt[[feature_col]][cpts],
            color = "red",
            linetype = "dashed",
            linewidth = 0.8
          )
      }

      p +
        theme +
        ggplot2::labs(
          title = sprintf("Task: %s", task$id),
          subtitle = sprintf(
            "Viewing: trace | Detected %d points",
            length(cpts)
          ),
          x = feature_col,
          y = target_col
        )
    },
    "segments" = {
      if (length(cpts) > 0) {
        dt[[".row_idx"]] = seq_len(nrow(dt))
        segment_ids = findInterval(dt[[".row_idx"]], c(0, cpts)) + 1
        dt[[".seg_mean"]] = ave(dt[[target_col]], segment_ids, FUN = mean)
      } else {
        dt[[".seg_mean"]] = mean(dt[[target_col]])
      }

      p = ggplot2::ggplot(dt, ggplot2::aes(x = .data[[feature_col]])) +
        ggplot2::geom_line(
          ggplot2::aes(y = .data[[target_col]]),
          color = "blue",
          alpha = 0.4
        )

      if (length(cpts) > 0) {
        p = p +
          ggplot2::geom_step(
            ggplot2::aes(y = .data[[".seg_mean"]]),
            color = "red",
            linewidth = 1.2
          )
      } else {
        p = p +
          ggplot2::geom_hline(
            yintercept = dt[[".seg_mean"]][1],
            color = "red",
            linewidth = 1.2
          )
      }

      p +
        theme +
        ggplot2::labs(
          title = sprintf("Task: %s", task$id),
          subtitle = sprintf(
            "Viewing: segments | Detected %d points",
            length(cpts)
          ),
          x = feature_col,
          y = target_col
        )
    },
    stop(sprintf("Unknown plot type '%s'", type))
  )
}

#' @export
plot.PredictionCpt = function(x, ...) {
  print(autoplot(x, ...))
}
