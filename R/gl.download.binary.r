#' Support function to download binaries from github 
#' 
#' This functions supports the download of binaries from github. Those binaries are compiled files that allow to run dartR functions that integrate third party software such as epos (gl.run.epos), NeEstimator (gl.LDNe) or Structure (gl.run.structure). Please be aware this is just to allow for easy install and use of dartR functions seemlessly. We have explicitely asked the authors of the software for permission to include those binaries here. Understandably some authors prefer to direct users to their own websites to download the software. Here a comment is issued by the function how to do so. Please note: **The third party packages are the work of others and please make the effort to cite them accordingly**. You find the citations under the help pages of the respective functions, for example ?gl.run.epos.
#' 
#' @param software name of the software package to download. Currently supported are: "epos", "NeEstimator", "Stairway2" and  "Gone". Please note, depending on the software several files will be downloaded
#' @param os the operating system to download the binary for. Currently supported are: "windows", "mac" and "linux". Please be aware some binaries are not available for all operating systems.
#' @param branch which branch to download from (leave empty for the main branch and there should not be a reason to change that)
#' @param out.dir the path where to save the binary. If left empty the binary will be saved in the temporary directory.
#' @param verbose .If zero, suppresses output messages. Default is zero

#' @return functions returns NULL
#' @examples 
#' gl.download.binary
#' \donttest{
#' dartRverse_install()
#' }
#' @export
#' @importFrom utils installed.packages install.packages available.packages
#' @importFrom RCurl url.exists
#' @importFrom utils download.file unzip
#' @importFrom httr GET content

gl.download.binary <- function(software=NULL,
                               os=NULL,
                               branch="main",
                               out.dir=tempdir(),
                               verbose=2)
 
{

  
  
  oses <- c("windows","mac","linux")
  
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
    
    req  <- GET("https://api.github.com/repos/green-striped-gecko/dartRverse/git/trees/dev?recursive=1")
    
    all.files <- unlist(lapply(content(req)$tree, "["), use.names = F)
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
  webpath <- paste0("https://raw.github.com/green-striped-gecko/dartRverse/", branch,"/binaries/",zipfile)
  
  if (!url.exists(webpath)) {
    stop(paste0("Binary for ",software," on ",os," not available. Please check the dartRverse binary folder on github for available binariers."))
  }
  #download to temp file
  tmpfile <- tempfile()
  download.file(webpath, destfile=tmpfile, quiet = quiet, mode="wb")
  if (quiet==FALSE) cat("Downloaded binary to ",tmpfile,"\n")
  
  xx <- unzip(tmpfile, exdir=out.dir)
  
  if (quiet==FALSE) cli::cat_line(cli::col_green(paste0("Unzipped binary to ",out.dir,"/",software)))
  
  invisible(file.path(out.dir,software))
  }
}

  
  