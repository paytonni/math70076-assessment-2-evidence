args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
if (length(file_arg) > 0L) {
  this_file <- normalizePath(sub("^--file=", "", file_arg[[1]]))
} else {
  file_index <- match("-f", args)
  if (is.na(file_index) || file_index == length(args)) {
    stop("Unable to determine the path of this script")
  }
  this_file <- normalizePath(args[[file_index + 1L]])
}
project_root <- normalizePath(file.path(dirname(this_file), ".."))

stage1_env <- new.env(parent = globalenv())
stage2_env <- new.env(parent = globalenv())
sys.source(
  file.path(
    project_root,
    "..",
    "question_3_function_design",
    "improved",
    "pt_sampler_improved.R"
  ),
  envir = stage1_env
)
sys.source(
  file.path(project_root, "improved_stage2", "pt_sampler_stage2.R"),
  envir = stage2_env
)

fixed_points <- c(
  2, 2.0001, 2.5, 5, 10, 19.9, 20,
  20.1, 25, 29, 30, 31, 40
)
below_support_points <- c(-10, 0, 1, 1.999999)
set.seed(20260811)
random_points <- c(
  runif(500, min = 2, max = 40),
  2 + rexp(500, rate = 0.05)
)

compare_target <- function(points) {
  vector_values <- stage1_env$coursework_log_target(points)
  scalar_values <- vapply(
    points,
    stage2_env$coursework_log_target_scalar,
    numeric(1)
  )
  finite_pairs <- is.finite(vector_values) & is.finite(scalar_values)
  max_difference <- if (any(finite_pairs)) {
    max(abs(vector_values[finite_pairs] - scalar_values[finite_pairs]))
  } else {
    0
  }
  non_finite_mismatch <- sum(
    is.finite(vector_values) != is.finite(scalar_values) |
      (is.infinite(vector_values) & is.infinite(scalar_values) &
         sign(vector_values) != sign(scalar_values))
  )
  list(
    vector = vector_values,
    scalar = scalar_values,
    max_difference = max_difference,
    non_finite_mismatch = non_finite_mismatch
  )
}

fixed_comparison <- compare_target(fixed_points)
random_comparison <- compare_target(random_points)
support_comparison <- compare_target(below_support_points)

support_correct <- all(
  is.infinite(support_comparison$vector) &
    support_comparison$vector < 0 &
    is.infinite(support_comparison$scalar) &
    support_comparison$scalar < 0
)
scalar_rejects_vector <- inherits(
  try(stage2_env$coursework_log_target_scalar(c(2, 3)), silent = TRUE),
  "try-error"
)
max_difference <- max(
  fixed_comparison$max_difference,
  random_comparison$max_difference
)
non_finite_mismatch <-
  fixed_comparison$non_finite_mismatch +
  random_comparison$non_finite_mismatch +
  support_comparison$non_finite_mismatch
equivalence_passed <-
  max_difference <= 1e-12 &&
  non_finite_mismatch == 0L &&
  support_correct &&
  scalar_rejects_vector

validation <- data.frame(
  check = c(
    "fixed_points_count",
    "random_points_count",
    "below_support_points_count",
    "fixed_points_max_absolute_log_density_difference",
    "random_points_max_absolute_log_density_difference",
    "overall_max_absolute_log_density_difference",
    "non_finite_mismatch_count",
    "support_handling_correct",
    "scalar_rejects_vector_input",
    "numeric_equivalence_passed"
  ),
  value = c(
    length(fixed_points),
    length(random_points),
    length(below_support_points),
    fixed_comparison$max_difference,
    random_comparison$max_difference,
    max_difference,
    non_finite_mismatch,
    as.integer(support_correct),
    as.integer(scalar_rejects_vector),
    as.integer(equivalence_passed)
  ),
  stringsAsFactors = FALSE
)

write.csv(
  validation,
  file.path(project_root, "results", "stage2_target_validation.csv"),
  row.names = FALSE
)

cat("Stage 2 target validation\n")
print(validation)

if (!equivalence_passed) {
  stop("Stage 2 target failed numerical-equivalence validation")
}
