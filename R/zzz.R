#' @import cli
#' @import devtools
#' @importFrom rlang is_installed inform
#' @importFrom utils packageVersion

core <- c("dartR.base", "dartR.data")
addons <- c("dartR.sim","dartR.popgen","dartR.spatial","dartR.captive","dartR.sexlinked")

dartR_check <- function()
{

  
  bc <- unlist(lapply(core, function(x)  
  {
    loc <- if (x %in% loadedNamespaces()) dirname(getNamespaceInfo(x, "path"))
    
   suppressMessages(suppressWarnings(require(x, lib.loc = loc,  quietly = TRUE, character.only = TRUE )))
    
  }))
  
  ba <- unlist(lapply(addons, function(x)  
  {
    loc <- if (x %in% loadedNamespaces()) dirname(getNamespaceInfo(x, "path"))
    
   suppressMessages(suppressWarnings(require(x, lib.loc = loc,  quietly = TRUE, character.only = TRUE )))
    
  }))
  
  core <- core[bc]
  
  installedaddons <- addons[ba]
  if (is.null(ba)) notinstalledaddons <- addons else 
    notinstalledaddons <- addons[!ba]  
  if (length(core) == 0) notinstalledaddons <- c("dartR.base","dartR.data", notinstalledaddons)
  
  return(pack<- list(core=core, ip=installedaddons, nip = notinstalledaddons))
  
}

.onAttach <- function(...) {
 packageStartupMessage(
    cli::col_blue(
    paste0("**********************************************",
           "\n**** Welcome to dartRverse [Version ",
      utils::packageVersion("dartRverse"),  "] ****\n",
           "**********************************************"
    ), collapse="\n")
  )
  dc <- dartR_check()
  #core <- dc$core
  #installedaddons <- dc$ip
  #notinstalledaddons <- dc$nip
  #dartRverse_attach() 
  inform_startup(dartRverse_attach_message(dc$core,"core")) 
  inform_startup(dartRverse_attach_message(dc$ip,"addon"))
  inform_startup(dartRverse_attach_message(dc$nip,"notaddon"))
  
  if (length(dc$core)<2) {
    inform_startup(paste0("\nPlease note: The core dartRverse packages are not installed yet. \nYou can install the missing core packages using: \n",cli::style_bold(cli::col_blue("install.packages('BiocManager')\nBiocManager::install('SNPRelate')\ndartRverse_install('dartR.base',rep='CRAN')\n")),"To install all packages of the dartRverse, use:\n",cli::style_bold(cli::col_blue("dartRverse_install('all')"))))
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

