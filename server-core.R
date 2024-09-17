library('rcdk')
library('randomForest')
library('xlsx')
library('base64enc')
library('pheatmap')
library('RColorBrewer')
library('networkD3')

# render .md files to html on-the-fly
includeMD = function(file) {
  return(markdownToHTML(file, options = c(''), stylesheet = ''))
}

# render .Rmd files to html on-the-fly
includeRmd = function(path) {
  # shiny:::dependsOnFile(path)
  contents = paste(readLines(path, warn = FALSE), collapse = '\n')
  # do not embed image or add css
  html = knit2html(text = contents, fragment.only = TRUE,
                   quiet = TRUE, options = '', stylesheet = '')
  Encoding(html) = 'UTF-8'
  HTML(html)
}

# compute standard (FP2) fingerprint and return matrix for Java molecular object
calcStandardFP = function (molecules, depth = 6L,
                           size = 1024L, silent = TRUE) {

  if (length(molecules) == 1L) {

    x = rcdk::get.fingerprint(molecules[[1L]], type = 'standard',
                              depth = depth, size = size, verbose = !silent)

    fp = integer(x@nbit)
    fp[x@bits] = 1L
    fp = t(fp)

  } else {

    x = lapply(molecules, get.fingerprint, type = 'standard',
               depth = depth, size = size, verbose = !silent)

    fp = matrix(0L, nrow = length(molecules), ncol = size)

    for (i in 1:length(molecules)) fp[ i, x[[i]]@bits ] = 1L

  }

  return(fp)

}

# return file extension in lower case
file.ext = function (x) return(rev(strsplit(tolower(x), split = '\\.')[[1L]])[1L])

# A rewrite for the write.xlsx2() since it has logical problems and will cause write fail
xn.write.xlsx = function (x, file, sheetName = "Sheet1",
                          col.names = TRUE, row.names = TRUE) {
  wb = createWorkbook(type = 'xlsx')
  sheet = createSheet(wb, sheetName)
  addDataFrame(x, sheet, col.names = col.names, row.names = row.names,
               startRow = 1, startColumn = 1, colStyle = NULL, colnamesStyle = NULL,
               rownamesStyle = NULL)
  saveWorkbook(wb, file)
  invisible()
}

# return Lipinski's rule of five table (4 numbers for each molecule)
# https://en.wikipedia.org/wiki/Lipinski's_rule_of_five
calcFiveRule = function (molecules, silent = TRUE) {

  hbd = rcdk::eval.desc(molecules,
                        "org.openscience.cdk.qsar.descriptors.molecular.HBondDonorCountDescriptor",
                        verbose = !silent)
  hba = rcdk::eval.desc(molecules,
                        "org.openscience.cdk.qsar.descriptors.molecular.HBondAcceptorCountDescriptor",
                        verbose = !silent)
  mw = rcdk::eval.desc(molecules,
                       "org.openscience.cdk.qsar.descriptors.molecular.WeightDescriptor",
                       verbose = !silent)
  logP = eval.desc(molecules,
                   "org.openscience.cdk.qsar.descriptors.molecular.XLogPDescriptor",
                   verbose = !silent)

  fiveruledf = cbind(hbd, hba, mw, logP)
  names(fiveruledf) = c('Hydrogen.Bond.Donors', 'Hydrogen.Bond.Acceptors', 'Molecular.Mass', 'logP')

  return(fiveruledf)

}

# convert Java molecular object to png base64 string (with <img> label)
# directly return png base64 flow to avoid writing files to web directory
# modified from http://www.cureffi.org/2013/09/23/a-quick-intro-to-chemical-informatics-in-r/
mol2base64 = function(molecule, width = 200L, height = 200L) {
  tmp = view.image.2d(molecule, depictor = get.depictor(width = width, height = height))  # get Java representation into an image matrix
  pngfile = tempfile()  # plot to a temporary png
  png(pngfile, width = width, height = height)
  par(mar = c(0, 0, 0, 0), bty = 'n')  # set margins to zero since this isn't a real plot and bty = 'n' means no margin
  plot(NA, NA, xlim = c(1, 10), ylim = c(1, 10), xaxt = 'n', yaxt = 'n', xlab = '', ylab = '') # create an empty plot
  rasterImage(tmp, 1, 1, 10, 10)  # boundaries of raster: xmin, ymin, xmax, ymax. here i set them equal to plot boundaries
  invisible(dev.off())
  return(paste0('<img src="', dataURI(file = pngfile, mime = "image/png"), '"/>'))
}

# batch process Java molecular object containing one or multiple molecules
mol2base64_batch = function (molecule, width = 200L, height = 200L) {
  molcount = length(molecule)
  result = rep(NA, molcount)
  for (i in 1L:molcount) result[i] = mol2base64(molecule[[i]], width = width, height = height)
  return(result)
}

# convert Java molecular object to formula
mol2formula = function (molecule) {
  molcount = length(molecule)
  result = rep(NA, molcount)
  for (i in 1L:molcount) {
    tmp = molecule[[i]]
    convert.implicit.to.explicit(tmp)
    formulaobj = get.mol2formula(tmp, charge = 0L)
    result[i] = formulaobj@string
  }
  return(result)
}

# draw heatmap (self-adaptive size) for the result TSV
xn.heatmap = function(tsvpath) {

  heatmappng = tempfile(fileext = '.png')
  pal = colorRampPalette(rev(brewer.pal(n = 9, name = "RdYlGn")))(100)

  # load TSV
  tab = read.table(tsvpath, header = TRUE, sep = '\t', as.is = TRUE)
  # get the target id column
  targetnamecol = which(names(tab) == 'Target')
  if ( length(targetnamecol) != 1L )
    stop('TSV must have a target name column named "Target"')
  # get the numerical columns
  numtab = tab[, sapply(tab, is.numeric), drop = FALSE]
  rownames(numtab) = tab[, targetnamecol]

  tabrow = nrow(numtab)
  tabcol = ncol(numtab)

  # draw heatmap
  if ( tabcol == 1L ) {

    xn.width = 400
    xn.height = tabrow * 8 + 50 + 50
    png(heatmappng, width = xn.width, height = xn.height)
    pheatmap(numtab,
             color = pal,
             cluster_rows = FALSE,
             cluster_cols = FALSE,
             cellwidth = (1/0.618) * 8,
             cellheight = 8, fontsize = 10)
    dev.off()

  } else if ( tabcol >= 2L & tabcol <= 25L ) {

    xn.width =  tabcol * round((1/0.618) * 16) + 100 + 100
    xn.height = tabrow * 16 + 100 + 100
    png(heatmappng, width  = xn.width, height = xn.height, antialias = 'none')
    pheatmap(numtab,
             color = pal,
             clustering_distance_rows = 'euclidean',
             clustering_distance_cols = 'euclidean',
             clustering_method = 'ward.D2',
             cellwidth = (1/0.618) * 16,
             cellheight = 16, fontsize = 14)
    dev.off()

  } else if ( tabcol >= 25L ) {

    xn.width = tabcol * round((1/0.618) * 8) + 60 + 90
    xn.height = tabrow * 8 + 100 + 100
    png(heatmappng, width  = xn.width, height = xn.height, antialias = 'none')
    pheatmap(numtab,
             color = pal,
             clustering_distance_rows = 'euclidean',
             clustering_distance_cols = 'euclidean',
             clustering_method = 'ward.D2',
             cellwidth = (1/0.618) * 8,
             cellheight = 8, fontsize = 9)
    dev.off()

  }

  return(list(src = heatmappng,
              contentType = 'image/png',
              width  = xn.width,
              height = xn.height,
              alt = 'Target Netting Heatmap'))

}

d3network = function(tsvdata) {

  graph = read.table(tsvdata, header = TRUE, as.is = TRUE)
  graph[, 1L] = paste0('Drug.', graph[, 1L])
  graph[, 2L] = paste0('Target.', graph[, 2L])
  simpleNetwork(graph)

}
