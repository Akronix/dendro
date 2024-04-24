library(anomalize) # time series decomposition
library(stats) # stl Decomposition
library(ggpubr) # ggarange
library(zoo) # print dates in x-axis for ts objects
library(tidyverse)

source('correlations.R')

# DEFINE COMMON COLORS
temperature.color <- "darkorange"
season.color <- "darkgreen"

c_labels = c("Quercus", "Declining Pines", "Non-Declining Pines")
c_class_values = c(Quercus = "purple", D = "darkred", ND = "darkorange")

# Decompose functions
##  Define plot_decompose function which uses basic time series decomposition
plot_decompose <- function (db, name) {
  # decompose a time series (has to be in tibble format)
  decompose = time_decompose(
    # choose dataframe containing the data and convert it to tibble
    as.tibble(db,
              #what to do with na in the dataframe
               na.action = na.pass),
    # select varaible to decompose
    value)
  
  # plot time series
  p_ts = ggplot (decompose, aes(x = ts, y = observed)) +
    ggtitle(glue("Time series decomposition for {name}")) +
    geom_line (col = "black") +
    scale_x_datetime(date_breaks = "1 month", date_labels="%b %Y") +
    theme_classic() +
    labs ( x = NULL,
             y = "Original data (um)")
  
  # plot trend
  p_trend = ggplot (decompose, aes(x = ts, y = trend)) +
    geom_line (col = "#D55E00") + 
    scale_x_datetime(date_breaks = "1 month", date_labels="%b %Y") +
    geom_hline(yintercept = 0, linetype='dotted', col = 'red') +
    theme_classic() +
    labs ( x = NULL,
             y = "Trend")
  
  # plot season
  p_season = ggplot (decompose, aes(x = ts, y = season)) +
    geom_line (col = "#E69F00") +
    scale_x_datetime(date_breaks = "1 month", date_labels="%b %Y") +
    theme_classic() +
    labs ( x = NULL,
             y = "Season")
  
  # plot remainder
  p_remainder = ggplot (decompose, aes(x = ts, y = remainder)) +
    geom_line (col = "#F0E442") +
    scale_x_datetime(date_breaks = "1 month", date_labels="%b %Y") +
    theme_classic() +
    labs ( x = "Period (month)",
             y = "Remainder")
  
  # plot all together
  ggarrange (p_ts, p_trend, p_season, p_remainder, ncol = 1)
}

## Save the plot of decompose_ts
save_plot_decompose <- function (dat, name) {
  plot_decompose(dat, name) %>% ggexport(filename = glue('output/{name}-decomp-anomalize.png'),  width = 4500, height = 3000, res = 300)
}

## Plot seasonality but printing the dates in the x-axis
plot_seasonality <- function(stl.out, name) {
  
  seasonality <- stl.out$time.series[,1]
  timestamps <- seq(from = as.POSIXct(ts_start, tz='Madrid/Spain'), by = "15 min", length.out = length(dat.ts))
  zoo_data <- zoo(seasonality, order.by = timestamps)
  plot(zoo_data, xaxt = "n", type = "l", xlab = "", ylab = "Value", main = glue("Time Series by Month-Year for {name}"))
  axis(1, at = time(zoo_data), labels = format(time(zoo_data), "%Y-%m"))
  
  # Add x-axis label
  mtext("Month-Year", side = 1, line = 3)
}

save_plot_seasonality_stl <- function(stl.out, name) {
  png(glue('output/{name}-seasonality-stl.png'), width=15, height=10, units="in", res=300)
  plot_seasonality(stl.out, name)
  dev.off()
}


## Define amplitude-related functions
calculate_amplitude <- function(dat) {
  dat %>% mutate(date = date(ts)) %>% group_by(date) %>% summarize(max = max(value), min = min(value)) %>% mutate(ampl = max-min)
}

save_plot_amplitude <- function(dat.ampl, name) {
  ggplot(data = dat.ampl, mapping = aes(x = date, y = ampl)) + geom_line()
  ggsave(glue('output/{name}-amplitude.png'), width = 15, height = 10)
}

## Define stl-related functions
plot_stl <- function (stl.out) {
  summary(stl.out)
  plot(stl.out)
}

save_plot_stl <- function (stl.out, name) {
  png(glue('output/{name}-stl.png'), width=15, height=10, units="in", res=300)
  plot_stl(stl.out)
  dev.off()
}

## Calculate stl seasonality for all dendros in db which belongs to dendro.series set
calculate_stl_seasonalities <- function (db, dendro.series) {
  seasonalities <- data.frame()

  for (dendro.no in dendro.series) {
    # Filter data by that no
    dat = db[db$series == dendro.no,]
    dat = dat %>% select(ts, value)
    dat.ts <- ts(data = dat$value, frequency = 96)
    
    stl.out = stl(dat.ts, s.window = 25, t.window = 673)

    seasonality <- stl.out$time.series[,1]
    
    aux <- data.frame(
      value = as.numeric(seasonality),
      series = as.factor(dendro.no),
      ts = dat$ts
    )

    seasonalities <- rbind.data.frame(seasonalities, aux)
  }
  
  return(seasonalities)
  
}

decompose_ts_stl <- function(db, dendro.series) {
  
  if (any(is.na(db$value))) { return ("Couldn't be calculated due to NA values")}
  
  all.ts.decomposed <- data.frame()
  
  for (dendro.no in dendro.series) {
    # Filter data by that no
    dat = db[db$series == dendro.no,] %>% select(ts, value)
    
    dat.ts <- ts(data = dat$value, frequency = 96) # natural time period <- day, data sampled every quarter <- 4*24 = 96 samples per day
    
    stl.out = stl(dat.ts, s.window = 97, t.window = 673)
    # ^ About the given paramenters:
    # s.window <- 97 is like a day of data (it has to be odd), but the value 25 was working as well (6h and a quarter)
    # t.window <- 97 is like a week of data (it has to be odd), it showed smooth values of trend
    
    
    # plot(stl.out)
    # title(dendro.no)
    
    aux <- data.frame(
      series = as.factor(dendro.no),
      ts = dat$ts,
      stl.out$time.series
    )
    
    all.ts.decomposed <- rbind.data.frame(all.ts.decomposed, aux)
  }
  
  return( all.ts.decomposed )
  
}


# Calculate daily growth rate in micrometers per day
calc.growth.rate <- function (dendro.ts) {
  
  growth.df <- dendro.ts %>%
    mutate(date = date(dendro.ts$ts)) %>% 
    summarise(maxOfDay = max(value), .by = date) %>% 
    arrange(date)
  
  # TOREWRITE USING diff()
  # val.diff <- diff(t - t-1)
  # growth.df$rate <- c(0, val.diff[2:n])
  
  growth.df$value <- growth.df$maxOfDay-min(growth.df$maxOfDay) # the max of the day minus the mininum of all days
  
  growth.df$rate <- c(0,(growth.df$value[2:nrow(growth.df)]-growth.df$value[1:(nrow(growth.df)-1)]))
  growth.df$rate <- ifelse(growth.df$rate<0,0,growth.df$rate)
  
  return (growth.df)
}


plot_growth_rate <- function (growth.df) {
  growth.df %>%
    mutate (year = as.factor(year(date)), doy = yday(date)) %>% 
    ggplot() +
      geom_line(aes(x = doy, y = rate, col = year)) +
      labs(y = expression("Daily growth rate ratio(um · "~ day^{-1}), x = "Day of the year") +
      scale_x_continuous(breaks = seq(0, 360, by = 30), limits = c(0, 366))
}

# Calculate daily growth rate from trend data from 0 to 1 ratio.
calc.growth.rate.ratio <- function (dendro.ts) {
  trend.df <- dendro.ts %>% select(ts, trend) %>% rename(value = trend)
  
  growth.df <- trend.df %>%
    mutate(date = date(trend.df$ts)) %>% 
    summarise(maxOfDay = max(value), .by = date) %>% 
    arrange(date)
  
  growth.df$value <- growth.df$maxOfDay-min(growth.df$maxOfDay) + 1 # the max of the day minus the mininum of all days, plus 1 so we don't have 0 as denominator
  
  # TOREWRITE USING diff()
  # val.diff <- diff(t - t-1)
  # growth.df$rate <- c(0, val.diff[2:n] / values[1:n-1])
  
  growth.df$rate <- c(0,(growth.df$value[2:nrow(growth.df)]-growth.df$value[1:(nrow(growth.df)-1)])/growth.df$value[1:(nrow(growth.df)-1)])
  growth.df$rate <- ifelse(growth.df$rate<0,0,growth.df$rate)
  
  return (growth.df)
}

plot_growth_rate_ratio <- function (growth.df) {
  growth.df %>%
    mutate (year = as.factor(year(date)), doy = yday(date)) %>% 
    ggplot() +
      geom_line(aes(x = doy, y = rate, col = year)) +
      labs(y = "Daily Growth rate ratio (0-1)", x = "Day of the year") +
      scale_x_continuous(breaks = seq(0, 360, by = 30), limits = c(0, 366))
}

plot_day_seasonality <- function (seasons, sp, site, period){
  ggplot( data = seasons, mapping = aes(x = timeOfDay, y = meanSeasonalityTime)) + 
    geom_line(col = season.color, show.legend = F) + 
    geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime + SE_SeasonalityTime)), col = season.color, alpha = 0.5, linetype = "dashed", show.legend = F) +
    geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime - SE_SeasonalityTime)), col = season.color, alpha = 0.5, linetype = "dashed", show.legend = F) +
    ggtitle(glue("Aggregated mean in one day of seasonalities from {period} for {sp} in {site}")) +
    scale_x_time(breaks = seq(0, 85500, by = 3600), labels = every_hour_labels) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(x = "Hour of the day", y = expression(paste("Micrometers of Daily seasonality (", mu, "m)")))
}

plot_day_seasonality_byclass <- function (seasons, sp, site, period){
  ggplot( data = seasons, mapping = aes(x = timeOfDay, y = meanSeasonalityTime, col = class)) + 
    geom_line() + 
    geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime + SE_SeasonalityTime)), alpha = 0.5, linetype = "dashed", show.legend = F) +
    geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime - SE_SeasonalityTime)), alpha = 0.5, linetype = "dashed", show.legend = F) +
    scale_color_manual(labels = c_labels, values=c_class_values) +
    ggtitle(glue("Aggregated mean in one day of seasonalities from {period} for {sp} in {site}")) +
    scale_x_time(breaks = seq(0, 85500, by = 3600), labels = every_hour_labels) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(x = "Hour of the day", y = expression(paste("Micrometers of Daily seasonality (", mu, "m)")))
}

plot_day_seasonalities_periods <- function (seasons.periods.joined, sp, site){
ggplot(seasons.periods.joined) +
  ggtitle(glue("Aggregated mean in one day for periods: All period of study and June-July for {sp} in {site}")) +
  geom_line(aes(x = timeOfDay, y = meanSeasonalityTime, col = period)) + 
  geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime + SE_SeasonalityTime), col = period), alpha = 0.5, linetype = "dashed", show.legend = F) +
  geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime - SE_SeasonalityTime), col = period), alpha = 0.5, linetype = "dashed", show.legend = F) +
  scale_x_time(breaks = seq(0, 85500, by = 3600), labels = every_hour_labels) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x = "Hour of the day", y = expression(paste("Micrometers of Daily seasonality (", mu, "m)")))
}

plot_day_seasonality_and_temp <- function (seasons, temp, sp, site, period) {
  ggplot( data = seasons, mapping = aes(x=timeOfDay, y = meanSeasonalityTime)) + 
    geom_line(aes(col = "Seasonality"), show.legend = T) +
    geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime + SE_SeasonalityTime)), col = season.color, alpha = 0.5, linetype = "dashed", show.legend = F) +
    geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime - SE_SeasonalityTime)), col = season.color, alpha = 0.5, linetype = "dashed", show.legend = F) +
    ggtitle(glue("Aggregated mean in one day of seasonalities plus daily temperature variation from {period} for {sp} in {site}")) +
    scale_x_time(breaks = seq(0, 85500, by = 3600), labels = every_hour_labels ) +
    labs(x = "Hour of the day", y = expression(paste("Micrometers of Daily seasonality (", mu, "m)"))) +
    scale_y_continuous(breaks = seq(-5,5,1), sec.axis = sec_axis(trans = ~ ((. * 5) + 23), name = "Temperature (ºC)", breaks = seq(0,40,5)) ) +
    geom_line(data = temp, aes(x = timeOfDay, y = (meanTemp - 23) / 5, col = "Temperature"), alpha = 0.6, show.legend = T) +
    geom_line(data = temp, aes(x = timeOfDay, y = (meanTemp - 23) / 5 + se_temp), col = temperature.color, alpha = 0.4, linetype = "dashed") +
    geom_line(data = temp, aes(x = timeOfDay, y = (meanTemp - 23) / 5 - se_temp), col = temperature.color, alpha = 0.4, linetype = "dashed") +
    scale_color_manual(values = c(season.color, temperature.color)) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      axis.title.y = element_text(color = season.color, face = "bold", size = 13),
      axis.text.y = element_text(color = season.color),
      axis.title.y.right = element_text(color = temperature.color, face= "bold", size = 13),
      axis.text.y.right = element_text(color = temperature.color)
    )
}
  
  
