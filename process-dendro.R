library(treenetproc)
library(tidyverse)
library(glue)


### DEFINE GLOBAL VARS ###
PATH = '/home/akronix/workspace/dendro'
setwd(PATH)

source("lib-dendro.R")

SAVE <- T # to save output csv processed file at the end of the script

args <- commandArgs(trailingOnly = TRUE)
# print(args)

# SENSOR-SPECIFIC GLOBAL VARIABLES #
if (length(args) > 0 & !is.na(as.numeric(args[1]))){
  SELECTED_DENDROMETER = as.character(args[1])
  SAVE <- T # to save output csv processed file at the end of the script
} else {
  SELECTED_DENDROMETER = "92223484"
}

TOL_JUMP = 11
TOL_OUT = 11

# VARIABLES TO SET FOR EVERY SITE #
PLACE = 'PacoEzpela'

FILENAME_EXCESS = "_2024_02_01_0.csv"

# DATE_FORMAT = "%Y.%m.%d %H:%M" # Default
DATE_FORMAT = "%d.%m.%Y %H:%M:%S"

ts_start<-"2023-03-26 09:00:00" # from March 26 (2 days after installation)
ts_end<-"2024-01-30 23:45:00" # day before last data.

# OTHER DERIVED GLOBAL VARIABLES #

DATA_DIR = glue('raw/{PLACE}-dataD')
OUTPUT_DATA_DIR = glue('processed/{PLACE}-processed')
OUTPUT_ASSETS_DIR = 'output'

SELECTED_FILENAME = paste0('data_', SELECTED_DENDROMETER, FILENAME_EXCESS)
  
# Set initial and final date and sampling dates
# ts_start<-"2022-04-01 11:00:00" # After 2023 winter shrinking, so it gets more accurate values for TWD and growth.
# ts_start<-"2023-02-16 14:00:00" # no data until 16 feb 2023

print("process-dendro script running with the next parameters:")
cat(paste0("\t SELECTED DENDROMETER: ", SELECTED_DENDROMETER, "\n"))
cat(paste0("\t TOL_OUT: ", TOL_OUT, "\n"))
cat(paste0("\t TOL_JUMP: ", TOL_JUMP, "\n"))
cat(paste0("\t TS_START: ", ts_start, "\n"))
cat(paste0("\t TS_END: ", ts_end, "\n"))

#-----------------------------------------------#

### IMPORT DENDRO DATA ###

# importing dendro data #
db <- read.one.dendro(file.path(".",DATA_DIR,SELECTED_FILENAME), ts_start, ts_end,
                      date_format = DATE_FORMAT)

### CLEAN & PREPARE DATA ###

# Keep data of dates we're interested in (already done in read.one.dendro)
# db <- db[which(db$ts>=ts_start & db$ts<=ts_end),] 

# zeroing variations in diameter
# db$value<-db$um-db$um[1]

# Clean name of field series
db$series <- gsub(paste0("./", DATA_DIR, "/"),"",db$series) 
db$series <- gsub(FILENAME_EXCESS,"",db$series) # remove trailing filename _%date%_0.csv
db$series <- substr(db$series,6,nchar(db$series)) # remove initial "data_" in filename


# Add tree information to each dendrometer (series)
# TreeList<-read.table("TreeList.txt",header=T)
# db <- merge(db,TreeList[,c(1:4,6)],  by = "series")

# dim(db)

# This removes duplicates on timestamps (many of them due to daylight savingtime issues)
print("These are the duplicated data by timestamp:")
print(db[duplicated(db$ts),])
db = db[!duplicated(db$ts),];
# db = db[(!duplicated(db$ts)) | !dst(db$ts),];
# print(db[duplicated(db$ts),])

summary(db)

### PLOT RAW DATA ###

## TEMP DATA ##
plotTemp <- ggplot(data = db, mapping = aes(x=ts, y=temp, col=temp)) +
  scale_colour_gradient(low = "light blue", high = "red") +
  labs(x=expression('date'),
       y=expression("Temperature (ºC)")) +
  geom_line() +
  ggtitle(paste("Dendrometer temperature for sensor series: ",db$series[1], " - ", db$sp[1])) +
  scale_x_datetime(date_breaks = "1 month", date_labels = "%m-%y") +
  geom_hline(yintercept=0,lty=2,linewidth=0.2) +
  theme_bw()
plotTemp

## DENDRO DATA ##

#plot(value~ts,db,type="l",col="blue",axes=T)

dendro_raw_plot <-
  ggplot(data = db, mapping = aes(x=ts, y=value))+
  geom_line( )+
  ggtitle(paste0("Dendro data for sensor series: ",db$series[1], " - ", db$sp[1])) +
  labs(x=expression('Date'),
       y=expression(Delta*"D (um)"))+
  geom_hline(yintercept=0,lty=2,linewidth=0.2)+
  scale_x_datetime(date_breaks = "1 month", date_labels = "%m-%y") +
  theme_bw()
  
dendro_raw_plot

raw.output.fn <- file.path( OUTPUT_ASSETS_DIR, paste( db$series[1] ,"-",'raw data plot.png'))

if (!file.exists(raw.output.fn)) {ggsave( raw.output.fn, plot = dendro_raw_plot, 
                                          width = 15, height = 10)}

### PROCESS WITH TREENETPROC ###

# str(db)
# head(db)
# tail(db)

## TREENETPROC: Prepare data ##

# Subset the columns we want for treenetproc
db <- subset(db, select = c(ts, value, series, temp)) # -> Without TreeList.txt file
# db <- subset(db, select = c(ts, value, series, ID, site, sp, class, temp))

# define dendro_data_L0 to work with. Here we will use the "wide" format.
dendro_data_L0 = subset(db, select = c(series, ts, value))
temp_data_L0 = subset(db, select = c(series, ts, temp))

# If I don't to the below code some NAs get filled inside proc_L1 when it check_ts(), throwing an error and messin up the timestamp
dendro_data_L0$ts = strftime(db$ts, "%Y-%m-%d %H:%M:%S", tz = "Europe/Madrid" )
temp_data_L0$ts = strftime(db$ts, "%Y-%m-%d %H:%M:%S", tz = "Europe/Madrid" )

colnames(temp_data_L0)<-colnames(dendro_data_L0)

# str(dendro_data_L0)
# str(temp_data_L0)

## TREENETPROC: Time-alignment processing (L1) ##

# dendro data
dendro_data_L1 <- proc_L1(data_L0 = dendro_data_L0,
                          reso = 15,
                          date_format = "%Y-%m-%d %H:%M:%S",
                          input = "long",
                          year = "asis",
                          tz = "Europe/Madrid")
# head(dendro_data_L1)
# str(dendro_data_L1)


# temp data
temp_data_L1 <- proc_L1(data_L0 = temp_data_L0,
                        reso = 15,
                        date_format = "%Y-%m-%d %H:%M:%S",
                        input = "long",
                        year = "asis",
                        tz = "Europe/Madrid")
# head(temp_data_L1)
# str(temp_data_L1)

## TREENETPROC: Error detection and processing of the L1 data (L2) ##

dendro_data_L2 <- proc_dendro_L2(dendro_L1 = dendro_data_L1,
                                 temp_L1 = temp_data_L1,
                                 tol_out = TOL_OUT,
                                 tol_jump = TOL_JUMP,
                                 plot_period = "monthly",
                                 plot = T,
                                 plot_export = T,
                                 plot_name = file.path(OUTPUT_ASSETS_DIR, paste0( db$series[1] ,"-", db$sp[1],"-proc_L2_plot")),
                                 tz="Europe/Madrid")

#highlight corrections made on the dendrometer data:
# if ( length(which(is.na(dendro_data_L2$flags)==F) > 0)) {
View(dendro_data_L2[which(is.na(dendro_data_L2$flags)==F),])

# check the data
# head(dendro_data_L2)
# tail(dendro_data_L2)


# -> Open proc_L2_plot.pdf file to see results

final_processed_data <- dendro_data_L2;

# DANGER! Only use next line if you want to do MANUAL CORRECTIONS #
# final_processed_data <- corr_dendro_L2(dendro_L1 = dendro_data_L1,
#                                        dendro_L2 = dendro_data_L2,
#                                        # reverse = c(2),
#                                        # force = c("2023-07-06"),
#                                        force.now = c( "2023-11-02 06:30:00"),
#                                        # delete = c( "2023-07-06 19:00:00", "2023-07-06 19:00:00"),
#                                        plot = T,
#                                        plot_export = T,
#                                        plot_name = file.path(OUTPUT_ASSETS_DIR, paste0( "CORRECTED-", db$series[1] ,"-proc_L2_plot")),
#                                        tz="Europe/Madrid")


#highlight manual corrections made on the dendrometer data:
View(final_processed_data[which(is.na(final_processed_data$flags)==F),])

grow_seas(dendro_L2 = final_processed_data, agg_yearly=TRUE, tz="Europe/Madrid")

### SAVE PROCESSED DATA ###
if (SAVE) {
  OUTPUT_PATH = file.path(PATH, OUTPUT_DATA_DIR)
  if (!dir.exists(OUTPUT_PATH)) {dir.create(OUTPUT_PATH)}
  ### SAVE IN PROCESSED FORMAT ###
  output_data <- subset(final_processed_data, select = c(series, ts, value, max, twd, gro_yr))
  write_csv(output_data, file.path(OUTPUT_PATH, paste0("proc-", db$series[1], ".csv")), append = FALSE)
  # write_csv(output_data, file.path(OUTPUT_PATH, paste0("proc-", db$series[1], "-", db$class[1], ".csv")), append = FALSE)
}

### SAVE IN INPUT SENSOR FORMAT ###
## OVERWRITE INPUT DATA VALUES WITH PROCESSED VALUES ##
# db$value = final_processed_data$value
# write_csv(db, file.path(OUTPUT_PATH, paste0("proc-input-format-", db$series[1], ".csv")), append = FALSE)