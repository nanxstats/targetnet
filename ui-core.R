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
