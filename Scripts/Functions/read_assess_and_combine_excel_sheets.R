# Function that generically checks for sheet name existence before trying to rbinding them.
read_excel_weather <- function(XLSX_LOC, SHEET_NAMES = c("01min", "05min", "30min", "60min") ){
  
  sheet_names <- SHEET_NAMES
  
  # Read all sheets into a list, checking if the data is a data.frame and not empty
  sheets_list <- lapply(sheet_names, function(sheet) {
    # Try reading the sheet and handle errors gracefully
    tmp <- tryCatch({
      read.xlsx(xlsxFile = XLSX_LOC, sheet = sheet)
    }, error = function(e) {
      # If an error occurs (e.g., sheet doesn't exist), return NULL
      return(NULL)
    })
    
    # Check if tmp is a data frame and if it has rows
    if (is.data.frame(tmp) && nrow(tmp) > 0) {
      return(tmp)
    } else {
      return(NULL)
    }
  })
  
  # Filter out NULL elements (empty or non-existent sheets)
  sheets_list <- Filter(Negate(is.null), sheets_list)
  
  # Combine the non-empty data frames
  result <- do.call(rbind.fill, sheets_list)
  
  return(result)
}
