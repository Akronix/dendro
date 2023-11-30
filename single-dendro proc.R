### IMPORT LIBRARIES ###
library(tidyverse)
library(Rmisc)
library(viridis)
library(ggplot2)
library(treenetproc)
library(lubridate)

### DEFINE GLOBAL VARS ###
PATH = '/home/akronix/workspace/dendro';
setwd(PATH)
SELECTED_DENDROMETER = "92222174" # 92222174 is declining pine


### DEFINE GLOBAL Functs ###
left <-  function(string, char){substr(string, 1,char)}

### IMPORT DATA ###

## IMPORT DENDRO DATA ##

####################################
############# MIEDES ###############
####################################

# Set initial and final date and sampling dates
ts_start<-"2022-03-12 00:00:00" #from March 12 (2 days after installation)
ts_end<-"2023-09-14 00:00:00"

# Import data from dataD/ in working directory
read.data.dendro <- function(nameFiles){
  FileList <- list()
  print(nameFiles)
  for (i in 1:length(nameFiles)){
    File <- read.csv(nameFiles[i],  
                     sep = ";",  header=FALSE, skip=0, dec=",", stringsAsFactors=FALSE)
    File$ts<-as.POSIXct(File$V2, format="%Y.%m.%d %H:%M", tz="Europe/Madrid")
    File$date <- as.Date(File$ts)
    File<-File[which(File$ts>=ts_start & File$ts<=ts_end),] 
    File$um<-as.numeric(File$V7)
    File$value<-File$um-File$um[1] #zeroing variations in diameter
    File$temp<-as.numeric(File$V4)
    File$series<-as.factor(nameFiles[i])
    File<-subset(File,select=c(ts,date,um,value,temp,series))
    FileList[[i]] <- File
  }
  return(FileList)
}

# importing dendro data #
list.files <- list.files(path="./dataD", pattern="*.csv", full.names=TRUE)
dball<-do.call(rbind.data.frame, read.data.dendro(list.files))
db <- dball


# Clean name of field series
db$series <- gsub("./dataD/","",db$series)
db$series <- gsub("_2023_09_13_0.csv","",db$series)
db$series <- substr(db$series,6,nchar(db$series))

# In this script, we will work with one dendrometer series only
db = db[db$series == SELECTED_DENDROMETER,]
db

# Add tree information to each dendrometer (series)
TreeList<-read.table("TreeList.txt",header=T)
db <- merge(db,TreeList[,c(1:4,6)],  by = "series") 

str(db)
head(db)


## CLEAN DATA ##

### BEGIN COMMENT ###
## Remove duplicated dates, which corresponds actually to spring daylight saving shift ###

# Daylight-saving times for the interval
# dst_spring_start <- as.POSIXct("2022-03-27 01:00:00", tz="Europe/Madrid")
# dst_spring_end <- as.POSIXct("2022-03-27 01:45:00", tz="Europe/Madrid")
# 
# within_dst_spring <- function(datetime) { return ((datetime >= dst_spring_start) & (datetime <= dst_spring_end)) }
# 
# dates_duplicated = within_dst_spring(db$ts) & (rownames(db) > which( within_dst_spring(db$ts) )[4])
# 
# nrow(db)
# nrow(db[- which(out),])

### END COMMENT ###

# This removes duplicates on timestamps (presumably because of daylight savingtime issues)
db = db[!duplicated(db$ts),];


### PLOT RAW DATA ###

## TEMP DATA ##

# Calculate mean temperature by day and site
db.mean.Temp <- summarySE(db, measurevar="temp", 
                          groupvars=c("date","site"),na.rm=TRUE)
db.mean.Temp$sp<-fct_relevel(db.mean.Temp$site, "CO", "MI","PE")
db.mean.Temp

plot.Temp2<-
  ggplot(data = db.mean.Temp, aes(x=date, y=temp))+
  ggtitle(paste0("Temperature data for sensor with ID: ",db$ID[1])) +
  geom_line(aes(color=site))+
  geom_ribbon(aes(ymin=temp-se, ymax=temp+se, fill=site),alpha=0.3)+
  labs(x=expression(''),
       y=expression("Temperature (ºC)"))+
  theme_bw() +  
  scale_color_viridis(discrete = TRUE, option = "D")+
  scale_fill_viridis(discrete = TRUE, option = "D") +
  scale_x_date(date_breaks = "1 month", expand = c(0,0))+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
plot.Temp2

## DENDRO DATA ##

# PLotting continuous series #

checkplot_diam_raw<-
  ggplot(data = db,  aes(x=ts, y=value, color=ID))+
  geom_line( )+
  ggtitle(paste0("Dendro data for sensor with ID: ",db$ID[1])) +
  labs(x=expression(''),
       y=expression(Delta*"D (um)"))+
  theme_bw() +
  geom_hline(yintercept=0,lty=2,linewidth=0.2)+
  facet_grid(class~.,scales = "free_y")+
  scale_x_datetime(date_breaks = "1 month") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
checkplot_diam_raw


#plot(um~ts,db,type="l",col="red",axes=F)



# plotting by year #

# grab years
years <-left(db[,"ts"],4)
library(viridis)

dendro_data_L0 = db
# plotting
par(mfrow=c(1,1))
par(mar = c(5, 5, 5, 5))
for(y in 1:length(unique(years))){
  # selected year
  sel<-dendro_data_L0[which(years==unique(years)[y]),]
  # handle first year
  if(y==1){
    plot(difftime(as.POSIXct(sel$ts,format="%Y-%m-%d %H:%M:%S",tz="Europe/Madrid"),
                  as.POSIXct(paste0(unique(years)[y],"-01-01 00:00:00"),
                             format="%Y-%m-%d %H:%M:%S",tz="Europe/Madrid"),
                  units = "days"),
         sel$value,
         ylab=expression("L0 ("*mu*"m)"),
         xlab="Day of year",type="l",
         col=viridis(length(unique(years)))[y],
         xlim=c(0,365),
         ylim=c(min(dendro_data_L0$value,na.rm=T),
                max(dendro_data_L0$value,na.rm=T)),
    )

    title(paste0("Plotting by year sensor with ID: ",dendro_data_L0$ID[1]))

    legend("bottomright",
           as.character(unique(years)[-4]),
           col=viridis(length(unique(years))),
           bty="n",lty=1)
    # add other years
  }else{
    lines(difftime(as.POSIXct(sel$ts,format="%Y-%m-%d %H:%M:%S",tz="Europe/Madrid"),
                   as.POSIXct(paste0(unique(years)[y],"-01-01 00:00:00"),
                              format="%Y-%m-%d %H:%M:%S",tz="Europe/Madrid"),
                   units = "days"),
          sel$value,
          col=viridis(length(unique(years)))[y])}}


### TREENETPROC ###

str(db)
head(db)
tail(db)


# Subset the columns we want for treenetproc
db<-subset(db, select = c(ts, value, series,  ID, site, sp, class, temp))

# If I don't to the below code some NAs get filled inside proc_L1 when it check_ts(), throwing an error and messin up the timestamp
db$ts = strftime(db$ts, "%Y-%m-%d %H:%M:%S", tz = "Europe/Madrid" )

# define dendro_data_L0 to work with. Here we will use the "wide" format.
dendro_data_L0 = subset(db, select = c(series, ts, value, ID, site, sp, class))
temp_data_L0 = subset(db, select = c(series, ts, temp, ID, site, sp, class))

colnames(temp_data_L0)<-colnames(dendro_data_L0)

str(dendro_data_L0)
str(temp_data_L0)
# treenetproc: Time-alignment processing (L1)

# dendro data
dendro_data_L1 <- proc_L1(data_L0 = dendro_data_L0,
                          reso = 15,
                          date_format = "%Y-%m-%d %H:%M:%S",
                          input = "long",
                          year = "asis",
                          tz = "Europe/Madrid")
head(dendro_data_L1)
str(dendro_data_L1)


# temp data
temp_data_L1 <- proc_L1(data_L0 = temp_data_L0,
                          reso = 15,
                          date_format = "%Y-%m-%d %H:%M:%S",
                          input = "long",
                          year = "asis",
                          tz = "Europe/Madrid")
head(temp_data_L1)
str(temp_data_L1)

# Now we do the error detection and processing with treenetproc
par(mfrow=c(1,1))
par(mar = c(5, 5, 5, 5))


### BEGIN COMMENT ###
# !! No entiendo porqué treenetproc falla con el daylight saving time incluso con el TZ bien fijado aquí:
#dendro_data_L1$ts = with_tz(dendro_data_L1$ts, tz="Europe/Madrid")
#temp_data_L1$ts = with_tz(temp_data_L1$ts, tz="Europe/Madrid")
# Pero es desesperante, así que voy a borrar los datos cuando se cambia la hora y palante.
# Otra opción, forkear y arreglar. El problema está aquí: https://github.com/treenet/treenetproc/blob/6f0fa35df5b2e5e2096dfb0a42512da2163a8213/R/check_input_data.R#L188

# Antes estaba obligado a coger un subset de los datos evitando las zonas donde se produce el daylight saving time:
# Testing with small datasets
#dball<-db

### ! Me quedo con subconjunto donde no da error -> Hay que mirar qué pasa fuera de ese rango para que dé error.
# Buscar cambio de hora alrededor de 1400-1450 (marzo 2022), borrar esos datos de la hora que se cambia y lo mismo en otoño.
#db<-dball[1:10000,]#db<-dball[1400:35000,]#db<-dball[1500:35000,]

### END COMMENT ###

# detect errors
dendro_data_L2 <- proc_dendro_L2(dendro_L1 = dendro_data_L1,
                                 temp_L1 = temp_data_L1,
                                 #tol_out = 1,
                                 tol_jump = 10,
                                 plot_period = "monthly",
                                 plot = TRUE,
                                 plot_export = TRUE,
                                 tz="Europe/Madrid")
# check the data
head(dendro_data_L2)

#highlight corrections made on the dendrometer data:
View(dendro_data_L2[which(is.na(dendro_data_L2$flags)==F),])

### PLOT CLEANED DATA ###

# -> Open proc_L2_plot.pdf file

### DATA AGGREGATION AND ANALYSIS ###

# GROWING SEASON #
# aggregate to growing season by year
grow_seas_L2 <- grow_seas(dendro_L2 = dendro_data_L2,
                          agg_yearly=TRUE)
knitr::kable(grow_seas_L2,
             caption = "Sample output data of the function `grow_seas`.")


# PHASE STATISTICS #
# calculate phase statistics #

# create plot
par(mfrow=c(1,1))
par(mar = c(5, 5, 5, 5))

phase_stats_L2 <- phase_stats(dendro_L2 = dendro_data_L2,
                              plot_phase = TRUE,
                              plot_export = TRUE)

# view dalculated phase_stats:
knitr::kable(phase_stats_L2[1:5, ],
             caption = "Sample output data of the function `phase_stats`.")

# ANALYSE RADIAL CHANGE PATTERS AND CAUSES #

# calculate radial change patterns:
options(warn = 1)

trans_stats_L2 <- phase_stats_L2[which(phase_stats_L2$phase_class==1),]
temp_stats_L2 <- phase_stats_L2[which(phase_stats_L2$phase_class==-1),]
other_stats_L2 <- phase_stats_L2[which(is.na(phase_stats_L2$phase_class)==T),]
other_stats_L2$phase_class <- 0

trans <- aggregate(trans_stats_L2$phase_class,by=list(trans_stats_L2$doy),sum)
temp <- aggregate(temp_stats_L2$phase_class,by=list(temp_stats_L2$doy),sum)
temp$x <- sqrt(temp$x^2)
other <- aggregate(other_stats_L2$phase_class,by=list(other_stats_L2$doy),sum)

# plot causes of daily radial change patterns:
par(mfrow=c(1,1))
par(mar = c(5, 5, 5, 5))

plot(trans$Group.1,trans$x,
     pch=16,
     col="black",
     cex=2,
     ylim=c(0,4),
     ylab="Cumulative days",
     xlab="Day of year")

points(trans$Group.1,trans$x,pch=16,cex=1,col="cyan")
points(temp$Group.1,temp$x,pch=16,cex=2,col="black")
points(temp$Group.1,temp$x,pch=16,cex=1,col="darkorange")
points(other$Group.1,other$x,pch=16,cex=2,col="black")
points(other$Group.1,other$x,pch=16,cex=1,col="grey70")

legend("topleft",
       pch=16,
       c("Transpiration","Temperature","Other"),
       col=c("cyan","darkorange","grey70"),
       bty="n",
       pt.cex=1.5,
       cex=1.5)


## Tree water deficit (TWD) as an indicator of drought stress. ##
# plot minimum daily twd against day of year
par(mfrow=c(1,1))
par(mar = c(5, 5, 5, 5))

plot(1,
     1,
     ylim=c(0,max(dendro_data_L2$twd,na.rm=T)),
     xlim=c(0,365),
     ylab=expression("twd ("*mu*"m)"),
     xlab="Day of year",
     col="white")

col_sel<-c("cyan","darkorange","purple")

for(y in c(1:length(unique(left(dendro_data_L2$ts,4))))){
  # selected year
  sel<-dendro_data_L2[which(left(dendro_data_L2$ts,4)==unique(left(dendro_data_L2$ts,4))[y]),]
  # calc twd
  twd<-suppressWarnings(aggregate(sel$twd,list(as.Date(sel$ts)),min,na.rm=T))
  twd$doy<-as.numeric(strftime(as.Date(twd$Group.1), format = "%j"))
  
  # clean
  twd[which(twd$x=="Inf"),"x"]<-NA
  
  lines(twd$doy,twd$x,col=col_sel[y],lwd=1.5)
  twd[which(is.na(twd$x)==T),"x"]<-0
  polygon(c(c(0,twd$doy),c(rev(twd$doy),0)),
          c(c(0,twd$x),rep(0,nrow(twd)+1)),
          col=rgb(0,0,0,0.1),
          border=rgb(0,0,0,0))
}

legend("topleft",
       c(unique(left(dendro_data_L2$ts,4))),
       col=col_sel,
       lty=1,
       bty="n")

# Add growing season extent:
grow_seas_L2 <- grow_seas(dendro_L2 = dendro_data_L2,
                          agg_yearly=TRUE,
                          tol_seas = 0.1)


abline(v=c(mean(grow_seas_L2$gro_start),
           mean(grow_seas_L2$gro_end)),
       lty=2)
text(mean(c(mean(grow_seas_L2$gro_start),
            mean(grow_seas_L2$gro_end))),
     max(dendro_data_L2$twd,na.rm=T),
     "Growing season")


### PLOT TEMPERATURE DATA ###
# Plotting temperature monthly and export to PDF to compare with growth results:

pdf("dendrometer_temperature_plots.pdf", onefile = TRUE)
for (year in c(2022,2023))
  for(m in 1:12){
    #print(m, year)
    temp_data_monthly = subset(dball, month(ts) == m & year(ts) == year)
    if (nrow(temp_data_monthly) == 0 ) next;
    plot <- ggplot(data = temp_data_monthly, mapping = aes(x=ts, y=temp))  +
      labs(x=expression('Day of month'),
           y=expression("Temperature (ºC)")) +
      geom_line() +
      ggtitle(paste("Dendrometer registered temperature for", month.name[m], year)) +
      scale_x_datetime(date_breaks = "1 day", date_labels = "%d")
    print(plot)
  }
dev.off()

### ENVIRONMENTAL DATA ###

siteFiles <- paste(getwd(),"/Prec/",sep="")

###list the RWL files present in the folder
SoilFiles <- paste(siteFiles,list.files(siteFiles, pattern=".csv"),sep="")
SoilFiles

## Let's get the associated environmental sensor for this dendrometer, if there's one
sensor.id = TreeList[TreeList$series == as.integer(SELECTED_DENDROMETER),]$soil.sensor
if (!is.na(sensor.id)) {
  
  # 1. load environmental data
  filename = paste0(siteFiles, "data_", sensor.id, "_2023_09_13_0.csv")
  env.db <- read.csv(filename, sep = ";", header = FALSE, skip = 0, dec = ",", stringsAsFactors = FALSE)
  env.db$ts<-as.POSIXct(env.db$V2, format="%Y.%m.%d %H:%M", tz="Europe/Madrid")
  env.db$date <- as.Date(env.db$ts)
  #File<-File[which(File$ts>=ts_start & File$ts<=ts_end),]
  env.db$soil.temp <- env.db$V4
  env.db$bottom.temp <- env.db$V5
  env.db$top.temp <- env.db$V6
  env.db$humidity <- env.db$V7
  
  env.db<-subset(env.db,select=c(ts,date,soil.temp,bottom.temp,top.temp,humidity))
  str(env.db)
  
  # plot and export PDF monthly
  
  # plot temp monthly
  pdf("air_temperature_plots.pdf", onefile = TRUE)
  for (year in c(2022,2023))
    for(m in 1:12){
      #print(m, year)
      temp2_data_monthly = subset(env.db, month(ts) == m & year(ts) == year)
      if (nrow(temp2_data_monthly) == 0 ) next;
      plot <- ggplot(data = temp2_data_monthly, mapping = aes(x=ts, y=top.temp)) +
        labs(x=expression('Day of month'),
             y=expression("Temperature (ºC)")) +
        geom_line() +
        ggtitle(paste("Air temperature for", month.name[m], year)) +
        scale_x_datetime(date_breaks = "1 day", date_labels = "%d")
      print(plot)
    }
  dev.off()
  
  # plot humidity monthly
  pdf("humidity_plots.pdf", onefile = TRUE)
  for (year in c(2022,2023) )
    for(m in 1:12){
    #print(m, year)
    hum_data_monthly = subset(env.db, month(ts) == m & year(ts) == year)
    if (nrow(hum_data_monthly) == 0 ) next;
    plot <- ggplot(data = hum_data_monthly, mapping = aes(x=ts, y=humidity))  +
      labs(x=expression('Day of month'),
           y=expression("Humidity (mV)")) +
      geom_line() +
      ggtitle(paste("Humidity for", month.name[m], year)) +
      scale_x_datetime(date_labels = "%d", date_breaks = "1 day")
    print(plot)
  }
  dev.off()
  
  
  # plot temp & humidity monthly in one pdf 
  pdf("environmetal_plots.pdf", onefile = TRUE)
  for (year in c(2022,2023))
    for(m in 1:12){
      #print(m, year)
      temp2_data_monthly = subset(env.db, month(ts) == m & year(ts) == year)
      if (nrow(temp2_data_monthly) == 0 ) next;
      plot <- ggplot(data = temp2_data_monthly, mapping = aes(x=ts, y=top.temp)) +
        labs(x=expression('Day of month'),
             y=expression("Temperature (ºC)")) +
        geom_line() +
        ggtitle(paste("Air temperature for", month.name[m], year)) +
        scale_x_datetime(date_breaks = "1 day", date_labels = "%d")
      print(plot)
    }
  dev.off()
  
  # plot humidity monthly
  pdf("humidity_plots.pdf", onefile = TRUE)
  for (year in c(2022,2023) )
    for(m in 1:12){
      #print(m, year)
      hum_data_monthly = subset(env.db, month(ts) == m & year(ts) == year)
      if (nrow(hum_data_monthly) == 0 ) next;
      plot <- ggplot(data = hum_data_monthly, mapping = aes(x=ts, y=humidity))  +
        labs(x=expression('Day of month'),
             y=expression("Humidity (mV)")) +
        geom_line() +
        ggtitle(paste("Humidity for", month.name[m], year)) +
        scale_x_datetime(date_labels = "%d", date_breaks = "1 day")
      print(plot)
    }
  dev.off()
  
  
  
  
    
}