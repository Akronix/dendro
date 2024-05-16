library('tidyverse')
library('glue')

## Global variables ##
db.all.sites <- data.frame()
OUTPUT_PATH = './output-data'
if (!dir.exists(OUTPUT_PATH)) {dir.create(OUTPUT_PATH)}

## Load every site's dataset

for (PLACE in c('Penaflor', 'Miedes', 'Corbalan')) {
  source('init-analysis.R') # load dendrometers data from 'PLACE' into db variable and climate data in clim.daily and db.env
  db$site <- PLACE
  
  db.all <- left_join(db, subset(db.env, select=-series), by=c("ts"))
  
  db.all.sites <- rbind.data.frame(db.all.sites, db.all)
}

write_csv(db.all.sites, file.path(OUTPUT_PATH, 'proc_dendro_clim-allsites.csv'), append = F, col_names = T)
