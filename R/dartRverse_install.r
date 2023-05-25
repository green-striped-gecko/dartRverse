#' Supports installation of CRAN and Github package of the dartRverse
#' 
#' This functions expects the name of one (or several) dartR packages, the repository (CRAN or Github) and in the case of github the branch (main, dev, beta) to install the identified version of the pacakge. If run with no parameter the current installed packages and its versions are printed
#' 
#' @param package Name of the package to install, currently [dartR.sim, dartR.spatial, dartR.popgenomics]
#' @param rep Which repository is used (CRAN or Github) 
#' @param branch If Github is used the branch on Github needs to be specified, [either main, beta or dev]
#' @return NULL
#' @export
#' @importFrom utils installed.packages install.packages available.packages

dartRverse_install <- function(
                                package = NULL,
                                rep = "CRAN",
                                branch = "main")
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
  pkg <- "stringr"
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
    cli::cat_line()
    cli::cat_line("Currently installed dartRverse packages:")
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
    
    
    
  return (invisible(1))
    
  } else {
  
  
  
  if (!is.null(rep)) {
    
    #make sure package exists
    if (!package %in% addons)  {
      cat(cli::col_red(
        "\n"
      ))
      return(-1)
    }
    
    
    if (!is.na(pmatch(toupper(rep), "CRAN"))) {
      ps <- paste0("package:",package)
      if (ps %in% search()) detach(ps, unload = TRUE, character.only = TRUE)
        cat(cli::col_green(paste0("  Installing ",package ," from CRAN (latest version)\n")))
      install.packages(package)
    }
    if (!is.na(pmatch(toupper(rep), "GITHUB"))) {
        cat(cli::col_green(paste0("  Installing ",package," from Github from branch [",branch,"] \n")))
      ps <- paste0("package:",package)
      if (ps %in% search()) detach(ps, unload = TRUE, character.only = TRUE)
      devtools::install_github(paste0("green-striped-gecko/",package),
                               ref = branch,
                               dependencies = TRUE)
    }
  }
  }
}
