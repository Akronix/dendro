source('lib-dendro.R')

library(tidyverse)
library(imputeTS)

selected_dendros <- c("92222156")
DATA_DIR <- 'processed/Miedes-last'
fn <- 'proc-M_Pp410-92222156.csv'

db <- read.one.processed(file.path(DATA_DIR, fn)) 

# Set initial and final date for analysis
ts_start <- "2022-03-14 09:00:00" # skip first 2 days for calibration
ts_end <- db$ts[length(db$ts)] # to the end
db <- reset.initial.values(db, ts_start, ts_end)

statsNA(db$value)

db$value <- db$value %>% 
  na_interpolation(option = "spline")


dat = db %>% select(ts, value)
dat.ts <- ts(data = dat$value, frequency = 96)

stl.out = stl(dat.ts, s.window = 25, t.window = 673)
plot(stl.out)

df <- data.frame(db$ts, stl.out$time.series) %>% rename(ts = db.ts)

write_csv(df, paste0(paste('ts_decomposed', selected_dendros[1], sep='_'), '.csv'))

