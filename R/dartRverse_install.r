#' Checks installed package and Supports installation of CRAN and Github packages of the dartRverse
#' 
#' This function expects the name of one (or several) dartR packages, the repository (CRAN or Github) and in the case of github the branch (main, dev, beta) to install the identified version of the package. If run with no parameter the current installed packages and their versions are printed.
#' 
#' All dartR packages depend on dartR.base, which imports the Bioconductor packages SNPRelate and snpStats. These cannot be installed from CRAN, so the function stops and shows the commands to install them if they are missing.
#' If a package is already loaded, the new version is only used after R is restarted; the function says so after installing.
#' 
#' @param package Name(s) of the package(s) to install: dartR.base, dartR.data, dartR.sim, dartR.popgen, dartR.spatial, dartR.captive or dartR.sexlinked. Use "all" to print the commands that install the whole dartRverse. If NULL, the installed packages and the versions available on CRAN and Github are printed [default NULL].
#' @param rep Which repository is used: 'CRAN' or 'Github' (partial matching, any case) [default 'CRAN'].
#' @param branch If Github is used, the branch to install from: main, beta or dev [default 'main'].
#' The 'main' repository on Github is identical with the latest CRAN submission. Important changes and fixes are published under 'beta' and tested there, before they are submitted to CRAN. Hence this might be the best chance 
#' to look for fixes. All 'dev' branches are 'risky' meaning they have not been tested.
#' To get the current versions available and which are installed run: dartRverse_install().
#' To get the code how to install all other packages run: dartRverse_install("all").
#' @param verbose If TRUE, the version table is printed when package is NULL; it has no effect otherwise [default TRUE].
#' @return Invisibly: 1 when the version table is requested, NULL otherwise.
#' @examples 
#' # print the commands that install the whole dartRverse
#' dartRverse_install("all")
#' \dontrun{
#' # installed packages and available versions (needs internet)
#' dartRverse_install()
#' # install the dev version of dartR.popgen from Github
#' dartRverse_install("dartR.popgen", rep = "Github", branch = "dev")
#' }
#' @export
#' @importFrom utils installed.packages install.packages available.packages

dartRverse_install <- function(
                                package = NULL,
                                rep = "CRAN",
                                branch = "main", 
                                verbose=TRUE)
{
  err <- NULL
  
  dc <- dartR_check()
  
  

  
  
  #check package
  if (is.null(package))  #just print current versions
  {
    if (verbose>0) {
    cli::cat_line()
    cli::cat_line("dartRverse packages:")
    pkg_str <- paste0(deparse(c(dc$core, dc$ip)), collapse = "\n")
    cversions <- vapply(c(dc$core), package_version_h, character(1)) 
    cversions <- cli::style_bold(cversions)
    iversions <- vapply(c(dc$ip), package_version_h, character(1)) 
    iversions <- cli::style_bold(iversions)
    
        #versions <- paste(versions, "(installed)")

        
    #find versions from github
    dvcc <- NA
    dvcm <- NA
    dvcb <- NA
    dvcd <- NA

    # a failed remote read shows "?" instead of stopping the whole table
    failed <- character(0)
    av <- tryCatch(suppressWarnings(available.packages(repos = "https://cran.r-project.org/")),
                   error = function(e) NULL)
    if (is.null(av) || nrow(av) == 0) failed <- c(failed, "CRAN")
    cran_version <- function(p) {
      if ("CRAN" %in% failed) return("?")
      if (p %in% rownames(av)) av[p, "Version"] else NA
    }
    gh_version <- function(p, b) {
      tryCatch({
        myfile <- readLines(url(paste0("https://raw.githubusercontent.com/green-striped-gecko/", p, "/", b, "/DESCRIPTION")), warn = FALSE)
        gsub(pattern = "Version: ", "", myfile[grep("Version: ", myfile)])
      }, error = function(e) {
        failed <<- c(failed, "Github")
        "?"
      }, warning = function(w) {
        failed <<- c(failed, "Github")
        "?"
      })
    }
    if (length(dc$core)>0) {
    for (i in 1:length(dc$core)) {
      
      dvcc[i] <- cran_version(dc$core[i])
      dvcm[i] <- gh_version(dc$core[i], "main")
      dvcb[i] <- gh_version(dc$core[i], "beta")
      dvcd[i] <- gh_version(dc$core[i], "dev")
    }
      versions <- paste0(cversions, " | CRAN: ", c(dvcc), " | Github: ",c(dvcm)," (main) | ",c(dvcb)," (beta) | ",c(dvcd), " (dev)")
}
    dvic <- NA
    dvim <- NA
    dvib <- NA
    dvid <- NA
    if (length(dc$ip)>0) {
    for (i in 1:length(dc$ip)) {
      
      dvic[i] <- cran_version(dc$ip[i])
      dvim[i] <- gh_version(dc$ip[i], "main")
      dvib[i] <- gh_version(dc$ip[i], "beta")
      dvid[i] <- gh_version(dc$ip[i], "dev")
    }
      versions2 <- paste0(iversions, " | CRAN: ", c( dvic), " | Github: ",c(dvim)," (main) | ",c( dvib)," (beta) | ",c(dvid), " (dev)")
      
      versions <- c(versions, versions2)  
  }
    
    
    dvnc <- NA
    dvnm <- NA
    dvnb <- NA
    dvnd <- NA
    if (length(dc$nip)>0) {
    for (i in 1:length(dc$nip)) {

      dvnc[i] <- cran_version(dc$nip[i])
      dvnm[i] <- gh_version(dc$nip[i], "main")
      dvnb[i] <- gh_version(dc$nip[i], "beta")
      dvnd[i] <- gh_version(dc$nip[i], "dev")
    }
    
    nversions <- paste0(cli::style_bold("--- "), " | CRAN:",dvnc," | Github:  ",dvnm," (main) | ",dvnb," (beta) | ",dvnd," (dev)")
    
    }
    
    if (length(c(dc$core, dc$ip)>0)) {   
    pkg_str <- paste0(
      cli::col_green(cli::symbol$tick), " ", cli::col_blue(format(c(dc$core, dc$ip))), " ",
      cli::ansi_align(versions, max(cli::ansi_nchar(versions))))
    cli::cat_line(pkg_str)
    }
    
    if (length(dc$nip)>0) {
    pkg_str <- paste0(
      cli::col_red(cli::symbol$cross), " ", cli::col_blue(format(dc$nip)), " ",
      cli::ansi_align(nversions, max(cli::ansi_nchar(nversions))))
     
    
    cli::cat_line(pkg_str)
    cli::cat_line()
    }
    
    if (length(failed) > 0) {
      cli::cat_line(cli::col_red(paste0("Versions shown as ? could not be read from ", paste(unique(failed), collapse = " and "), ". Check your internet connection.")))
    }
    
  }  
    
  return (invisible(1))
    
  } else     if (identical(tolower(package), "all")) {
  
    #check if all packages should be installed
    #print out instructions

      cli::cat_line()
      cli::cat_line(cli::style_bold("To install all packages from the dartRverse, please empty your workspace, restart R and run the following commands (you can copy the commands from here):"), col="black")
      cli::cat_line()
      cli::cat_line("#########################################", col="green")
      cli::cat_line(cli::style_bold("# bioconductor packages:"),col="green")
      cli::cat_line("install.packages('BiocManager')", col="blue")
      cli::cat_line("BiocManager::install('SNPRelate')", col="blue")
      cli::cat_line("BiocManager::install('snpStats')", col="blue")
      cli::cat_line(cli::style_bold("# core packages:"),col="green")
      cli::cat_line("library(dartRverse)", col="blue")
      cli::cat_line("dartRverse_install('dartR.base', rep='CRAN')", col="blue")
      cli::cat_line("#installs also dartR.data", col="green")
      cli::cat_line(cli::style_bold("# additional packages:"),col="green")
      cli::cat_line("dartRverse_install('dartR.popgen', rep='CRAN')", col="blue")
      cli::cat_line("dartRverse_install('dartR.captive', rep='CRAN')", col="blue")
      cli::cat_line("dartRverse_install('dartR.sim', rep='CRAN')", col="blue")
      cli::cat_line("dartRverse_install('dartR.spatial', rep='CRAN')", col="blue")
      cli::cat_line("dartRverse_install('dartR.sexlinked', rep='CRAN')", col="blue")
      cli::cat_line("#########################################", col="green")
      cli::cat_line()
      cli::cat_line(cli::style_bold("In case you want to install the latest version from Github, please use the following commands:"), col="black")
      cli::cat_line(cli::style_bold("[You can change the branch to 'beta' or 'dev' to get the latest changes and fixes.]"), col="black")
      cli::cat_line()
      cli::cat_line("dartRverse_install('dartR.popgen', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.captive', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.sim', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.spatial', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.sexlinked', rep='Github', branch='main')", col="blue")
      cli::cat_line()
 
      
      
      
      
      
    } else {
    
    #make sure all packages exist before installing any
    bad <- package[!package %in% c(core,addons)]
    if (length(bad) > 0) {
      stop(paste0("Unknown dartRverse package: ", paste(bad, collapse = ", "), ". Use one of: ", paste(c(core, addons), collapse = ", ")))
    }
    reps <- c("CRAN", "GITHUB")
    if (is.null(rep) || length(rep) != 1 || is.na(rp <- pmatch(toupper(rep), reps))) {
      stop("rep must be 'CRAN' or 'Github'.")
    }
    rep <- reps[rp]
    
    # dartR.base (a dependency of every dartR package) imports these Bioconductor packages, which install.packages cannot find on CRAN
    bioc <- c("SNPRelate", "snpStats")
    missing.bioc <- bioc[!vapply(bioc, rlang::is_installed, logical(1))]
    if (length(missing.bioc) > 0) {
      stop(paste0("Bioconductor package(s) ", paste(missing.bioc, collapse = ", "), " must be installed first. Please run:\n",
                  "install.packages('BiocManager')\n",
                  paste0("BiocManager::install('", missing.bioc, "')", collapse = "\n")))
    }
    
    for (pk in package) {
      # a namespace imported by another loaded dartR package cannot be unloaded, so the old version stays in use until R restarts
      was.loaded <- pk %in% loadedNamespaces()
      ps <- paste0("package:",pk)
      if (ps %in% search()) suppressWarnings(detach(ps, unload = TRUE, character.only = TRUE, force=TRUE))
      if (rep == "CRAN") {
        cat(cli::col_green(paste0("  Installing ",pk ," from CRAN (latest version)\n")))
        install.packages(pk)
      } else {
        cat(cli::col_green(paste0("  Installing ",pk," from Github from branch [",branch,"] \n")))
        remotes::install_github(paste0("green-striped-gecko/",pk),
                                ref = branch,
                                dependencies = TRUE)
      }
      if (was.loaded) cat(cli::style_bold(cli::col_red(paste0("  Restart R to use the new version of ", pk, "\n"))))
    }
    return(invisible(NULL))
  }
  
}
