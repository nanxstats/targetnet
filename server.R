# Workaround for rJava loading problem since OS X El Capitan:
# dyn.load('/Library/Java/JavaVirtualMachines/jdk1.8.0_102.jdk/Contents/Home/jre/lib/server/libjvm.dylib')

library('shiny')

source('server-core.R', local = TRUE)

shinyServer(function(input, output, session) {

  observe({
    # switch selected tab
    # note the tabset container must be created with the "id" argument
    if ( input$inputsmi != '' & input$netButtonSMILE != 0L ) {
      updateTabsetPanel(session, "mainnavbar", selected = "Result")
    }
  })

  observe({
    if ( !is.null(input$file1) & input$netButtonUpload != 0L ) {
      updateTabsetPanel(session, "mainnavbar", selected = "Result")
    }
  })

  crlist = c('auc' = 'AUC', 'acc' = 'Accuracy', 'bedroc' = 'BEDROC',
             'mcc' = 'ThresMCC', 'f' = 'ThresF')

  calcPredDF = reactive({

    if ( input$inputsmi == '' & is.null(input$file1) ) {
      stop('Please provide a SMILES string or upload a SMI/SDF file.')
    }

    if ( input$inputsmi != '' & !is.null(input$file1) ) {
      stop('Please refresh the page and only use "Upload", or only use a single SMILES string as input.')
    }

    if ( input$inputsmi != '' & is.null(input$file1) ) {
      parsed_mol = try(rcdk::parse.smiles(input$inputsmi), silent = TRUE)
      criter = crlist[input$criterion]
      thresh = input$threshold
    }

    if ( input$inputsmi == '' & !is.null(input$file1) ) {

      infile = input$file1

      if ( file.ext(infile$name) %in% c('smi', 'smile', 'smiles') ) {
        parsed_mol = try(rcdk::parse.smiles(as.character(scan(infile$datapath, what = "complex", quiet = TRUE))), silent = TRUE)
      } else if ( file.ext(infile$name) %in% c('sd', 'sdf') ) {
        parsed_mol = try(rcdk::load.molecules(infile$datapath), silent = TRUE)
      } else {
        stop('File extension must be ".smi" or ".sdf".')
      }

      criter = crlist[input$criterionupload]
      thresh = input$thresholdupload

    }

    if (inherits(parsed_mol, "try-error")) {
      stop(paste('The input SMILES string is invalid, please retry with a valid SMILES string. :-('))
    }

    fpmat = calcStandardFP(parsed_mol)
    nmol = length(parsed_mol)

    # predict

    perfmat = readRDS('data/perfmat.rds')
    selected_targets = names(which(perfmat[, criter] >= thresh))

    # dirty hack to randomize the global variable name to avoid conflict across sessions
    rndnum = gsub('\\.', '', as.character(runif(1)))
    eval(parse(text = paste0('predmat', rndnum, ' = matrix(NA, nrow = length(selected_targets), ncol = nmol)')))
    eval(parse(text = paste0('row.names(predmat', rndnum, ') = selected_targets')))

    n = length(selected_targets)

    withProgress(message = 'Predicting on target ', value = 0, {

      for ( i in 1L:n ) {
        rfmodel = readRDS(paste0('data/model/', selected_targets[i], '.rds'))
        eval(parse(text = paste0("predmat", rndnum, "[i, ] = predict(rfmodel, newdata = fpmat, type = 'prob')[, '1']")))
        # predmat[i, ] = predict(rfmodel, newdata = fpmat, type = 'prob')[, '1']
        incProgress(1/n, detail = paste0(i, ': ', selected_targets[i]))
      }

    })

    eval(parse(text = paste0('predmat = predmat', rndnum)))
    eval(parse(text = paste0('rm(predmat', rndnum, ')')))
    rm(list = 'rndnum')

    # default sort by 1st column!
    preddf = predmat[order(predmat[, 1L], decreasing = TRUE), , drop = FALSE]
    # add target descriptive name column
    targetinfo = readRDS('data/targetinfo.rds')
    preddf = cbind(targetinfo[row.names(preddf), 'UniProt.Recommended.Name'], preddf)
    # add target name with link column
    preddf = cbind(paste0('<a href="https://nanx.me/targetnet/', row.names(preddf), '/" target="_blank">', row.names(preddf), '</a>'), preddf)
    colnames(preddf) = c('Target', 'UniProt.Name', paste0('Comp.', (1L:(ncol(preddf) - 2L))))

    if (nmol > 50L) {

      first.smi = get.smiles(parsed_mol[[1]])
      first.mol = try(rcdk::parse.smiles(first.smi), silent = TRUE)
      ro5df = calcFiveRule(first.mol)  # only calc one if more than 50

      ro5df = cbind('Compound.ID' = paste0('Comp.', 1L:nrow(ro5df)),
                    '2D.Structure' = mol2base64_batch(first.mol),
                    'Formula' = mol2formula(first.mol), ro5df)

    } else {

      ro5df = calcFiveRule(parsed_mol)  # calc lipski's rule of five

      ro5df = cbind('Compound.ID' = paste0('Comp.', 1L:nrow(ro5df)),
                    '2D.Structure' = mol2base64_batch(parsed_mol),
                    'Formula' = mol2formula(parsed_mol), ro5df)

    }

    list('preddf' = preddf, 'ro5df' = ro5df)

  })

  output$tablepred = DT::renderDT({

    if (ncol(calcPredDF()$'preddf') > 52L) {
      resultdf = calcPredDF()$'preddf'[, 1L:52L]  # limit max column number
    } else {
      resultdf = calcPredDF()$'preddf'
    }

    resultdf

  }, escape = FALSE,
  options = list(lengthMenu = c(10, 25, 50, 100),
                 pageLength = 10,
                 orderClasses = TRUE))

  output$tablero5 = DT::renderDT({

    resultdf = calcPredDF()$'ro5df'
    resultdf

  }, escape = FALSE,
  options = list(lengthMenu = c(10, 25, 50, 100),
                 pageLength = 10,
                 columns = list(list(bSearchable = TRUE), list(bSearchable = FALSE),
                                list(bSearchable = TRUE), list(bSearchable = TRUE),
                                list(bSearchable = TRUE), list(bSearchable = TRUE),
                                list(bSearchable = TRUE)),
                 orderClasses = TRUE)
  # available options from https://demo.shinyapps.io/018-datatable-options/

  )

  output$downloadpredTSV = downloadHandler(
    filename = function() { paste('TargetNet-', gsub(' ', '-', gsub(':', '-', Sys.time())), '.tsv', sep = '') },
    content = function(file) {
      resultdf = calcPredDF()$'preddf'
      resultdf[, 'Target'] = row.names(resultdf)  # remove the link a href
      write.table(resultdf, file, sep = '\t', row.names = FALSE, quote = FALSE)
    }
  )

  output$downloadpredXLSX = downloadHandler(
    filename = function() { paste('TargetNet-', gsub(' ', '-', gsub(':', '-', Sys.time())), '.xlsx', sep = '') },
    content = function(file) {
      resultdf = calcPredDF()$'preddf'
      resultdf[, 'Target'] = row.names(resultdf)  # remove the link a href
      xn.write.xlsx(resultdf, file, sheetName = "TargetNet.Predicted.Result", col.names = TRUE, row.names = FALSE)
    }
  )

  output$downloadro5TSV = downloadHandler(
    filename = function() { paste('TargetNet-RO5-', gsub(' ', '-', gsub(':', '-', Sys.time())), '.tsv', sep = '') },
    content = function(file) {
      resultdf = calcPredDF()$'ro5df'
      resultdf = resultdf[, -2L]  # remove the molecule image
      write.table(resultdf, file, sep = '\t', row.names = FALSE, quote = FALSE)
    }
  )

  output$downloadro5XLSX = downloadHandler(
    filename = function() { paste('TargetNet-RO5-', gsub(' ', '-', gsub(':', '-', Sys.time())), '.xlsx', sep = '') },
    content = function(file) {
      resultdf = calcPredDF()$'ro5df'
      resultdf = resultdf[, -2L]  # remove the molecule image
      xn.write.xlsx(resultdf, file, sheetName = "TargetNet.Rule.of.Five", col.names = TRUE, row.names = FALSE)
    }
  )

  output$heatmapImage = renderImage({

    input$makeheatmapButton

    hmap = isolate({
      if ( is.null(input$heatmaptsv) ) {
        xn.heatmap('data/heatmap-example.tsv')
      } else {
        xn.heatmap(input$heatmaptsv$datapath)
      }
    })
    hmap

  }, deleteFile = TRUE)

  output$simplenetwork = renderSimpleNetwork({

    input$makenetworkButton

    network = isolate({
      if ( is.null(input$networktsv) ) {
        d3network('data/network-example.tsv')
      } else {
        d3network(input$networktsv$datapath)
      }
    })

  })

  output$alltargets = DT::renderDT({

    alltargets.perfmat = readRDS('data/perfmat.rds')
    alltargets.name = row.names(alltargets.perfmat[order(alltargets.perfmat[, 'AUC'], decreasing = TRUE), ])  # rank by AUC to be consistent with the chart
    alltargetinfo = readRDS('data/targetinfo.rds')
    resultdf = alltargetinfo[alltargets.name, 1L:2L]
    resultdf[, 'ID'] = 1L:length(alltargets.name)
    resultdf[, 'Target Details'] = paste0('<a class="btn btn-primary" href="https://nanx.me/targetnet/', resultdf[, 'Primary.ID'], '/" target="_blank">View <i class="fa fa-external-link"></i></a>')
    resultdf = resultdf[, c(3, 1, 2, 4)]
    names(resultdf) = c('ID', 'UniProt Primary ID', 'UniProt Recommended Name', 'Target Details')
    resultdf

  }, escape = FALSE,
  options = list(lengthMenu = c(25, 50, 100),
                 pageLength = 25,
                 columns = list(list(bSearchable = TRUE), list(bSearchable = TRUE),
                                list(bSearchable = TRUE), list(bSearchable = FALSE)),
                 orderClasses = TRUE))

})
