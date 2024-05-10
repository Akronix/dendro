library('tidyverse')
library('glue')

## Global variables ##
ampl.db.all <- data.frame()
OUTPUT_PATH = './cooked-data'
if (!dir.exists(OUTPUT_PATH)) {dir.create(OUTPUT_PATH)}

## Load every site's dataset

for (PLACE in c('Penaflor', 'Miedes', 'Corbalan')) {
  source('init-analysis.R') # load dendrometers data from 'PLACE' into db variable and climate data in clim.daily and db.env
  db$site <- PLACE
  
  ampl.db <- calculate_amplitudes_df(db)
  ampl.db <- ampl.db %>% mutate(doy = yday(date))
  ampl.db <- left_join(ampl.db, clim.daily, by=c("doy", "date"))
  
  write_csv(ampl.db, file.path(OUTPUT_PATH, glue('amplitudeAndClimate-{PLACE}.csv')), append = F, col_names = T)
  
  ampl.db.all <- rbind.data.frame(ampl.db.all, ampl.db)
}

# db.phase_stats <- phase_stats(dendro_L2 = db, plot_phase = F, plot_export = F, tz = 'Europe/Madrid')

write_csv(ampl.db.all, file.path(OUTPUT_PATH, 'amplitudeAndClimate-allsites.csv'), append = FALSE, col_names = T)
