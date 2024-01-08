source("lib-dendro.R")

### DEFINE GLOBAL VARS ###
PATH = '/home/akronix/workspace/dendro';
setwd(PATH)

DATA_DIR = 'Partinchas-dec-data'
OUTPUT_DATA_DIR = 'processed-Partinchas-dec-data'
FILENAME_EXCESS = "_2023_12_28_0.csv"

# Set initial and final date and sampling dates
ts_start<-"2023-02-11 09:00:00" # 2 days after installation
ts_end<-"2023-12-28 12:45:00" # last timestamp of downloaded data

### IMPORT DENDRO DATA ###

# importing dendro data #
list_files <- list.files(file.path(".",DATA_DIR), pattern="*.csv", full.names=TRUE)
db<-read.all.dendro(list_files)

### CLEAN & PREPARE DATA ###

# Clean name of field series
db$series <- gsub(paste0("./", DATA_DIR, "/"),"",db$series) 
db$series <- gsub(FILENAME_EXCESS,"",db$series) # remove trailing filename _%date%_0.csv
db$series <- substr(db$series,6,nchar(db$series)) # remove initial "data_" in filename

# INSPECT DATA
str(db)
head(db)
tail(db)

## PLOT ALL DENDROS ##
dendro_all_plots <-
  ggplot(data = db, mapping = aes(x=ts, y=value, col=series))+
  geom_line( )+
  # ggtitle(paste0("Dendro data for sensor series: ",db$series[1], " - ", db$sp[1])) +
  labs(x=expression('Date'),
       y=expression(Delta*"D (um)"))+
  geom_hline(yintercept=0,lty=2,linewidth=0.2)+
  scale_x_datetime(date_breaks = "1 month", date_labels = "%m-%y") +
  theme_bw()
dendro_all_plots
