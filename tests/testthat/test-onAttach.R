# Characterization test for .onAttach and dartR_check (function-review
# baseline). Snapshots what the startup message does today, bugs included:
# it detects change, it does not assert correctness.

# Run .onAttach and return its messages as plain text
startup_messages <- function() {
  m <- character(0)
  withCallingHandlers(
    dartRverse:::.onAttach(),
    message = function(e) {
      m <<- c(m, cli::ansi_strip(conditionMessage(e)))
      invokeRestart("muffleMessage")
    }
  )
  m
}

orig_require <- base::require

# require() that fails for chosen packages, as a broken install would
failing_require <- function(broken, msg = NULL) {
  function(package, ...) {
    if (package %in% broken) {
      if (!is.null(msg)) warning(msg)
      return(FALSE)
    }
    orig_require(package, ...)
  }
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
  m <- with_mocked_bindings(
    startup_messages(),
    require = failing_require(
      "dartR.popgen",
      "package or namespace load failed for 'dartR.popgen': version mismatch"
    ),
    .package = "base"
  )
  txt <- paste(m, collapse = "\n")
  expect_match(txt, "Installed but failed to load[^\n]*\n[^\n]*dartR.popgen[^\n]*version mismatch")
  expect_match(txt, "Run library\\(dartR.popgen\\)")
  expect_false(grepl("Not \\[yet\\] installed", txt))
})

# Review change 1: a failing core package does not trigger the
# "not installed yet" advice
test_that("a core package that fails to load gets no install advice", {
  m <- with_mocked_bindings(
    startup_messages(),
    require = failing_require("dartR.base", "load failed: SNPRelate missing"),
    .package = "base"
  )
  txt <- paste(m, collapse = "\n")
  expect_match(txt, "dartR.base[^\n]*SNPRelate missing")
  expect_false(grepl("Please note", txt))
})

# Changed by review change 3: snpStats used to be missing from the advice
test_that("missing core: advice installs SNPRelate and snpStats", {
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
  expect_match(advice, "BiocManager::install\\('SNPRelate'\\)")
  expect_match(advice, "BiocManager::install\\('snpStats'\\)")
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
