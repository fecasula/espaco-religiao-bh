academic_theme <- function(base_size=12) {
  ggplot2::theme_minimal(base_size=base_size) +
    ggplot2::theme(
      plot.title.position="plot", plot.title=ggplot2::element_text(face="bold", size=base_size*1.2),
      panel.grid.minor=ggplot2::element_blank(), legend.position="bottom",
      axis.title=ggplot2::element_text(face="bold"),
      plot.caption=ggplot2::element_text(hjust=1, colour="grey35")
    )
}

plot_proportion <- function(data, category, title, xlab=NULL) {
  category <- rlang::ensym(category)
  ggplot2::ggplot(data, ggplot2::aes(x=!!category, y=proporcao, ymin=ic95_wilson_inf, ymax=ic95_wilson_sup)) +
    ggplot2::geom_col(width=.68, fill="#526879") +
    ggplot2::geom_errorbar(width=.16, linewidth=.5) +
    ggplot2::scale_y_continuous(labels=scales::label_percent(accuracy=1), limits=c(0,NA), expand=ggplot2::expansion(mult=c(0,.08))) +
    ggplot2::labs(title=title, x=xlab, y="Proporção de deslocamentos", caption="Fonte: elaboração própria.") +
    academic_theme()
}
