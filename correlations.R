library(correlation)

# Correlations

## Find best fit of cross-correlation
find_Max_CCF = function(x, y, lag.max = NULL) {
  # run cross-correlation function
  ccf = ccf(x, y, plot = FALSE, na.action = na.pass) 
  # build a dataset with lag times and correlation coefficients
  res_cc = data.frame(lag = ccf$lag[,,1], cor = ccf$acf[,,1]) 
  max = res_cc[which.max(abs(res_cc$cor)),] 
  # return only the data of interest
  return(max) 
}

## Find best fit of cross-correlation
sort_CCF_values = function(x, y, lag.max = NULL) {
  # run cross-correlation function
  ccf = ccf(x, y, plot = FALSE, na.action = na.pass, lag.max = lag.max) 
  # build a dataset with lag times and correlation coefficients
  res_cc = data.frame(lag = ccf$lag[,,1], cor = ccf$acf[,,1])
  # sort by correlation values
  res_cc <- res_cc[order(abs(res_cc$cor), decreasing = T), ]
  return(res_cc) 
} 

## cor.test all methods
cor.test.all.methods <- function (x, y, ci) {
  print(cor.test(x,y, method = c("pearson"), conf.level = ci))
  print(cor.test(x,y, method = c("spearman"), conf.level = ci))
  print(cor.test(x,y, method = c("kendall"), conf.level = ci))
}

## customized ccf function but using the desired method and only for lags given, allowing positive lags only as well.
# ccf.custom <- function(x, y, lag.max, method = "pearson", positive.only = F) {
#   
#   if (positive.only)
#     lags <- 0:lag.max
#   else
#     lags <- -lag.max:lag.max
#   
#   print(lags)
#   
#   result <- list()
#   
#   for (i in 1:length(lags)) {
#     lag_i <- lags[i]
#     if (lag_i <= 0)
#       shifted_x <- lag (x, n = abs(lag_i))
#     else
#       shifted_x <- lead (x, n = lag_i)
#     
#     print(shifted_x)
#     
#     # cor.test of shifted values using given method
#     result[[as.character(lag_i)]] <- cor.test(shifted_x, y, method = method)
#   }
#   
#   return (result)
# }
