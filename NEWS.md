# dartRverse 1.2.2.9000

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
