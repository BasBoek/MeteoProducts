

aggregator <- function(data, VOIs, GOIs, ALLFUNC = 'mean', all = FALSE, casted = FALSE) {

  sort_df <- function(data, colnames){
    for(i in length(colnames):1){
      if(i == length(colnames)){
        new_df <- data[,c(which(colnames(data)==colnames[i]), which(colnames(data)!=colnames[i]))]
      } else {      new_df <- new_df[,c(which(colnames(new_df)==colnames[i]), which(colnames(new_df)!=colnames[i]))]    }}
    return(new_df)
  }
  
  NA_maker <- function(DF) {
    
    DF[] <- lapply(DF, function(x) {
      x[x == -Inf | x == Inf | is.nan(x)] <- NA
      return(x)
    })
    
    return(DF)
  }
  

  
  # Convert factors to characters
  data[] <- lapply(data, function(x) if (is.factor(x)) as.character(x) else x)
  
  if (all && length(GOIs) == 1) {
    warning("Ignoring 'all=TRUE'. Only 1 group given")
  }
  
  options(warn=-1) # Get rid of -Inf warnings
  
  
  if (length(ALLFUNC) == 2 && ALLFUNC[1] == 'quantile') {
    ALLFUNC <- list(ALLFUNC)
  }
  
  for (FUNC_index in 1:length(ALLFUNC)) {
    
    FUNC <- ALLFUNC[[FUNC_index]][1]
    
    # Prepare lists for group and value columns
    GRP_list <- lapply(GOIs, function(goi) data[[goi]])
    VAR_list <- lapply(VOIs, function(voi) data[[voi]])
    
    # Clean the data to avoid Inf, -Inf, and NaN before aggregation
    clean_data <- function(x) {
      x[is.infinite(x) | is.nan(x)] <- NA
      return(x)
    }
    
    # Apply the clean_data function to the variables of interest
    VAR_list <- lapply(VAR_list, clean_data)
    
    
    # Creating newdata for a specific function
    if (FUNC != 'count') {
      if (FUNC != "quantile") {
        
        # Base aggregation function for mean / min / max / median / sd
        newdata     <- aggregate(VAR_list, by = GRP_list, FUN = FUNC, na.rm = TRUE)
        
      } else {
        
        # Base aggregation function for 'quantile'
        newdata     <- aggregate(VAR_list, by = GRP_list, FUN = FUNC, na.rm = TRUE, probs = as.numeric(ALLFUNC[[FUNC_index]][2]) / 100)
        
      }
      
    } else {
      
      # Base aggregation function for 'count'
      summarization  <- function(x) sum(!is.na(x))  # Count non-NA values
      newdata        <- aggregate(VAR_list, by = GRP_list, FUN = summarization)
      
    }

    # Make column names neat
    FUNC_final       <- paste(as.character(ALLFUNC[[FUNC_index]]), collapse = '')
    newdata$Function <- FUNC_final
    newdata          <- newdata[, c("Function", setdiff(names(newdata), "Function"))] # Ensure 'Function' is the first column
    names(newdata)   <- c("Function", GOIs, VOIs)
    
    # Check for NA when calculating standard deviation
    if (FUNC_final == 'sd') {
      NA_data <- newdata[is.na(newdata[ncol(newdata)]), ]
      if (nrow(NA_data) > 0) {
        warning(paste0("Only 1 data entry present for ", nrow(NA_data), " group combinations. Calculation of sd not possible: Returning NA"))
      }
    }
    
    # Add all combinations for 'all = TRUE'
    if (all && length(GOIs) > 1) {
      existing_combs    <- nrow(newdata)
      combs             <- lapply(GOIs, function(goi) unique(newdata[[goi]]))
      ALLCOMB           <- expand.grid(combs)
      names(ALLCOMB)    <- GOIs
      
      if (FUNC_final == 'count') {
        ALLCOMB[(length(GOIs) + 1):(length(GOIs) + length(VOIs))] <- 0
      } else {
        ALLCOMB[(length(GOIs) + 1):(length(GOIs) + length(VOIs))] <- NA
      }
      
      ALLCOMB$Function  <- FUNC_final
      ALLCOMB           <- ALLCOMB[, c("Function", setdiff(names(ALLCOMB), "Function"))]
      colnames(ALLCOMB) <- c("Function", GOIs, VOIs)
      
      newdata           <- rbind(newdata, ALLCOMB)
      newdata$doubles   <- duplicated(newdata[, GOIs])
      newdata           <- newdata[!newdata$doubles, ]
      newdata$doubles   <- NULL
      added_combs       <- nrow(newdata) - existing_combs
      
      if (FUNC_index == 1) {
        print(paste0(added_combs, " of the ", nrow(newdata), " possible unique group combinations were not present"))
      }
    }
    
    # Combine data from multiple functions
    if (FUNC_index == 1) {
      allnewdata <- newdata
    } else {
      allnewdata <- rbind(allnewdata, newdata)
    }
  }
  
  # Reset row names
  rownames(allnewdata) <- NULL
  
  # # Remove 'Function' column if COLFUNC is FALSE
  # if (!COLFUNC) {
  #   allnewdata$Function <- NULL
  # }
  
  # Remove all -Inf's, Inf's and NA's
  allnewdata <- NA_maker(allnewdata)
  
  options(warn=0)  # Turn warnings on again
  
  # Cast the data
  if(casted == T){

      allnewdata <- reshape(allnewdata, 
                            idvar     = GOIs,  
                            timevar   = c("Function"),
                            direction = "wide", sep = "__"
      )
      allnewdata <- sort_df(allnewdata, c(GOIs, sort(colnames(allnewdata)) ) )

  }

  return(allnewdata)
}


# aggregator <- function(data, VOIs, GOIs, ALLFUNC = 'mean', all = FALSE, COLFUNC = FALSE, melted = FALSE) {
#   
#   # Convert factors to characters
#   data[] <- lapply(data, function(x) if (is.factor(x)) as.character(x) else x)
#   
#   if (all && length(GOIs) == 1) {
#     warning("Ignoring 'all=TRUE'. Only 1 group given")
#   }
#   
#   if (length(ALLFUNC) == 2 && ALLFUNC[1] == 'quantile') {
#     ALLFUNC <- list(ALLFUNC)
#   }
#   
#   # Clean the data to avoid Inf, -Inf, and NaN before aggregation
#   clean_data <- function(x) {
#     x[is.infinite(x) | is.nan(x)] <- NA
#     return(x)
#   }
#   
#   for (FUNC_index in 1:length(ALLFUNC)) {
#     
#     FUNC <- ALLFUNC[[FUNC_index]][1]
#     
#     # Prepare lists for group and value columns
#     GRP_list <- lapply(GOIs, function(goi) data[[goi]])
#     VAR_list <- lapply(VOIs, function(voi) data[[voi]])
#     
#     # Apply the clean_data function to the variables of interest
#     VAR_list <- lapply(VAR_list, clean_data)
#     
#     # Remove rows with any NA in group variables (GOIs)
#     clean_rows <- complete.cases(data[GOIs]) 
#     data_cleaned <- data[clean_rows, ]
#     
#     # Clean group and variable lists
#     GRP_list_cleaned <- lapply(GOIs, function(goi) data_cleaned[[goi]])
#     VAR_list_cleaned <- lapply(VOIs, function(voi) data_cleaned[[voi]])
#     
#     # Creating newdata for a specific function
#     if (FUNC != 'count') {
#       if (FUNC != "quantile") {
#         
#         # Base aggregation function for mean / min / max / median / sd
#         newdata <- aggregate(VAR_list_cleaned, by = GRP_list_cleaned, FUN = FUNC, na.rm = TRUE)
#         
#       } else {
#         
#         # Base aggregation function for 'quantile'
#         newdata <- aggregate(VAR_list_cleaned, by = GRP_list_cleaned, 
#                              FUN = function(x) quantile(x, probs = as.numeric(ALLFUNC[[FUNC_index]][2]) / 100, na.rm = TRUE))
#         
#       }
#       
#     } else {
#       
#       # Base aggregation function for 'count'
#       summarization <- function(x) sum(!is.na(x))  # Count non-NA values
#       newdata <- aggregate(VAR_list_cleaned, by = GRP_list_cleaned, FUN = summarization)
#       
#     }
#     
#     # Make column names neat
#     FUNC_final <- paste(as.character(ALLFUNC[[FUNC_index]]), collapse = '')
#     newdata$Function <- FUNC_final
#     newdata <- newdata[, c("Function", setdiff(names(newdata), "Function"))] # Ensure 'Function' is the first column
#     names(newdata) <- c("Function", GOIs, VOIs)
#     
#     # Check for NA when calculating standard deviation
#     if (FUNC_final == 'sd') {
#       NA_data <- newdata[is.na(newdata[ncol(newdata)]), ]
#       if (nrow(NA_data) > 0) {
#         warning(paste0("Only 1 data entry present for ", nrow(NA_data), " group combinations. Calculation of sd not possible: Returning NA"))
#       }
#     }
#     
#     # Add all combinations for 'all = TRUE'
#     if (all && length(GOIs) > 1) {
#       existing_combs <- nrow(newdata)
#       combs <- lapply(GOIs, function(goi) unique(newdata[[goi]]))
#       ALLCOMB <- expand.grid(combs)
#       names(ALLCOMB) <- GOIs
#       
#       if (FUNC_final == 'count') {
#         ALLCOMB[(length(GOIs) + 1):(length(GOIs) + length(VOIs))] <- 0
#       } else {
#         ALLCOMB[(length(GOIs) + 1):(length(GOIs) + length(VOIs))] <- NA
#       }
#       
#       ALLCOMB$Function <- FUNC_final
#       ALLCOMB <- ALLCOMB[, c("Function", setdiff(names(ALLCOMB), "Function"))]
#       colnames(ALLCOMB) <- c("Function", GOIs, VOIs)
#       
#       newdata <- rbind(newdata, ALLCOMB)
#       newdata$doubles <- duplicated(newdata[, GOIs])
#       newdata <- newdata[!newdata$doubles, ]
#       newdata$doubles <- NULL
#       added_combs <- nrow(newdata) - existing_combs
#       
#       if (FUNC_index == 1) {
#         print(paste0(added_combs, " of the ", nrow(newdata), " possible unique group combinations were not present"))
#       }
#     }
#     
#     # Combine data from multiple functions
#     if (FUNC_index == 1) {
#       allnewdata <- newdata
#     } else {
#       allnewdata <- rbind(allnewdata, newdata)
#     }
#   }
#   
#   # Reset row names
#   rownames(allnewdata) <- NULL
#   
#   # Remove 'Function' column if COLFUNC is FALSE
#   if (!COLFUNC) {
#     allnewdata$Function <- NULL
#   }
#   
#   return(allnewdata)
# }




###### ORIGINAL
# aggregator <- function(data, VOIs, GOIs, ALLFUNC='mean', all=F, COLFUNC = F, melted=F){
# 
#   VAR_list <- GRP_list <- list()
#   data[sapply(data, is.factor)] <- lapply(data[sapply(data, is.factor)], as.character)
# 
#   if(all == T & length(GOIs) == 1){ warning("Ignoring 'all=T'. Only 1 group given") }
# 
#   if(length(ALLFUNC) == 2 & ALLFUNC[1] == 'quantile'){ALLFUNC <- list(ALLFUNC)}
# 
#   for(FUNC_index in 1:length(ALLFUNC)){
# 
#     FUNC <- ALLFUNC[[FUNC_index]][1]
# 
#     for(i in 1:length(GOIs)){  GRP_list[[i]] <- data[[GOIs[i]]]}
#     for(i in 1:length(VOIs)){  VAR_list[[i]] <- data[[VOIs[i]]]}
#     # GRP_list <- GRP_list
#     if(FUNC != 'count'){
#       if(FUNC != "quantile" ){newdata <- aggregate(VAR_list, by=GRP_list, FUN=FUNC, na.rm=T)} else {newdata <- aggregate(VAR_list, by=GRP_list, FUN=FUNC, na.rm=T, probs=as.numeric(ALLFUNC[[FUNC_index]][2])/100)}
#     } else {
#       newsum  <- aggregate(VAR_list, by=GRP_list, FUN='sum', na.rm=T)
#       newavg  <- aggregate(VAR_list, by=GRP_list, FUN='mean', na.rm=T)
#       newdata <- as.data.frame(cbind(newsum[,1:(ncol(newsum)-length(VOIs))],(newsum[,(ncol(newsum)-length(VOIs)+1):ncol(newsum)])/(newavg[,(ncol(newavg)-length(VOIs)+1):ncol(newavg)])), stringsAsFactors = F)
#     }
#     FUNC_final       <- paste(as.character(ALLFUNC[[FUNC_index]]), collapse='')
#     newdata$Function <- FUNC_final
#     newdata          <- newdata[,c(which(colnames(newdata)=="Function"), which(colnames(newdata)!="Function"))]
#     names(newdata)   <- c("Function", GOIs, VOIs)
#     # newdata          <-  newdata # REMOVE WHEN DONE
# 
#     if(FUNC_final == 'sd'){
#       NA_data <- newdata[is.na(newdata[length(newdata)]),]
#       if(nrow(NA_data) > 0){ warning(paste0("Only 1 data entry present for ", nrow(NA_data), " group combinations. Calculation of sd not possible: Returning NA"))}
#     }
# 
#     if(all == T & length(GOIs) > 1){ # Add lines for all combinations when preferred
#       existing_combs    <- nrow(newdata)
#       combs             <- list()
#       for(i in 1:length(GOIs)){  combs[[i]] <- unique(newdata[,GOIs[i]]) }
#       ALLCOMB           <- expand.grid(combs)
#       names(ALLCOMB)    <- GOIs
# 
#       if(FUNC_final == 'count'){
#         ALLCOMB[(length(GOIs) + 1):(length(GOIs)+length(VOIs))] <- 0
#       } else {
#         ALLCOMB[(length(GOIs) + 1):(length(GOIs)+length(VOIs))] <- NA
#       }
#       ALLCOMB$Function  <- FUNC_final
#       ALLCOMB           <- ALLCOMB[, c(which(colnames(ALLCOMB)=="Function"), which(colnames(ALLCOMB)!="Function"))]
#       colnames(ALLCOMB) <- c("Function", GOIs,VOIs)
#       newdata           <- rbind(newdata, ALLCOMB)
#       newdata$doubles   <- duplicated(newdata[,GOIs])
#       newdata           <- newdata[newdata$doubles == F,]
#       newdata$doubles   <- NULL
#       added_combs       <- nrow(newdata) - existing_combs
#       if(FUNC_index == 1){print(paste0(added_combs, " of the ", nrow(newdata), " possible unique group combinations were not present"))}
#     }
#     if(FUNC_index == 1){      allnewdata <- newdata    } else { allnewdata <- rbind(allnewdata, newdata)}
#   }
#   rownames(allnewdata) <- c()
# 
#   if(COLFUNC == F){
#     allnewdata[,"Function"] <- NULL
#   }
# 
#   
#   
#   # if (melted) {
#   #   
#   #   # Reshape from wide to long format
#   #   allnewdata <- reshape(allnewdata, 
#   #                         varying   = VOIs, 
#   #                         idvar     = "Function",
#   #                         v.names   = "Value", 
#   #                         timevar   = "Variable", 
#   #                         times     = VOIs, 
#   #                         direction = "long")
#   #   
#   #   rownames(allnewdata) <- NULL  # Remove row names
#   #   # allnewdata$id        <- NULL
#   # }
#   
# 
#   
#   return(allnewdata)
# }


# aggregator <- function(data, VOIs, GOIs, ALLFUNC = 'mean', all = FALSE, COLFUNC = FALSE) {
#   data[sapply(data, is.factor)] <- lapply(data[sapply(data, is.factor)], as.character)
# 
#   if (all == TRUE & length(GOIs) == 1) warning("Ignoring 'all=TRUE'. Only 1 group given")
# 
#   results <- list()
# 
#   for (func_item in ALLFUNC) {
# 
#     func <- if (is.list(func_item)) func_item[[1]] else func_item
# 
#     if (func == "quantile" && is.list(func_item)) {
#       prob <- as.numeric(func_item[[2]]) / 100
#       summarization <- function(x) quantile(x, probs = prob, na.rm = TRUE)
#     } else if (func == "count") {
#       summarization <- function(x) sum(!is.na(x))
#     } else {
#       summarization <- match.fun(func)
#     }
# 
#     newdata <- aggregate(data[VOIs], by = data[GOIs], FUN = summarization, na.rm = TRUE)
#     newdata$Function <- paste(func_item, collapse = "")
# 
#     if (all == TRUE && length(GOIs) > 1) {
#       group_combinations <- do.call(expand.grid, lapply(GOIs, function(col) unique(data[[col]])))
#       newdata <- merge(group_combinations, newdata, by = GOIs, all.x = TRUE)
#     }
# 
#     results[[length(results) + 1]] <- newdata
#   }
# 
#   final_data <- do.call(rbind, results)
#   if (!COLFUNC) final_data$Function <- NULL
# 
#   return(final_data)
# }



# aggregator <- function(data, VOIs, GOIs, ALLFUNC = 'mean', all = FALSE, COLFUNC = FALSE) {
#   data[sapply(data, is.factor)] <- lapply(data[sapply(data, is.factor)], as.character)
#   
#   if (all == TRUE & length(GOIs) == 1) warning("Ignoring 'all=TRUE'. Only 1 group given")
#   
#   results <- list()
#   
#   for (func_item in ALLFUNC) {
#     func <- if (is.list(func_item)) func_item[[1]] else func_item
#     
#     if (func == "quantile" && is.list(func_item)) {
#       prob          <- as.numeric(func_item[[2]]) / 100
#       summarization <- function(x) ifelse(length(na.omit(x)) > 0, quantile(x, probs = prob, na.rm = TRUE), NA)
#     } else if (func == "count") {
#       summarization <- function(x) round(sum(!is.na(x)))
#     } else {
#       summarization <- function(x) ifelse(length(na.omit(x)) > 0, match.fun(func)(x, na.rm = TRUE), NA)
#     }
#     
#     newdata <- aggregate(data[VOIs], by = data[GOIs], FUN = summarization)
#     newdata$Function <- paste(func_item, collapse = "")
#     
#     # Reorder columns to ensure "Function" is first
#     newdata <- newdata[, c("Function", GOIs, VOIs)]
#     
#     if (all == TRUE && length(GOIs) > 1) {
#       group_combinations <- do.call(expand.grid, lapply(GOIs, function(col) unique(data[[col]])))
#       newdata <- merge(group_combinations, newdata, by = GOIs, all.x = TRUE)
#       
#       # Reorder again after merging
#       newdata <- newdata[, c("Function", GOIs, VOIs)]
#     }
#     
#     results[[length(results) + 1]] <- newdata
#   }
#   
#   final_data <- do.call(rbind, results)
#   
#   if (!COLFUNC) final_data$Function <- NULL
#   
#   return(final_data)
# }







