# dartRverse 1.2.6

* `dartRverse_install()` behaviour changes:
  - A failed install now ends in an error naming the packages that failed,
    after trying the others. A failed CRAN install used to give only a
    warning, and a failed Github install skipped the remaining packages. The
    restart message prints only after a successful install, and a package
    detached for the install is re-attached if the install fails.
  - The function no longer attaches dartR packages, so code that relied on
    this must call `library()`. `library(dartRverse)` still attaches them.
    The version table marks a package that is installed but fails to load.
  - Supplying `branch` with `rep = "CRAN"` is now an error (`branch` used to
    be ignored, so CRAN was installed). A NULL or vector `branch` and an
    empty `package` are also errors, and duplicate package names install once.
  - `dartR.data` can be installed on its own without SNPRelate and snpStats.
  - The Github commands printed by `dartRverse_install("all")` now include
    dartR.data and dartR.base.
* README: the example that installs a Github branch uses `rep`; it used
  `repository`, which is not an argument and gave an error.
* Startup message: a dartRverse package that is installed but fails to
  load is now listed under "Installed but failed to load" with its error,
  instead of "Not [yet] installed". A single missing core package is now
  listed. The install advice includes snpStats.
  `options(dartRverse.quiet = TRUE)` now also hides the welcome banner.
* `dartRverse_install()`: an unknown package name now stops with an error
  listing the valid names (it used to return `-1`), and an unrecognised or
  NULL `rep` stops with an error (it used to do nothing). Several packages
  can be installed in one call. Before installing, it checks for the
  Bioconductor packages SNPRelate and snpStats and prints the
  `BiocManager::install()` commands if either is missing. After
  reinstalling a loaded package it tells the user to restart R. The
  version table shows `?` for versions it could not read instead of
  stopping.
* devtools is no longer imported; Github installs use
  `remotes::install_github()`.
* `gl.download.binary()`: listing mode (`software = NULL`) now shows the
  binaries on `branch` (default `"main"`) instead of always `dev`.
  Software names are converted to lower case, so the documented
  `"NeEstimator"`, `"Stairway2"` and `"Gone"` now download. Download and
  listing failures report their cause.
* RCurl is no longer imported.
