# Bastiaen Boekelo, March 2025
# Goal: Download data from Veenkampen weather via API requests, based on user defined request parameters

# Specifications:
  # Time range for the download request can be defined manually in Data/1_Input/API_request_parameters.csv
  # Variables can be defined manually in the API parameter csv
  # Statistics (if indicated in the input file) are calculated per individual:
      # Hour
      # Day (24 hours)
      # Daytime (between sunrise and sunset)
  # The following statistics can be chosen: count,min,median,max,mean,sd.
  # Output is split per sheet, for both measurement intervals as well as statistics.

# Note:
  # Hourly statistics are calculated over all measurements following the hour of interest. 
  # This means that the hour '14' performs statistics over the time range 14:00:00 - 14:59:59.
  # The data will be fetched for the "time range INCLUDING the end date itself".
  # Time is in UTC! (so conversion to local time should be performed by the user)

# Restrictions:
  # Due to row number limits of Excel (1,048,576), it is advised to NOT request data for more than 1 year (525,949 minutes,)
  # You can only get statistics from variables that are marked as "Y"
  # The excel file is written in 3_Output, but quickly re-opened again within this script (to add statistics). Wait until the script finished.

# Resource use indication:
  # Downloading ALL (>200) variables for 1 year...
      # Takes approximately 1:15 hour
      # Saves about 160 MB of disk space of pure data in an excel sheet
      # Adds about   10 MB of disk space for day statistics
  # Downloading < 10 variables for a few months of data should take only a couple of minutes


## SET ENVIRONMENT
##############################################################################


# Prevents erroneous writing of data values in the end
options(digits = 15)

# Clean environment and set working directory
rm(list=ls())

if(!requireNamespace("easypackages")) install.packages("easypackages")
library(easypackages)
easypackages::packages(c("here", "httr", "jsonlite", "plyr", "dplyr", "tidyr", "lubridate", "openxlsx", "rstudioapi", "bioRad"), prompt = FALSE)

setwd(here::here())


# Load required libraries
source("Scripts/Functions/fetch_data.R") # API REQUEST FUNCTION
source("Scripts/Functions/aggregator.R")
source("Scripts/Functions/read_assess_and_combine_excel_sheets.R") # Combine all written sheets to prepare for day aggregates


## READ PARAMETER DATA. USER PREFERENCES (TIME RANGE + VARIABLE SELECTION) SHOULD BE INDICATED
##############################################################################

# Read input parameters (two options to make it generic for ',' and ';' separating csv files.
df_API_pars                          <- read.csv("Data/1_Input/API_request_parameters.csv", stringsAsFactors = F, sep=";", fileEncoding="latin1")
if(ncol(df_API_pars)==1){df_API_pars <- read.csv("Data/1_Input/API_request_parameters.csv", stringsAsFactors = F, sep=",", fileEncoding="latin1")}



## DEFINE 'API REQUEST VARIABLES' BEFORE APPROACHING THE SERVER 
##############################################################################


API_KEY             <- df_API_pars$API_key[1]   

# Check
if(API_KEY == "PUT_YOUR_API_KEY_STRING_HERE"){
  stop("You haven't placed your API KEY yet in the parameter file.")
} else { 
  print("String stored in the right location")
}


nr_defined_ranges   <- length(df_API_pars$Date_start[nchar(df_API_pars$Date_start) > 0])


for(i in 1:nr_defined_ranges){
  
  # Retrieve the date range and the selected variables
  FINAL_START      <- as.Date(df_API_pars$Date_start, format = "%Y__%m__%d")[i]
  FINAL_END        <- as.Date(df_API_pars$Date_end, format = "%Y__%m__%d")[i]
  
  # Create table for per-month request chunks
  tmp_dates        <- format(seq(as.Date("1990-01-13"), as.Date("2035-01-11"), by="days"), format="%Y-%m-%d")
  tmp_dates        <- tmp_dates[tmp_dates >= FINAL_START & tmp_dates <= FINAL_END + 1]
  yearmonths       <- paste0(year(tmp_dates), "_", month(tmp_dates))
  df_alldates      <- data.frame(
    date      = tmp_dates,
    yearmonth = yearmonths)
  rm(tmp_dates)
  
  # Depict what unique measurement intervals have been selected
  df_vars_sel      <- df_API_pars[df_API_pars$Var_selection == "Y",c("Var_name","Var_name_long","Unit","Frequency",
                                                                     "STATS_Day24","STATS_Daylight","STATS_Hour")]    
  variables        <- df_vars_sel$Var_name
  intervals        <- unique(df_vars_sel$Frequency)
  
  
  # Create folder location to store intermediate exports
  moment    <- substr(gsub(":", "", Sys.time() ),1, 17)
  moment    <- gsub("-","_", moment)
  moment    <- gsub(" ","_", moment)
  
  if(i==1){
    LOC     <- paste0(Sys.getenv("USERNAME"),"__", moment)
    dir.create(paste0("Data/2_Intermediate/", LOC))
  }
  
  LOC_SUB   <- paste0(  LOC, "/", gsub("-","", as.character(FINAL_START)), "_", gsub("-", "", as.character(FINAL_END) )  )
  dir.create(paste0("Data/2_Intermediate/", LOC_SUB))
  
  
  ## DO THE API REQUEST USING THE INPUT DEFINED ABOVE
  ##############################################################################
  
  
  # EXECUTE: API request / month / unique measurement interval
  for(YEARMONTH in unique(yearmonths)){
    
    print(paste("__________________________ ", YEARMONTH, " _____________________________" ))
    
    # SELECTION & SPLIT OF UNIQUE MONTHS IN INITIAL SELECTION
    DATES_YEARMONTH  <- df_alldates$date[df_alldates$yearmonth == YEARMONTH]
    DATE_START       <- as.Date(DATES_YEARMONTH)[1]
    DATE_END         <- as.Date(DATES_YEARMONTH[length(DATES_YEARMONTH)]) + 1
    
    for(INTERVAL in intervals){
      
      FILENAME       <- paste0("Data/2_Intermediate/", LOC_SUB, "/Veenkampen_", YEARMONTH, "__", INTERVAL, ".csv")
      
      # SELECTION OF VARIABLES BASED ON THEIR INTERVAL
      VARS_SEL       <- df_vars_sel$Var_name[df_vars_sel$Frequency == INTERVAL]
      
      fetch_data(DATE_START, DATE_END, 1, VARS_SEL, API_KEY, TRUE, FILENAME) 
      
    }
  }
  
}



## WRITE EXCEL FILE, SHEETS SPLIT PER MEASUREMENT INTERVAL
##############################################################################

# Where to store new excel file with metadata
XLSX_LOC    <- paste0("Data/3_Output/Export_Veenkampen___", LOC, ".xlsx")
wb          <- createWorkbook()
addWorksheet(wb, "Metadata Export")
addWorksheet(wb, "Metadata Variables")

# Write metadata
writeData(wb, 
          sheet = "Metadata Export", 
          c(paste0(  "<><><><><><><><><><><><><><><><><><><><><><><><><><>"                                          ),
            paste0(  "<><><><><><><><><><><><><><><><><><><><><><><><><><>"                                          ),
            paste0(  "<><><>    METADATA  -  Veenkampen API request"                                                 ),
            paste0(  "<><><>    CREATION DATE:    ", Sys.time()                                                      ),
            paste0(  "<><><>    CREATED BY:    ",    Sys.getenv("USERNAME")                                          ),
            paste0(  "<><><>    TIME RANGE:    ",    FINAL_START, " to ", FINAL_END                                  ),
            paste0(  "<><><>    VARIABLES SELECTED:    See 'Metadata Variables'"                                     ),
            paste0(  "<><><>    <><><><><><><><><><><><><><><><><><><><><>'"                                         ),
            paste0(  "<><><>    SHEETS:"                                                                             ),
            paste0(  "<><><>    Metadata Variables:    Selected variables"                                           ),
            paste0(  "<><><>    01min:    Data with 1 minute measurement interval"                                   ),
            paste0(  "<><><>    05min:    Data with 5 minute measurement interval"                                   ),
            paste0(  "<><><>    30min:    Data with 30 minute measurement interval"                                  ),
            paste0(  "<><><>    60min:    Data with 60 minute measurement interval"                                  ),
            paste0(  "<><><>    STATS_Hour:    Statistics of all variables, per hour"                                ),
            paste0(  "<><><>    STATS_Day24:    Statistics of all variables, for the entire day"                     ),
            paste0(  "<><><>    STATS_Daylight:    Statistics of all variables, from sunrise untill sunset"          ),
            paste0(  "<><><><><><><><><><><><><><><><><><><><><><><><><><>"                                          ),
            paste0(  "<><><><><><><><><><><><><><><><><><><><><><><><><><>"                                          )
          ) 
)
writeData(wb, sheet = "Metadata Variables", df_vars_sel) 

# Write excel file
if(file.exists(XLSX_LOC)){  file.remove(XLSX_LOC)  }
saveWorkbook(wb, XLSX_LOC, overwrite = TRUE)

# Function to add measurement intervals per excel sheet
write_weather_sheets <- function(PATTERN_MIN, FOLDER_LOC, XLSX_LOC){
  
  # Read files by their measurement interval
  files     <- list.files(FOLDER_LOC, full.names = T, pattern=PATTERN_MIN, recursive=T)
  
  if(length(files) > 0){
    DF      <- do.call(rbind.fill,  lapply(files, read.table, sep=";", header=T))
    DF      <- DF[!duplicated(DF),] # remove 1 extra value based at the overlap between months (00:00:00)

    # Remove the last row if it is the only record of that date (at 00:00:00)
    DF$Date              <- substr(DF$Timestamp, 1, 10)
    tmp                  <- table(DF$Date)
    last_date            <- names(tmp[length(tmp)])
    last_date_nr_records <- as.vector(tmp[length(tmp)])
    if(DF$Date[nrow(DF)] == last_date & last_date_nr_records == 1) {      DF <- DF[1:(nrow(DF)-1),]      }
    DF$Date              <- NULL
    rm(tmp)
    
    # Put data in a single Excel sheet
    wb      <- loadWorkbook(XLSX_LOC)
    addWorksheet(wb, PATTERN_MIN)
    writeData(wb, sheet = PATTERN_MIN, DF)
    saveWorkbook(wb, XLSX_LOC, overwrite = TRUE)
    
  } else {
    
    # Write empty sheet
    wb <- loadWorkbook(XLSX_LOC)
    addWorksheet(wb, PATTERN_MIN)
    writeData(wb, sheet = PATTERN_MIN, NA)
    saveWorkbook(wb, XLSX_LOC, overwrite = TRUE)
  }
}

# Write data to excel file into the corresponding sheet
write_weather_sheets("01min", paste0("Data/2_Intermediate/", LOC), XLSX_LOC)
write_weather_sheets("05min", paste0("Data/2_Intermediate/", LOC), XLSX_LOC)
write_weather_sheets("30min", paste0("Data/2_Intermediate/", LOC), XLSX_LOC)
write_weather_sheets("60min", paste0("Data/2_Intermediate/", LOC), XLSX_LOC)


## ADD DAILY AGGREGATES TO EXCEL FILE
##############################################################################


# Read the data
options(warn=-1) # Entire function designed for the optionality of having empty sheet names, so ignore warning.
df_exp       <- read_excel_weather(XLSX_LOC, c("01min", "05min", "30min", "60min"))
options(warn=0)

# Retrieve weather variables
VARS         <- colnames(df_exp[,2:ncol(df_exp)])

# Add time variables and ensure the data begins with this
df_exp$Date           <- substr(  df_exp$Timestamp, 1,  10)
df_exp$Year           <- substr(  df_exp$Timestamp, 1,   4)
df_exp$Month          <- substr(  df_exp$Timestamp, 6,   7)
df_exp$Day            <- substr(  df_exp$Timestamp, 9,  10)
df_exp$Hour           <- substr(  df_exp$Timestamp, 12, 13)
df_exp$Min            <- substr(  df_exp$Timestamp, 15, 16)
df_exp$Time           <- round(as.numeric(df_exp$Hour) + as.numeric(df_exp$Min)/60, 3)

# Make selection for daytime, defined as time between sunset and sunrise.
# Location (LON,LAT) is based on Veenkampen weather station.
df_exp$Sunrise        <- sunrise( df_exp$Date, 5.62048, 51.98133, elev = -0.268, tz = "UTC", force_tz = T)
df_exp$Sunset         <- sunset(  df_exp$Date, 5.62048, 51.98133, elev = -0.268, tz = "UTC", force_tz = T)
df_exp$Sunrise_hour   <- round(as.numeric(substr(df_exp$Sunrise, 12,13)) + as.numeric(substr(df_exp$Sunrise, 15,16))/60 + as.numeric(substr(df_exp$Sunrise, 18,19))/3600,3)
df_exp$Sunset_hour    <- round(as.numeric(substr(df_exp$Sunset, 12,13)) + as.numeric(substr(df_exp$Sunset, 15,16))/60 + as.numeric(substr(df_exp$Sunset, 18,19))/3600,3)
df_exp$Daylength_hour <- df_exp$Sunset_hour - df_exp$Sunrise_hour
df_exp$daytime        <- df_exp$Time >= df_exp$Sunrise_hour & df_exp$Time <= df_exp$Sunset_hour

df_exp_daytime        <- df_exp[df_exp$daytime == T,]

# Function to select only statistics as depicted by the user
statistics_keeper <- function(DF, AGG_COL){
  for(i in 1:length(variables)){
    tmp  <- strsplit(DF[,AGG_COL], split=",")[[i]]
    tmp  <- paste0(DF[,"Var_name"][i], "__", tmp)
    if(i == 1){
      colnames_stats <- tmp
    } else {
      colnames_stats <- c(colnames_stats, tmp)
    }
  }
  colnames_stats <- colnames_stats[!grepl("__$", colnames_stats)]
  return(colnames_stats)
}

# Define statistics for entire day, daytime, and per hour
ALLSTATS        <- c("count", "min", "median", "max", "mean", "sd", "sum")
TIME_GROUPS     <- c("Date", "Year", "Month", "Day")
df_date         <- aggregator(df_exp,         VARS, c(TIME_GROUPS, "Daylength_hour"),                                ALLSTATS, all=F, casted=T)
df_date_daytime <- aggregator(df_exp_daytime, VARS, c(TIME_GROUPS, "Daylength_hour", "Sunrise_hour", "Sunset_hour"), ALLSTATS, all=F, casted=T)
df_date_hour    <- aggregator(df_exp,         VARS, c(TIME_GROUPS, "Hour"),                                          ALLSTATS, all=F, casted=T)

# Remove undesired statistics
df_date         <- df_date[,         c(TIME_GROUPS, "Daylength_hour",                               statistics_keeper(df_vars_sel, "STATS_Day24")    )]
df_date_daytime <- df_date_daytime[, c(TIME_GROUPS, "Daylength_hour","Sunrise_hour", "Sunset_hour", statistics_keeper(df_vars_sel, "STATS_Daylight") )]
df_date_hour    <- df_date_hour[,    c(TIME_GROUPS, "Hour",                                         statistics_keeper(df_vars_sel, "STATS_Hour")     )]

# Order the dataframes by time
df_date         <- df_date[order(df_date$Date),]
df_date_daytime <- df_date_daytime[order(df_date_daytime$Date),]
df_date_hour    <- df_date_hour[order(df_date_hour$Date),]

# Write data in single Excel sheets
wb <- loadWorkbook(XLSX_LOC)

addWorksheet(wb,      "STATS_Day24")
writeData(wb, sheet = "STATS_Day24",    df_date)
addWorksheet(wb,      "STATS_Daylight")
writeData(wb, sheet = "STATS_Daylight", df_date_daytime)
addWorksheet(wb,      "STATS_Hour")
writeData(wb, sheet = "STATS_Hour",     df_date_hour)

saveWorkbook(wb, XLSX_LOC, overwrite = TRUE)



