#' @import cli
#' @import devtools
#' @importFrom rlang is_installed inform
#' @importFrom utils packageVersion

core <- c("dartR.base", "dartR.data")
addons <- c("dartR.sim","dartR.popgen","dartR.spatial","dartR.captive","dartR.sexlinked")

dartR_check <- function()
{

  # require() returns FALSE both when a package is absent and when it is installed but fails to load; keep the load error so the banner can tell the two apart
  failed <- character(0)
  try_attach <- function(x) {
    loc <- if (x %in% loadedNamespaces()) dirname(getNamespaceInfo(x, "path"))
    msg <- character(0)
    ok <- withCallingHandlers(
      suppressMessages(require(x, lib.loc = loc,  quietly = TRUE, character.only = TRUE )),
      warning = function(w) {
        msg <<- c(msg, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
    if (!ok && is_pkg_installed(x)) {
      failed[x] <<- if (length(msg) > 0) gsub("\\s+", " ", msg[length(msg)]) else "unknown error"
    }
    ok
  }
  
  bc <- vapply(core, try_attach, logical(1))
  
  ba <- vapply(addons, try_attach, logical(1))
  
  installedcore <- core[bc]
  installedaddons <- addons[ba]
  # missing core packages are listed too, also when only one of them is missing
  notinstalled <- c(core[!bc], addons[!ba])
  
  return(pack<- list(core=installedcore, ip=installedaddons, nip = notinstalled, failed = failed))
  
}

is_pkg_installed <- function(x) nzchar(system.file(package = x))

.onAttach <- function(...) {
 inform_startup(
    cli::col_blue(
    paste0("***********************************************",
           "\n**** Welcome to dartRverse [Version ",
      utils::packageVersion("dartRverse"),  "] ****\n",
           "***********************************************"
    ), collapse="\n")
  )
  dc <- dartR_check()
  #core <- dc$core
  #installedaddons <- dc$ip
  #notinstalledaddons <- dc$nip
  #dartRverse_attach() 
  inform_startup(dartRverse_attach_message(dc$core,"core")) 
  inform_startup(dartRverse_attach_message(dc$ip,"addon"))
  # packages that are installed but failed to load get their own section
  notinstalled <- setdiff(dc$nip, names(dc$failed))
  inform_startup(dartRverse_attach_message(notinstalled,"notaddon"))
  inform_startup(dartRverse_attach_message(names(dc$failed),"failed", dc$failed))
  
  if (any(c("dartR.base","dartR.data") %in% notinstalled)) {
    inform_startup(paste0("\nPlease note: The core dartRverse packages are not installed yet. \nYou can install the missing core packages using: \n",cli::style_bold(cli::col_blue("install.packages('BiocManager')\nBiocManager::install('SNPRelate')\nBiocManager::install('snpStats')\ndartRverse_install('dartR.base',rep='CRAN')\n")),"To install all packages of the dartRverse, use:\n",cli::style_bold(cli::col_blue("dartRverse_install('all')"))))
  }
  
}

is_attached <- function(x) {
  paste0("package:", x) %in% search()
}

inform_startup <- function(msg, ...) {
  if (is.null(msg)) {
    return()
  }
  if (isTRUE(getOption("dartRverse.quiet"))) {
    return()
  }
  
  rlang::inform(msg, ..., class = "packageStartupMessage")
}

