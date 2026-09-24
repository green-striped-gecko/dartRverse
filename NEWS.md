# dartRverse (development version)

* Startup message: a dartRverse package that is installed but fails to
  load is now listed under "Installed but failed to load" with its error,
  instead of "Not [yet] installed". A single missing core package is now
  listed. The install advice includes snpStats.
  `options(dartRverse.quiet = TRUE)` now also hides the welcome banner.
* `gl.download.binary()`: listing mode (`software = NULL`) now shows the
  binaries on `branch` (default `"main"`) instead of always `dev`.
  Software names are converted to lower case, so the documented
  `"NeEstimator"`, `"Stairway2"` and `"Gone"` now download. Download and
  listing failures report their cause.
* RCurl is no longer imported.
