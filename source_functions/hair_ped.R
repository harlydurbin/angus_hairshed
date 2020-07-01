hair_ped <-
  read_tsv(here::here("data/raw_data/Pedigree_harley_082019.txt")) %>%
  mutate(dob = mdy(birthdt),
         sex =
           case_when(sex %in% c("B", "S") ~ "M",
                     sex == "C" ~ "F")) %>%
  select(full_reg = regnumber,
         sex,
         dob,
         sire_reg = sire,
         dam_reg = dam) %>%
  bind_rows(
    read_csv(
      here::here("data/raw_data/HairShedGrowthData_Ped_091119.csv"),
      col_names = c("full_reg", "dob", "sex", "sire_reg", "dam_reg", "et_dam_reg"),
      skip = 1
    ) %>%
      mutate(
        dob = lubridate::mdy(dob),
        sex =
          case_when(sex == "C" ~ "F",
                    sex %in% c("S", "B") ~ "M")
      ) %>%
      mutate_at(vars(contains("reg")), ~ str_remove_all(., "[:blank:]"))
  ) %>% 
  distinct() %>% 
  group_by(full_reg) %>% 
  arrange(full_reg, et_dam_reg) %>% 
  slice(1) %>% 
  ungroup() %>% 
  mutate_at(vars(contains("reg")), ~ replace_na(., "0"))