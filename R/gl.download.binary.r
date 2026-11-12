#' Support function to download binaries from github
#'
#' This function supports the download of binaries from github. Those binaries are compiled files that allow to run dartR functions that integrate third party software such as epos (gl.run.epos), NeEstimator (gl.LDNe) or Structure (gl.run.structure). Please be aware this is just to allow for easy install and use of dartR functions. We have explicitly asked the authors of the software for permission to include those binaries here. Understandably some authors prefer to direct users to their own websites to download the software. Here a comment is issued by the function how to do so. Please note: **The third party packages are the work of others and please make the effort to cite them accordingly**. You find the citations under the help pages of the respective functions, for example ?gl.run.epos.
#'
#' @param software Name of the software package to download, one of "beagle", "colony", "eems", "emibd9", "epos", "faststructure", "gone", "ms", "neestimator", "plink", "popcluster", "stairway2" and "structure". Upper case is converted to lower case. Depending on the software several files will be downloaded. If NULL, a table of the binaries available for each operating system is printed [default NULL].
#' @param os The operating system to download the binary for: "windows", "mac" or "linux" (partial matching is allowed). Some binaries are not available for all operating systems. If NULL, the current operating system is used [default NULL].
#' @param branch Which branch of the dartRverse github repository to download from, or to list the binaries of. There should be no reason to change it [default "main"].
#' @param out.dir The path where to save the binary [default tempdir()].
#' @param verbose If 0, download progress and messages are suppressed; any other value prints them [default 2].
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
    
    l1<- ansi_columns(cli::col_blue(c("    ",colnames(dc))), width = 65, align = "center")
    ly <- NA
    for (i in 1:nrow(dc)) {
      
      lx <- paste0(cli::col_green(soft[i]), " ")
      for (ii in 1:ncol(dc))   lx[ii+1] <-  ifelse(dc[i,ii]==1, cli::col_green(cli::symbol$tick), col_red(cli::symbol$cross))
      ly[i] <- ansi_columns(lx, width = 65, align = "center")
      #cli::cat_line(lx)
    }
    cli::cat_line(boxx(c(l1,ly)))
    
  
      
    
  } else  {
  
  
  
  zipfile <- paste0(software,"_",os,".zip")
  webpath <- paste0("https://raw.githubusercontent.com/green-striped-gecko/dartRverse/", branch,"/binaries/",zipfile)
  
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
  if (os!="windows") Sys.chmod(xx, mode = "0755")
  
  if (quiet==FALSE) cli::cat_line(cli::col_green(paste0("Unzipped binary to ",out.dir,"/",software)))
  
  invisible(file.path(out.dir,software))
  }
}

  
  