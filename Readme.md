# Veenkampen Weather API Downloader

This project downloads weather data from the Veenkampen weather station application programming interface (API). The user defines the date range, variables, and desired summary statistics in a parameter file. The script then downloads the selected data, stores intermediate files, and writes a final Microsoft Excel workbook (XLSX).

## Goal

The goal of this script is to make Veenkampen weather data exports reproducible and easy to configure.

The script can:
* Download selected weather variables
* Handle one or more date ranges
* Split raw data by measurement interval
* Calculate hourly, daily, and daylight-period statistics
* Write all results to one XLSX file

## Project structure

```text
.
├── .here
├── README.md
├── Scripts/
│   ├── 005_Download_Weather_Veenkampen.R
│   └── Functions/
└── Data/
    ├── 1_Input/
    │   └── API_request_parameters.csv
    ├── 2_Intermediate/
    └── 3_Output/
```

The `.here` file marks the project root. The script uses `here::here()` so it can be run without relying on RStudio.

## Input

The script uses two input components:

```text
Data/1_Input/API_request_parameters.csv
Data/1_Input/API_KEY/api_key.txt
```

The parameter file contains the date range, selected variables, measurement frequencies, and requested statistics.

The application programming interface (API) key is stored separately in:

```text
Data/1_Input/API_KEY/api_key.txt
```

This file should contain only the API key, on one line, without quotes.

Example structure:

```text
Data/
└── 1_Input/
    ├── API_request_parameters.csv
    └── API_KEY/
        └── api_key.txt
```

Do not commit your real API key to GitHub. The folder `Data/1_Input/API_KEY/` is ignored by Git, except for an optional `.gitkeep` file that keeps the folder visible in the repository.

Dates in `API_request_parameters.csv` should use this format:

```text
YYYY__MM__DD
```

Example:

```text
2024__03__23
```


Do not commit a real API key to GitHub. Prefer committing an example parameter file and keeping the real file private.

## Running the script

From R:
```r
source("Scripts/main_download_script.R")
```

From the command line:
```bash
Rscript Scripts/main_download_script.R
```

The script creates intermediate comma-separated values (CSV) files during the download and then combines them into the final XLSX file.

## Output

Intermediate files are written to:
```text
Data/2_Intermediate/
```

The final XLSX export is written to:
```text
Data/3_Output/
```

The workbook contains metadata, raw data sheets for the available measurement intervals, and statistics sheets when requested.

## Statistics

The script can calculate statistics per:

* hour
* full day
* daylight period

Daylight is calculated from sunrise and sunset times at the Veenkampen weather station location.

All timestamps from the API are in Coordinated Universal Time (UTC). Convert them separately if local time is needed.

## Notes and limitations

Large requests can take a long time. Downloading many variables for long periods may also cause server timeout errors.

Microsoft Excel has a row limit of 1,048,576 rows per sheet. For high-frequency data, avoid requesting too long a period in one export.

If a timeout occurs, rerun the script or reduce the number of variables or the length of the requested period.

## Recommended `.gitignore`

```text
Data/1_Input/API_request_parameters.csv
Data/2_Intermediate/
Data/3_Output/
*.xlsx
.Rhistory
.RData
.Rproj.user/
```

Commit an example input file instead, for example:
```text
Data/1_Input/API_request_parameters_example.csv
```
