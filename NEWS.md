# dartRverse (development version)

* `gl.download.binary()`: listing mode (`software = NULL`) now shows the
  binaries on `branch` (default `"main"`) instead of always `dev`.
  Software names are converted to lower case, so the documented
  `"NeEstimator"`, `"Stairway2"` and `"Gone"` now download. Download and
  listing failures report their cause.
* RCurl is no longer imported.
