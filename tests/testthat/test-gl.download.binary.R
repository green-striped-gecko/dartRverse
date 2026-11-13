# Characterization test for gl.download.binary (function-review baseline).
# Snapshots what the function does today, bugs included: it detects change,
# it does not assert correctness. Needs network access to GitHub.

test_that("listing mode prints the table and returns NULL", {
  skip_on_cran()
  skip_if_offline("api.github.com")
  # GitHub throttles shared CI runners; that is not a failure of the function
  out <- tryCatch(
    capture.output(res <- gl.download.binary(verbose = 0)),
    error = function(e) {
      if (grepl("rate limit", conditionMessage(e))) {
        skip("GitHub API rate limit exceeded")
      }
      stop(e)
    }
  )
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

# Listing sends GITHUB_PAT when set, and no header when unset
test_that("listing mode authenticates with GITHUB_PAT", {
  captured <- list()
  capture_get <- function(url, ...) {
    captured[[length(captured) + 1]] <<- list(...)
    stop("captured")
  }
  with_mocked_bindings({
    withr::with_envvar(c(GITHUB_PAT = "abc123"),
      try(gl.download.binary(verbose = 0), silent = TRUE))
    withr::with_envvar(c(GITHUB_PAT = NA),
      try(gl.download.binary(verbose = 0), silent = TRUE))
  }, GET = capture_get, .package = "dartRverse")
  expect_equal(captured[[1]][[1]]$headers[["Authorization"]], "token abc123")
  expect_null(captured[[2]][[1]])
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

# Ticks in the table are links where the console supports them
test_that("ticks run a download, open the zip, or stay plain", {
  # cli only writes links when it thinks the console shows them
  withr::local_options(cli.hyperlink = TRUE, cli.hyperlink_run = TRUE)
  run <- binary_cell("plink", "mac", "main", list(href = TRUE, run = TRUE))
  expect_match(run, "dartRverse::download_binary('plink', os = 'mac')", fixed = TRUE)
  # RStudio runs only pkg::fun(args) with no dots in the names and no ( ) ; in args
  code <- sub("\a.*", "", sub("^.*?run:", "", run, perl = TRUE))
  expect_match(code, "^\\w+::\\w+[(][^();]*[)]$", perl = TRUE)
  dev <- binary_cell("plink", "mac", "dev", list(href = TRUE, run = TRUE))
  expect_match(dev, "branch = 'dev'", fixed = TRUE)
  href <- binary_cell("plink", "linux", "main", list(href = TRUE, run = FALSE))
  expect_match(href, binary_url("plink", "linux", "main"), fixed = TRUE)
  plain <- binary_cell("plink", "linux", "main", list(href = FALSE, run = FALSE))
  expect_equal(cli::ansi_strip(plain), binary_symbols()$tick)
})

# The table only uses symbols that console fonts draw one character wide
test_that("tick and cross are in common console fonts", {
  withr::local_options(cli.unicode = TRUE)
  expect_equal(binary_symbols(), list(tick = "\u221a", cross = "\u00d7"))
  withr::local_options(cli.unicode = FALSE)
  expect_equal(binary_symbols(), list(tick = "v", cross = "x"))
})

# The alias used by the links passes its arguments on unchanged
test_that("download_binary() is gl.download.binary()", {
  expect_error(download_binary(1, os = "linux"), "single character string")
})

# After a download the user is told what it is, where it is used, and to cite it
test_that("the notice names the software, its functions and asks for a citation", {
  withr::local_options(cli.hyperlink = FALSE)
  # pretend every function has a help page, whatever dartR versions are installed
  all.help <- function(pkg, fun) TRUE
  n <- binary_notice("structure", has_help = all.help)
  expect_equal(n[1], "Downloaded STRUCTURE.")
  expect_match(n[2], "gl.run.structure(), gl.plot.structure(), gl.evanno(), gl.map.structure() in dartR.popgen",
               fixed = TRUE)
  expect_match(n[3], "check the help pages of the functions above", fixed = TRUE)
  n <- binary_notice("plink", has_help = all.help)
  expect_match(n[2], "in dartR.base; gl.inbreeding() in dartR.captive", fixed = TRUE)
  # software that no dartR function runs yet still gets the citation request
  n <- binary_notice("gone")
  expect_length(n, 2)
  expect_match(n[2], "GONE is the work of others", fixed = TRUE)
})

# An installed but older package without the function gets no link
test_that("functions missing from an older installed version are marked", {
  # installed is enough; the notice never loads the package
  skip_if(!nzchar(system.file(package = "dartR.captive")), "dartR.captive is not installed")
  no.inbreeding <- function(pkg, fun) fun != "gl.inbreeding"
  n <- binary_notice("plink", has_help = no.inbreeding)
  expect_match(n[2], "gl.inbreeding() (needs a newer dartR.captive) in dartR.captive", fixed = TRUE)
})

test_that("every documented binary has an entry and the functions exist", {
  documented <- c("beagle", "colony", "eems", "emibd9", "epos", "faststructure", "gone",
                  "ms", "neestimator", "plink", "popcluster", "stairway2", "structure")
  expect_true(all(documented %in% names(binary_info())))
  # only against the dartR versions the list was written for; older versions
  # (e.g. CRAN 1.2.2) do not have all these functions yet
  for (f in unlist(lapply(binary_info(), `[[`, "funs"))) {
    pkg <- sub("::.*", "", f)
    if (!nzchar(system.file(package = pkg)) || utils::packageVersion(pkg) < "1.2.7") next
    expect_true(sub(".*::", "", f) %in% getNamespaceExports(pkg), label = f)
  }
})

test_that("functions missing from the installed version are not linked", {
  expect_true(binary_has_help("stats", "median"))
  expect_false(binary_has_help("stats", "gl.not.a.function"))
  expect_false(binary_has_help("dartR.not.a.package", "median"))
})

test_that("functions are help links where the console supports them", {
  withr::local_options(cli.hyperlink = TRUE, cli.hyperlink_help = TRUE)
  skip_if_not_installed("dartR.popgen")
  expect_match(binary_notice("epos")[2], "help:dartR.popgen::gl.run.epos", fixed = TRUE)
})

# mac and linux binaries are made executable for everyone
test_that("unzipped mac and linux binaries get mode 777", {
  skip_on_os("windows")  # Windows has no execute permission bits
  skip_on_cran()
  skip_if_offline("raw.githubusercontent.com")
  d <- file.path(tempdir(), "baseline_chmod")
  gl.download.binary("gone", os = "linux", out.dir = d, verbose = 0)
  f <- list.files(d, recursive = TRUE, full.names = TRUE)
  expect_true(all(as.character(file.mode(f)) == "777"))
})
