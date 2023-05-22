#' @import cli
#' @import dartR.base
#' @importFrom dplyr filter "%>%"
#' @importFrom purrr map2_lgl map_chr
#' @importFrom rlang is_installed inform
#' @importFrom tibble tibble

.onAttach <- function(...) {
  
  packageStartupMessage(
    cli::col_blue(
    paste0("**********************************************",
           "\n**** Welcome to dartRverse [Version ",
      packageVersion("dartRverse"),  "] ****\n",
           "**********************************************"
    ), collapse="\n")
  )
  
  
  attached <- dartRverse_attach()
  inform_startup(dartRverse_attach_message(core,"core")) 
  inform_startup(dartRverse_attach_message(installedaddons,"addon"))
  inform_startup(dartRverse_attach_message(notinstalledaddons,"notaddon"))
}

is_attached <- function(x) {
  paste0("package:", x) %in% search()
}

