library(treenetproc)
library(tidyverse)

### DEFINE GLOBAL VARS ###
PATH = '/home/akronix/workspace/dendro';
setwd(PATH)
SELECTED_DENDROMETER = "92222169"
DATA_DIR = 'dataD'
OUTPUT_DATA_DIR = 'processed-dataD'

#-----------------------------------------------#
  
# Set initial and final date and sampling dates
ts_start<-"2022-03-12 00:00:00" #from March 12 (2 days after installation)


if (SELECTED_DENDROMETER == 92222174) { # for dendro no 92222174, data is corrupted from "2023-07-06 18:45:00" to the end
  ts_end<-"2023-07-06 18:30:00"
} else if (SELECTED_DENDROMETER == 92222161) { # dendro 92222161
  ts_end <-"2023-09-13 11:15:00"
} else {
  ts_end<-"2023-09-14 00:00:00" 
}

### IMPORT DENDRO DATA ###

# Import data from dataD/ in working directory
read.data.dendro <- function(nameFiles){
  FileList <- list()
  print(nameFiles)
  for (i in 1:length(nameFiles)){
    File <- read.csv(nameFiles[i],  
                     sep = ";",  header=FALSE, skip=0, dec=",", stringsAsFactors=FALSE)
    File$ts<-as.POSIXct(File$V2, format="%Y.%m.%d %H:%M", tz="Europe/Madrid")
    File$date <- as.Date(File$ts)
    File<-File[which(File$ts>=ts_start & File$ts<=ts_end),] 
    File$um<-as.numeric(File$V7)
    File$value<-File$um-File$um[1] #zeroing variations in diameter
    File$temp<-as.numeric(File$V4)
    File$series<-as.factor(nameFiles[i])
    File<-subset(File,select=c(ts,date,um,value,temp,series))
    FileList[[i]] <- File
  }
  return(FileList)
}

# importing dendro data #
list.files <- list.files(file.path(".",DATA_DIR), pattern="*.csv", full.names=TRUE)
#db<-read.data.dendro(list.files) %>% rbind.data.frame
db<-do.call(rbind.data.frame, read.data.dendro(list.files))

# Clean name of field series
db$series <- gsub("./dataD/","",db$series)
db$series <- gsub("_2023_09_13_0.csv","",db$series)
db$series <- substr(db$series,6,nchar(db$series))

### CLEAN & PREPARE DATA ###

# In this script, we will work with one dendrometer series only
db = db[db$series == SELECTED_DENDROMETER,]

# Add tree information to each dendrometer (series)
TreeList<-read.table("TreeList.txt",header=T)
db <- merge(db,TreeList[,c(1:4,6)],  by = "series") 
db

# This removes duplicates on timestamps (presumably because of daylight savingtime issues)
print("These are the duplicated data by timestamp:")
print(db[duplicated(db$ts),])
db = db[!duplicated(db$ts),];

### PLOT RAW DATA ###

## TEMP DATA ##
plotTemp <- ggplot(data = db, mapping = aes(x=ts, y=temp, col=temp)) +
  labs(x=expression('date'),
       y=expression("Temperature (ºC)")) +
  geom_line() +
  ggtitle(paste("Dendrometer temperature for sensor series: ",db$series[1])) +
  scale_x_datetime(date_breaks = "1 month", date_labels = "%m-%y") +
  geom_hline(yintercept=0,lty=2,linewidth=0.2) +
  theme_bw()
plotTemp

## DENDRO DATA ##

#plot(value~ts,db,type="l",col="blue",axes=T)

dendro_raw_plot <-
  ggplot(data = db, mapping = aes(x=ts, y=value))+
  geom_line( )+
  ggtitle(paste0("Dendro data for sensor series: ",db$series[1])) +
  labs(x=expression('Date'),
       y=expression(Delta*"D (um)"))+
  geom_hline(yintercept=0,lty=2,linewidth=0.2)+
  scale_x_datetime(date_breaks = "1 month", date_labels = "%m-%y") +
  theme_bw()
dendro_raw_plot

### PROCESS WITH TREENETPROC ###

str(db)
head(db)
tail(db)

## TREENETPROC: Prepare data ##

# Subset the columns we want for treenetproc
db <- subset(db, select = c(ts, value, series, ID, site, sp, class, temp))

# If I don't to the below code some NAs get filled inside proc_L1 when it check_ts(), throwing an error and messin up the timestamp
db$ts = strftime(db$ts, "%Y-%m-%d %H:%M:%S", tz = "Europe/Madrid" )

# define dendro_data_L0 to work with. Here we will use the "wide" format.
dendro_data_L0 = subset(db, select = c(series, ts, value, ID, site, sp, class))
temp_data_L0 = subset(db, select = c(series, ts, temp, ID, site, sp, class))

colnames(temp_data_L0)<-colnames(dendro_data_L0)

str(dendro_data_L0)
str(temp_data_L0)

## TREENETPROC: Time-alignment processing (L1) ##

# dendro data
dendro_data_L1 <- proc_L1(data_L0 = dendro_data_L0,
                          reso = 15,
                          date_format = "%Y-%m-%d %H:%M:%S",
                          input = "long",
                          year = "asis",
                          tz = "Europe/Madrid")
head(dendro_data_L1)
str(dendro_data_L1)


# temp data
temp_data_L1 <- proc_L1(data_L0 = temp_data_L0,
                        reso = 15,
                        date_format = "%Y-%m-%d %H:%M:%S",
                        input = "long",
                        year = "asis",
                        tz = "Europe/Madrid")
head(temp_data_L1)
str(temp_data_L1)

## TREENETPROC: Error detection and processing of the L1 data (L2) ##

dendro_data_L2 <- proc_dendro_L2(dendro_L1 = dendro_data_L1,
                                 temp_L1 = temp_data_L1,
                                 tol_out = 10,
                                 tol_jump = 10,
                                 plot_period = "monthly",
                                 plot = TRUE,
                                 plot_export = TRUE,
                                 plot_name = paste0( db$series[1] ,"-proc_L2_plot"),
                                 tz="Europe/Madrid")
# check the data
head(dendro_data_L2)
tail(dendro_data_L2)

#highlight corrections made on the dendrometer data:
View(dendro_data_L2[which(is.na(dendro_data_L2$flags)==F),])

# -> Open proc_L2_plot.pdf file to see results

# DANGER! MANUAL CORRECTIONS #
corr_dendro_data_L2<-corr_dendro_L2(dendro_L1 = dendro_data_L1,
                                    dendro_L2 = dendro_data_L2,
                                    reverse = c(6, 9:10, 11:14, 15),
                                    force = c("2023-07-01 13:15:00"),
                                    delete = c("2023-09-13 10:00:00", "2023-09-13 10:15:00",
                                               "2023-03-01 00:00:00", "2023-03-03 00:00:00"),
                                    plot = TRUE,
                                    plot_export = TRUE,
                                    #plot_name = paste0( "CORRECTED-", db$series[1] ,"-proc_L2_plot"),
                                    tz="Europe/Madrid")
#highlight manual corrections made on the dendrometer data:
View(corr_dendro_data_L2[which(is.na(corr_dendro_data_L2$flags)==F),])


### SAVE PROCESSED DATA ###

output_data <- subset(dendro_data_L2, select = c(series, ts, value, max, twd, gro_yr))
OUTPUT_PATH = file.path(PATH, OUTPUT_DATA_DIR)
if (!dir.exists(OUTPUT_PATH)) {dir.create(OUTPUT_PATH)}
write_csv(output_data, file.path(OUTPUT_PATH, paste0("proc-", db$ID[1], "-", db$series[1], ".csv")), append = FALSE)

