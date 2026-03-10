# CaliBin

**CaliBin** is an R Shiny app for processing breath-by-breath metabolic data exported from the [Calibre](https://www.calibre.com) system. It bins raw breath-by-breath data into user-defined time windows (default: 15 seconds), lets you inspect both raw and binned variables visually, and exports the results as a clean CSV.

---

## Features

- **Automatic file detection** — drop CSV files into the `raw_data/` folder and the app lists them instantly on launch
- **Adjustable bin size** — defaults to 15-second bins, configurable from 1–600 seconds
- **Column selection** — choose exactly which variables to include in the binned output and plots
- **Raw data viewer** — click through breath-by-breath plots of all selected numeric variables to inspect data quality before processing
- **Binned data viewer** — click through the same variables after averaging to confirm the output looks correct
- **Data table preview** — scrollable, paginated table of the binned output before saving
- **Summary cards** — at-a-glance display of raw breath count, number of bins, column count, and total recording duration
- **Clean output** — saves binned files to a separate `binned_data/` folder with a prefixed filename (e.g. `15_sec_yourfile.csv`)

---

## Folder Structure

Place `app.R` in a project folder and create a `raw_data/` subfolder alongside it. The app will automatically create `binned_data/` on first save.

```
your_project/
├── app.R
├── README.md
├── raw_data/           ← place your raw Calibre CSV exports here
│   ├── participant_01.csv
│   └── participant_02.csv
└── binned_data/        ← created automatically on first save
    ├── 15_sec_participant_01.csv
    └── 15_sec_participant_02.csv
```

> ⚠️ Keep only **raw** breath-by-breath files in `raw_data/`. Do not place previously binned output files back in this folder, as they will appear in the file list and produce meaningless results.

---

## Requirements

**R version:** 4.0 or higher

**R packages:**

| Package | Purpose |
| `shiny` | App framework |
| `shinythemes` | UI theme (flatly) |
| `dplyr` | Data manipulation |
| `readr` | CSV reading/writing |
| `ggplot2` | Plotting |
| `DT` | Interactive data table |

Install all dependencies at once:

```r
install.packages(c("shiny", "shinythemes", "dplyr", "readr", "ggplot2", "DT"))
```

---

## Getting Started

1. Clone or download this repository
2. Place your raw Calibre CSV exports into the `raw_data/` folder
3. Open `app.R` in RStudio and click **Run App**, or launch from the terminal:

```r
shiny::runApp("path/to/your_project")
```

---

## Workflow

### 1. Load a File
The sidebar automatically lists all CSV files found in `raw_data/`. Select the file you want to process and click **Load File**. Use the **↻ Refresh** button if you add new files while the app is already running.

### 2. Configure the Bin Size
Enter the desired bin size in seconds. The default is **15 seconds**.

### 3. Select Columns
All columns from the loaded file are listed in the sidebar with checkboxes. Use **Select / Deselect All** to toggle everything, or manually check the variables you want to include in the output and plots.

### 4. Inspect Raw Data
Navigate to the **📈 Raw Data** tab to review the breath-by-breath signal for each selected numeric variable. Use the **‹** and **›** buttons to step through variables. The counter (e.g. *3 / 24*) shows your position. This is a useful data quality check before binning.

### 5. Process & Preview
Click **Process & Preview** in the sidebar. The app will average all selected numeric columns within each time bin and automatically switch to the **📊 Binned Data** tab so you can review the result.

### 6. Review Binned Data
Step through the same set of variables in the **📊 Binned Data** tab to confirm the binning looks correct. The **🗃 Data Table** tab shows the full numeric output in a scrollable, paginated table.

### 7. Save
Click **Save CSV**. The file is written to `binned_data/` with the bin size prepended to the original filename:

```
binned_data/15_sec_yourfilename.csv
```

---

## Binning Method

Each breath is assigned to a time bin using `floor(time_s / bin_size)`. Within each bin:

- **Numeric columns** are averaged (mean, ignoring NAs)
- **Non-numeric columns** (e.g. character/factor fields like `interval`) take the first value in the bin
- The time column is replaced with the **bin start time** (e.g. bin 0 = 0 s, bin 1 = 15 s, bin 2 = 30 s, etc.)

---

## Input File Format

CaliBin expects CSV files exported directly from Calibre. The app assumes:

- The **first column** is time in seconds (e.g. `time [s]`)
- Subsequent columns are physiological variables, optionally including `(SMOOTHED)` variants
- No special header rows above the column names

---

## Notes

- The app was developed for use with data from the **Calibre** metabolic measurement system as part of the open assessment protocol
- The name *CaliBreaker* is a play on **Calibre** + **breaking** breath-by-breath data into time bins
- Inspired by [SILO](https://github.com/lindseyboulet/silo) made by Lindsey M Boulet

