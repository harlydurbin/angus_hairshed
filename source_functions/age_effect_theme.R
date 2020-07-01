

# For making uniform age effect plot
age_effect_theme <- function(gg, plot_title = NULL, x_title = NULL, y_title = NULL){
  
  gg + 
    geom_bar(stat = "identity",
             position = "identity") +
    scale_fill_manual(name = "age",
                      values = c("#FF842A", "lightgrey")) +
    geom_errorbar(aes(ymin = solution - se,
                      ymax = solution + se)) +
    theme_classic() +
    theme(
      plot.title = element_text(
        size = 22,
        face = "italic",
        margin = margin(
          t = 0,
          r = 0,
          b = 13,
          l = 0
        )
      ),
      axis.title = element_text(size = 16),
      axis.title.y = element_text(margin = margin(
        t = 0,
        r = 10,
        b = 0,
        l = 0
      )),
      axis.title.x = element_text(margin = margin(
        t = 10,
        r = 0,
        b = 0,
        l = 0
      )),
      axis.text = element_text(size = 14),
      legend.position = "none"
    ) +
    labs(x = x_title,
         y = y_title,
         title = plot_title)
}