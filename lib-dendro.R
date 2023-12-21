library(lubridate)

# import one csv data
read.one.dendro <- function(nameFile){
  File <- read.csv(nameFile,  
                   sep = ";",  header=FALSE, skip=0, dec=",", stringsAsFactors=FALSE)
  File$ts<-as.POSIXct(File$V2, format="%d.%m.%Y %H:%M:%S", tz="Europe/Madrid")
  File$date <- as.Date(File$ts)
  File<-File[which(File$ts>=ts_start & File$ts<=ts_end),] 
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
