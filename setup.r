
# List of required packages
required_packages <- c(
"httr",
"rvest",
"dplyr",
"openxlsx",
"stringr"
)

# Install missing packages
installed <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!pkg %in% installed) {
    message(paste("Installing package:", pkg))
    install.packages(pkg, dependencies = TRUE)
  } else {
    message(paste("Package already installed:", pkg))
  }
}
