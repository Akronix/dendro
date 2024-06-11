source('lib-dendro.R')
source('lib-ts-analysis.R')

library('glue')
library('tidyverse')
library(imputeTS)
library(ggplot2)

## Global variables ##
PLACE = 'Miedes'
DATA_DIR = glue('processed/{PLACE}-processed/old')
RAW_DIR = glue('raw/Miedes-dataD.old')
ENV_DIR = glue('processed/{PLACE}-env-processed')

OUTPUT_PATH = './cooked-data'
if (!dir.exists(OUTPUT_PATH)) {dir.create(OUTPUT_PATH)}

SELECTED_TMS <- case_when(  # select one TMS sensor for this site which has all its data valid
  PLACE == 'Miedes' ~ "94231935",
  PLACE == 'Corbalan' ~ "94231943",
  PLACE == 'Penaflor' ~ "94231934",
  .default = NA
)

# excluding problematic dendros: 92222175 (too many missing values)
selected_dendros <- c("92222156", "92222169", "92222157", "92222154", "92222170", "92222173", "92222180", "92222155", "92222163", "92222171", "92222161", "92222164")  

## Load datasets ##
list_files <- list.files(file.path(".",DATA_DIR), pattern="*.csv$", full.names=TRUE)
db<-read.all.processed(list_files)

db.env <- read.env.proc(file.path(".",ENV_DIR,'proc-env.csv'))
db.env <- db.env[db.env$series == SELECTED_TMS,]

TreeList <- read.table("TreeList.txt", header=T)


## Prepare and filter data ##

# Set initial and final date for analysis
# ts_start <- "2022-03-14 09:00:00" # skip first 2 days for calibration
# ts_end <- db$ts[length(db$ts)] # to the end
# db <- reset.initial.values(db, ts_start, ts_end)

db = db %>% filter(db$series %in% selected_dendros)

# interpolate missing data
statsNA(db$value)

db$value <- db$value %>% na_interpolation(option = "spline")

statsNA(db.env$vwc)

db.env <- db.env %>% mutate_at(vars(air.temp, surface.temp, soil.temp, vwc), \(x) (na_interpolation(x, option = "spline")))

# Add class column
Qi = TreeList %>% filter(class == "Quercus", series %in% unique(db$series)) %>% pull(series)
P_D = TreeList %>% filter(class == "D", series %in% unique(db$series)) %>% pull(series)
P_ND = TreeList %>% filter(class == "ND", series %in% unique(db$series)) %>% pull(series)

summary(db)
summary(db.env)


## Decompose time-series ##

decomposed.db <- decompose_ts_stl(db, selected_dendros)

decomposed.db <- decomposed.db %>% mutate (
  class = case_when(
    series %in% Qi ~ factor("Quercus"),
    series %in% P_D ~ factor("D"),
    series %in% P_ND ~ factor("ND"),
    .default = NA
  )
)

summary(decomposed.db)

## Now let's append environmental data
db.env.selected <- db.env %>% select(ts, vwc, surface.temp)
db.joined <- left_join(decomposed.db, db.env.selected, by = join_by(ts))
## Now let's append processed dendro data
db.joined.all <- left_join(db.joined, db, by = join_by(ts, series))
summary(db.joined.all)

# PLot trend results
ggplot(data = db.joined, aes(x = ts, y = trend, col = series)) + geom_line()


# RAW DATA #
## Finally, let's append raw dendro data

# original raw data
list_files_raw <- list.files(file.path(".",RAW_DIR), pattern="*.csv$", full.names=TRUE)
db.raw <- read.all.dendro(list_files_raw, ts_start = "2022-03-12 00:00:00", ts_end = "2023-09-13 08:00:00", date_format = "%Y.%m.%d %H:%M")

FILENAME_EXCESS = "_2023_09_13_0.csv"

# Clean name of field series
db.raw$series <- gsub(paste0("./", RAW_DIR, "/"),"",db.raw$series) 
db.raw$series <- gsub(FILENAME_EXCESS,"",db.raw$series) # remove trailing filename _%date%_0.csv
db.raw$series <- substr(db.raw$series,6,nchar(db.raw$series)) # remove initial "data_" in filename

db.raw$series <- as.factor(db.raw$series)

# keep only selected dendros
db.raw = db.raw %>% filter(db.raw$series %in% selected_dendros)

# This removes duplicates on timestamps (many of them due to daylight savingtime issues)
#print("These are the duplicated data by timestamp:")
# db.raw %>% group_by(series) %>% mutate(duplicated = lag(ts, n = 4)) filter (duplicated(ts)) # <- something equivalent to this

db.raw <- db.raw %>% 
  mutate(idx = row_number()) %>% 
  group_by(series) %>% 
  arrange(ts) %>% 
  mutate(lag_ts = lag(ts)) %>% 
  ungroup() %>% 
  mutate(keep = ifelse(ts == lag_ts, 0, 1)) %>% 
  arrange(idx) %>% filter (keep == 1)

db.raw <- db.raw %>% select(ts, value, series) %>% rename (raw.value = value)

# count = 0
# for (dendro.no in unique(db.raw$series)) {
#   db.series <- db.raw[db.raw$series == dendro.no,]
#   count <- count + sum(duplicated(db.series$ts), na.rm = T)
# }

summary(db.raw)

db.joined.all <- left_join(db.joined.all, db.raw, by = join_by(ts, series))
summary(db.joined.all)

write_csv(db.joined.all, file.path(OUTPUT_PATH, glue('time-series-decomp-and-climate-{PLACE}.csv')), append = F, col_names = T)
