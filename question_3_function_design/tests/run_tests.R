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
Sys.setenv(ASSESSMENT2_Q3_Q4_ROOT = project_root)

cat(sprintf("Test run: %s\n", format(Sys.time(), tz = "Europe/London")))
cat(sprintf("R version: %s\n\n", R.version.string))
testthat::test_dir(
  file.path(project_root, "tests", "testthat"),
  reporter = "summary",
  stop_on_failure = TRUE,
  stop_on_warning = FALSE
)
