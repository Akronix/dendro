library('tidyverse')
library('glue')

## Global variables ##
db.all.sites <- data.frame()
OUTPUT_PATH = './cooked-data'
if (!dir.exists(OUTPUT_PATH)) {dir.create(OUTPUT_PATH)}

## Load every site's dataset

for (PLACE in c('Penaflor', 'Miedes', 'Corbalan')) {
  source('init-analysis.R') # load dendrometers data from 'PLACE' into db variable and climate data in clim.daily and db.env
  db$site <- PLACE
  
  seasonalities <- calculate_stl_seasonalities(db, unique(db$series)) %>%
                  select(value, series, ts) %>% 
                  rename(seasonality = value)
  print(summary(seasonalities))
  
  db.all <- left_join(db, seasonalities, by=c("ts", "series"))
  db.all <- left_join(db.all, subset(db.env, select=-series), by=c("ts"))
  
  summary(db.all)
  
  write_csv(db.all, file.path(OUTPUT_PATH, glue('seasonality-clim-proc-{PLACE}.csv')), append = F, col_names = T)
  
  db.all.sites <- rbind.data.frame(db.all.sites, db.all)
}

write_csv(db.all.sites, file.path(OUTPUT_PATH, 'seasonality-clim-proc-allsites.csv'), append = F, col_names = T)
