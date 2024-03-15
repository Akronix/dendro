library(anomalize) # time series decomposition
library(stats) # stl Decomposition
library(ggpubr) # ggarange
library(zoo) # print dates in x-axis for ts objects

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

# cor.test all methods
cor.test.all.methods <- function (x, y, ci) {
  print(cor.test(x,y, method = c("pearson"), conf.level = ci))
  print(cor.test(x,y, method = c("spearman"), conf.level = ci))
  print(cor.test(x,y, method = c("kendall"), conf.level = ci))
}
