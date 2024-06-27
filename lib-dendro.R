library(lubridate)
library(tidyverse)

library(treenetproc)

# import one csv data
# Examples of date_format: "%Y.%m.%d %H:%M", "%d.%m.%Y %H:%M:%S", "%d/%m/%Y %H:%M:%S"
read.one.dendro <- function(nameFile, series.no, date_format = "%d.%m.%Y %H:%M:%S",
                            timezone = "Europe/Madrid"){
  
  File <- read.csv(nameFile,  
                   sep = ";",  header=FALSE, skip=0, dec=",", stringsAsFactors=FALSE)
  
  
  ts<-File$V2
  
  if (date_format == "%d.%m.%Y %H:%M:%S")
    ts <- gsub("^(\\d{2}\\.\\d{2}\\.\\d{4})$", "\\1 00:00:00", ts) # appends 00:00 to midnight
  else if (date_format == "%d/%m/%Y %H:%M:%S")
    ts <- gsub("^(\\d{2}\\/\\d{2}\\/\\d{4})$", "\\1 00:00:00", ts) # appends 00:00 to midnight
  else if (date_format == "%Y.%m.%d %H:%M")
    ts <- gsub("^(\\d{4}\\.\\d{2}\\.\\d{2})$", "\\1 00:00", ts) # appends 00:00 to midnight
  
  File$ts<-as.POSIXct(ts, format=date_format, tz="Europe/Madrid")
  
  File$date <- as.Date(File$ts)
  File$um<-as.numeric(File$V7)
  File$value<-File$um-File$um[1] #zeroing variations in diameter
  File$temp<-as.numeric(File$V4)
  File$series<-as.factor(series.no)
  File<-subset(File,select=c(ts,date,um,value,temp,series))
  return(File)
}


# import all csv data and put it altogether in one dataframe
read.all.dendro <- function(nameFiles, date_format = "%d.%m.%Y %H:%M:%S"){
  FileList <- list()
  # print(nameFiles)
  for (i in 1:length(nameFiles)){
    # Clean name of field series
    # db$series <- gsub(paste0("./", DATA_DIR, "/"),"",db$series) 
    
    series.no <- nameFiles[i]
    # print(series.no)
    series.no <- gsub(".*data_([^_]*).*","\\1",series.no)
    # print(series.no)
    
    File <- read.one.dendro(nameFiles[i], series.no, date_format = date_format)
    # print(File)
    FileList[[i]] <- File
  }
  return(do.call(rbind.data.frame, FileList))
}


read.one.processed <- function(nameFile){
  File <- read.csv(nameFile, sep = ",",  header=TRUE, stringsAsFactors=FALSE)
  File$ts <- as_datetime(File$ts, tz = "Europe/Madrid")
  File$series <- as.factor(File$series)
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


read.env.proc <- function(filename) {
  File <- read.csv(filename, sep = ",",  header=TRUE, stringsAsFactors=FALSE)
  File$series <- as.factor(File$series)
  File$ts <- as_datetime(File$ts, tz = "Europe/Madrid")
  return(File)
}


read.all.env.processed <- function(nameFiles){
  FileList <- list()
  print(nameFiles)
  for (i in 1:length(nameFiles)){
    File <- read.env.proc(nameFiles[i])
    FileList[[i]] <- File
  }
  return(do.call(rbind.data.frame, FileList))
}


read.env.agg <- function(filename) {
  File <- read.csv(filename, sep = ",",  header=TRUE, stringsAsFactors=FALSE)
  File$ts <- as_datetime(File$ts, tz = "Europe/Madrid")
  return(File)
}


reset.initial.values <- function (dendros, ts_start, ts_end = NULL) {
  
  if(is.null(ts_end)) {
      dendros <- dendros[which(dendros$ts>=ts_start),]
    } else {
      dendros <- dendros[which(dendros$ts>=ts_start & dendros$ts<=ts_end),]
    }
  
  sub_first_element <- function (dendro, group_key){
    # equivalent to one-liner: return (df$value = sapply(df$value, \(val, first_val) val - first_val, df$value[1]))
    dendro$value = dendro$value - dendro$value[1]
    return (dendro)
  }
  
  return (dendros %>% group_by(series) %>% group_modify( sub_first_element ) %>% 
            recalc_growth_variables(tz = 'Europe/Madrid') %>% select(-version) %>%
            ungroup() %>% as.data.frame()
          )

}


normalize.0_1 <- function (values) {
  minV <- min(values, na.rm = TRUE)
  maxV <- max(values, na.rm = TRUE)
  return ((values - minV) / (maxV - minV))
}
