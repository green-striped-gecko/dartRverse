#' Checks installed package and Supports installation of CRAN and Github packages of the dartRverse
#' 
#' This functions expects the name of one (or several) dartR packages, the repository (CRAN or Github) and in the case of github the branch (main, dev, beta) to install the identified version of the pacakge. If run with no parameter the current installed packages and their versions are printed.
#' 
#' @param package Name of the package to install, currently [dartR.base, dartR.data, dartR.sim, dartR.spatial, dartR.popgen, dartR.sexlinked]
#' @param rep Which repository is used ('CRAN' or 'Github'). 
#' @param branch If Github is used the branch on Github needs to be specified, [either main, beta or dev]
#' The 'main' repository on Github is identical with the latest CRAN submission. Important changes and fixes are published under 'beta' and tested there, before the are submitted to CRAN. Hence this might be the best chance 
#' to look for fixes. All 'dev' branches are 'risky' meaning they have not been tested.
#' @param verbose if set to true the current installed packages are printed.
#' @return functions returns NULL
#' @examples 
#' dartRverse_install()
#' @export
#' @importFrom utils installed.packages install.packages available.packages

dartRverse_install <- function(
                                package = NULL,
                                rep = "CRAN",
                                branch = "main", 
                                verbose=TRUE)
{
  pkg <- "devtools"
  if (!(requireNamespace(pkg, quietly = TRUE))) {
    cat(cli::col_red(
      "Package",
      pkg,
      " needed for this function to work. Please install it.\n"
    ))
    return(-1)
  }
  err <- NULL
  
  dc <- dartR_check()
  
  

  
  
  #check package
  if (is.null(package))  #just print current versions
  {
    if (verbose>0) {
    cli::cat_line()
    cli::cat_line("dartRverse packages:")
    pkg_str <- paste0(deparse(c(dc$core, dc$ip)), collapse = "\n")
    versions <- vapply(c(dc$core, dc$ip), package_version_h, character(1)) 
    
    pkg_str <- paste0(
      cli::col_green(cli::symbol$tick), " ", cli::col_blue(format(c(dc$core, dc$ip))), " ",
      cli::ansi_align(versions, max(cli::ansi_nchar(versions))))
    
    
    
    cli::cat_line(pkg_str)
    if (length(dc$nip)>0) {
    pkg_str <- paste0(
      cli::col_red(cli::symbol$cross), " ", cli::col_blue(format(dc$nip)), " ")
    
    cli::cat_line(pkg_str)
    cli::cat_line()
    }
    
  }  
    
  return (invisible(1))
    
  } else     if (tolower(package)=="all") {
  
    #check if all packages should be installed
    #print out instructions

      
      cli::cat_line("To install all packages from the dartRverse, please restart R and run the following commands (you can copy it from here):", col="green") 
      cli::cat_line()
      cli::cat_line("library(dartRverse)", col="blue")
      cli::cat_line("dartRverse_install('dartR.popgen', rep='CRAN')", col="blue")
      cli::cat_line("dartRverse_install('dartR.captive', rep='CRAN')", col="blue")
      cli::cat_line("dartRverse_install('dartR.sim', rep='CRAN')", col="blue")
      cli::cat_line("dartRverse_install('dartR.spatial', rep='CRAN')", col="blue")
      cli::cat_line("dartRverse_install('dartR.sexlinked', rep='CRAN')", col="blue")
      cli::cat_line()
      cli::cat_line("In case you want to install the latest version from Github, please use the following commands:", col="green")
      
      cli::cat_line("dartRverse_install('dartR.popgen', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.captive', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.sim', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.spatial', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.sexlinked', rep='Github', branch='main')", col="blue")
      cli::cat_line()
      cli::cat_line("You can change the branch to 'beta' or 'dev' to get the latest changes and fixes.", col="green")
      
      
      
      
      
    } else  if (!is.null(rep)) {
    
    #make sure package exists
    if (!package %in% c(core,addons))  {
      cat(cli::col_red(
        "\n"
      ))
      return(-1)
    }
    
    
    if (!is.na(pmatch(toupper(rep), "CRAN"))) {
      ps <- paste0("package:",package)
      if (ps %in% search()) detach(ps, unload = TRUE, character.only = TRUE, force=TRUE)
        cat(cli::col_green(paste0("  Installing ",package ," from CRAN (latest version)\n")))
      install.packages(package)
    }
    if (!is.na(pmatch(toupper(rep), "GITHUB"))) {
        cat(cli::col_green(paste0("  Installing ",package," from Github from branch [",branch,"] \n")))
      ps <- paste0("package:",package)
      if (ps %in% search()) detach(ps, unload = TRUE, character.only = TRUE, force=TRUE)
      devtools::install_github(paste0("green-striped-gecko/",package),
                               ref = branch,
                               dependencies = TRUE)
    }
  }
  
}

  
 