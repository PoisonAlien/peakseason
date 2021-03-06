#' Draw a profile plot
#' @details This function takes output from clustered extract_matrix and draws a profile plot
#'
#' @param mat_list Input matrix list generated by \code{\link{extract_matrix}} run with k
#' @param color named vector of colors for each sample
#' @param ci add SEM bars.
#' @param legend_font_size cex for font size. Default 1.
#' @param line_size line width. Default 3.
#' @param axis_lwd axis line width. Default 3.
#' @param axis_font_size font size for axis. Default 1.
#' @param sample_names names for samples. Default NULL parses from bigwig files.
#' @param auto_y_axis Default TRUE. If FALSE plots from zero to max.
clustered_profile_plot = function(mat_list, summarizeBy = 'mean', color = NULL, n_rows = NULL, n_cols = NULL,
                                  sample_names = NULL, auto_y_axis = TRUE, ci = FALSE, line_size = 2,
                                  axis_lwd = 3, axis_font_size = 1, legend_font_size = 1){

  plot_dat = clustered_hm(mat_list = mat_list, return_mats = TRUE)
  mats = plot_dat[1:(length(plot_dat$cluster_tbl)-2)]


  if(is.null(n_cols)){
    n_cols = 3
  }

  if(is.null(n_rows)){
    n_rows = ceiling(length(mats)/n_cols)
  }

  n_cuts = cumsum(x = plot_dat$cluster_tbl[,.N,cluster_k][,N])
  #print(n_cuts)

  par(mfrow = c(n_rows, n_cols))
  size = as.character(plot_dat$param["size"])
  xlabs = c(sapply(strsplit(x = as.character(size), split = ":", fixed = TRUE), "[[", 1), 0,
            sapply(strsplit(x = as.character(size), split = ":", fixed = TRUE), "[[", 2))

  if(is.null(color)){
    color = c(RColorBrewer::brewer.pal(8,name = "Dark2"), RColorBrewer::brewer.pal(9,name = "Set1")[1:3],'black', 'violet', 'royalblue')
    color = color[1:length(n_cuts)]
    #names(color) = names(mat_list)
  }else{
    if(length(color) != length(mats)){
      warning("Insufficient number of colors. Randomly choosing few colors")
      color = c(color,
                sample(colors(), size = length(mats) - length(color), replace = FALSE))
    }
  }

  #print(color)
  names(color) = paste0("k_", 1:length(n_cuts))

  n_cuts = c(1, n_cuts)

  for(i in 1:length(mats)){

    mat_i = mats[[i]]

    mat_i_mean = lapply(1:(length(n_cuts)-1), function(k){
      mat_k = mat_i[n_cuts[k]:(n_cuts[k+1])]
      mat_mean = apply(mat_k, 2, mean, na.rm = TRUE)
      mat_mean
    })
    names(mat_i_mean) = paste0("k_", 1:length(mat_i_mean))

    if(ci){
      mat_i_ci = lapply(1:(length(n_cuts)-1), function(k){
        mat_ci = apply(mat_k, 2, function(y){
          sd(y, na.rm = TRUE)/sqrt(length(y))
        })
      })
    }

    if(auto_y_axis){
      yl = round(c(min(unlist(lapply(mat_i_mean, min, na.rm = TRUE))),
                   max(unlist(lapply(mat_i_mean, max, na.rm = TRUE)))), digits = 2)
    }else{
      yl = round(c(0, max(unlist(lapply(mat_i_mean, max, na.rm = TRUE)))), digits = 2)
    }

    if(auto_y_axis){
      yl[1] = round(min(yl) - (min(yl)*0.10), digits = 2)
      yl[length(yl)] = round(max(yl) + (max(yl)*0.10), digits = 2)
    }

    par(mar = c(3, 3, 4, 2), font = 4)
    plot(mat_i_mean[[1]], frame.plot = FALSE, axes = F,
         xlab = '', ylab = '', type = 'l',
         lwd = line_size,
         col = color[1],#color[names(mat_list)[[1]]]
         ylim = c(min(yl), yl[2] + yl[2] * 0.2))
    title(main = names(mats)[i], line = -0.5, outer = FALSE, adj = 0)

    if(length(mat_i_mean) > 1){
      for(i in 2:length(mat_i_mean)){

        points(mat_i_mean[[i]], type = 'l', lwd = line_size, col = color[i])#color[names(mat_list)[[i]]])
        # if(ci){
        #   polygon(x = c(1:length(mat_i_mean[[i]]), rev(1:length(mat_i_mean[[i]]))),
        #           y = c(mat_list[[i]]-ci_list[[i]], rev(mat_list[[i]]+ci_list[[i]])),
        #           col = grDevices::adjustcolor(col = color[i], #color[names(mat_list)[[i]]],
        #                                        alpha.f = 0.4), border = NA)
        # }
        #title(main = names(mats)[i], line = -0.5, outer = FALSE, adj = 0)
      }
    }

    xticks = c(0,
               as.integer(length(mat_i_mean[[1]])/sum(as.numeric(xlabs[1]), as.numeric(xlabs[3])) * as.numeric(xlabs[1])),
               length(mat_i_mean[[1]]))

    axis(side = 1, at = xticks,
         labels = c(paste0("-", xlabs[1]), xlabs[2], xlabs[3]), lty = 1, lwd = axis_lwd,
         font = 2, cex.axis = axis_font_size, line = 0.5)
    axis(side = 2, at = yl, labels = yl, lty = 1, lwd = axis_lwd, las = 2, font = 2, cex = axis_font_size)

    #print(xticks)
    legend(x = 0, y = yl[2] + yl[2] * 0.2, bty = "n", legend = names(color),
           col = color, lty = 1, lwd = 3, cex = legend_font_size, ncol = 2, y.intersp = 1, adj= 0)
  }
}
