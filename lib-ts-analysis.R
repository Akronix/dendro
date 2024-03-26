library(anomalize) # time series decomposition
library(stats) # stl Decomposition
library(ggpubr) # ggarange
library(zoo) # print dates in x-axis for ts objects
library(tidyverse)

# DEFINE COMMON COLORS
temperature.color <- "darkorange"
season.color <- "darkgreen"


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

# Correlations

## Find best fit of cross-correlation
find_Max_CCF = function(x,y) {
  # run cross-correlation function
  ccf = ccf(x, y, plot = FALSE, na.action = na.pass) 
  # build a dataset with lag times and correlation coefficients
  res_cc = data.frame(lag = ccf$lag[,,1], cor = ccf$acf[,,1]) 
  max = res_cc[which.max(abs(res_cc$cor)),] 
  # return only the data of interest
  return(max) 
}

## Find best fit of cross-correlation
sort_CCF_values = function(x,y) {
  # run cross-correlation function
  ccf = ccf(x, y, plot = FALSE, na.action = na.pass) 
  # build a dataset with lag times and correlation coefficients
  res_cc = data.frame(lag = ccf$lag[,,1], cor = ccf$acf[,,1])
  # sort by correlation values
  res_cc <- res_cc[order(res_cc$cor, decreasing = T), ]
  return(res_cc) 
} 

# cor.test all methods
cor.test.all.methods <- function (x, y, ci) {
  print(cor.test(x,y, method = c("pearson"), conf.level = ci))
  print(cor.test(x,y, method = c("spearman"), conf.level = ci))
  print(cor.test(x,y, method = c("kendall"), conf.level = ci))
}

# Calculate daily growth rate from trend data
calc.growth.rate <- function (trend.df) {
  trend.df <- dendroM %>% select(ts, trend) %>% rename(value = trend)
  
  growth.df <- trend.df %>%
    mutate(day = day(trend.df$ts), month = month(trend.df$ts), year = year(trend.df$ts)) %>% 
    summarise(max = max(value), .by = c(year, month, day)) %>% 
    arrange(year, month, day)
  
  # val.diff <- diff(t - t-1)
  # growth.df$rate <- c(NA, val.diff[1:n] / val.diff[1:n])
  
  growth.df$rate <- c(0,(growth.df$max[2:nrow(growth.df)]-growth.df$max[1:(nrow(growth.df)-1)])/growth.df$max[1:(nrow(growth.df)-1)])
  
  return (growth.df)
  
  dendroY <- aggregate(dendroM$trend,by=list(dendroM$year,dendroM$month,dendroM$day),max)
  dendroY <- dendroY[order(dendroY[,1],dendroY[,2],dendroY[,3],decreasing=F),]
  
  dim(dendroY)
  head(dendroY)
  plot(dendroY$x,type="l")
  dendroY$x <- dendroY$x-min(dendroY$x-1)
  dendroY$rate <- 0
  dendroY$rate <- c(0,(dendroY$x[2:nrow(dendroY)]-dendroY$x[1:(nrow(dendroY)-1)])/dendroY$x[1:(nrow(dendroY)-1)])
}

plot_day_seasonality <- function (seasons, sp, site, period){
  ggplot( data = seasons, mapping = aes(x = timeOfDay, y = meanSeasonalityTime)) + 
    geom_line(col = season.color, show.legend = F) + 
    geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime + SE_SeasonalityTime)), col = season.color, alpha = 0.5, linetype = "dashed", show.legend = F) +
    geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime - SE_SeasonalityTime)), col = season.color, alpha = 0.5, linetype = "dashed", show.legend = F) +
    ggtitle(glue("Aggregated mean in one day of seasonalities from {period} for {sp} in {site}")) +
    scale_x_time(breaks = seq(0, 85500, by = 3600), labels = every_hour_labels) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(x = "Hour of the day", y = "Micrometers of Daily seasonality (um)")
}

plot_day_seasonalities_periods <- function (seasons.periods.joined, sp, site){
ggplot(seasons.periods.joined) +
  ggtitle(glue("Aggregated mean in one day for periods: All period of study and June-July for {sp} in {site}")) +
  geom_line(aes(x = timeOfDay, y = meanSeasonalityTime, col = period)) + 
  geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime + SE_SeasonalityTime), col = period), alpha = 0.5, linetype = "dashed", show.legend = F) +
  geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime - SE_SeasonalityTime), col = period), alpha = 0.5, linetype = "dashed", show.legend = F) +
  scale_x_time(breaks = seq(0, 85500, by = 3600), labels = every_hour_labels) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x = "Hour of the day", y = "Micrometers of Daily seasonality (um)")
}

plot_day_seasonality_and_temp <- function (seasons, temp, sp, site, period) {
  ggplot( data = seasons, mapping = aes(x=timeOfDay, y = meanSeasonalityTime)) + 
    geom_line(aes(col = "Seasonality"), show.legend = T) +
    geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime + SE_SeasonalityTime)), col = season.color, alpha = 0.5, linetype = "dashed", show.legend = F) +
    geom_line(aes (x = timeOfDay, y = (meanSeasonalityTime - SE_SeasonalityTime)), col = season.color, alpha = 0.5, linetype = "dashed", show.legend = F) +
    ggtitle(glue("Aggregated mean in one day of seasonalities plus daily temperature variation from {period} for {sp} in {site}")) +
    scale_x_time(breaks = seq(0, 85500, by = 3600), labels = every_hour_labels ) +
    labs(x = "Hour of the day", y = "Micrometers of Daily seasonality (um)") +
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
  
  
