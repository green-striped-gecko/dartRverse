#' Checks installed package and Supports installation of CRAN and Github packages of the dartRverse
#' 
#' This function expects the name of one (or several) dartR packages, the repository (CRAN or Github) and in the case of github the branch (main, dev, beta) to install the identified version of the package. If run with no parameter the current installed packages and their versions are printed.
#' 
#' All dartR packages except dartR.data depend on dartR.base, which imports the Bioconductor packages SNPRelate and snpStats. These cannot be installed from CRAN, so the function stops and shows the commands to install them if they are missing, unless dartR.data is the only package requested.
#' If a package is already loaded, the new version is only used after R is restarted; the function says so after a successful install. If an install fails, the function still tries the other requested packages, re-attaches any package it detached, and then stops with an error naming the packages that failed.
#'
#' @name dartRverse_install
#' @family dartRverse installation
#' @details
#' The function does not attach any dartR package. The version table loads the packages to check that they work, and marks a package that is installed but fails to load.
#'
#' The 'main' branch on Github is identical with the latest CRAN submission. Important changes and fixes are published under 'beta' and tested there, before they are submitted to CRAN. Hence this might be the best chance to look for fixes. All 'dev' branches are 'risky' meaning they have not been tested.
#'
#' A Github install changes only the named package. Packages it depends on, such as dartR.base, are not moved to the same branch, so install them from that branch as well if you need matching versions.
#'
#' To get the current versions available and which are installed run: dartRverse_install().
#' To get the code how to install all other packages run: dartRverse_install("all").
#' @param package Name(s) of the package(s) to install: dartR.base, dartR.data, dartR.sim, dartR.popgen, dartR.spatial, dartR.captive or dartR.sexlinked. Use "all" to print the commands that install the whole dartRverse. If NULL, the installed packages and the versions available on CRAN and Github are printed [default NULL].
#' @param rep Which repository is used: 'CRAN' or 'Github' (partial matching, any case) [default 'CRAN'].
#' @param branch The Github branch to install from, usually main, beta or dev. It needs rep = 'Github'; supplying it with rep = 'CRAN' is an error [default 'main'].
#' @param verbose If TRUE, the version table is printed when package is NULL; it has no effect otherwise [default TRUE].
#' @return Invisibly: 1 when the version table is requested, NULL otherwise.
#' @author Author(s): Bernd Gruber. Custodian: Bernd Gruber -- Post to \url{https://groups.google.com/d/forum/dartr}
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

  #check package
  if (is.null(package))  #just print current versions
  {
    if (verbose>0) {
    # dartR_check() and package_version_h() call require(), which would attach every package to the user's search path
    dc <- dartR_status()
    installed_version <- function(p) highlight_version(utils::packageVersion(p))
    cli::cat_line()
    cli::cat_line("dartRverse packages:")
    pkg_str <- paste0(deparse(c(dc$core, dc$ip)), collapse = "\n")
    cversions <- vapply(c(dc$core), installed_version, character(1))
    cversions <- cli::style_bold(cversions)
    iversions <- vapply(c(dc$ip), installed_version, character(1))
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
      # a failed read does not close the connection by itself
      con <- url(paste0("https://raw.githubusercontent.com/green-striped-gecko/", p, "/", b, "/DESCRIPTION"))
      on.exit(close(con))
      tryCatch({
        myfile <- readLines(con, warn = FALSE)
        gsub(pattern = "Version: ", "", myfile[grep("Version: ", myfile)])
      }, error = function(e) {
        failed <<- c(failed, "Github")
        "?"
      }, warning = function(w) {
        failed <<- c(failed, "Github")
        "?"
      })
    }
    versions <- character(0)
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
    
    nstate <- rep("--- ", length(dc$nip))
    isfailed <- dc$nip %in% dc$failed
    nstate[isfailed] <- paste0(vapply(dc$nip[isfailed], installed_version, character(1)), " installed, fails to load")
    nversions <- paste0(cli::style_bold(nstate), " | CRAN:",dvnc," | Github:  ",dvnm," (main) | ",dvnb," (beta) | ",dvnd," (dev)")
    
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
      cli::cat_line("dartRverse_install('dartR.data', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.base', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.popgen', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.captive', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.sim', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.spatial', rep='Github', branch='main')", col="blue")
      cli::cat_line("dartRverse_install('dartR.sexlinked', rep='Github', branch='main')", col="blue")
      cli::cat_line()
 
      
      
      
      
      
    } else {
    
    #make sure all packages exist before installing any
    if (length(package) == 0) {
      stop(paste0("package must name at least one package. Use one of: ", paste(c(core, addons), collapse = ", ")))
    }
    package <- unique(package)
    bad <- package[!package %in% c(core,addons)]
    if (length(bad) > 0) {
      stop(paste0("Unknown dartRverse package: ", paste(bad, collapse = ", "), ". Use one of: ", paste(c(core, addons), collapse = ", ")))
    }
    reps <- c("CRAN", "GITHUB")
    if (is.null(rep) || length(rep) != 1 || is.na(rp <- pmatch(toupper(rep), reps))) {
      stop("rep must be 'CRAN' or 'Github'.")
    }
    rep <- reps[rp]
    # rep defaults to CRAN, where a requested branch would otherwise be ignored and the wrong version installed
    if (rep == "CRAN" && !missing(branch)) {
      stop("branch only applies to Github installs. Use rep = 'Github' to install from a branch.")
    }
    if (!is.character(branch) || length(branch) != 1 || is.na(branch) || !nzchar(branch)) {
      stop("branch must be one branch name, for example 'main', 'beta' or 'dev'.")
    }

    # dartR.base (a dependency of every dartR package except dartR.data) imports these Bioconductor packages, which install.packages cannot find on CRAN
    bioc <- c("SNPRelate", "snpStats")
    missing.bioc <- bioc[!vapply(bioc, rlang::is_installed, logical(1))]
    if (length(missing.bioc) > 0 && !identical(package, "dartR.data")) {
      stop(paste0("Bioconductor package(s) ", paste(missing.bioc, collapse = ", "), " must be installed first. Please run:\n",
                  "install.packages('BiocManager')\n",
                  paste0("BiocManager::install('", missing.bioc, "')", collapse = "\n")))
    }
    
    # install.packages() reports these failures as warnings and returns normally, so they have to be caught by their text
    fail.warning <- "not available|non-zero exit status|cannot remove prior installation|restored"
    install.errors <- character(0)
    for (pk in package) {
      # a namespace imported by another loaded dartR package cannot be unloaded, so the old version stays in use until R restarts
      was.loaded <- pk %in% loadedNamespaces()
      ps <- paste0("package:",pk)
      was.attached <- ps %in% search()
      if (was.attached) suppressWarnings(detach(ps, unload = TRUE, character.only = TRUE, force=TRUE))
      why <- NULL
      tryCatch(
        withCallingHandlers({
          if (rep == "CRAN") {
            cat(cli::col_green(paste0("  Installing ",pk ," from CRAN (latest version)\n")))
            install.packages(pk)
          } else {
            cat(cli::col_green(paste0("  Installing ",pk," from Github from branch [",branch,"] \n")))
            remotes::install_github(paste0("green-striped-gecko/",pk),
                                    ref = branch,
                                    dependencies = TRUE)
          }
        }, warning = function(w) {
          if (grepl(fail.warning, conditionMessage(w))) {
            why <<- c(why, conditionMessage(w))
            invokeRestart("muffleWarning")
          }
        }),
        error = function(e) why <<- c(why, conditionMessage(e))
      )
      if (is.null(why)) {
        if (was.loaded) cat(cli::style_bold(cli::col_red(paste0("  Restart R to use the new version of ", pk, "\n"))))
      } else {
        install.errors[pk] <- paste(why, collapse = "; ")
        if (was.attached) suppressWarnings(suppressMessages(require(pk, character.only = TRUE, quietly = TRUE)))
      }
    }
    if (length(install.errors) > 0) {
      stop(paste0("Installation failed for ", paste0(names(install.errors), ": ", install.errors, collapse = "\n")))
    }
    return(invisible(NULL))
  }

}

# Load-only counterpart of dartR_check(): same result structure, except that failed holds only names, and nothing is attached to the search path
dartR_status <- function() {
  loads <- function(x) {
    tryCatch(suppressMessages(suppressWarnings(requireNamespace(x, quietly = TRUE))),
             error = function(e) FALSE)
  }
  bc <- vapply(core, loads, logical(1))
  ba <- vapply(addons, loads, logical(1))
  notloaded <- c(core[!bc], addons[!ba])
  list(core = core[bc], ip = addons[ba], nip = notloaded,
       failed = notloaded[vapply(notloaded, is_pkg_installed, logical(1))])
}
