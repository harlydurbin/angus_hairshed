library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(rlang)
library(lubridate)
library(glue)
library(magrittr)
library(purrr)
library(readxl)
library(tidylog)

angus_join <- read_rds(here::here("data/derived_data/angus_join.rds"))

angus_join %>%
  filter(sex == "F") %>%
  mutate(
    age_group =
      case_when(
        # Heifers and yearlings
        age == 1 ~ "yearling",
        age == 2 ~ "fch",
        age == 3 ~ "three",
        age >= 4 ~ "mature"
      )
  ) %>%
  left_join(
    read_excel(here::here("data/derived_data/score_windows2.xlsx")) %>%
      mutate(date_score_recorded = lubridate::ymd(date_score_recorded)) %>%
      select(farm_id, year, date_score_recorded, score_group)
  ) %>%
  mutate(score_group = tidyr::replace_na(score_group, 1)) %>%
  mutate(
    cg = glue("{farm_id}{year}{calving_season}{age_group}{score_group}{toxic_fescue}"),
    cg_num = as.integer(factor(cg))
  ) %>%
  group_by(cg) %>% 
  # At least 5 animals per CG
  filter(n() >= 5) %>% 
  # Remove CGs with no variation
  filter(var(hair_score) != 0) %>% 
  ungroup() %>% 
  write_rds(here::here("data/derived_data/start.rds"))