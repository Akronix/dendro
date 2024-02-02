source("lib-dendro.R")

library(readr) # for write_csv() function
library(plyr) # for empty()
library(tidyverse) # for %>%

library(myClim)

### DEFINE GLOBAL VARS ###
PATH = '/home/akronix/workspace/dendro';
setwd(PATH)

ts_start<-"2022-03-16 11:00:00" # # from March 16 (1 day after installation)
ts_end<-"2023-09-27 08:00:00" # last timestamp of downloaded data

ENVIRONMENT_DIR = 'raw/Corbalan-env'
OUTPUT_ENV_DIR = 'processed/Corbalan-env-processed'

SOIL_TYPE = "sandy loam B"

OUTPUT_PATH = file.path(PATH, OUTPUT_ENV_DIR)
if (!dir.exists(OUTPUT_PATH)) {dir.create(OUTPUT_PATH)}

# sensor.id = 94231938;
# sensor.fn = paste0("data_", sensor.id, "_2023_09_13_0.csv")
#filename = file.path(ENVIRONMENT_DIR, sensor.fn )


#env.db <- read.env.data(filename)

# filter dates
#env.db<-env.db[which(env.db$ts>=ts_start & env.db$ts<=ts_end),]
#env.db

list_files <- list.files(file.path(".",ENVIRONMENT_DIR), pattern="*.csv$", full.names=TRUE)

print(list_files)

dfs.all <- data.frame()

for (filename in list_files) {
  
  # use myClim library for soil moisture conversion to volumetric water content (VWC)
  tms.f <- mc_read_files(filename, dataformat_name = "TOMST", silent = FALSE)
  tms.f
  
  tms.vwc <- mc_calc_vwc(tms.f, soiltype = SOIL_TYPE, output_sensor = "vwc")
  tms.vwc
  
  tms.df <- mc_reshape_wide(tms.vwc, sensors = c("vwc", "TMS_T2"))
  names(tms.df) <- c("ts", "temp", "vwc")
  
  if (empty(dfs.all)) {dfs.all = tms.df} else {dfs.all = rbind.data.frame(dfs.all, tms.df)}
  
  # write processed environmental data, one per sensor
  serial_no = (mc_info(tms.vwc)$serial_number)[1]
  tms.df$series = serial_no # here we manually add a series column
  write_csv(tms.df, file.path(OUTPUT_PATH, paste0("proc-", serial_no , "-tms.csv")), append = F, col_names = T)
}

str(dfs.all)

db.env <- subset(dfs.all, select = c("ts", "temp", "vwc") )

# Do mean of all sensors
db.env <- dfs.all %>%
  #filter(ts < ymd_hms("2022-12-31 00:00:00")) %>%
  group_by(ts) %>%
  dplyr::summarise(temp = mean(temp, na.rm = TRUE), VWC = mean(vwc, na.rm = T))

summary(db.env)

# write aggregated data to file.
if (!dir.exists(file.path(OUTPUT_PATH, 'aggregated'))) {dir.create(file.path(OUTPUT_PATH, 'aggregated'))}
write_csv(db.env, file.path(OUTPUT_PATH, 'aggregated', "proc-agg-temp&vwc.csv"), append = F, col_names = T)
