# Characterization test for gl.download.binary (function-review baseline).
# Snapshots what the function does today, bugs included: it detects change,
# it does not assert correctness. Needs network access to GitHub.

test_that("listing mode prints the table and returns NULL", {
  skip_on_cran()
  skip_if_offline("api.github.com")
  out <- capture.output(res <- gl.download.binary(verbose = 0))
  expect_null(res)
  expect_true(any(grepl("Available binaries", out)))
})

test_that("unknown os errors", {
  expect_error(gl.download.binary("epos", os = "solaris"), "not supported")
})

test_that("os is partially matched", {
  skip_on_cran()
  skip_if_offline("raw.githubusercontent.com")
  d <- file.path(tempdir(), "baseline_pm")
  res <- gl.download.binary("epos", os = "win", out.dir = d, verbose = 0)
  expect_equal(res, file.path(d, "epos"))
})

test_that("lower-case software names download on every os", {
  skip_on_cran()
  skip_if_offline("raw.githubusercontent.com")
  for (os in c("windows", "mac", "linux")) {
    d <- file.path(tempdir(), paste0("baseline_", os))
    res <- gl.download.binary("gone", os = os, out.dir = d, verbose = 0)
    # Returned path is out.dir/software whether or not the zip creates it
    expect_equal(res, file.path(d, "gone"))
    expect_true(length(list.files(d, recursive = TRUE)) > 0)
  }
})

# Changed by review change 1: mixed-case names used to error "not available"
test_that("mixed-case names are lower-cased and download", {
  skip_on_cran()
  skip_if_offline("raw.githubusercontent.com")
  d <- file.path(tempdir(), "baseline_case")
  res <- gl.download.binary("NeEstimator", os = "linux", out.dir = d,
                            verbose = 0)
  expect_equal(res, file.path(d, "neestimator"))
  expect_true(dir.exists(res))
})

# Review change 2: listing queries the tree of `branch`, not always `dev`
test_that("listing mode uses branch", {
  urls <- character(0)
  with_mocked_bindings(
    try(gl.download.binary(branch = "main", verbose = 0), silent = TRUE),
    GET = function(url, ...) {
      urls <<- c(urls, url)
      stop("captured")
    },
    .package = "dartRverse"
  )
  expect_match(urls, "/git/trees/main\\?recursive=1$")
})

# Review change 3: API refusal gives a clear message
test_that("listing mode reports a GitHub API refusal", {
  with_mocked_bindings(
    expect_error(gl.download.binary(verbose = 0),
                 "did not return the list of binaries \\(API rate limit"),
    GET = function(...) structure(list(), class = "fake"),
    content = function(...) list(message = "API rate limit exceeded"),
    .package = "dartRverse"
  )
})

# Review change 4: 404 means "not available", other failures show the cause,
# and raw download.file warnings are not printed
test_that("a 404 errors 'not available' without raw warnings", {
  skip_on_cran()
  skip_if_offline("raw.githubusercontent.com")
  expect_no_warning(
    expect_error(
      gl.download.binary("faststructure", os = "windows",
                         out.dir = tempdir(), verbose = 0),
      "not available"
    )
  )
})

test_that("a network failure reports its cause", {
  with_mocked_bindings(
    expect_error(
      gl.download.binary("plink", os = "linux", out.dir = tempdir(),
                         verbose = 0),
      "failed \\(Could not resolve host.*internet connection"
    ),
    download.file = function(...) stop("Could not resolve host: github"),
    .package = "dartRverse"
  )
})

# Review change 5: software must be a single string
test_that("software must be a single string", {
  expect_error(gl.download.binary(c("gone", "plink"), os = "linux"),
               "single character string")
  expect_error(gl.download.binary(1, os = "linux"),
               "single character string")
})
