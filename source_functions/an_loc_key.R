read_csv(here::here("data/raw_data/location_key.csv"),
         col_types = cols(.default = "c")) %>%
  janitor::clean_names() %>%
  filter(location %in% angus_join$farm_id) %>%
  select(farm_id = location,
         zip) %>%
  bind_rows(read_csv(here::here("data/raw_data/location_miss.csv"),
                     col_types = cols(.default = "c")) %>%
              select(farm_id,
                     zip = X3) %>%
              distinct()) %>%
  left_join(
    read_delim(
      here::here("data/raw_data/us-zip-code-latitude-and-longitude.csv"),
      delim = ";"
    ) %>%
      janitor::clean_names() %>%
      select(zip:state,
             lat = latitude,
             lng = longitude),
    by = c("zip")
  ) %>% 
  write_csv(here::here("data/raw_data/an_loc_key.csv"), na = "")
