#' @import cli
#' @import dartR.base
#' @import dartR.data
#' @importFrom rlang is_installed inform
#' @importFrom utils packageVersion

core <- c("dartR.base", "dartR.data")
addons <- c("dartR.sim","dartR.popgenomics","dartR.spatial","dartR.sexlinked","dartR.captive")

dartR_check <- function()
{

  ip <- installed.packages()[,1]
  
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
  inform_startup(dartRverse_attach_message(dc$core,"core")) 
  inform_startup(dartRverse_attach_message(dc$ip,"addon"))
  inform_startup(dartRverse_attach_message(dc$nip,"notaddon"))
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

