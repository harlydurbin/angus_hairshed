# Tidy Angus legacy hair shedding data from Mike MacNeil

## ------------------------------------------------------------------------
legacy_data <-
  read_excel(here::here("data/raw_data/FinalFile(WW work)_MacNeil0619.xlsx"),
             na = "0") %>%
  janitor::clean_names() %>%
  # Remove empty rows and columns
  janitor::remove_empty(which = c("rows", "cols")) %>%
  select(
    farm_id = owner,
    location,
    registration_number = dam_reg,
    animal_id = cow_id,
    age = dam_bd,
    date_score_recorded = date,
    calf_dob = calf_bd,
    contains("hc"),
    region
  ) %>%
  reshape2::melt(
    id = c(
      "farm_id",
      "location",
      "registration_number",
      "animal_id",
      "age",
      "date_score_recorded",
      "calf_dob",
      "region"
    )
  ) %>%
  rename(scored_by = variable,
         hair_score = value) %>%
  mutate(
    scored_by = as.character(scored_by),
    registration_number = as.character(registration_number),
    scored_by = case_when(
      scored_by == "hcs" ~ "A",
      scored_by == "hc_sa" ~ "B",
      scored_by == "hc_sb" ~ "C"
    )
  ) %>%
  filter(!is.na(hair_score)) %>%
  mutate(
    hair_score = as.integer(hair_score),
    year = as.character(lubridate::year(date_score_recorded)),
    date_score_recorded = ymd(date_score_recorded),
    toxic_fescue =
      case_when(
        region == "TX" ~ "NO",
        TRUE ~ NA_character_
      ),
    sex = "F",
    # Infer age from birth date and date scored
    age = as.integer(lubridate::time_length(
      ymd(date_score_recorded) - ymd(age), unit = "years"
    )),
    # Infer calving season from calf dob
    calving_season =
      case_when(
        between(
          lubridate::month(calf_dob),
          left = 1,
          right = 6
        ) ~ "SPRING",
        between(
          lubridate::month(calf_dob),
          left = 7,
          right = 12
        ) ~ "FALL"
      )
  ) 
  # # Worried about batch effects, reomve scores that aren't integers
  # mutate(hair_score = as.character(hair_score)) %>% 
  # filter(!str_detect(hair_score, "\\."))  %>% 
  # mutate(hair_score = as.integer(hair_score)) %>% 
  # # If an animal was called two different scores on that day, remove
  # # both scores for that day
  # group_by(registration_number, date_score_recorded) %>%
  # filter(n_distinct(hair_score) == 1) %>%
  # ungroup() %>%
  # select(-scored_by, -region, -calf_dob) %>%
  # distinct()
