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

source(here::here("source_functions/three_gen.R"))

#### Setup ####


## ------------------------------------------------------------------------
source(here::here("source_functions/hair_ped.R"))



## ------------------------------------------------------------------------


genotyped <-
  read_table2(here::here("data/derived_data/genotyped_id.txt"),
              col_names = FALSE) %>%
  pull(X1)

#### Starting data ####

fescue_start <-
  read_rds(here::here("data/derived_data/angus_join.rds")) %>%
  # Have to explicitly list on or off fescue
  filter(!is.na(toxic_fescue)) %>% 
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
    cg = glue("{farm_id}{year}{calving_season}{age_group}{score_group}"),
    cg_num = as.integer(factor(cg))
  ) %>%
  group_by(cg) %>% 
  # At least 5 animals per CG
  filter(n() >= 5) %>% 
  # Remove CGs with no variation
  filter(var(hair_score) != 0) %>% 
  ungroup()



#### Ped ####
fescue_ped <-
  fescue_start %>%
  left_join(hair_ped %>%
              select(full_reg, sire_reg, dam_reg))  %>%
  three_gen(full_ped = hair_ped) %>%
  mutate_all( ~ replace_na(., "0"))

purrr::map(
  .x = c("bivariate", "fixed"),
  ~ write_delim(
    fescue_ped,
    here::here(glue(
      "data/derived_data/fescue/{.x}/ped.txt"
    )),
    delim = " ",
    col_names = FALSE
  )
)

#### List of genotypes to pull ####

fescue_ped %>%
  filter(full_reg %in% genotyped) %>%
  select(full_reg) %>%
  write_delim(here::here("data/derived_data/fescue/pull_list.txt"),
              col_names = FALSE)

#### Data ####

## Bivariate

fescue_start %>%
  select(full_reg, hair_score, cg_num, toxic_fescue) %>%
  pivot_wider(
    values_from = hair_score,
    names_from = toxic_fescue,
    id_cols = c("full_reg", "cg_num")
  ) %>%
  mutate_all(~ replace_na(., "0")) %>%
  select(full_reg, cg_num, YES, NO) %>%
  write_delim(
    here::here("data/derived_data/fescue/bivariate/data.txt"),
    delim = " ",
    col_names = FALSE
  )

## Fixed

fescue_start %>%
  select(full_reg, cg_num, toxic_fescue, hair_score) %>%
  mutate_all(~ replace_na(., "0")) %>%
  write_delim(
    here::here("data/derived_data/fescue/fixed/data.txt"),
    delim = " ",
    col_names = FALSE
  )
