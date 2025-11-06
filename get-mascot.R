library(httr)
library(rvest)
library(tidyverse,
        quietly = T)
library(openxlsx)

source("functions.r")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Username and password not provided")
}

username <- args[1]
password <- args[2]

cat("Username:", username, "\n")

# The URL you want to access after authentication
target_url <- "https://mascot.proteomics.dundee.ac.uk/x-cgi/ms-review.exe"

webpage_html <- get_html_from_mascot(my_username = username, 
                                     my_password = password, 
                                     target_url)    
  
data_tables <- get_data_tables(webpage_html)
  
sample_links <- get_mascot_links_from_html (webpage_html)
mascot_bob <- format_mascot_log (data_tables = data_tables,
                                 user = paste0("Discoverer_", username)) 
mascot_bob <- mascot_bob |>
  left_join(sample_links,
            by = join_by(`Job#` == mascot_number))
 
output <- mascot_bob |>
  select(dbase,
         `start time`,
         `Peak list data file`,
         link,
         mascot_name,
         name) |>
  mutate(Axel_filename = str_extract(`Peak list data file`, "(?<=121006_)\\d+(?=\\.raw)"))

# Create workbook
wb <- createWorkbook()
addWorksheet(wb, "Mascot Files")

# Write all columns except 'link'
non_link_cols <- output

writeData(wb, sheet = "Mascot Files", x = non_link_cols, startCol = 1, startRow = 2, colNames = TRUE)

# Write hyperlinks in the 'link' column (as Excel formulas)
for (i in seq_len(nrow(output))) {
  url <- output$link[i]
  formula <- sprintf('HYPERLINK("%s", "Click here")', url)
  writeFormula(wb, sheet = "Mascot Files", x = formula, startCol = which(colnames(output) == "link"), startRow = i + 2)
}

# Save
saveWorkbook(wb, "mascot-files.xlsx", overwrite = TRUE)


