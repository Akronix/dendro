source("lib-dendro.R")

library(readr) # for write_csv() function
library(plyr) # for empty()
library(tidyverse) # for %>%

library(myClim)

### DEFINE GLOBAL VARS ###
PATH = '/home/akronix/workspace/dendro';
setwd(PATH)

ts_start<-"2022-03-12 00:00:00" # from March 12 (2 days after installation)
ts_end<-"2023-09-13 09:00:00" # last timestamp of downloaded data

ENVIRONMENT_DIR = 'Prec'
OUTPUT_ENV_DIR = 'Prec-processed'

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

dfs <- data.frame()

for (filename in list_files) {
  
  # use myClim library for soil moisture conversion to volumetric water content (VWC)
  tms.f <- mc_read_files(filename, dataformat_name = "TOMST", silent = FALSE)
  tms.f
  
  tms.vwc <- mc_calc_vwc(tms.f, soiltype = "loamy sand B", output_sensor = "vwc")
  tms.vwc
  
  tms.df <- mc_reshape_wide(tms.vwc, sensors = c("vwc", "TMS_T3"))
  names(tms.df) <- c("ts", "temp", "vwc")
  
  if (empty(dfs)) {dfs = tms.df} else {dfs = rbind.data.frame(dfs, tms.df)}
  
  # write processed environmental data, one per sensor
  serial_no = (mc_info(tms.vwc)$serial_number)[1]
  write_csv(tms.df, file.path(OUTPUT_PATH, paste0("proc-", serial_no , "-tmt.csv")), append = F, col_names = T)
}

#dfs$serial_number <- as.factor(dfs$serial_number)
str(dfs)

db.env <- subset(dfs, select = c("ts", "temp", "vwc") )

# Do mean of all sensors
db.env <- dfs %>%
  filter(ts < ymd_hms("2022-12-31 00:00:00")) %>%
  group_by(ts) %>%
  summarise(temp = mean(temp, na.rm = TRUE), VWC = mean(vwc, na.rm = T))

summary(db.env)

# write aggregated data to file.
write_csv(db.env, file.path(OUTPUT_PATH, "proc-agg-temp&vwc.csv"), append = F, col_names = T)
