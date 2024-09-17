library('markdown')
library('knitr')
library('magrittr')

# dark actionButton
xn.actionButton = function (inputId, label, icon = NULL) {
  if (!is.null(icon))
    buttonContent <- list(icon, label)
  else buttonContent <- label
  tags$button(id = inputId, type = "button", class = "btn btn-primary action-button",
              buttonContent)
}

# textInput with placeholder
xn.textInput = function (inputId, label, value = '', placeholder = '') {
  tagList(tags$label(label, `for` = inputId),
          tags$input(id = inputId, type = 'text', value = value, placeholder = placeholder))
}

# render .md files to html on-the-fly
includeMD = function(file) {
  return(markdownToHTML(file))
}

# render .Rmd files to html on-the-fly
includeRmd = function(path) {
  # shiny:::dependsOnFile(path)
  contents = paste(readLines(path, warn = FALSE), collapse = '\n')
  # do not embed image or add css
  html = knit2html(text = contents, fragment.only = TRUE, quiet = TRUE)
  Encoding(html) = 'UTF-8'
  HTML(html)
}

# Bootstrap 3 popup help modal
# Modified from Vincent Nijs's Radiant code:
# https://github.com/vnijs/radiant/blob/33f9ba81153d028c2c7ad7d7221f346072a84b2b/inst/base/radiant.R#L350
popHelp = function(modal_title, link, help_file) {
  sprintf("<div class='modal fade' id='%s' tabindex='-1' role='dialog' aria-labelledby='%s_label' aria-hidden='true'>
          <div class='modal-dialog'>
          <div class='modal-content'>
          <div class='modal-header'>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span aria-hidden='true'>&times;</span></button>
          <h4 class='modal-title' id='%s_label'>%s</h4>
          </div>
          <div class='modal-body'>%s
          </div>
          </div>
          </div>
          </div>
          <i title='Help' class='fa fa-question' data-toggle='modal' data-target='#%s'></i>",
          link, link, link, modal_title, help_file, link) %>%
    enc2utf8 %>% HTML
}
