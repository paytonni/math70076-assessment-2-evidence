project_root <- Sys.getenv("ASSESSMENT2_Q3_Q4_ROOT")
stopifnot(nzchar(project_root))

original_env <- new.env(parent = globalenv())
improved_env <- new.env(parent = globalenv())
sys.source(file.path(project_root, "original", "pt_sampler_original.R"), envir = original_env)
sys.source(file.path(project_root, "improved", "pt_sampler_improved.R"), envir = improved_env)

testthat::test_that("improved sampler returns valid structured output", {
  set.seed(1)
  result <- improved_env$pt_sampler_trunc(
    log_target = improved_env$coursework_log_target,
    lower_bound = 2,
    n = 2000,
    x0 = rep(5, 7),
    sigmas = c(1, 3, 6, 10, 14, 18, 20),
    temps = c(1, 5, 20, 50, 100, 200, 500),
    swap_every = 5
  )

  testthat::expect_identical(dim(result$samples), c(2000L, 7L))
  testthat::expect_true(all(is.finite(result$samples)))
  testthat::expect_true(all(result$samples >= 2))
  testthat::expect_length(result$acc_rw, 7)
  testthat::expect_length(result$acc_swap, 6)
  testthat::expect_true(all(result$acc_rw >= 0 & result$acc_rw <= 1))
  testthat::expect_true(all(result$acc_swap >= 0 & result$acc_swap <= 1))
})

testthat::test_that("input validation rejects invalid configurations", {
  valid_args <- list(
    log_target = improved_env$coursework_log_target,
    lower_bound = 2,
    n = 100,
    x0 = c(5, 5),
    sigmas = c(1, 3),
    temps = c(1, 5),
    swap_every = 5
  )

  testthat::expect_error(do.call(improved_env$pt_sampler_trunc, modifyList(valid_args, list(log_target = 1))), "must be a function")
  testthat::expect_error(do.call(improved_env$pt_sampler_trunc, modifyList(valid_args, list(x0 = c(1, 5)))), "at or above")
  testthat::expect_error(do.call(improved_env$pt_sampler_trunc, modifyList(valid_args, list(sigmas = c(1, 0)))), "positive")
  testthat::expect_error(do.call(improved_env$pt_sampler_trunc, modifyList(valid_args, list(temps = c(5, 1)))), "increasing")
  testthat::expect_error(do.call(improved_env$pt_sampler_trunc, modifyList(valid_args, list(swap_every = 100))), "between 1 and n - 1")
})

testthat::test_that("original and improved implementations retain compatible behaviour", {
  n_test <- 5000L
  temps <- c(1, 5, 20, 50, 100, 200, 500)
  sigmas <- c(1, 3, 6, 10, 14, 18, 20)
  x0 <- rep(5, length(temps))

  set.seed(1)
  original <- original_env$pt_sampler_trunc(n_test, x0, sigmas, temps, 5)
  set.seed(1)
  improved <- improved_env$pt_sampler_trunc(
    improved_env$coursework_log_target,
    2,
    n_test,
    x0,
    sigmas,
    temps,
    5
  )

  testthat::expect_identical(dim(original$samples), dim(improved$samples))
  testthat::expect_true(all(improved$samples >= 2))
  testthat::expect_lt(max(abs(original$acc_rw - improved$acc_rw)), 0.05)
  testthat::expect_lt(max(abs(original$acc_swap - improved$acc_swap)), 0.05)
  testthat::expect_lt(abs(mean(original$samples[, 1]) - mean(improved$samples[, 1])), 2)
})
