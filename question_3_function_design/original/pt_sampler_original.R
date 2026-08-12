# Original MATH70093 coursework implementation extracted from the submitted
# executable R Markdown. The submission and assessment PDFs are deliberately
# not included in this public evidence repository.
#
# The algorithm below is intentionally preserved without refactoring.
# Assessment 2 design/performance changes belong in improved/, not this file.

logf <- function(x) {
  out <- rep(-Inf, length(x))
  idx <- (x >= 2)
  if (any(idx)) {
    xx <- x[idx]
    term1 <- -3 * (xx - 2)
    term2 <- -(xx - 30)^2
    term3 <- -(xx - 20)^2 / 0.01
    m <- pmax(term1, term2, term3)
    out[idx] <- m + log(exp(term1 - m) + exp(term2 - m) + exp(term3 - m))
  }
  out
}

r_trunc_norm <- function(current, sigma) {
  repeat {
    y <- rnorm(1, mean = current, sd = sigma)
    if (y >= 2) return(y)
  }
}

Z_tail <- function(current, sigma) {
  1 - pnorm(2, mean = current, sd = sigma)
}

pt_rw_step_trunc <- function(x_curr, sigma, T) {
  prop <- r_trunc_norm(x_curr, sigma)

  log_pi_curr <- logf(x_curr)
  log_pi_prop <- logf(prop)

  log_alpha <- (1 / T) * (log_pi_prop - log_pi_curr) +
               log(Z_tail(x_curr, sigma)) - log(Z_tail(prop, sigma))

  if (is.finite(log_alpha) && log(runif(1)) < log_alpha) {
    list(x = prop, accepted = TRUE)
  } else {
    list(x = x_curr, accepted = FALSE)
  }
}

pt_sampler_trunc <- function(n, x0, sigmas, temps, swap_every = 10) {
  K <- length(temps)
  stopifnot(length(x0) == K, length(sigmas) == K)

  X <- matrix(NA_real_, nrow = n, ncol = K)
  X[1, ] <- x0

  acc_rw   <- integer(K)
  acc_swap <- integer(K - 1)

  for (t in 2:n) {
    for (k in 1:K) {
      step <- pt_rw_step_trunc(X[t - 1, k], sigma = sigmas[k], T = temps[k])
      X[t, k] <- step$x
      if (step$accepted) acc_rw[k] <- acc_rw[k] + 1
    }

    if (t %% swap_every == 0) {
      for (k in 1:(K - 1)) {
        xk   <- X[t, k]
        xkp1 <- X[t, k + 1]

        log_pi_k   <- logf(xk)
        log_pi_kp1 <- logf(xkp1)

        if (is.finite(log_pi_k) && is.finite(log_pi_kp1)) {
          log_alpha_swap <- (1 / temps[k] - 1 / temps[k + 1]) *
                            (log_pi_kp1 - log_pi_k)

          if (log(runif(1)) < log_alpha_swap) {
            X[t, k]     <- xkp1
            X[t, k + 1] <- xk
            acc_swap[k] <- acc_swap[k] + 1
          }
        }
      }
    }
  }

  list(
    samples  = X,
    temps    = temps,
    acc_rw   = acc_rw / (n - 1),
    acc_swap = acc_swap / floor((n - 1) / swap_every)
  )
}

# Representative settings used in the original coursework.
coursework_seed <- 1L
coursework_temps <- c(1, 5, 20, 50, 100, 200, 500)
coursework_sigmas <- c(1, 3, 6, 10, 14, 18, 20)
coursework_x0 <- rep(5, length(coursework_temps))
coursework_n <- 100000L
coursework_swap_every <- 5L
