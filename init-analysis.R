# IMPORT, GLOBAL VARS, LOAD DATA
  # Import local libraries:
source('lib-dendro.R')
source('lib-ts-analysis.R')
  # Import other libraries:
library(glue)
library(tidyverse)
library(ggplot2)
library(lubridate)
library(hms)

library(imputeTS)

### DEFINE GLOBAL VARS ###

# ts_start2022 <- "2022-04-01 09:00:00" # from first of May
# ts_end2022 <-"2022-10-30 23:45:00" # to 30 October
# 
# ts_start2023 <- "2023-04-01 09:00:00" # from first of May
# ts_end2023 <-"2023-10-30 23:45:00" # to 30 October

DATA_DIR = glue('processed/{PLACE}-processed')
ENV_DIR = glue('processed/{PLACE}-env-processed')

TreeList <- read.table("TreeList.txt", header=T)

ALL_PERIOD_ST <- "May to October"
SAVE <- F

#Select dendros for this analysis (all if empty vector)
# SELECTED_DENDROS <- case_when(  # exclude problematic dendrometers data
#   PLACE == 'Miedes' ~ c(), # c("92222154", "92222155", "92222156", "92222157", "92222161", "92222163", "92222164", "92222169", "92222170", "92222171", "92222173", "92222175", "92222180"),
#   PLACE == 'Corbalan' ~ c(), # We don't know the class of some missing
#   PLACE == 'Penaflor' ~ c(), #c("92222151", "92222152", "92222153", "92222158", "92222159", "92222160", "92222165", "92222166", "92222168", "92222172", "92222177", "92222179"),
#   .default = c()
# )

SELECTED_DENDROS <- c()

#Select TMS serial no for this analysis
SELECTED_TMS <- case_when(  # select one TMS sensor for this site which has all its data valid
  PLACE == 'Miedes' ~ "94231935",
  PLACE == 'Corbalan' ~ "94231943",
  PLACE == 'Penaflor' ~ "94231950",
  .default = NA
)

# Load dataset:
list_files <- list.files(file.path(".",DATA_DIR), pattern="*.csv$", full.names=TRUE)
db <- read.all.processed(list_files)

## CLEAN & PREPARE DATA ###

# keep data of selected dendros only
if (length(SELECTED_DENDROS) > 0) {db = db %>% filter(db$series %in% SELECTED_DENDROS)}
str(db)

Qi = TreeList %>% filter(class == "Quercus", series %in% unique(db$series)) %>% pull(series)
P_D = TreeList %>% filter(class == "D", series %in% unique(db$series)) %>% pull(series)
P_ND = TreeList %>% filter(class == "ND", series %in% unique(db$series)) %>% pull(series)

db <- db %>% mutate (
  class = case_when(
    series %in% Qi ~ factor("Quercus"),
    series %in% P_D ~ factor("D"),
    series %in% P_ND ~ factor("ND"),
    .default = NA
  )
) %>% mutate(date = date(ts), doy = yday(date), year = year(date))

### Data imputation ###
# Is there missing data?
print('Is there any dendrometer missing data?')
statsNA(db$value)

# Let's fill it through interpolation
db$value <- db$value %>% 
            na_interpolation(option = "spline") %>% 
            round()


### GGPLOT THEME CUSTOMIZATION ###S
# Set ggplot label options, themes & vars:
theme_set( theme_bw() +
          theme(
            axis.text=element_text(size=12),
            legend.text=element_text(size=10),
            axis.title=element_text(size=14),
            plot.title = element_text(hjust = 0.5, face = "bold")
          ))

every_hour_labels = format(lubridate::parse_date_time(hms(hours = 0:23), c('HMS', 'HM')), '%H:%M')
labels = c("Quercus", "Declining Pines", "Non-Declining Pines")

n.per.class <- db %>% group_by(class) %>% summarise (n = n_distinct(series)) %>% pivot_wider(names_from = class, values_from = n)

c_labels = c(Quercus = glue("{labels[1]} ({n.per.class$Quercus})"), D = glue("{labels[2]} ({n.per.class$D})"), ND = glue("{labels[3]} ({n.per.class$ND})"))
c_values = c(Quercus = "purple", D = "darkred", ND = "darkorange")

# # filter data to study period for two years of the analysis
# # Set initial and final date for analysis
# db2022 <- reset.initial.values(db, ts_start2022, ts_end2022)
# db2023 <- reset.initial.values(db, ts_start2023, ts_end2023)
# 
# # append the two previous dbs in one
# db <- rbind.data.frame(db2022, db2023)
# 
# ### Climate data ###

# Importing environmental data and keeping the one sensor with all valid data
if (exists('db.env')) {remove('db.env')}
db.env <- read.env.proc(file.path('.',ENV_DIR,'proc-env.csv'))
db.env <- db.env[db.env$series == SELECTED_TMS,]

# # Filter env data to period of study
# db.env2022 <- db.env[which(db.env$ts>=ts_start2022 & db.env$ts<=ts_end2022),]
# db.env2023 <- db.env[which(db.env$ts>=ts_start2023 & db.env$ts<=ts_end2023),]
# db.env <- rbind.data.frame(db.env2022, db.env2023)

print(summary(db.env))

print('Is there any TMS missing data?')
statsNA(db.env$vwc)

if (any(is.na(db.env$vwc))) {
  for (series_no in SELECTED_TMS) {
    db.env[db.env$series == series_no,] <- db.env[db.env$series == series_no,] %>%
      mutate_at(vars(air.temp, surface.temp, soil.temp, vwc), \(x) (na_interpolation(x, option = "spline")))
  }
}

# Calculations of useful aggregation data for climate:
# * soil moisture: max VWC, range VWC, mean of VWC (misleading)
# * temp: Mean of daily temp, minimum daily temp and maximum daily temp, range temp and interquartile temp (Q3-Q1). We will use soil temperature as it's used on many other studies and it isn't so much influenced by sun irradiation and night/day differences.
clim.daily <- db.env %>% 
  mutate (date = date(ts)) %>% 
  group_by(date) %>% 
  summarise(max.temp = max(surface.temp), min.temp = min(surface.temp),
            mean.temp = mean(surface.temp), sd.temp = sd(surface.temp),
            range.vwc = max(vwc) - min(vwc), max.vwc = max(vwc), mean.vwc = mean(vwc),
            range.temp = max.temp - min.temp, degree.hours.temp = sum(surface.temp),
            interquartil.temp = as.numeric(quantile(surface.temp, prob=c(.75)) - quantile(surface.temp, prob=c(.25)) ) ) %>% 
  mutate(doy = yday(date))

summary(clim.daily)
