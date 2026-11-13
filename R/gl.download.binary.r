#' Support function to download binaries from github
#'
#' This function supports the download of binaries from github. Those binaries are compiled files that allow to run dartR functions that integrate third party software such as epos (gl.run.epos), NeEstimator (gl.LDNe) or Structure (gl.run.structure). Please be aware this is just to allow for easy install and use of dartR functions. We have explicitly asked the authors of the software for permission to include those binaries here. Understandably some authors prefer to direct users to their own websites to download the software. Here a comment is issued by the function how to do so. Please note: **The third party packages are the work of others and please make the effort to cite them accordingly**. You find the citations under the help pages of the respective functions, for example ?gl.run.epos.
#'
#' @param software Name of the software package to download, one of "beagle", "colony", "eems", "emibd9", "epos", "faststructure", "gone", "ms", "neestimator", "plink", "popcluster", "stairway2" and "structure". Upper case is converted to lower case. Depending on the software several files will be downloaded. If NULL, a table of the binaries available for each operating system is printed. Where the console supports it, such as in RStudio, clicking a tick in the table downloads that binary [default NULL].
#' @param os The operating system to download the binary for: "windows", "mac" or "linux" (partial matching is allowed). Some binaries are not available for all operating systems. If NULL, the current operating system is used [default NULL].
#' @param branch Which branch of the dartRverse github repository to download from, or to list the binaries of. There should be no reason to change it [default "main"].
#' @param out.dir The path where to save the binary [default tempdir()].
#' @param verbose If 0, download progress and messages are suppressed; any other value prints them [default 2].
#' @details After a download the function says which software was downloaded, which dartR functions use it (with links to their help pages where the console supports them) and asks you to check the help pages of those functions to cite the program and its methods correctly.
#'
#' On mac and linux the unzipped files are made executable (mode 777), so the dartR functions that call them, such as gl.run.epos or gl.LDNe, can run them straight away.
#' @return When software is given, invisibly, the path of the folder that holds the unzipped binary (out.dir/software). When software is NULL, NULL (the table of available binaries is printed).
#' @examples
#' \dontrun{
#' # list the binaries available for each operating system
#' gl.download.binary()
#' # download PLINK for the current operating system into tempdir()
#' path <- gl.download.binary("plink")
#' }
#' @export
#' @importFrom utils installed.packages install.packages available.packages
#' @importFrom utils download.file unzip
#' @importFrom httr GET content add_headers

gl.download.binary <- function(software=NULL,
                               os=NULL,
                               branch="main",
                               out.dir=tempdir(),
                               verbose=2)
 
{

  
  
  oses <- c("windows","mac","linux")
  
  # file names on github are lower case and the host is case-sensitive
  if (!is.null(software)) {
    if (!is.character(software) || length(software) != 1) {
      stop("software must be a single character string, e.g. \"plink\". Use gl.download.binary() to list the available binaries.")
    }
    software <- tolower(software)
  }
  
  #set quiet depending on verbose
  if (verbose==0) quiet <- TRUE else quiet <- FALSE
  #check if the binary is available
  #available software
  
  #if no os then use the current one
  if (is.null(os)) {
    os <- tolower(Sys.info()['sysname'] )
    if (os=="darwin") os <- "mac"
  }
  if (is.na(osm <- pmatch(os, oses))) {
    stop(paste0("Specified os: ",os, " not supported. Please use ", paste0(c("windows","mac","linux"), collapse=", ")))
  } else os <- oses[osm]
  
  
  if (is.null(software)) { #show all binaries in the folder
    
    # send a GitHub token if one is set (limit 5000/h instead of 60/h per IP)
    pat <- Sys.getenv("GITHUB_PAT")
    auth <- if (nzchar(pat)) add_headers(Authorization = paste("token", pat)) else NULL
    req <- tryCatch(
      GET(paste0("https://api.github.com/repos/green-striped-gecko/dartRverse/git/trees/", branch, "?recursive=1"), auth),
      error = function(e) e
    )
    browse <- paste0("https://github.com/green-striped-gecko/dartRverse/tree/", branch, "/binaries")
    if (inherits(req, "error")) {
      stop(paste0("Could not reach github to list the binaries (", conditionMessage(req), "). Check your internet connection or browse ", browse))
    }
    tree <- content(req)$tree
    # when the API rate limit is hit the body holds only a message
    if (is.null(tree)) {
      stop(paste0("Github did not return the list of binaries (", content(req)$message, "). Try again later or browse ", browse))
    }
    
    all.files <- unlist(lapply(tree, "["), use.names = F)
    all.files <- all.files[grep(".zip", all.files)]
    all.files <- gsub("binaries/", "", all.files)
    all.files <- gsub(tolower(".zip"), "", all.files)
    
    
    
    
    soft <- unique(sapply(strsplit(all.files, "_"),"[",1))
    os <- unique(sapply(strsplit(all.files, "_"),"[",2))
    
    
    l0 <- cli::cat_line(cli::style_bold("Available binaries:"))
    
    dc <- data.frame(matrix(0, nrow=length(soft), ncol=length(os)))
    
    for (i in 1:length(all.files)) {
      dc[which(soft==sapply(strsplit(all.files[i], "_"),"[",1)), which(os==sapply(strsplit(all.files[i], "_"),"[",2))] <- 1
    }
    
    
    rownames(dc)<- soft
    colnames(dc)<- os
    
    links <- dartR_links()
    l1<- ansi_columns(cli::col_blue(c("    ",colnames(dc))), width = 65, align = "center")
    ly <- NA
    for (i in 1:nrow(dc)) {
      
      lx <- paste0(cli::col_green(soft[i]), " ")
      for (ii in 1:ncol(dc)) {
        lx[ii+1] <- if (dc[i,ii]==1) {
          binary_cell(soft[i], os[ii], branch, links)
        } else col_red(binary_symbols()$cross)
      }
      ly[i] <- ansi_columns(lx, width = 65, align = "center")
    }
    cli::cat_line(boxx(c(l1,ly)))
    if (links$run) {
      cli::cat_line("Click a tick to download that binary into tempdir().")
    } else if (links$href) {
      cli::cat_line("Click a tick to download the zip file in your browser, or type for example: gl.download.binary(\"plink\")")
    } else {
      cli::cat_line("To download, type for example: gl.download.binary(\"plink\")")
    }
    
  
      
    
  } else  {
  
  
  
  webpath <- binary_url(software, os, branch)
  
  #download to temp file
  tmpfile <- tempfile()
  # collect download.file warnings (they carry the HTTP status) instead of printing them
  msgs <- character(0)
  result <- withCallingHandlers(
    tryCatch(
      download.file(webpath, destfile = tmpfile, quiet = quiet, mode = "wb"),
      error = function(e) conditionMessage(e)
    ),
    warning = function(w) {
      msgs <<- c(msgs, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (!(is.numeric(result) && result == 0)) {
    msgs <- c(msgs, as.character(result))
    if (any(grepl("404", msgs))) {
      stop(paste0("Binary for ", software, " on ", os, " not available. Use gl.download.binary() to list the available binaries."))
    }
    stop(paste0("Download of ", webpath, " failed (", paste(unique(msgs), collapse = "; "), "). Check your internet connection or proxy settings."))
  }
  xx <- unzip(tmpfile, exdir=out.dir)
  # mac and linux binaries must be executable. zip files made on Windows do not
  # keep that permission, and use_umask = FALSE stops the umask removing it.
  if (os!="windows") {
    Sys.chmod(unique(dirname(xx)), mode = "0777", use_umask = FALSE)
    Sys.chmod(xx, mode = "0777", use_umask = FALSE)
  }
  
  if (quiet==FALSE) {
    cli::cat_line(cli::col_green(paste0("Unzipped binary to ",out.dir,"/",software)))
    cli::cat_line(binary_notice(software))
  }
  
  invisible(file.path(out.dir,software))
  }
}

# Tick and cross for the table of binaries. cli's heavy tick and cross (U+2714,
# U+2716) are missing from common console fonts such as Lucida Console and
# Consolas, so consoles like RStudio draw them wider from another font and the
# box around the table is no longer square. The square root sign and the
# multiplication sign are in those fonts. Consoles without UTF-8 get v and x.
binary_symbols <- function() {
  if (cli::is_utf8_output()) list(tick = "\u221a", cross = "\u00d7")
  else list(tick = "v", cross = "x")
}

#' Download a binary (alias for clickable links)
#'
#' Calls [gl.download.binary()] with the same arguments. It exists because
#' RStudio runs code from a console link only if the function name has no
#' dots, so the clickable ticks in the table printed by `gl.download.binary()`
#' call this alias. Use [gl.download.binary()] in your own code.
#'
#' @param ... Arguments passed to [gl.download.binary()].
#' @return The value returned by [gl.download.binary()].
#' @seealso [gl.download.binary()]
#' @keywords internal
#' @export
download_binary <- function(...) {
  gl.download.binary(...)
}

# The software in each binary and the dartR functions that run it, as
# "package::function". The list is kept by hand: searching the packages for
# the software name finds many functions that only mention it. Update it when
# a function that runs one of the binaries is added, renamed or moved.
binary_info <- function() {
  list(
    bayescan      = list(name = "BayeScan", funs = "dartR.popgen::gl.run.bayescan"),
    beagle        = list(name = "Beagle", funs = "dartR.base::gl.impute"),
    colony        = list(name = "COLONY", funs = c("dartR.captive::gl.run.colony",
                                                   "dartR.captive::gl.parentage.power")),
    eems          = list(name = "EEMS", funs = "dartR.spatial::gl.run.eems"),
    emibd9        = list(name = "EMIBD9", funs = c("dartR.captive::gl.run.EMIBD9",
                                                   "dartR.captive::gl.sim.relatedness")),
    epos          = list(name = "EPOS", funs = "dartR.popgen::gl.run.epos"),
    faststructure = list(name = "fastStructure", funs = c("dartR.popgen::gl.run.faststructure",
                                                          "dartR.popgen::gl.plot.faststructure")),
    gone          = list(name = "GONE", funs = character(0)),
    ms            = list(name = "ms", funs = character(0)),
    neestimator   = list(name = "NeEstimator", funs = "dartR.popgen::gl.LDNe"),
    plink         = list(name = "PLINK", funs = c("dartR.base::gl2plink",
                                                  "dartR.base::gl.read.PLINK",
                                                  "dartR.captive::gl.inbreeding")),
    popcluster    = list(name = "PopCluster", funs = c("dartR.popgen::gl.run.popcluster",
                                                       "dartR.popgen::gl.plot.popcluster")),
    stairway2     = list(name = "Stairway Plot 2", funs = "dartR.popgen::gl.run.stairway2"),
    structure     = list(name = "STRUCTURE", funs = c("dartR.popgen::gl.run.structure",
                                                      "dartR.popgen::gl.plot.structure",
                                                      "dartR.popgen::gl.evanno",
                                                      "dartR.popgen::gl.map.structure"))
  )
}

# What was downloaded, the dartR functions that run it (help links where the
# console supports them) and a request to cite the software
binary_notice <- function(software) {
  info <- binary_info()[[software]]
  if (is.null(info)) info <- list(name = software, funs = character(0))
  out <- paste0("Downloaded ", info$name, ".")
  if (length(info$funs) > 0) {
    pkg <- sub("::.*", "", info$funs)
    fun <- sub(".*::", "", info$funs)
    help <- isTRUE(cli::ansi_hyperlink_types()$help)
    installed <- vapply(pkg, function(x) nzchar(system.file(package = x)), logical(1))
    shown <- ifelse(help & installed,
                    vapply(info$funs, function(f) {
                      cli::format_inline(paste0("{.help [", sub(".*::", "", f), "()](", f, ")}"))
                    }, character(1)),
                    paste0(fun, "()"))
    by.pkg <- vapply(unique(pkg), function(x) {
      paste0(paste(shown[pkg == x], collapse = ", "), " in ", x,
             if (!installed[pkg == x][1]) " (not installed)")
    }, character(1))
    out <- c(out, paste0("Used by ", paste(by.pkg, collapse = "; "), "."))
  }
  c(out, paste0(info$name, " is the work of others. Please cite the program and its methods correctly",
                if (length(info$funs) > 0) ": check the help pages of the functions above for the references to cite", "."))
}

# The webpath of a binary's zip file on github
binary_url <- function(software, os, branch) {
  paste0("https://raw.githubusercontent.com/green-striped-gecko/dartRverse/", branch,
         "/binaries/", software, "_", os, ".zip")
}

# A tick in the table of binaries. Where the console can run code from a link
# (RStudio), clicking it downloads the binary; where it can only open web links,
# clicking it downloads the zip file in the browser.
binary_cell <- function(software, os, branch, links) {
  tick <- cli::col_green(binary_symbols()$tick)
  if (links$run) {
    code <- paste0("dartRverse::download_binary('", software, "', os = '", os, "'",
                   if (branch != "main") paste0(", branch = '", branch, "'"), ")")
    return(cli::format_inline(paste0("{.run [", binary_symbols()$tick, "](", code, ")}")))
  }
  if (links$href) {
    return(cli::format_inline(paste0("{.href [", binary_symbols()$tick, "](", binary_url(software, os, branch), ")}")))
  }
  tick
}
