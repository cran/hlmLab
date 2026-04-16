#' Teaching plot for intraclass correlation (ICC)
#'
#' Visualizes the intraclass correlation by plotting the between- and
#' within-cluster variance components as a stacked bar. This is intended
#' as a teaching diagram to help students see how the ICC reflects the
#' share of variance that lies between clusters.
#'
#' @param model A fitted \code{lmerMod} model with a random intercept.
#' @param cluster_size Optional scalar giving the average cluster size,
#'   passed to \code{hlm_icc()} to compute the design effect.
#'
#' @return A \code{ggplot} object.
#' @export
hlm_icc_plot <- function(model, cluster_size = NULL) {
  ic <- hlm_icc(model, cluster_size = cluster_size)

  df <- dplyr::tibble(
    component = c("Between-cluster variance", "Within-cluster variance"),
    variance  = c(ic$re_var, ic$resid_var)
  )
  df$share <- df$variance / sum(df$variance)

  subtitle_txt <- sprintf("ICC = %.3f", ic$icc)
  if (!is.na(ic$deff)) {
    subtitle_txt <- paste0(
      subtitle_txt,
      sprintf("   |   Design effect \u2248 %.2f", ic$deff)
    )
  }

  ggplot2::ggplot(df, ggplot2::aes(x = "", y = share, fill = component)) +
    ggplot2::geom_col(width = 0.4) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(
      labels = scales::percent_format(accuracy = 1)
    ) +
    ggplot2::labs(
      x = NULL,
      y = "Share of total variance",
      title = "Intraclass correlation (ICC) as variance partitioning",
      subtitle = subtitle_txt,
      fill = NULL
    ) +
    ggplot2::theme_minimal()
}
