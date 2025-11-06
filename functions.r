library(httr)
library(rvest)
library(tidyverse,
        quietly = T)

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

