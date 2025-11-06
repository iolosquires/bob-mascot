library(httr)
library(rvest)
library(tidyverse,
        quietly = T)
library(openxlsx)

get_mascot_links_from_html <- function(webpage_html) {
  
  links <- webpage_html %>%
    html_elements("a") %>% # Select all <a> elements
    html_attr("href")      # Extract the 'href' attribute from each <a>
  
  # Remove any NULL or NA entries that might result from missing hrefs
  links <- na.omit(links) |>
    str_subset("master_results")
  
  links <- paste0("https://mascot.proteomics.dundee.ac.uk",substr(links,3,nchar(links)))
  
  link_df <- data.frame(link = links) |>
    mutate(mascot_name = str_extract(link, "F\\d+(?=\\.dat)"),
           mascot_number = substr(mascot_name,2,nchar(mascot_name)))
  return(link_df)
}

format_mascot_log <- function(data_tables,
                              user) {
  mascot_log <- data_tables[[2]] |>
    as_tibble()
  
  colnames(mascot_log) <- mascot_log[1,]
  mascot_log <- mascot_log[-c(1:4),]
  
  mascot_bob <- mascot_log |>
    filter(`User Name` == user) |>
    mutate(name = str_extract(`Peak list data file`,"RS_.*?(?=\\.raw)"))
  
  return(mascot_bob)
}

get_html_from_mascot <- function (my_username,
                                  my_password,
                                  target_url) {
  
  # Make the GET request with authentication
  response <- GET(
    url = target_url,
    authenticate(my_username, my_password, type = "basic"), # Specify basic authentication
    add_headers("User-Agent" = "R web scraper") # Good practice
  )
  
  # Check if the request was successful (status code 200)
  if (status_code(response) == 200) {
    message("Successfully authenticated and retrieved the page!")
    
    # Parse the content of the page
    webpage_html <- read_html(content(response, "text"))
    
    return(webpage_html)
  } else if (status_code(response) == 401) {
    message("Authentication failed. Check your username and password.")
    message("Status code: ", status_code(response))
  } else {
    message("Failed to retrieve the page. Status code: ", status_code(response))
  }}

get_data_tables <- function(webpage_html) {
  # Now you can proceed to extract data, for example, if there are tables:
  data_tables <- html_table(webpage_html, fill = TRUE)
  
  if (length(data_tables) > 0) {
    message(paste("Found", length(data_tables), "tables on the page."))
    return(data_tables)
    
  } else {
    message("No HTML tables found on the page. You may need to use CSS selectors or XPath.")
  }
}


args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Username and password not provided")
}

username <- args[1]
password <- args[2]

cat("Username:", username, "\n")


# The URL you want to access after authentication
target_url <- "https://mascot.proteomics.dundee.ac.uk/x-cgi/ms-review.exe"

webpage_html <- get_html_from_mascot(my_username = username, #"RGourlay",
                                     my_password = password, #"money4nothing8",
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


