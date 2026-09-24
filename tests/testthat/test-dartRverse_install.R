# Characterization test for dartRverse_install (function-review baseline).
# Snapshots what the function does today, bugs included: it detects change,
# it does not assert correctness. Installers are mocked; nothing is installed.

# Record which installer was called and with what arguments
mock_installers <- function(code) {
  calls <- list()
  with_mocked_bindings(
    with_mocked_bindings(
      code,
      install_github = function(repo, ...) {
        calls[[length(calls) + 1]] <<- list(fun = "install_github",
                                            repo = repo, args = list(...))
        invisible(TRUE)
      },
      .package = "remotes"
    ),
    install.packages = function(pkgs, ...) {
      calls[[length(calls) + 1]] <<- list(fun = "install.packages",
                                          repo = pkgs, args = list(...))
      invisible(NULL)
    },
    .package = "dartRverse"
  )
  calls
}

test_that("CRAN install calls install.packages with the package name", {
  calls <- mock_installers(
    res <- dartRverse_install("dartR.sim", rep = "CRAN")
  )
  expect_length(calls, 1)
  expect_equal(calls[[1]]$fun, "install.packages")
  expect_equal(calls[[1]]$repo, "dartR.sim")
  expect_null(res)
})

test_that("Github install calls install_github on the branch", {
  calls <- mock_installers(
    dartRverse_install("dartR.sim", rep = "github", branch = "dev")
  )
  expect_length(calls, 1)
  expect_equal(calls[[1]]$fun, "install_github")
  expect_equal(calls[[1]]$repo, "green-striped-gecko/dartR.sim")
  expect_equal(calls[[1]]$args$ref, "dev")
  expect_true(calls[[1]]$args$dependencies)
})

test_that("rep is partially matched", {
  calls <- mock_installers(dartRverse_install("dartR.sim", rep = "G"))
  expect_equal(calls[[1]]$fun, "install_github")
})

# Changed by review change 3: used to print a blank line and return -1
test_that("unknown package errors and installs nothing", {
  calls <- mock_installers(
    expect_error(dartRverse_install("dartR.popgn"),
                 "Unknown dartRverse package: dartR.popgn.*dartR.captive")
  )
  expect_length(calls, 0)
})

# Changed by review change 4: used to return NULL silently
test_that("unrecognised or NULL rep errors and installs nothing", {
  calls <- mock_installers({
    expect_error(dartRverse_install("dartR.sim", rep = "bioconductor"),
                 "rep must be")
    expect_error(dartRverse_install("dartR.sim", rep = NULL), "rep must be")
  })
  expect_length(calls, 0)
})

# Changed by review change 5: used to error "the condition has length > 1"
test_that("several packages are installed in turn", {
  calls <- mock_installers(
    dartRverse_install(c("dartR.sim", "dartR.popgen"), rep = "Github")
  )
  expect_equal(vapply(calls, `[[`, "", "repo"),
               c("green-striped-gecko/dartR.sim",
                 "green-striped-gecko/dartR.popgen"))
})

# Review change 3 applies to every name before anything is installed
test_that("one bad name in a vector installs nothing", {
  calls <- mock_installers(
    expect_error(dartRverse_install(c("dartR.sim", "dartR.popgn")),
                 "Unknown")
  )
  expect_length(calls, 0)
})

# Review change 1: no detach warnings; restart advice for a loaded package
test_that("reinstalling a loaded package advises a restart", {
  expect_no_warning(
    calls <- mock_installers(
      out <- capture.output(dartRverse_install("dartR.base", rep = "CRAN"))
    )
  )
  expect_true(any(grepl("Restart R to use the new version of dartR.base",
                        out)))
})

# Review change 2: missing Bioconductor imports stop before installing
test_that("missing Bioconductor packages stop with BiocManager commands", {
  calls <- with_mocked_bindings(
    mock_installers(
      expect_error(dartRverse_install("dartR.sim"),
                   "snpStats must be installed first.*BiocManager::install\\('snpStats'\\)")
    ),
    is_installed = function(pkg, ...) pkg != "snpStats",
    .package = "rlang"
  )
  expect_length(calls, 0)
})

# Review change 6: a failed read shows ? and the table still prints
test_that("listing survives failed GitHub reads", {
  skip_on_cran()
  skip_if_offline("cran.r-project.org")
  out <- with_mocked_bindings(
    capture.output(res <- dartRverse_install()),
    readLines = function(...) stop("cannot open the connection"),
    .package = "base"
  )
  expect_equal(res, 1)
  expect_equal(sum(grepl("dartR\\.", out)), 7)
  expect_true(any(grepl("could not be read from Github", out)))
})

test_that("'all' prints instructions and installs nothing", {
  calls <- mock_installers(
    out <- capture.output(res <- dartRverse_install("all"))
  )
  expect_length(calls, 0)
  expect_null(res)
  expect_true(any(grepl("BiocManager::install\\('snpStats'\\)", out)))
})

test_that("verbose = FALSE with no package prints nothing", {
  out <- capture.output(res <- dartRverse_install(verbose = FALSE))
  expect_length(out, 0)
  expect_equal(res, 1)
})

test_that("listing prints one line per dartR package", {
  skip_on_cran()
  skip_if_offline("raw.githubusercontent.com")
  out <- capture.output(res <- dartRverse_install())
  expect_equal(res, 1)
  expect_equal(sum(grepl("dartR\\.", out)), 7)
  expect_true(all(grepl("CRAN: .* \\(main\\) .* \\(beta\\) .* \\(dev\\)",
                        out[grepl("dartR\\.", out)])))
})
