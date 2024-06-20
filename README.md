This is a repo for processsing and analysis data from TOMST dendrometers.

# DATA MINING WORKFLOW

We can define two main stages for the data mining process involved to analyse this data. The first one is mainly related to the processing and cleanind of the data, and the second one corresponds to the data transformation, visualization in plots and analysis of the data.

## First Stage: Data cleaning

The first stage is illustrated in the image below:
<img alt="data mining schema part1" src="https://github.com/Akronix/dendro/blob/main/assets/processing%20data%20schema%20-%20part1.png?raw=true" width=700px />

In this stage we load the raw data from the sensors: dendrometers (`dataD`) and TMS microclimate loggers (`envData`).

We use the R script `process-dendro.R` to load the raw data of a dendrometer from a csv file, using for that the utilities of the local library `lib-dendro.R`, and then we use the `treenetproc` library to correct the artifacts. Note that sometimes we won't be sure if there's an actual artifact in the recorded data, to inspect the data more carefully, we can use the external library `datacleanr`, which interactively provides ways to visualize the data. The final processed data should be saved in a csv file inside the `processsed` folder. As a good practice, a short summary and manual notes should be written in the `processed.txt` log file, in particular, the chosen params to the `treenetproc` function calls, in order to keep record of the changes made and be able to reproduce the processing. The output csv files are stored in the `{PLACE}-processed` directories.

We use the R script `process-env.R` to load the raw data of a TMS from a csv file, that script loads the raw data and use the myClim library to callibrate the input data with the pertinent soil type and to transform the soil moisture into volumetric water content. To select the right soil type, we can choose the one that better adjust to our measured levels concentrations of silt, clay and sand from [this table](https://github.com/ibot-geoecology/myClim/blob/a06730359da80cd962f3709097f619236fcd5d29/data-raw/mc_data_vwc_parameters.R)

The recorded microclimate data is stored in a buffer folder (`env-buffer-toclear`), that data still needs to be visually inspected in order to detect when the sensor has been moved out from the ground (presumably, by a wild animal), so that data might be incorrect since them. To aim the detection of those events, we use the notebook `clear-invalid-env.Rmd`; there we graphically plot every sensors, and we inspect when the humidity (VWC) of a sensor drastically change to 0 in a sensor which likely corresponds with that movementand all data from that sensor is invalid until is restored to a normal VWC value. We annotate the timestamps for those events in the `env-processing.txt` log file and we filter the invalid periods in the same `clear-invalid-env.Rmd` notebook. The output csv files correspond to the valid microclimate data and is stored in the `{PLACE}-env-processed` directories.

## Second Stage: Data analysis

The second stage corresponds to the data transformation, visualization, analysis and modelization; and it uses the output from the previous stage to start with processed data. Below there is a simplified schema of the processes conforming this second stage:

<img alt="data mining schema part2" src="https://github.com/Akronix/dendro/blob/main/assets/processing%20data%20schema%20-%20part2.png?raw=true" width=700px />

From the processed data, we can already visualize the processed data like the dendrometers data (`plot-proc-dendro.Rmd` and `plot-individuals-dendro.Rmd`), some variables of growth (`plot-growth.Rmd`) or the climate data (`plotClimate.Rmd`).

But, more interestingly, we will want to do some analysis and modelization of the data. For that, we found convenient to transform the data for later use. There are several scripts to do different transformations, and the output folder changes depending on:

* if they just group the data to ease the later loading or do a simple calculation (output-data). For instance, `generate_data+clim.R` joins all the sites data in one csv file and appends the climate data, `calc_growing_season.R` calculates the growing season for each dendrometer.
* if they do further calculations and transformations, so the ouput data has a different shape (cooked-data). For instance, `generate_data+clim+seasonality.R` and `generate_full_amplitude.R` calculates seasonality variables from the processed data.

Finally, we can use that transformed data to do statistical analysis (see for example, `analysis-correlations-amplitude.Rmd`) or statistical models (`models-amplitude-{PLACE}.Rmd`). It can be interesting to plot the transformed data for better inspection and visualization, see for instance `plot-Seasonality-aggregated.Rmd`.

# PROJECT FILES

## INTERNAL LIBRARIES

- `lib-dendro.R`
  * functions related to read, transform and visualize dendro data, either raw or processed.
  
- `lib-ts-analysis.R`
  * all common functions related to decomposing time-series and plotting them.

## PROCESSING DATA

- `process-dendro.R`
  * Process the dendrometer raw data and clean it from artifacts.

- `process-env.R`
  * Process the microclimate TMS raw data. Callibrate the source data, extracts the different temperature data and convert the soil moisture values (sensor subjective value) to Volumetric Water Content (%)

- `clear-invalid-env-{PLACE}.Rmd`
  * This notebook helps to graphically detect when the TMS sensor data might be invalidated due to a displacement from the ground to the surface by a wild animal. In this case, we should annotate the timestamp of the event and filter out all the data until the sensor is placed back correctly and the data can be considered valid again.

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
  * output -> output-data: `proc_dendro_clim-allsites.csv` and `clim-allsites.csv`

### Timeseries decomposition:
- `extract-ts-decomp-and-clim.R`
  * A script to decomposite the time series of the processed dendro data in seasonality, trend and remainder.
  * output -> cooked-data:
  
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
  
- `plot-Seasonality-aggregated.Rmd`
  * plot seasonalities for every class / group of different periods plus temperature.
  * input <- processed seasonalities and TMS data
  * output -> plots: seasonalities of the different classes + temperature for the different seasons / periods in one plot.

## ANALYSIS

- `analysis-correlations-amplitude.Rmd`
  * Analyse amplitude correlations and ANOVA.

- `analysis-gr_vs_climate.Rmd`
  * Analysis growth vs climate.

- `Seasonality-aggregated.Rmd`
  * plots and correlation analysis of the seasonality aggregated of dendrometer per class, for each site.
  * input <- processed dendro and TMS data, TreeList
  * filter <-> selected sensors, dates of study
  * calculations / processing -- extract seasonality from time-series, aggregate by class.
  * output -> plots of aggregated seasonalities, cross-correlation with climate data.
  
- `probing-models-amplitude.Rmd`
  * Test different models and libraries to test which one works better. We finally decided to go with nlme package and lme() function within that package.
  
- `models-amplitude-{PLACE}.Rmd`
  * model using lme from nlme the amplitudes separating by classes, species and adding climate variables for every different site, and looking for the most parsimounious model by evaluation the different combinations of the explicative variables.
  
## OTHERS
- `launch-datacleanr.R`
  * very simple scipt to launch datacleanr to help on locating and inspecting artifacts when processing dendro data.
