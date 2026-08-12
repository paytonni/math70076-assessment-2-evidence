# Stage 2 Assessment 2 implementation.
#
# This file is independent of improved/pt_sampler_improved.R. The sampler,
# validation, caching, log-tail calculation, return structure, statistical
# target and Parallel Tempering rules are retained from Stage 1. The only new
# performance change is a scalar-specialised coursework target evaluator.

#' Vector-capable coursework target log density
#'
#' Evaluate the unnormalised log density used in the original MATH70093
#' coursework for a numeric vector. The support is `[2, Inf)`. This function
#' retains the general vector implementation used in Assessment 2 Stage 1 and
#' serves as the numerical reference for the Stage 2 scalar evaluator.
#'
#' @param x Numeric vector of states.
#' @return A numeric vector of unnormalised log-density values.
#' @export
coursework_log_target_vector <- function(x) {
  out <- rep(-Inf, length(x))
  idx <- x >= 2
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

#' Scalar-specialised coursework target log density
#'
#' Evaluate the same unnormalised coursework target as
#' `coursework_log_target_vector()`, but require exactly one finite state. This
#' implementation is intended for the scalar-heavy MCMC inner loop. It avoids
#' vector allocation, logical subsetting, `any()` and `pmax()` while retaining
#' the same stable log-sum-exp calculation and support `[2, Inf)`.
#'
#' This is a coursework-specific target implementation, not a target hard-coded
#' into the generic sampler. `pt_sampler_trunc()` continues to accept any valid
#' scalar log-target function through its explicit `log_target` argument.
#'
#' @param x One finite numeric state.
#' @return One unnormalised log-density value, or `-Inf` below the support.
#' @export
coursework_log_target_scalar <- function(x) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) {
    stop("x must be one finite numeric state", call. = FALSE)
  }
  if (x < 2) {
    return(-Inf)
  }

  term1 <- -3 * (x - 2)
  term2 <- -(x - 30)^2
  term3 <- -(x - 20)^2 / 0.01

  largest_term <- term1
  if (term2 > largest_term) {
    largest_term <- term2
  }
  if (term3 > largest_term) {
    largest_term <- term3
  }

  largest_term + log(
    exp(term1 - largest_term) +
      exp(term2 - largest_term) +
      exp(term3 - largest_term)
  )
}

# Backward-compatible Stage 1 target name. The Stage 2 benchmark deliberately
# passes coursework_log_target_scalar instead of this vector-capable function.
coursework_log_target <- coursework_log_target_vector

#' Draw from a lower-truncated normal random-walk proposal
#'
#' Repeatedly draw from `N(current, sigma^2)` until the proposal is at or
#' above `lower_bound`. This preserves the rejection-sampling mechanism in the
#' original coursework implementation.
#'
#' @param current Current scalar chain state.
#' @param sigma Positive proposal standard deviation.
#' @param lower_bound Finite lower truncation bound.
#' @return One numeric proposal at or above `lower_bound`.
#' @keywords internal
r_trunc_norm <- function(current, sigma, lower_bound) {
  repeat {
    proposal <- rnorm(1, mean = current, sd = sigma)
    if (proposal >= lower_bound) {
      return(proposal)
    }
  }
}

#' Log probability above a normal truncation bound
#'
#' @param current Scalar normal mean.
#' @param sigma Positive normal standard deviation.
#' @param lower_bound Finite lower truncation bound.
#' @return The log upper-tail probability.
#' @keywords internal
log_Z_tail <- function(current, sigma, lower_bound) {
  pnorm(
    lower_bound,
    mean = current,
    sd = sigma,
    lower.tail = FALSE,
    log.p = TRUE
  )
}

#' Perform one tempered truncated-normal Metropolis step
#'
#' The current log-target value is supplied and the accepted value is returned.
#' This avoids evaluating the target twice on successive iterations while
#' preserving the Metropolis-Hastings acceptance probability.
#'
#' @param x_curr Current scalar state.
#' @param log_pi_curr Unnormalised log-target value at `x_curr`.
#' @param sigma Positive proposal standard deviation.
#' @param temperature Positive chain temperature.
#' @param log_target Function mapping a numeric state to a scalar log density.
#' @param lower_bound Finite lower truncation bound.
#' @return A list with `x`, `log_target`, and logical `accepted`.
#' @keywords internal
pt_rw_step_trunc <- function(
  x_curr,
  log_pi_curr,
  sigma,
  temperature,
  log_target,
  lower_bound
) {
  proposal <- r_trunc_norm(x_curr, sigma, lower_bound)
  log_pi_proposal <- log_target(proposal)

  log_alpha <- (log_pi_proposal - log_pi_curr) / temperature +
    log_Z_tail(x_curr, sigma, lower_bound) -
    log_Z_tail(proposal, sigma, lower_bound)

  if (is.finite(log_alpha) && log(runif(1)) < log_alpha) {
    list(x = proposal, log_target = log_pi_proposal, accepted = TRUE)
  } else {
    list(x = x_curr, log_target = log_pi_curr, accepted = FALSE)
  }
}

.is_whole_number <- function(x) {
  length(x) == 1L && is.numeric(x) && is.finite(x) && x == floor(x)
}

#' Parallel tempering with lower-truncated normal proposals
#'
#' Run adjacent-swap parallel tempering. Each chain uses a random-walk normal
#' proposal truncated below at `lower_bound`; chain `k` targets a density
#' proportional to `exp(log_target(x) / temps[k])`. Every `swap_every`
#' iterations, adjacent temperature chains attempt a Metropolis swap.
#'
#' The function caches each chain's current log-target value. This optimisation
#' removes repeated deterministic density evaluations without changing the
#' target distribution or the sequence of random-number calls. Stage 2 does not
#' hard-code a target: the caller chooses either a generic or specialised target
#' implementation through `log_target`.
#'
#' @param log_target Function accepting a numeric state and returning one
#'   unnormalised log-density value. It must be finite at every initial state.
#' @param lower_bound Finite scalar lower bound for the proposal support.
#' @param n Integer number of iterations, including the initial state; at least 2.
#' @param x0 Numeric vector of initial states, one per temperature chain. Every
#'   value must be finite and at or above `lower_bound`.
#' @param sigmas Positive finite proposal standard deviations, one per chain.
#' @param temps Positive, finite, strictly increasing temperatures, one per
#'   chain. At least two chains are required.
#' @param swap_every Positive integer number of iterations between adjacent-swap
#'   attempts. It must not exceed `n - 1`.
#'
#' @return A list containing:
#'   * `samples`: an `n` by `length(temps)` numeric matrix;
#'   * `temps` and `sigmas`: the supplied chain settings;
#'   * `lower_bound`: the supplied truncation bound;
#'   * `acc_rw`: within-chain acceptance rates;
#'   * `acc_swap`: adjacent-chain swap acceptance rates.
#'
#' @details
#' The caller controls reproducibility with `set.seed()` before calling this
#' function. Caching reduces target evaluations but retains all samples. It does
#' not change the temperature ladder, proposal mechanism, swap rule, or target.
#'
#' @examples
#' set.seed(1)
#' result <- pt_sampler_trunc(
#'   log_target = coursework_log_target_scalar,
#'   lower_bound = 2,
#'   n = 1000,
#'   x0 = rep(5, 3),
#'   sigmas = c(1, 3, 6),
#'   temps = c(1, 5, 20),
#'   swap_every = 5
#' )
#' @export
pt_sampler_trunc <- function(
  log_target,
  lower_bound,
  n,
  x0,
  sigmas,
  temps,
  swap_every = 10L
) {
  if (!is.function(log_target)) {
    stop("log_target must be a function", call. = FALSE)
  }
  if (length(lower_bound) != 1L || !is.numeric(lower_bound) || !is.finite(lower_bound)) {
    stop("lower_bound must be one finite numeric value", call. = FALSE)
  }
  if (!.is_whole_number(n) || n < 2) {
    stop("n must be an integer of at least 2", call. = FALSE)
  }
  if (!.is_whole_number(swap_every) || swap_every < 1 || swap_every > n - 1) {
    stop("swap_every must be an integer between 1 and n - 1", call. = FALSE)
  }
  if (!is.numeric(temps) || length(temps) < 2L || any(!is.finite(temps)) ||
      any(temps <= 0) || any(diff(temps) <= 0)) {
    stop("temps must contain at least two finite, positive, increasing values", call. = FALSE)
  }

  K <- length(temps)
  if (!is.numeric(x0) || length(x0) != K || any(!is.finite(x0)) ||
      any(x0 < lower_bound)) {
    stop("x0 must contain one finite value per chain at or above lower_bound", call. = FALSE)
  }
  if (!is.numeric(sigmas) || length(sigmas) != K || any(!is.finite(sigmas)) ||
      any(sigmas <= 0)) {
    stop("sigmas must contain one finite positive value per chain", call. = FALSE)
  }

  current_log_target <- vapply(x0, log_target, numeric(1))
  if (any(!is.finite(current_log_target))) {
    stop("log_target must be finite at every initial state", call. = FALSE)
  }

  n <- as.integer(n)
  swap_every <- as.integer(swap_every)
  samples <- matrix(NA_real_, nrow = n, ncol = K)
  samples[1, ] <- x0
  accepted_rw <- integer(K)
  accepted_swap <- integer(K - 1L)

  for (iteration in 2:n) {
    for (chain in seq_len(K)) {
      step <- pt_rw_step_trunc(
        x_curr = samples[iteration - 1L, chain],
        log_pi_curr = current_log_target[chain],
        sigma = sigmas[chain],
        temperature = temps[chain],
        log_target = log_target,
        lower_bound = lower_bound
      )
      samples[iteration, chain] <- step$x
      current_log_target[chain] <- step$log_target
      if (step$accepted) {
        accepted_rw[chain] <- accepted_rw[chain] + 1L
      }
    }

    if (iteration %% swap_every == 0L) {
      for (chain in seq_len(K - 1L)) {
        next_chain <- chain + 1L
        log_pi_chain <- current_log_target[chain]
        log_pi_next <- current_log_target[next_chain]
        log_alpha_swap <- (1 / temps[chain] - 1 / temps[next_chain]) *
          (log_pi_next - log_pi_chain)

        if (is.finite(log_alpha_swap) && log(runif(1)) < log_alpha_swap) {
          state_buffer <- samples[iteration, chain]
          samples[iteration, chain] <- samples[iteration, next_chain]
          samples[iteration, next_chain] <- state_buffer

          log_buffer <- current_log_target[chain]
          current_log_target[chain] <- current_log_target[next_chain]
          current_log_target[next_chain] <- log_buffer
          accepted_swap[chain] <- accepted_swap[chain] + 1L
        }
      }
    }
  }

  swap_attempts <- floor((n - 1L) / swap_every)
  list(
    samples = samples,
    temps = temps,
    sigmas = sigmas,
    lower_bound = lower_bound,
    acc_rw = accepted_rw / (n - 1L),
    acc_swap = accepted_swap / swap_attempts
  )
}

# Full coursework configuration retained for Stage 2.
coursework_seed <- 1L
coursework_lower_bound <- 2
coursework_temps <- c(1, 5, 20, 50, 100, 200, 500)
coursework_sigmas <- c(1, 3, 6, 10, 14, 18, 20)
coursework_x0 <- rep(5, length(coursework_temps))
coursework_n <- 100000L
coursework_swap_every <- 5L
