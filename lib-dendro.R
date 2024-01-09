library(lubridate)


# import one csv data
read.one.dendro <- function(nameFile){
  File <- read.csv(nameFile,  
                   sep = ";",  header=FALSE, skip=0, dec=",", stringsAsFactors=FALSE)
  File$ts<-as.POSIXct(File$V2, format="%d.%m.%Y %H:%M:%S", tz="Europe/Madrid")
  File$date <- as.Date(File$ts)
  File$um<-as.numeric(File$V7)
  File$value<-File$um-File$um[1] #zeroing variations in diameter
  File$temp<-as.numeric(File$V4)
  File$series<-as.factor(nameFile)
  File<-subset(File,select=c(ts,date,um,value,temp,series))
  return(File)
}


# import all csv data and put it altogetuer in one dataframe
read.all.dendro <- function(nameFiles){
  FileList <- list()
  print(nameFiles)
  for (i in 1:length(nameFiles)){
    File <- read.one.dendro(nameFiles[i])
    FileList[[i]] <- File
  }
  return(do.call(rbind.data.frame, FileList))
}


read.one.processed <- function(nameFile){
  File <- read.csv(nameFile, sep = ",",  header=TRUE, stringsAsFactors=FALSE)
  File$ts <- as_datetime(File$ts, tz = "Europe/Madrid")
  return(File)
}


read.all.processed <- function(nameFiles){
  FileList <- list()
  print(nameFiles)
  for (i in 1:length(nameFiles)){
    File <- read.one.processed(nameFiles[i])
    FileList[[i]] <- File
  }
  return(do.call(rbind.data.frame, FileList))
}


read.env.data <- function(filename) {
  File <- read.csv(filename, sep = ";", header = FALSE, skip = 0, dec = ",", stringsAsFactors = FALSE)
  File$ts<-as.POSIXct(File$V2, format="%Y.%m.%d %H:%M", tz="Europe/Madrid")
  File$date <- as.Date(File$ts)
  File$soil.temp <- File$V4
  File$bottom.temp <- File$V5
  File$top.temp <- File$V6
  File$humidity <- File$V7
  return (subset(File, select = c(ts, date, soil.temp, bottom.temp, top.temp, humidity)))
}
