library("knitr")
library("markdown")

# generate static pages
knit("www/help/template-help.Rmd", output = paste0("www/help/index.md"))

markdownToHTML(
  "www/help/index.md",
  "www/help/index.html",
  title = "TargetNet User Guide",
  stylesheet = "www/spacelab.css",
  header = "www/help/header-help.html"
)

browseURL("www/help/index.html")
