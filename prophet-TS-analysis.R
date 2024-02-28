library(dplyr)
library(prophet)

dat. = rename(dat, c(ds = ts, y = value))
m <- prophet(dat.)
future <- make_future_dataframe(m, periods = 96)
forecast <- predict(m, future)
prophet_plot_components(m, forecast)
