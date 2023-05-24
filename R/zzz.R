#' @import cli
#' @import dartR.base
#' @import dartR.data
#' @importFrom dplyr filter "%>%"
#' @importFrom purrr map2_lgl map_chr
#' @importFrom rlang is_installed inform
#' @importFrom tibble tibble

#StagedInstall: no

core <- c("dartR.base", "dartR.data")
addons <- c("dartR.sim","dartR.popgenomics","dartR.spatial")

bc <- unlist(lapply(core, function(x)  
{
  loc <- if (x %in% loadedNamespaces()) dirname(getNamespaceInfo(x, "path"))

library(x, lib.loc = loc, logical.return = TRUE, quietly = TRUE, character.only = TRUE)

}))

ba <- unlist(lapply(addons, function(x)  
{
  loc <- if (x %in% loadedNamespaces()) dirname(getNamespaceInfo(x, "path"))
  
  library(x, lib.loc = loc, logical.return = TRUE, quietly = TRUE, character.only = TRUE)
  
}))


core <- core[bc]
installedaddons <- addons[ba]
notinstalledaddons <- addons[!ba]  



.onAttach <- function(...) {
  
  packageStartupMessage(
    cli::col_blue(
    paste0("**********************************************",
           "\n**** Welcome to dartRverse [Version ",
      packageVersion("dartRverse"),  "] ****\n",
           "**********************************************"
    ), collapse="\n")
  )
  
  #dartRverse_attach() 
  inform_startup(dartRverse_attach_message(core,"core")) 
  inform_startup(dartRverse_attach_message(installedaddons,"addon"))
  inform_startup(dartRverse_attach_message(notinstalledaddons,"notaddon"))
}

is_attached <- function(x) {
  paste0("package:", x) %in% search()
}

