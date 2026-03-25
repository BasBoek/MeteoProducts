# Function that connects to the Veenkampen Weather server
fetch_data <- function(start_date, end_date, site, variables, API_KEY, save_file, save_filename) {
  
  HOST_KL  <- 'https://maq-observations.nl'
  headers  <- add_headers(
    Accept         = 'application/json',
    Authorization  = paste('ApiKey', API_KEY),
    'Content-Type' = 'application/json'
  )
  
  # Format dates
  start_date_str    <- format(as.Date(start_date), '%Y-%m-%d')
  end_date_str      <- format(as.Date(end_date),   '%Y-%m-%d')
  
  # Fetch metadata (variables)
  metadata_url      <- paste0(HOST_KL, '/wp-json/maq/v1/sites/', site, '/stations/', site, '/streams')
  response_metadata <- GET(metadata_url, headers)
  
  if (status_code(response_metadata) == 200) {
    data_metadata   <- fromJSON(content(response_metadata, as = 'text'))
    df_metadata     <- as.data.frame(data_metadata$streams)
    df_filtered     <- df_metadata %>% filter(name %in% variables)
    
    # Check if any variables were retrieved
    if (nrow(df_filtered) == 0) {
      cat("No matching variables found in metadata.\n")
      return(NULL)
    }
    
    # Collect data for each variable
    all_data <- list()
    
    for (variable_name in variables) {
      stream_id <- df_filtered %>% filter(name == variable_name) %>% pull(id)
      
      if (length(stream_id) == 0) {
        cat("Variable not found:", variable_name, "\n")
        next
      }
      
      data_url <- paste0(HOST_KL, '/wp-json/maq/v1/streams/', stream_id, "/measures?from=", start_date_str, "&to=", end_date_str)
      cat("Processing variable", variable_name, "\n")
      
      data_response <- GET(data_url, headers)
      
      if (status_code(data_response) == 200) {
        data_content <- fromJSON(content(data_response, as = 'text'))
        
        # Check if measures are present and non-empty
        if (!is.null(data_content$measures) && length(data_content$measures) > 0) {
          df <- as.data.frame(data_content$measures)
          
          if (nrow(df) > 0) {
            df$variable <- variable_name
            all_data[[variable_name]] <- df
          } else {
            cat("No data returned for variable:", variable_name, "\n")
          }
        } else {
          cat("No measures available for variable:", variable_name, "\n")
        }
        
      } else {
        cat("Failed to retrieve data for variable", variable_name, "HTTP Status code:", status_code(data_response), "\n")
      }
    }
    
    # Combine all collected data
    if (length(all_data) > 0) {
      final_df <- bind_rows(all_data)
      final_df <- final_df %>% select(timestamp, variable, value)
      final_df <- spread(final_df, variable, value)
      
      # Rename timestamp column
      colnames(final_df)[1] <- "Timestamp"
      
      # Make sure there are no extra dates included in the export
      final_df$Date <- as.Date(substr(final_df$Timestamp, 1, 10))
      final_df      <- final_df[final_df$Date <= end_date_str,]
      final_df$Date <- NULL

      # Print a sample of the data
      print(head(final_df))
      
      if (save_file) {
        write.table(format(final_df, scientific = FALSE, trim = TRUE), file = save_filename, row.names = FALSE, sep = ";", quote = FALSE)
        cat("Data successfully saved to", save_filename, "\n")
      } else {
        return(final_df)
      }
    } else {
      cat("No data was retrieved for the specified variables and date range.\n")
    }
  } else {
    cat("Failed to retrieve metadata. HTTP Status code:", status_code(response_metadata), "\n")
  }
}
