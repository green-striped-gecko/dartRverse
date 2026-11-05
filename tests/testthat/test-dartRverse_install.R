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

# Regression tests from the second review
# (function-review/reports/dartRverse/dartRverse_install_review2.md).

# Installers that run the supplied behaviour and record each call
mock_with <- function(code, gh = function(repo, ...) invisible(TRUE),
                      cran = function(pkgs, ...) invisible(NULL)) {
  calls <- character(0)
  with_mocked_bindings(
    with_mocked_bindings(
      code,
      install_github = function(repo, ...) {
        calls <<- c(calls, repo)
        gh(repo, ...)
      },
      .package = "remotes"
    ),
    install.packages = function(pkgs, ...) {
      calls <<- c(calls, pkgs)
      cran(pkgs, ...)
    },
    .package = "dartRverse"
  )
  calls
}

# Version table with no network: every remote read fails
offline_table <- function(status) {
  with_mocked_bindings(
    with_mocked_bindings(
      capture.output(res <- dartRverse_install()),
      readLines = function(...) stop("cannot open the connection"),
      .package = "base"
    ),
    available.packages = function(...) stop("offline"),
    dartR_status = function() status,
    .package = "dartRverse"
  )
}

# Change 1
test_that("failed CRAN install errors, skips restart advice, re-attaches", {
  skip_if_not_installed("dartR.sexlinked")
  suppressWarnings(suppressMessages(
    require("dartR.sexlinked", character.only = TRUE, quietly = TRUE)
  ))
  out <- capture.output(
    calls <- mock_with(
      expect_error(dartRverse_install("dartR.sexlinked"),
                   "Installation failed.*dartR.sexlinked"),
      cran = function(pkgs, ...) {
        warning("package 'dartR.sexlinked' is not available for this version of R")
      }
    )
  )
  expect_length(calls, 1)
  expect_false(any(grepl("Restart R", out)))
  expect_true("package:dartR.sexlinked" %in% search())
})

test_that("a failed Github install does not skip the other packages", {
  skip_if_not_installed("dartR.sexlinked")
  out <- capture.output(
    calls <- mock_with(
      expect_error(
        dartRverse_install(c("dartR.sexlinked", "dartR.data"), rep = "Github"),
        "Installation failed.*dartR.sexlinked.*HTTP error 404"
      ),
      gh = function(repo, ...) {
        if (grepl("sexlinked", repo)) stop("HTTP error 404")
        invisible(TRUE)
      }
    )
  )
  expect_length(calls, 2)
  expect_false(any(grepl("new version of dartR.sexlinked", out)))
  expect_true("package:dartR.sexlinked" %in% search())
})

test_that("an unrelated installer warning is not treated as a failure", {
  expect_warning(
    capture.output(
      calls <- mock_with(
        dartRverse_install("dartR.sim"),
        cran = function(pkgs, ...) warning("something harmless")
      )
    ),
    "something harmless"
  )
  expect_length(calls, 1)
})

# Change 2
test_that("no mode uses the attaching helpers", {
  attaching <- function(...) stop("attaching helper called")
  with_mocked_bindings(
    {
      capture.output(mock_with(dartRverse_install("all")))
      capture.output(mock_with(dartRverse_install("dartR.data")))
      capture.output(dartRverse_install(verbose = FALSE))
      offline_table(list(core = "dartR.data", ip = character(0),
                         nip = character(0), failed = character(0)))
    },
    dartR_check = attaching,
    package_version_h = attaching,
    .package = "dartRverse"
  )
  succeed()
})

test_that("version table marks an installed package that fails to load", {
  skip_if_not_installed("dartR.sim")
  out <- offline_table(list(core = "dartR.data", ip = character(0),
                            nip = c("dartR.sim", "dartR.popgen"),
                            failed = "dartR.sim"))
  expect_true(any(grepl("dartR\\.sim.*installed, fails to load", out)))
  expect_false(any(grepl("dartR\\.popgen.*fails to load", out)))
})

test_that("version table copes with an add-on but no core package", {
  skip_if_not_installed("dartR.sim")
  out <- offline_table(list(core = character(0), ip = "dartR.sim",
                            nip = c("dartR.base", "dartR.data"),
                            failed = character(0)))
  expect_equal(sum(grepl("dartR\\.", out)), 3)
})

# Change 3
test_that("branch with CRAN errors and installs nothing", {
  calls <- mock_with({
    expect_error(dartRverse_install("dartR.sim", branch = "dev"),
                 "branch.*rep = 'Github'")
    expect_error(dartRverse_install("dartR.sim", rep = "CRAN", branch = "main"),
                 "branch.*rep = 'Github'")
  })
  expect_length(calls, 0)
})

test_that("branch must be one non-empty string", {
  calls <- mock_with({
    for (b in list(NULL, c("dev", "beta"), "", NA_character_, 1)) {
      expect_error(dartRverse_install("dartR.sim", rep = "Github", branch = b),
                   "branch must be")
    }
  })
  expect_length(calls, 0)
})

test_that("feature branches stay allowed", {
  capture.output(
    calls <- mock_with(
      dartRverse_install("dartR.sim", rep = "Github", branch = "dev_luis")
    )
  )
  expect_length(calls, 1)
})

test_that("empty package errors and duplicates install once", {
  calls <- mock_with(
    expect_error(dartRverse_install(character(0)), "package must name")
  )
  expect_length(calls, 0)
  capture.output(
    calls <- mock_with(dartRverse_install(c("dartR.sim", "dartR.sim")))
  )
  expect_length(calls, 1)
})

# Change 4
test_that("Bioconductor check applies to all packages except dartR.data", {
  with_mocked_bindings(
    {
      capture.output(calls <- mock_with(dartRverse_install("dartR.data")))
      expect_length(calls, 1)
      calls <- mock_with(
        expect_error(dartRverse_install(c("dartR.data", "dartR.sim")),
                     "must be installed first")
      )
      expect_length(calls, 0)
    },
    is_installed = function(pkg, ...) FALSE,
    .package = "rlang"
  )
})

# Change 5
test_that("'all' lists the core packages in the Github commands", {
  out <- capture.output(calls <- mock_with(dartRverse_install("all")))
  gh <- out[grepl("rep='Github'", out)]
  expect_length(gh, 7)
  expect_match(gh[1], "dartR.data", fixed = TRUE)
  expect_match(gh[2], "dartR.base", fixed = TRUE)
})

# Change 7
test_that("failed version reads leave no connection open", {
  before <- nrow(showConnections(all = TRUE))
  offline_table(list(core = "dartR.data", ip = character(0),
                     nip = character(0), failed = character(0)))
  expect_equal(nrow(showConnections(all = TRUE)), before)
})
