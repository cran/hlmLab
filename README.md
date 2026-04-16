# hlmLab <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/hlmLab)](https://CRAN.R-project.org/package=hlmLab)
[![R-CMD-check](https://github.com/causalfragility-lab/hlmLab/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/causalfragility-lab/hlmLab/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**hlmLab** provides tools for visualization and decomposition in hierarchical linear models (HLM), designed for researchers and students in education, psychology, and the social sciences. It offers a coherent set of functions for understanding how variance is distributed across levels, how predictors operate within and between clusters, and how random slopes vary across groups — all built on top of `lme4`.

---

## Installation

Install the released version from CRAN:

```r
install.packages("hlmLab")
```

Or install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("causalfragility-lab/hlmLab")
```

---

## Overview of Functions

| Function | What it does |
|---|---|
| `hlm_decompose()` | Decomposes variance into within- and between-cluster components (2-level or 3-level) |
| `hlm_decompose_long()` | Convenience wrapper for 3-level longitudinal B-P-W decomposition |
| `hlm_icc()` | Computes the intraclass correlation (ICC) and design effect from a fitted model |
| `hlm_icc_plot()` | Visualizes ICC as a stacked variance-partitioning bar chart |
| `hlm_context()` | Extracts within-cluster, between-cluster, and contextual effects (Mundlak specification) |
| `hlm_context_plot()` | Plots within, between, and contextual effects with 95% confidence intervals |
| `hlm_xint_geom()` | Produces a fan plot of random slopes to illustrate cross-level interactions |

---

## Usage

### 1. Variance Decomposition

`hlm_decompose()` partitions the total variance of a continuous variable into between-cluster and within-cluster components without fitting a model — useful as a first diagnostic step.

```r
library(hlmLab)

# 2-level: students nested in schools
result <- hlm_decompose(data = mydata,
                        var     = "math_score",
                        cluster = "school_id")
result
#> HLM variance decomposition for: math_score
#> # A tibble: 3 × 3
#>   component            variance share
#>   <chr>                   <dbl> <dbl>
#> 1 Between clusters (B)     42.1 0.312
#> 2 Within clusters (W)      92.8 0.688
#> 3 Total                   134.9 1.000

plot(result)
```

For 3-level longitudinal data (students measured repeatedly within schools):

```r
result_long <- hlm_decompose_long(data    = mydata_long,
                                  var     = "math_score",
                                  cluster = "school_id",
                                  id      = "student_id",
                                  time    = "wave")
plot(result_long)
```

The plot shows a bar chart of variance shares across Between-cluster (B), Between-person (P), and Within-person (W) components.

---

### 2. Intraclass Correlation (ICC) and Design Effect

`hlm_icc()` computes the ICC from a fitted `lme4` random-intercept model. Supplying `cluster_size` also returns the design effect, which quantifies how much clustering inflates standard errors relative to simple random sampling.

```r
library(lme4)

m0 <- lmer(math_score ~ 1 + (1 | school_id), data = mydata)

hlm_icc(m0, cluster_size = 25)
#> Intraclass correlation (ICC) and design effect
#>   ICC           : 0.312
#>   RE variance   : 42.1
#>   Residual var. : 92.8
#>   Design effect : 8.48
```

Visualize the ICC as a variance-partitioning diagram:

```r
hlm_icc_plot(m0, cluster_size = 25)
```

The plot displays a horizontal stacked bar with between- and within-cluster variance shares, with the ICC and design effect shown in the subtitle.

---

### 3. Contextual Effect Decomposition (Mundlak Specification)

`hlm_context()` separates the total effect of a Level-1 predictor into its within-cluster component (the pure individual-level effect) and its between-cluster component (the group-level effect). The contextual effect is their difference (between − within), following Mundlak (1978).

The model must include both the within-cluster centered predictor and the cluster mean:

```r
# Center SES within schools and compute school means
mydata$SES_c    <- mydata$SES - ave(mydata$SES, mydata$school_id)
mydata$SES_mean <- ave(mydata$SES, mydata$school_id)

m1 <- lmer(math_score ~ SES_c + SES_mean + (1 | school_id),
           data = mydata)

ctx <- hlm_context(m1,
                   x_within  = "SES_c",
                   x_between = "SES_mean")
ctx
#> Contextual effect decomposition
#>          effect_type estimate    se
#>       Within-cluster     2.31  0.18
#>      Between-cluster     5.84  0.62
#>   Contextual (B - W)     3.53  0.65
```

Plot the three effects with 95% confidence intervals:

```r
hlm_context_plot(ctx)
# or equivalently:
plot(ctx)
```

---

### 4. Cross-Level Interaction Geometry (Random Slopes Fan Plot)

`hlm_xint_geom()` visualizes how a random slope varies across clusters, producing a fan plot where each line represents one cluster's predicted regression of the outcome on the Level-1 predictor. Spread in the fan indicates slope heterogeneity; a cross-level interaction moderates this spread.

```r
m2 <- lmer(math_score ~ SES_c + SES_mean + (SES_c | school_id),
           data = mydata)

hlm_xint_geom(m2,
              x_within   = "SES_c",
              cluster    = "school_id",
              n_clusters = 20)
```

Use `n_clusters` to limit the number of lines displayed when you have many groups.

---

## Theoretical Background

hlmLab implements methods from the following foundational references:

- **Variance decomposition and ICC:** Snijders & Bosker (2012). *Multilevel Analysis*. SAGE. ISBN: 9781849202015
- **ICC and design effect:** Shrout & Fleiss (1979). *Psychological Bulletin*, 86(2), 420–428. [doi:10.1037/0033-2909.86.2.420](https://doi.org/10.1037/0033-2909.86.2.420)
- **Contextual effects / Mundlak specification:** Mundlak (1978). *Econometrica*, 46(1), 69–85. [doi:10.2307/1913646](https://doi.org/10.2307/1913646)
- **Random slopes and cross-level interactions:** Hofmann & Gavin (1998). *Journal of Management*, 24(5), 623–641. [doi:10.1177/014920639802400504](https://doi.org/10.1177/014920639802400504)
- **Cross-level interaction visualization:** Hamaker & Muthen (2020). *Psychological Methods*, 25(2), 157–173. [doi:10.1037/met0000239](https://doi.org/10.1037/met0000239)
- **Model estimation via lme4:** Bates et al. (2015). *Journal of Statistical Software*, 67(1), 1–48. [doi:10.18637/jss.v067.i01](https://doi.org/10.18637/jss.v067.i01)
- **General HLM framework:** Raudenbush & Bryk (2002). *Hierarchical Linear Models*. SAGE. ISBN: 9780761919049

---

## Citation

If you use hlmLab in your research, please cite it:

```r
citation("hlmLab")
```

```
Hait S (2025). hlmLab: Hierarchical Linear Modeling with Visualization
and Decomposition. R package version 0.1.0.
https://github.com/causalfragility-lab/hlmLab
```

---

## Contributing

Bug reports and feature requests are welcome at the [issue tracker](https://github.com/causalfragility-lab/hlmLab/issues). Please include a minimal reproducible example with any bug report.

---

## License

MIT © Subir Hait
