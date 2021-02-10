# Tidy Bradley 3 hair shedding data from James Henderson


bradley3_data <-
  readxl::read_excel(here::here("data/raw_data/henderson_hair_shed.xlsx"), 
           skip = 1) %>% 
  # Select all columns but name
  dplyr::select(
    animal_id = 1,
    registration_number = 3, 
    age = 4,
    hs19 = 5,
    hs18 = 6
    ) %>% 
  # Change from column for each year to row for each observation
  reshape2::melt(id = c("animal_id", "registration_number", "age")) %>% 
  dplyr::mutate(
    variable = case_when(
      variable == "hs19" ~ ymd("2019-05-01"),
      variable == "hs18" ~ ymd("2018-05-08")
      ),
    registration_number = as.character(registration_number)) %>% 
  dplyr::rename(
    hair_score = value,
    date_score_recorded = variable
    ) %>% 
  dplyr::mutate(
    hair_score = as.integer(hair_score),
    farm_id = "bradley3",
    date_score_recorded = lubridate::ymd(date_score_recorded),
    year = as.character(lubridate::year(date_score_recorded)),
    color = "BLACK",
    breed_code = "AN",
    sex = "F", 
  #  breed_assoc = "American Angus Association",
    # Infer age from birth date and date scored
    age = as.integer(lubridate::time_length(
      date_score_recorded - lubridate::ymd(age), unit = "years"
      )),
    toxic_fescue = "NO"
    ) %>% 
  dplyr::filter(!is.na(hair_score)) 



