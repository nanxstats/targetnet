library('shiny')
library('networkD3')

source('ui-core.R', local = TRUE)

shinyUI(navbarPage(title = 'TargetNet',
                   theme = bslib::bs_theme(version = "3", bootswatch = "spacelab"),
                   inverse = TRUE,
                   fluid = TRUE,
                   id = 'mainnavbar',

                   tabPanel(title = 'Home',

                            fluidRow(
                              column(width = 5, offset = 5,
                                     tags$br(), tags$br(), tags$br(),
                                     tags$br(), tags$br(), tags$br(),
                                     tags$br(), tags$br(), tags$br(),
                                     tags$h1('TargetNet'),
                                     tags$style(type = 'text/css', '@font-face { font-family: "ralewaythin"; src: url("fonts/raleway-thin-webfont.eot"); src: url("fonts/raleway-thin-webfont.eot?#iefix") format("embedded-opentype"), url("fonts/raleway-thin-webfont.woff2") format("woff2"), url("fonts/raleway-thin-webfont.woff") format("woff"), url("fonts/raleway-thin-webfont.ttf") format("truetype"); font-weight: normal; font-style: normal; }'),
                                     tags$style(type = 'text/css', 'h1 { font-family: "ralewaythin", "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 50px; letter-spacing: 2px; }'),
                                     tags$br()
                              )
                            ),

                            fluidRow(

                              column(width = 9, offset = 3,

                                     fluidRow(

                                       column(width = 7, offset = 0,
                                              textInput(inputId = 'inputsmi',
                                                        label = '',
                                                        value = '',
                                                        placeholder = 'Paste SMILES string here. Click the "?" icon below to see examples.',
                                                        width = '100%')
                                       ),

                                       column(width = 2, offset = 0,
                                              tags$div(class = 'netbutton', # use this div as a wrapper for the next css hack to vertical align the button ...
                                                       xn.actionButton('netButtonSMILE', 'Netting', icon('search')),
                                                       tags$style(type = 'text/css', 'div.netbutton { padding-top:20px; }')
                                              )
                                       )

                                     )
                              )

                            ),

                            fluidRow(

                              column(width = 9, offset = 3,
                                     fluidRow(
                                       column(width = 3, offset = 0,
                                              tags$div(class = 'longselect', # use this div as a wrapper for the next css hack to make the bottom space large enough when the options expand ...
                                                       selectInput('criterion', 'Include models with:',
                                                                   c('AUC >=' = 'auc',
                                                                     'Accuracy >=' = 'acc',
                                                                     'BEDROC >=' = 'bedroc',
                                                                     'MCC >=' = 'mcc',
                                                                     'F-score >=' = 'f'
                                                                   ))
                                              ),
                                              tags$style(type = 'text/css', 'div.longselect { margin-bottom:180px; }')
                                       ),
                                       column(width = 3, offset = 0,
                                              tags$div(class = 'thresholdslider', # use this div as a wrapper for the next css hack to vertical align the slider ...
                                                       sliderInput('threshold', '',
                                                                   min = 0.70, max = 0.99, value = 0.75, step = 0.01)
                                              )
                                       ),
                                       column(width = 1, offset = 0,
                                              tags$div(class = 'helpicon', # use this div as a wrapper for the next css hack to vertical align the help icon ...
                                                       popHelp('Submit Single Query Compound', 'smiles', includeMD('help/smiles.md')),
                                                       HTML('&nbsp;&nbsp;&nbsp;&nbsp;'),
                                                       HTML('<a href="draw/index.html" target = "_blank"><span style="color:#666666"><i title="Draw a Molecule" class="fa fa-pencil" data-toggle="modal"></i></span></a>')
                                              ),
                                              tags$style(type = 'text/css', 'div.helpicon { padding-top:40px; }')
                                       )
                                     )
                              )
                            )
                   ),


                   tabPanel(title = 'Upload',
                            mainPanel(

                              h2(tags$strong('Upload SMILES or SDF File')),
                              hr(),

                              fileInput(inputId = 'file1',
                                        label = 'Netting targets for one or more compounds stored in a SMILES or SDF file.',
                                        accept = c('chemical/x-daylight-smiles',
                                                   'chemical/x-mdl-sdfile',
                                                   '.smi', '.SMI',
                                                   '.smile', '.SMILE',
                                                   '.smiles', '.SMILES',
                                                   '.sd', '.SD',
                                                   '.sdf', '.SDF')),

                              fluidRow(
                                column(width = 3, offset = 0,
                                       tags$div(class = 'longselectupload', # use this div as a wrapper for the next css hack to make the bottom space large enough when the options expand ...
                                                selectInput('criterionupload', 'Include models with:',
                                                            c('AUC >=' = 'auc',
                                                              'Accuracy >=' = 'acc',
                                                              'BEDROC >=' = 'bedroc',
                                                              'MCC >=' = 'mcc',
                                                              'F-score >=' = 'f'
                                                            ))
                                       ),
                                       tags$style(type = 'text/css', 'div.longselectupload { margin-bottom:20px; }')
                                ),
                                column(width = 3, offset = 0,
                                       tags$div(class = 'thresholdsliderupload', # use this div as a wrapper for the next css hack to vertical align the slider ...
                                                sliderInput('thresholdupload', '',
                                                            min = 0.70, max = 0.99, value = 0.75, step = 0.01)
                                       )
                                ),
                                column(width = 1, offset = 0,
                                       tags$div(class = 'helpiconupload', # use this div as a wrapper for the next css hack to vertical align the help icon ...
                                                popHelp('Upload Query Compounds', 'uploadfile', includeMD('help/upload.md')),
                                                HTML('&nbsp;&nbsp;&nbsp;&nbsp;'),
                                                HTML('<a href="draw/index.html" target = "_blank"><span style="color:#666666"><i title="Draw a Molecule" class="fa fa-pencil" data-toggle="modal"></i></span></a>')
                                       ),
                                       tags$style(type = 'text/css', 'div.helpiconupload { padding-top:40px; }')
                                )
                              ),

                              xn.actionButton(inputId = 'netButtonUpload',
                                              label = 'Netting',
                                              icon = icon('search')),

                              includeMarkdown('help/upload_footer.md')

                            )
                   ),

                   tabPanel(title = 'Result',
                            mainPanel(width = 12L,
                                      h2(tags$strong('Target Netting')),
                                      hr(),
                                      DT::DTOutput('tablepred'),
                                      hr(),
                                      p('Save the result as an Excel (.xlsx) file or a tab-separated values (.tsv) file: '),
                                      downloadButton('downloadpredXLSX', 'Download Excel XLSX', class = 'btn btn-success'),
                                      downloadButton('downloadpredTSV', 'Download TSV', class = 'btn btn-info'),
                                      hr(),
                                      h2(tags$strong("Lipinski's Rule of Five")),
                                      hr(),
                                      DT::DTOutput('tablero5'),
                                      hr(),
                                      p('Save the Rule of Five table as an Excel (.xlsx) file or a tab-separated values (.tsv) file: '),
                                      downloadButton('downloadro5XLSX', 'Download Excel XLSX', class = 'btn btn-success'),
                                      downloadButton('downloadro5TSV', 'Download TSV', class = 'btn btn-info'),
                                      hr(),
                                      includeHTML('help/footer.html')
                            )
                   ),

                   navbarMenu("Tools",
                              tabPanel(title = 'Draw Heatmap',

                                       mainPanel(width = 12L,
                                                 h2(strong('Target Netting Heatmap')),
                                                 hr(),

                                                 sidebarPanel(width = 3L,
                                                              p("For the target netting result, cluster the compounds and targets using hierchical clustering (Ward's method, Euclidean distance)."),
                                                              p(a('Example TSV (1 compounds)', href = 'example/heatmap-1.tsv', target = '_blank')),
                                                              p(a('Example TSV (5 compounds)', href = 'example/heatmap-5.tsv', target = '_blank')),
                                                              p(a('Example TSV (50 compounds)', href = 'example/heatmap-50.tsv', target = '_blank')),

                                                              hr(),
                                                              fileInput('heatmaptsv', 'Choose the .tsv file and click "Make Heatmap". It may take several seconds to render a large heatmap.',
                                                                        accept = c('text/tsv', 'text/tab-separated-values', '.tsv', '.TSV')),

                                                              xn.actionButton(inputId = 'makeheatmapButton',
                                                                              label = 'Make Heatmap',
                                                                              icon = icon('table'))

                                                 ),

                                                 mainPanel(
                                                   div(id = "heatmapdiv",  # escape from the div to avoid vertical slider
                                                       style = "display:inline;position:absolute",
                                                       imageOutput("heatmapImage"))
                                                 )

                                       )

                              ),

                              tabPanel(title = "Network Visualization",

                                       mainPanel(width = 12L,
                                                 h2(strong('Drug-Target Interation Network Visualization')),
                                                 hr(),

                                                 sidebarPanel(width = 3L,
                                                              p("The see the required input format of the network data, download the example below:"),
                                                              p(a('Example Data (TSV format)', href = 'example/network-example.tsv', target = '_blank')),

                                                              hr(),
                                                              fileInput('networktsv', 'Choose the .tsv file and click "Draw Network".',
                                                                        accept = c('text/tsv', 'text/tab-separated-values', '.tsv', '.TSV')),

                                                              xn.actionButton(inputId = 'makenetworkButton',
                                                                              label = 'Draw Network',
                                                                              icon = icon('edit'))

                                                 ),

                                                 mainPanel(width = 8L,
                                                           tabsetPanel(
                                                             tabPanel("Network", simpleNetworkOutput("simplenetwork"))
                                                           )
                                                 )

                                       )

                              )
                   ),

                   tabPanel(title = 'Browse',
                            mainPanel(width = 12L,

                                      h2(strong('Model Performance Overview')),
                                      hr(),
                                      p(tags$strong('Tips: ')),
                                      p('1. Click on the legend labels in the upper right to hide or show the corresponding lines.'),
                                      p('2. Move cursor in the chart to see the detailed performance values of each target.'),
                                      includeHTML('help/chart.html'),
                                      hr(),
                                      h2(strong('All Targets')),
                                      hr(),
                                      DT::DTOutput('alltargets'),
                                      hr(),
                                      includeHTML('help/footer.html')
                            )
                   ),

                   tabPanel(title = 'Help',
                            mainPanel(width = 12L,
                                      h2(strong('A Tutorial on Using TargetNet for Reverse Target Searching')),
                                      hr(),
                                      includeMarkdown('help/help.md'),

                                      hr(),
                                      h2(strong('A Brief Introduction of the TargetNet Modeling Strategy')),
                                      hr(),
                                      includeMarkdown('help/intro.md')
                            )
                   )

))
