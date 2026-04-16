#' Intraclass correlation and design effect from a random-intercept model
#'
#' Computes the intraclass correlation (ICC) and, optionally, a design effect
#' from a random-intercept multilevel model fitted with \code{lme4::lmer()}.
#'
#' @param model A fitted \code{lmerMod} object with at least one random intercept.
#' @param cluster_size Optional scalar giving the average cluster size, used
#'   to compute the design effect. If \code{NULL}, the design effect is not
#'   computed.
#'
#' @return An object of class \code{hlm_icc} with components:
#'   \item{icc}{Estimated intraclass correlation.}
#'   \item{deff}{Design effect (if cluster_size supplied).}
#'   \item{re_var}{Random intercept variance.}
#'   \item{resid_var}{Residual variance.}
#'
#' @examples
#' set.seed(3)
#' toy <- data.frame(
#'   math_score = rnorm(80, 50, 10),
#'   SES        = rnorm(80),
#'   school_id  = rep(seq_len(8), each = 10)
#' )
#' \donttest{
#' library(lme4)
#' m <- lmer(math_score ~ SES + (1 | school_id), data = toy)
#' hlm_icc(m, cluster_size = 10)
#' }
#' @export
hlm_icc <- function(model, cluster_size = NULL) {
  if (!inherits(model, "lmerMod")) {
    stop("hlm_icc currently supports models fitted with lme4::lmer().")
  }
  vc <- lme4::VarCorr(model)
  # assume the first random-effect term is the main clustering
  re_var <- as.numeric(vc[[1]])[1]
  resid_var <- attr(vc, "sc")^2
  icc <- re_var / (re_var + resid_var)
  if (!is.null(cluster_size)) {
    m <- cluster_size
    deff <- 1 + (m - 1) * icc
  } else {
    deff <- NA_real_
  }
  out <- list(
    icc       = icc,
    deff      = deff,
    re_var    = re_var,
    resid_var = resid_var
  )
  class(out) <- c("hlm_icc", class(out))
  out
}

#' @export
print.hlm_icc <- function(x, ...) {
  cat("Intraclass correlation (ICC) and design effect\n")
  cat(sprintf("  ICC           : %.3f\n", x$icc))
  cat(sprintf("  RE variance   : %.3f\n", x$re_var))
  cat(sprintf("  Residual var. : %.3f\n", x$resid_var))
  if (!is.na(x$deff)) {
    cat(sprintf("  Design effect : %.3f\n", x$deff))
  } else {
    cat("  Design effect : (not computed; supply 'cluster_size' to hlm_icc)\n")
  }
  invisible(x)
}

