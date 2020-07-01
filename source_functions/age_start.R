## ----setup, include=FALSE------------------------------------------------

library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(rlang)
library(glue)
library(ggplot2)
library(lubridate)
library(forcats)
library(magrittr)
library(readxl)
library(purrr)
library(tidylog)

source(here::here("source_functions/three_gen.R"))

#### Setup ####

## ---- warning=FALSE, message=FALSE---------------------------------------
source(here::here("source_functions/hair_ped.R"))

genotyped <-
  read_table2(here::here("data/derived_data/genotyped_id.txt"), col_names = FALSE) %>%
  pull(X1)



## ------------------------------------------------------------------------
angus_join <- read_rds(here::here("data/derived_data/angus_join.rds"))

genotyped <-
  read_table2(here::here("data/derived_data/genotyped_id.txt"), col_names = FALSE) %>%
  pull(X1)

#### Starting data ####

## ------------------------------------------------------------------------
age_start <-
  angus_join %>%
  # No bulls for now
  filter(sex == "F") %>%
  # At least 5 per age
  ungroup() %>%
  mutate(
    four_groups =
      case_when(
        age == 1 ~ "yearling",
        age == 2 ~ "fch",
        age == 3 ~ "three",
        TRUE ~ "mature"
      ),
    # Edited 3/2/20 in order to reflect updated age of dam classifications
    bif_age =
      case_when(
        age == 1 ~ "yearling",
        age == 2 ~ "fch",
        age == 3 ~ "three",
        age == 4 ~ "four",
        between(age, 5, 9) ~ "5_9",
        age == 10 ~ "10",
        age == 11 ~ "11",
        age == 12 ~ "12",
        TRUE ~ "13+"
      ),
    four_groups = fct_relevel(as_factor(four_groups), "yearling", "fch", "three", "mature"),
    bif_age = fct_relevel(as_factor(bif_age), "yearling", "fch", "three", "four",  "5_9", "10", "11", "12", "13+"),
  ) %>%
  # Score windows for CG
  left_join(
    read_excel(here::here(
      "data/derived_data/score_windows2.xlsx"
    )) %>%
      mutate(date_score_recorded = lubridate::ymd(date_score_recorded)) %>%
      select(farm_id, year, date_score_recorded, score_group)
  ) %>%
  mutate(
    score_group = tidyr::replace_na(score_group, 1),
    # Exclude age from CG
    # 2/5/20 Add fescue status back in
    cg = glue(
      "{farm_id}{year}{calving_season}{score_group}{toxic_fescue}"
    ),
    hair_cg = as.integer(factor(cg)),
  ) %>%
  # Remove if fewer than 5 animals per CG
  group_by(hair_cg) %>%
  filter(n() >= 5) %>%
  # Remove CGs with no variation
  filter(var(hair_score) != 0) %>%
  ungroup()



#### Ped ####

## ------------------------------------------------------------------------

age_ped <-
  age_start %>%
  left_join(
    hair_ped %>%
      select(full_reg, sire_reg, dam_reg)
  )  %>%
  three_gen(full_ped = hair_ped) %>%
  mutate_all(~ replace_na(., "0"))

age_ped %>%
  # Write the same ped just multiple places
  list(., ., ., .) %>%
  purrr::map2(
    .y = c("years_factor", "bif_age", "four_groups", "null"),
             ~ write_delim(.x, here::here(glue("data/derived_data/age/{.y}/ped.txt")),
                           delim = " ",
                           col_names = FALSE))


#### List of genotypes to pull ####

age_ped %>%
  filter(full_reg %in% genotyped) %>%
  select(full_reg) %>%
  write_delim(here::here("data/derived_data/age/pull_list.txt"), col_names = FALSE)

#### Data ####

## ------------------------------------------------------------------------
# Null: no age at all
age_start %>%
  select(full_reg, hair_cg, hair_score) %>%
  write_delim(here::here("data/derived_data/age/null/data.txt"),
              delim = " ",
              col_names = FALSE)



## ------------------------------------------------------------------------
# Age in years as factor
age_start %>%
  group_by(age) %>%
  filter(n() >= 5) %>%
  ungroup() %>%
  #mutate(mn = 1) %>%
  select(full_reg, hair_cg, age, hair_score) %>%
  arrange(age, hair_cg) %>%
  write_delim(here::here("data/derived_data/age/years_factor/data.txt"),
              delim = " ",
              col_names = FALSE)



## ------------------------------------------------------------------------
# BIF age
age_start %>%
  group_by(bif_age) %>%
  filter(n() >= 5) %>%
  ungroup() %>%
  select(full_reg, hair_cg, bif_age, hair_score) %>%
  arrange(bif_age, hair_cg) %>%
  write_delim(here::here("data/derived_data/age/bif_age/data.txt"),
              delim = " ",
              col_names = FALSE)


## ------------------------------------------------------------------------
# four_groups
age_start %>%
  group_by(four_groups) %>%
  filter(n() >= 5) %>%
  ungroup() %>%
  select(full_reg, hair_cg, four_groups, hair_score) %>%
  arrange(four_groups, hair_cg) %>%
  write_delim(here::here("data/derived_data/age/four_groups/data.txt"),
              delim = " ",
              col_names = FALSE)
