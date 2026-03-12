#!/bin/bash
# ── CaliBin Launcher ─────────────────────────────────────────────────────────
# Double-click this file to launch CaliBin in your browser.
# On first run it will install any missing R packages automatically.

cd "$(dirname "$0")"

# Check if R is installed
if ! command -v Rscript &> /dev/null; then
    osascript -e 'display alert "R is not installed" message "Please install R from https://cran.r-project.org before running CaliBin." as critical'
    exit 1
fi

echo "Starting CaliBin..."
echo "Installing any missing packages (first run only)..."
echo ""

Rscript -e '
pkgs <- c("shiny", "shinythemes", "dplyr", "readr", "ggplot2", "DT")
missing <- pkgs[!sapply(pkgs, requireNamespace, quietly = TRUE)]
if (length(missing) > 0) {
  cat("Installing:", paste(missing, collapse = ", "), "\n")
  install.packages(missing, repos = "https://cloud.r-project.org")
}
cat("\nLaunching CaliBin in your browser...\n")
shiny::runApp(".", launch.browser = TRUE)
'
