require(readxl)
require(dplyr)
require(tidyr)
require(magrittr)

calves <-
  read_excel(here::here("data/raw_data/Harly_birthdt_sex.xlsx")) %>%
  separate(reg,
           into = c("reg_type", "registration_number"),
           sep = "[:blank:]") %>%
  mutate(anm_sex_ct =
           case_when(anm_sex_ct == "C" ~ "F",
                     anm_sex_ct %in% c("S", "B") ~ "M")) %>% 
  left_join(ped) %>% 
  filter(dam_id %in% angus_join$id_new) %>% 
  select(calf_reg = registration_number, 
         calf_dob = anm_birth_dt,
         calf_id = id_new,
         sire_id, 
         dam_id) %>% 
  mutate(year = lubridate::year(calf_dob))

calving_key <-
  # one
  # had a calf in the same year
  angus_join %>% 
  filter(sex == "F" & is.na(calving_season)) %>% 
  left_join(calves, by = c("id_new" = "dam_id", "year" = "year")) %>% 
  filter(!is.na(calf_id)) %T>% 
  bind_rows(
    # two
    # had a calf the previous year 
    anti_join(
      angus_join %>% 
        filter(sex == "F" & is.na(calving_season)),
      .,
      by = c("registration_number", "year")
      ) %>% 
      mutate(yr2 = year-1) %>% 
      left_join(calves, by = c("id_new" = "dam_id", "yr2" = "year")) %>% 
      filter(!is.na(calf_id)) 
    ) %>% 
  mutate(
    cs =
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
      )) %>% 
  select(farm_id, animal_id, id_new, year, cs) %>% 
  distinct() %>% 
  group_by(farm_id, animal_id) %>%
  filter(n_distinct(cs) == 1)
