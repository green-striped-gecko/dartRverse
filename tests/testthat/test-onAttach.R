# Characterization test for .onAttach and dartR_check (function-review
# baseline). Snapshots what the startup message does today, bugs included:
# it detects change, it does not assert correctness.

orig_require <- base::require
orig_loadNamespace <- base::loadNamespace
dartR_pkgs <- c(dartRverse:::core, dartRverse:::addons)

# require() that fails for chosen packages, as a broken install would. The
# other dartR packages count as installed and loadable without being loaded,
# so the tests do not depend on which dartR versions are installed (on CRAN
# a new dartR.base can sit next to older add-ons that fail to load).
failing_require <- function(broken = character(0), msg = NULL) {
  function(package, ...) {
    if (package %in% broken) {
      if (!is.null(msg)) warning(msg)
      return(FALSE)
    }
    if (package %in% dartR_pkgs) return(TRUE)
    orig_require(package, ...)
  }
}

# Run .onAttach with failing_require(broken, msg) and return its messages as
# plain text
startup_messages <- function(broken = character(0), msg = NULL) {
  m <- character(0)
  with_mocked_bindings(
    with_mocked_bindings(
      withCallingHandlers(
        dartRverse:::.onAttach(),
        message = function(e) {
          m <<- c(m, cli::ansi_strip(conditionMessage(e)))
          invokeRestart("muffleMessage")
        }
      ),
      require = failing_require(broken, msg),
      .package = "base"
    ),
    is_pkg_installed = function(x) TRUE,
    package_version_h = function(pkg) "1.0.0",
    .package = "dartRverse"
  )
  m
}

test_that("all installed: banner, core and add-on sections, no advice", {
  m <- startup_messages()
  expect_length(m, 3)
  expect_match(m[1], "Welcome to dartRverse")
  expect_match(m[2], "Core dartRverse packages")
  expect_match(m[3], "Installed dartRverse packages")
  expect_false(any(grepl("Please note", m)))
})

# Changed by review change 4: the banner used to print when quiet
test_that("dartRverse.quiet silences all startup output", {
  withr::local_options(dartRverse.quiet = TRUE)
  expect_length(startup_messages(), 0)
})

# Changed by review change 1: used to be listed as "Not [yet] installed"
# with the load error discarded
test_that("an installed package that fails to load is shown with its error", {
  m <- startup_messages(
    "dartR.popgen",
    "package or namespace load failed for 'dartR.popgen': version mismatch"
  )
  txt <- paste(m, collapse = "\n")
  expect_match(txt, "Installed but failed to load[^\n]*\n[^\n]*dartR.popgen[^\n]*version mismatch")
  expect_match(txt, "Run library\\(dartR.popgen\\)")
  expect_false(grepl("Not \\[yet\\] installed", txt))
})

# require(quietly = TRUE) gives no warning when a namespace fails to load
# (e.g. CRAN's dartR.sim 1.2.2 next to dartR.base 1.3.0); the banner used to
# show "unknown error" instead of the load error
test_that("a load error that require() swallows is still shown", {
  m <- with_mocked_bindings(
    startup_messages("dartR.sim"),
    loadNamespace = function(package, ...) {
      if (package == "dartR.sim") {
        stop("object 'gl.He' is not exported by 'namespace:dartR.base'")
      }
      orig_loadNamespace(package, ...)
    },
    .package = "base"
  )
  txt <- paste(m, collapse = "\n")
  expect_match(txt, "dartR.sim[^\n]*object 'gl.He' is not exported")
  expect_false(grepl("unknown error", txt))
})

# Review change 1: a failing core package does not trigger the
# "not installed yet" advice
test_that("a core package that fails to load gets no install advice", {
  m <- startup_messages("dartR.base", "load failed: SNPRelate missing")
  txt <- paste(m, collapse = "\n")
  expect_match(txt, "dartR.base[^\n]*SNPRelate missing")
  expect_false(grepl("Please note", txt))
})

# dartRverse_install() now installs the Bioconductor packages itself
test_that("missing core: advice is dartRverse_install, without BiocManager", {
  m <- with_mocked_bindings(
    startup_messages(),
    dartR_check = function() {
      list(core = character(0), ip = character(0),
           nip = c(core, addons))
    },
    .package = "dartRverse"
  )
  advice <- m[grepl("Please note", m)]
  expect_length(advice, 1)
  expect_match(advice, "dartRverse_install\\('dartR.base'\\)")
  expect_false(grepl("BiocManager", advice))
})

# Changed by review change 2: dartR.base used to appear in no list
test_that("only dartR.base missing: it is listed as not installed", {
  dc <- with_mocked_bindings(
    with_mocked_bindings(
      dartRverse:::dartR_check(),
      require = failing_require("dartR.base"),
      .package = "base"
    ),
    is_pkg_installed = function(x) x != "dartR.base",
    .package = "dartRverse"
  )
  expect_equal(dc$core, "dartR.data")
  expect_equal(dc$nip, "dartR.base")
  expect_length(dc$failed, 0)
})
