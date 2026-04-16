#' Contextual effect for a Level-1 predictor (Mundlak decomposition)
#'
#' Given a multilevel model with a within-cluster centered predictor and
#' its cluster-mean counterpart (Mundlak specification), this function
#' extracts the within- and between-cluster effects and computes the
#' contextual effect (between - within).
#'
#' @param model A fitted \code{lmerMod} model.
#' @param x_within Name of the within-cluster centered predictor (string).
#' @param x_between Name of the cluster-mean predictor (string).
#'
#' @return An object of class \code{hlm_context}, which is a tibble with:
#'   \item{effect_type}{Within, between, or contextual.}
#'   \item{estimate}{Estimate of the effect.}
#'   \item{se}{Standard error (approximate for contextual).}
#'
#' @examples
#' # Build a small toy dataset (no external data needed)
#' set.seed(1)
#' n_schools <- 8
#' n_students <- 12
#' school_id <- rep(seq_len(n_schools), each = n_students)
#' SES_raw   <- rnorm(n_schools * n_students)
#' SES_mean  <- rep(tapply(SES_raw, school_id, mean), each = n_students)
#' SES_c     <- SES_raw - SES_mean
#' math_score <- 50 + 2 * SES_c + 3 * SES_mean + rep(rnorm(n_schools, sd = 2), each = n_students) +
#'               rnorm(n_schools * n_students)
#' toy <- data.frame(math_score = math_score, SES_c = SES_c,
#'                   SES_mean = SES_mean, school_id = school_id)
#'
#' \donttest{
#' m   <- lme4::lmer(math_score ~ SES_c + SES_mean + (1 | school_id), data = toy)
#' ctx <- hlm_context(m, x_within = "SES_c", x_between = "SES_mean")
#' ctx
#' hlm_context_plot(ctx)
#' }
#' @export
hlm_context <- function(model, x_within, x_between) {
  if (!inherits(model, "lmerMod")) {
    stop("hlm_context currently supports models fitted with lme4::lmer().")
  }

  coefs <- stats::coef(summary(model))
  rn    <- rownames(coefs)

  if (!all(c(x_within, x_between) %in% rn)) {
    stop("Both 'x_within' and 'x_between' must be fixed effects in the model.")
  }

  bW  <- coefs[x_within, "Estimate"]
  seW <- coefs[x_within, "Std. Error"]
  bB  <- coefs[x_between, "Estimate"]
  seB <- coefs[x_between, "Std. Error"]

  ctxt     <- bB - bW
  # simple SE approximation (ignores covariance); OK for teaching
  se_ctxt  <- sqrt(seB^2 + seW^2)

  out <- dplyr::tibble(
    effect_type = c("Within-cluster", "Between-cluster", "Contextual (B - W)"),
    estimate    = c(bW, bB, ctxt),
    se          = c(seW, seB, se_ctxt)
  )
  class(out) <- c("hlm_context", class(out))
  out
}

#' @export
print.hlm_context <- function(x, ...) {
  cat("Contextual effect decomposition\n")
  print.data.frame(as.data.frame(x), row.names = FALSE)
  invisible(x)
}

#' Plot method for hlm_context objects
#'
#' Produces an error-bar plot of within, between, and contextual effects
#' with 95% confidence intervals. Intended as a teaching diagram.
#'
#' @param x An object of class \code{hlm_context}.
#' @param ... Not used.
#'
#' @return A ggplot object.
#' @method plot hlm_context
#' @export
plot.hlm_context <- function(x, ...) {
  df <- x
  df$effect_type <- factor(
    df$effect_type,
    levels = c("Between-cluster", "Contextual (B - W)", "Within-cluster")
  )

  ggplot2::ggplot(df, ggplot2::aes(x = effect_type, y = estimate)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed") +
    ggplot2::geom_point() +
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = estimate - 1.96 * se,
                   ymax = estimate + 1.96 * se),
      width = 0.1
    ) +
    ggplot2::labs(
      x = NULL,
      y = "Effect size",
      title = "Within, between, and contextual effects"
    ) +
    ggplot2::theme_minimal()
}

#' Convenience wrapper to plot contextual effects
#'
#' @param object An object of class \code{hlm_context}.
#'
#' @return A ggplot object.
#' @export
hlm_context_plot <- function(object) {
  plot(object)
}
