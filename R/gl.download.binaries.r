#' Support function to download binaries from github 
#' 
#' This functions supports the download of binaries from github. Those binaries are compiled files that allow to run dartR functions that integrate third party software such as epos (gl.run.epos), NeEstimator (gl.LDNe) or Structure (gl.run.structure). Please be aware this is just to allow for easy install and use of dartR functions seemlessly. We have explicitely asked the authors of the software for permission to include those binaries here. Understandably some authors prefer to direct users to their own websites to download the software. Here a comment is issued by the function how to do so. Please note: **The third party packages are the work of others and please make the effort to cite them accordingly**. You find the citations under the help pages of the respective functions, for example ?gl.run.epos.
#' 
#' @param software name of the software package to download. Currently supported are: "epos", "NeEstimator", "Stairway2" and  "Gone". Please note, depending on the software several files will be downloaded
#' @param os the operating system to download the binary for. Currently supported are: "windows", "mac" and "linux". Please be aware some binaries are not available for all operating systems.
#' @param branch which branch to download from (leave empty for the main branch and there should not be a reason to change that)
#' @param out.dir the path where to save the binary. If left empty the binary will be saved in the temporary directory.
#' @param quiet logical. If TRUE, suppresses output messages. Default is TRUE.

#' @return functions returns NULL
#' @examples 
#' gl.download.binary
#' \donttest{
#' dartRverse_install()
#' }
#' @export
#' @importFrom utils installed.packages install.packages available.packages

gl.download.binary <- function(software,
                               os,
                               branch="main",
                               out.dir=tempdir(),
                               quiet=TRUE
                               )
 
{

  oses <- c("windows","mac","linux")
  
  
  #check if the binary is available
  #available software
  path <- url("https://raw.github.com/green-striped-gecko/dartRverse/dev/binaries/binaries.csv")
  binaries <- read.csv(path)
  
  if (is.na(osm <- pmatch(os, oses))) {
    stop(paste0("Specified os: ",os, " not supported. Please use ", paste0(c("windows","mac","linux"), collapse=", ")))
  }
  binaries <- binaries[binaries$os==oses[osm],]
  
  if (is.na(softm <- pmatch(software, binaries$software))) {
    stop(paste0("Specified software: ",software, " not supported for ",os,"."))
  }
  binaries <- binaries[binaries$software==binaries$software[softm],]
  
  #create directory
  dir.create(file.path(out.dir,binaries$software[1]), showWarnings = TRUE)
  
  #download binaries
  for (i in 1:nrow(binaries)) {
    url <- paste0("https://raw.github.com/green-striped-gecko/dartRverse/dev/binaries/",oses[osm],"/",binaries$software[1],"/",binaries$files[i])
    xx <- download.file(url, destfile=file.path(out.dir,binaries$software[1],binaries$files[i]),quiet = quiet, mode="wb")
    if (xx!=0) {
      warning(paste0("Could not download ",binaries$files[i],"\n"))
    } else {
        cat(paste0("Downloaded ",binaries$files[i]," to ",file.path(out.dir,binaries$software[1]),"\n"))
    }
  }

  return(NULL)
  
}

  
  