source('lib-dendro.R')

library('glue')
library('tidyverse')
library(ggplot2)
library(treenetproc)

## Global variables ##
PLACE = 'Corbalan'
DATA_DIR = glue('processed/{PLACE}-processed')
ENV_DIR = glue('processed/{PLACE}-env-processed')

OUTPUT_PATH = './output-data'
if (!dir.exists(OUTPUT_PATH)) {dir.create(OUTPUT_PATH)}

# excluding problematic dendros for Miedes: 92222162
# excluding problematic dendros for Peñaflor: 92222178
# exclude problematic dendrometers data
SELECTED_DENDROS = if (PLACE == 'Miedes') {
  c("92222154", "92222155", "92222156", "92222157", "92222161", "92222163", "92222164", "92222169", "92222170", "92222171", "92222173", "92222175", "92222180")
} else if (PLACE == 'Corbalan') {
  c() # We don't know the class of some missing
} else if (PLACE == 'Penaflor') {
  c("92222151", "92222152", "92222153", "92222158", "92222159", "92222160", "92222165", "92222166", "92222168", "92222172", "92222177", "92222179")
} else
  SELECTED_DENDROS <- c()
  

## Load & calculate grow season of selected datasets ##
list_files <- list.files(file.path(".",DATA_DIR), pattern="*.csv$", full.names=TRUE)
db <- read.all.processed(list_files)

if (length(SELECTED_DENDROS) > 0) {db = db %>% filter(db$series %in% SELECTED_DENDROS)}

grow_seasons <- grow_seas(dendro_L2 = db, agg_yearly=TRUE, tol_seas = 0.05, tz = 'Madrid/Spain')

print(grow_seasons)

summary(grow_seasons)

write_csv(grow_seasons, file.path(OUTPUT_PATH, glue('growing_seasons-{PLACE}.csv')), append = F, col_names = T)
