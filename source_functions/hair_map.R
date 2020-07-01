

## ------------------------------------------------------------------------
usa <- 
  borders("state", regions = ".", fill = "white", colour = "black")

map_dat <-
  angus_join %>%
  mutate(source =
           case_when(source == "bradley3" ~ "legacy",
                     TRUE ~ source)) %>%
  group_by(source, lat, lng) %>% 
  summarise(n = n()) %>% 
  ungroup() 

## ----fig.width=8.76, fig.height=5.4, echo = TRUE-------------------------
hairmap <-
  ggplot(fescue_belt, aes(x = lng, y = lat))+
  usa +
  ggforce::geom_shape(expand = unit(0.1, 'mm'), radius = unit(0.4, 'mm'), alpha = 0.3) +
  geom_point(data = map_dat, aes(
    x = lng,
    y = lat,
    size = n,
    color = source
  ), alpha = 0.8) +
  scale_size(range = c(0.01, 1)) +
  scale_color_manual(
    # Green
    values = c("legacy" = "#FF842A",
               #Blue
               "mizzou" = "#538797"),
    labels = c("legacy" = "AGI data",
               "mizzou" = "Mizzou Hair Shedding Project data")
  ) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  coord_map("albers", lat0 = 39, lat1 = 45) +
  cowplot::theme_map() +
  guides(color = guide_legend(override.aes = list(size = 0.75))) +
  labs(x = NULL,
       y = NULL,
       title = NULL) +
  # Set the "anchoring point" of the legend (bottom-left is 0,0; top-right is 1,1)
  # Put bottom-left corner of legend box in bottom-left corner of graph
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    #legend.justification = c(0, .7),
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.box = "vertical",
    legend.key.size = unit(.1, "cm"),
    legend.spacing.y = unit(.1, 'cm'),
    legend.title = element_blank(),
    legend.text = element_text(# family = "catamaran",
      size = 6),
    # top, right, bottom, left
    legend.box.margin = margin(b = 0.1, l = 0.8, unit = "cm"),
    plot.margin = margin(
      t = 0.175,
      r = 0,
      b = 0,
      l = 0,
      unit = "mm"
    )
  )

print(hairmap)

# ggsave(
#   here::here("figures/samples_map.png"),
#   width = 8.76,
#   height = 5.4,
#   bg = "transparent"
# )

