# PROJECT FILES

## INTERNAL LIBRARIES

- `lib-dendro.R`
  * functions related to read, transform and visualize dendro data, either raw or processed.
  
- `lib-ts-analysis.R`
  * all common functions related to decomposing time-series and plotting them.

## PROCESSING DATA

- `process-dendro.R`

- `process-env.R`

- `clear-invalid-env-{PLACE}.R`

- `extract-ts-decomp-and-clim.R`

- `init-analysis.R`
  * load dendro & clim data for variable defined in PLACE, impute missing data, calculate clim daily, set several global vars, set custom theme for ggplot
  * input -> global variable PLACE defined with the place of study
  * output <- db variable with dendro data, db.env with climate data, and clim.daily with aggregated per day data


## GENERATING COOKED AND ENRICHED DATA

### general
- `calc_growing_season.R`
  * calculate growing season for each site.
  * input <- processed dendro data
  * filter <-> selected dendrometres series no.
  * output -> output-data: growing season for each dendrometer and aggregated statistics.
- `generate_data+clim.R`
  * join db data with db.env data in one df for all sites, and save it in csv file:
  * input <- processed dendro & TMS data for all sites
  * output -> output-data: `proc_dendro_clim-allsites.csv`

### shrink-swelling of the stem:
- `generate_data+clim+seasonality.R`
  * extract seasonality by using stl for each 15' and append it to the dataframe of dendro and climate data. Save the output as cooked-data.
  * output -> cooked-data: 
- `generate_full_amplitude.R`
  * generate cooked data of full amplitude (shrink-swell + growth) plus climate data.
  * input <- processed dendro & TMS data
  * output -> cooked data: dataframe with amplitude and climate data by sensor id and date.
- `generate_amplitude_data_stl.R`
  * Similar to the previous one calculated amplitude but using only the seasonality extracted from stl (only shrink-swell)
- `generate_phase_stats.R`
  * Calculate shrink-swell exact phases using treenetproc and save the output in output-data
  * output -> output-data:

### Short-term reaction to prec
- `calc_prec_reaction.R`
  * Calculate moment of prec events, reaction times to them and variables.
  * input <- processed dendro & TMS data
  * output <- cooked-data: two dataframes df, one with dates of each VWC increament (prec event); and another one of reaction variables for each tree.

## VISUALIZATION

- `plotClimate.Rmd`
  * plot microclimate data of surface temperature and soil moisture for one sensor of the site which has all data available (no missing data).

- `plot-proc-dendro.Rmd`
  * Several plots of the processed dendro data: each dendrometer, each dendrometer standarized from 0 to 1, dendrometers by class, and all microclimate data
  * input <- processed dendro and TMS data. optionally filter by dates.
  * output -> plots

- `plot-individuals-dendro.Rmd`
  * creates a pdf with one dendro data per page
  * input <- processed dendro data, TreeList
  * output -> pdf with one plot per page of processed dendro data
  
- `plot-growth.Rmd`
  * plot graphs of Growing rate, accumualted growth and TWD along with climate.
  * input <- processed dendro and TMS data.
  * output -> plots: TWD boxplot, TWD evolution, accumulated growth evolution, gr per day

## ANALYSIS

- `analysis-growth.Rmd`

- `Seasonality-aggregated.Rmd`
  * plots and correlation analysis of the seasonality aggregated of dendrometer per class, for each site.
  * input <- processed dendro and TMS data, TreeList
  * filter <-> selected sensors, dates of study
  * calculations / processing -- extract seasonality from time-series, aggregate by class.
  * output -> plots of aggregated seasonalities, cross-correlation with climate data.
  
- `analysis-correlations-amplitude.Rmd`
  * Analyse amplitude correlations and ANOVA.
  
- `probing-models-amplitude.Rmd`
  * Test different models and libraries to test which one works better. We finally decided to go with nlme package and lme() function within that package.
  
- `models-amplitude-{PLACE}.Rmd`
  * model using lme from nlme the amplitudes separating by classes, species and adding climate variables for every different site, and looking for the most parsimounious model by evaluation the different combinations of the explicative variables.
  
## OTHERS
- `launch-datacleanr.R`
  * very simple scipt to launch datacleanr to help on locating and inspecting artifacts when processing dendro data.