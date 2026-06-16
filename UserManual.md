## Set-up

Follow these steps before running the script.

### Step 1: Get access to the Veenkampen API

To download data, you need a valid Veenkampen application programming interface (API) key.

Ask the Veenkampen API provider, data manager, or project administrator for access. The script does not create an API key itself; it only uses an existing key.

### Step 2: Copy the input example

Use the example input file as a template:

```text
Data/1_Input/API_request_parameters_example.csv
```

Copy it and rename the copy to:

```text
Data/1_Input/API_request_parameters.csv
```

This is the file that the script reads.

### Step 3: Add your API key

Open:

```text
Data/1_Input/API_request_parameters.csv
```

Find the column:

```text
API_key
```

Replace:

```text
PUT_YOUR_API_KEY_STRING_HERE
```

with your real API key.

The script reads the API key from the first row of this column. If the placeholder is still present, the script stops.

Do not commit the real API key to GitHub.

### Step 4: Fill in the date range

Use the columns:

```text
Date_start
Date_end
```

Dates should be written as:

```text
YYYY__MM__DD
```

Example:

```text
2024__01__01
```

You can define more than one date range by filling in multiple rows.

The script downloads data including the end date itself.

### Step 5: Select the variables

Use the column:

```text
Var_selection
```

Set a variable to:

```text
Y
```

if it should be downloaded.

Leave it empty, or use another value, if the variable should not be downloaded.

Each selected row should also contain the variable information used by the script:

```text
Var_name
Var_name_long
Unit
Frequency
```

The `Frequency` column tells the script which measurement interval the variable belongs to, for example:

```text
01min
05min
30min
60min
```

### Step 6: Choose the statistics

The script can calculate statistics for three time periods:

```text
STATS_Hour
STATS_Day24
STATS_Daylight
```

Fill these columns with the statistics you want for each variable.

Available statistics are:

```text
count,min,median,max,mean,sd,sum
```

Use comma-separated values without spaces.

Example:

```text
mean,sd,min,max
```

Only selected variables can be used for statistics.

### Step 7: Save the file

Save the completed file as:

```text
Data/1_Input/API_request_parameters.csv
```

Then run the script.

From R:

```r
source("Scripts/main_download_script.R")
```

From the command line:

```bash
Rscript Scripts/main_download_script.R
```

### Step 8: Check the output

Intermediate files are written to:

```text
Data/2_Intermediate/
```

The final Excel workbook is written to:

```text
Data/3_Output/
```

If a download fails with a timeout, reduce the date range or the number of selected variables and run the script again.
