source("lib-dendro.R")

library(readr) # for write_csv() function
library(plyr) # for empty()
library(tidyverse) # for %>%
library(glue)

library(myClim)

### DEFINE GLOBAL VARS ###
PATH = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(PATH)

# ts_start<-"2022-03-16 11:00:00" # # from March 16 (1 day after installation)
# ts_end<-"2023-09-27 08:00:00" # last timestamp of downloaded data

PLACE = 'Miedes'
ENVIRONMENT_DIR = glue('raw/{PLACE}-env')
OUTPUT_ENV_DIR = glue('processed/{PLACE}-env-buffer-toclear')

SOIL_TYPE = "sandy loam A"

OUTPUT_PATH = file.path(PATH, OUTPUT_ENV_DIR)
if (!dir.exists(OUTPUT_PATH)) {dir.create(OUTPUT_PATH)}

# sensor.id = 94231938;
# sensor.fn = paste0("data_", sensor.id, "_2023_09_13_0.csv")
#filename = file.path(ENVIRONMENT_DIR, sensor.fn )


#env.db <- read.env.data(filename)

# filter dates
# env.db<-env.db[which(env.db$ts>=ts_start & env.db$ts<=ts_end),]
# env.db

list_files <- list.files(file.path(".",ENVIRONMENT_DIR), pattern="*.csv$", full.names=TRUE)

print(list_files)

dfs.all <- data.frame()

for (filename in list_files) {
  
  # use myClim library for soil moisture conversion to volumetric water content (VWC)
  tms.f <- mc_read_files(filename, dataformat_name = "TOMST", silent = FALSE,
                         date_format = c("%d.%m.%Y %H:%M:%S", "%Y.%m.%d %H:%M", "%Y.%m.%d %H:%M:%S"))
  tms.f
  
  sernum <- mc_info(tms.f)$serial_number[1]
  
  # calibrate moisture sensor
  # raw_air   <- 406   # signal in air, on average 406 (257 to 667) at average temperature of 23°C. 
  # raw_water <- 3698 # signal in water, 3698 (min 3582, max 3835) with average temperature of the bath 22°C. 
  # t_air     <- 23
  # t_water   <- 22
  raw_air   <- 50   #signal in air, typically around 350
  raw_water <- 3635 #signal in air, typically around 3700
  t_air     <- 20
  t_water   <- 20
  mc_info(tms.f)
  
  #calc sensor-specific calibration parameters
  cal.param <- mc_calib_moisture(raw_air = raw_air, 
                                 raw_water = raw_water, 
                                 t_air = t_air,
                                 t_water = t_water)
  
  #store params in table
  cal.tb <- data.frame(serial_number = sernum,
                       datetime = as.POSIXct("2020-01-01"),
                       sensor_id = "TMS_moist",
                       cal.param)
  
  #load calibration into myClim object
  tms.cal <- mc_prep_calib_load(tms.f, cal.tb)
  tms.cal$localities[[1]]$loggers[[1]]$sensors$TMS_moist$calibration
  
  # get vwc (calibrated)
  tms.vwc <- mc_calc_vwc(tms.cal, soiltype = SOIL_TYPE, output_sensor = "vwc")
  tms.vwc
  
  tms.df <- mc_reshape_wide(tms.vwc, sensors = c("vwc", "TMS_T1", "TMS_T2", "TMS_T3"))
  names(tms.df) <- c("ts", "soil.temp", "surface.temp", "air.temp", "vwc")
  
  if (empty(dfs.all)) {dfs.all = tms.df} else {dfs.all = rbind.data.frame(dfs.all, tms.df)}
  
  # write processed environmental data, one per sensor
  serial_no = (mc_info(tms.vwc)$serial_number)[1]
  tms.df$series = serial_no # here we manually add a series column
  write_csv(tms.df, file.path(OUTPUT_PATH, paste0("proc-", serial_no , "-tms2.csv")), append = F, col_names = T)
}

str(dfs.all)

