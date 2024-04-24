source('lib-dendro.R')

library('glue')
library('tidyverse')
library(ggplot2)
library(treenetproc)

## Global variables ##
PLACE = 'Miedes'
DATA_DIR = glue('processed/{PLACE}-processed')
ENV_DIR = glue('processed/{PLACE}-env-processed')

OUTPUT_PATH = './output-data'
if (!dir.exists(OUTPUT_PATH)) {dir.create(OUTPUT_PATH)}

# excluding problematic dendros: 92222162
# SELECTED_DENDROS <- c("92222154", "92222155", "92222156", "92222157", "92222161", "92222163", "92222164", "92222169", "92222170", "92222171", "92222173", "92222175", "92222180")

## Load & calculate grow season of selected datasets ##
list_files <- list.files(file.path(".",DATA_DIR), pattern="*.csv$", full.names=TRUE)
db<-read.all.processed(list_files)

# db %>% db %>% filter(series %in% SELECTED_DENDROS)

grow_seasons <- grow_seas(dendro_L2 = db, agg_yearly=TRUE, tol_seas = 0.15, tz = 'Madrid/Spain')

grow_seasons

summary(grow_seasons)
