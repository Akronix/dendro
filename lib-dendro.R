library(lubridate)


# import one csv data
read.one.dendro <- function(nameFile, ts_start, ts_end, old_format = FALSE){
  File <- read.csv(nameFile,  
                   sep = ";",  header=FALSE, skip=0, dec=",", stringsAsFactors=FALSE)
  
  if (old_format)
    File$ts<-as.POSIXct(File$V2, format="%Y.%m.%d %H:%M", tz="Europe/Madrid")
  else
    File$ts<-as.POSIXct(File$V2, format="%d.%m.%Y %H:%M:%S", tz="Europe/Madrid")
  File$date <- as.Date(File$ts)
  # print(File)
  File<-File[which(File$ts>=ts_start & File$ts<=ts_end),]
  File$um<-as.numeric(File$V7)
  File$value<-File$um-File$um[1] #zeroing variations in diameter
  File$temp<-as.numeric(File$V4)
  File$series<-as.factor(nameFile)
  File<-subset(File,select=c(ts,date,um,value,temp,series))
  return(File)
}


# import all csv data and put it altogetuer in one dataframe
read.all.dendro <- function(nameFiles, ts_start, ts_end){
  FileList <- list()
  print(nameFiles)
  for (i in 1:length(nameFiles)){
    File <- read.one.dendro(nameFiles[i], ts_start, ts_end)
    FileList[[i]] <- File
  }
  return(do.call(rbind.data.frame, FileList))
}


read.one.processed <- function(nameFile){
  File <- read.csv(nameFile, sep = ",",  header=TRUE, stringsAsFactors=FALSE)
  File$ts <- as_datetime(File$ts, tz = "Europe/Madrid")
  File$series <- as.character(File$series)
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


reset.initial.values <- function (dendros, ts_start, ts_end) {
  
  dendros <- dendros[which(dendros$ts>=ts_start & dendros$ts<=ts_end),]
  
  sub_first_element <- function (dendro, group_key){
    # equivalent to one-liner: return (df$value = sapply(df$value, \(val, first_val) val - first_val, df$value[1]))
    dendro$value = dendro$value - dendro$value[1]
    return (dendro)
  }
  
  return (dendros %>% group_by(series) %>% group_modify( sub_first_element ) %>% ungroup() %>% as.data.frame() )

}