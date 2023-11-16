#### IMPORT LIBRARIES ####
library(tidyverse)
library(Rmisc)
library(viridis)
library(ggplot2)
library(treenetproc)

#### IMPORT DATA ####

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
db<-do.call(rbind.data.frame, read.data.dendro(list.files))

# Clean name of field series
db$series <- gsub("./dataD/","",db$series)
db$series <- gsub("_2023_09_13_0.csv","",db$series)
db$series <- substr(db$series,6,nchar(db$series))

# In this script, we will work with one dendrometer series only
db = db[db$series == "92222154",]
db

# Add tree information to each dendrometer (series)
TreeList<-read.table("TreeList.txt",header=T)
db <- merge(db,TreeList[,c(1:4,6)],  by = "series") 

str(db)
head(db)


### PLOT RAW DATA ###

## TEMP DATA ##

# Calculate mean temperature by day and site
db.mean.Temp <- summarySE(db, measurevar="temp", 
                          groupvars=c("date","site"),na.rm=TRUE)
db.mean.Temp$sp<-fct_relevel(db.mean.Temp$site, "CO", "MI","PE")
db.mean.Temp

plot.Temp2<-
  ggplot(data = db.mean.Temp, aes(x=date, y=temp))+
  ggtitle(paste0("Sensor con ID: ",db$ID[1])) +
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
  ggtitle(paste0("Sensor con ID: ",db$ID[1])) +
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

# # grab years
# left <-  function(string, char){substr(string, 1,char)}
# years <-left(db[,"ts"],4)
# library(viridis)
# 
# dendro_data_L0 = db
# # plotting
# par(mfrow=c(1,1))
# par(mar = c(5, 5, 5, 5))
# for(y in 1:length(unique(years))){
#   # selected year
#   sel<-dendro_data_L0[which(years==unique(years)[y]),]
#   # handle first year
#   if(y==1){
#     plot(difftime(as.POSIXct(sel$ts,format="%Y-%m-%d %H:%M:%S",tz="Europe/Madrid"),
#                   as.POSIXct(paste0(unique(years)[y],"-01-01 00:00:00"),
#                              format="%Y-%m-%d %H:%M:%S",tz="Europe/Madrid"),
#                   units = "days"),
#          sel$value,
#          ylab=expression("L0 ("*mu*"m)"),
#          xlab="Day of year",type="l",
#          col=viridis(length(unique(years)))[y],
#          xlim=c(0,365),
#          ylim=c(min(dendro_data_L0$value,na.rm=T),
#                 max(dendro_data_L0$value,na.rm=T)),
#     )
#     
#     title(paste0("Sensor con ID: ",dendro_data_L0$ID[1]))
#     
#     legend("bottomright",
#            as.character(unique(years)[-4]),
#            col=viridis(length(unique(years))),
#            bty="n",lty=1)
#     # add other years
#   }else{
#     lines(difftime(as.POSIXct(sel$ts,format="%Y-%m-%d %H:%M:%S",tz="Europe/Madrid"),
#                    as.POSIXct(paste0(unique(years)[y],"-01-01 00:00:00"),
#                               format="%Y-%m-%d %H:%M:%S",tz="Europe/Madrid"),
#                    units = "days"),
#           sel$value,
#           col=viridis(length(unique(years)))[y])}}


### TREENETPROC ###

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
                          reso = 60,
                          date_format = "%Y-%m-%d %H:%M:%S",
                          input = "long",
                          year = "asis",
                          tz = "Europe/Madrid")
head(dendro_data_L1)
str(dendro_data_L1)


# temp data
temp_data_L1 <- proc_L1(data_L0 = temp_data_L0,
                          reso = 60,
                          date_format = "%Y-%m-%d %H:%M:%S",
                          input = "long",
                          year = "asis",
                          tz = "Europe/Madrid")
head(temp_data_L1)
str(temp_data_L1)

# Now we do the error detection and processing with treenetproc
par(mfrow=c(1,1))
par(mar = c(5, 5, 5, 5))

# detect errors
dendro_data_L2 <- proc_dendro_L2(dendro_L1 = dendro_data_L1,
                                 #temp_L1 = temp_data_L1,
                                 tol_out = 5,
                                 #tol_jump = 16,
                                 plot = TRUE,
                                 plot_export = TRUE,
                                 tz="Europe/Madrid")
# check the data
head(dendro_data_L2)

#highlight corrections made on the dendrometer data:
View(dendro_data_L2[which(is.na(dendro_data_L2$flags)==F),])



## SOIL DATA ##

siteFiles <- paste(getwd(),"/Prec/",sep="")

###list the RWL files present in the folder
ListFiles <- paste(siteFiles,list.files(siteFiles, pattern=".csv"),sep="")
ListFiles
