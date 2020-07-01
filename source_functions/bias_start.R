
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(glue)
library(lubridate)
library(forcats)
library(magrittr)
library(readxl)
library(purrr)
library(tidylog)

source(here::here("source_functions/three_gen.R"))


## ---- warning=FALSE, message=FALSE---------------------------------------
source(here::here("source_functions/hair_ped.R"))

iter <- as.character(commandArgs(trailingOnly = TRUE)[1])

genotyped <-
  read_table2(here::here("data/derived_data/genotyped_id.txt"), col_names = FALSE) %>%
  pull(X1)

## ------------------------------------------------------------------------



#### Starting data ####

## ------------------------------------------------------------------------
start <-
  read_rds(here::here("data/derived_data/start.rds"))




choose_validation_set <-
  function(df, frac) {

    # Registration numbers whose phenotypes will be dropped
    drop <-
      df %>%
      distinct(full_reg) %>%
      sample_frac(frac) %>%
      pull(full_reg)

    val_set <-
      df %>%
      filter(full_reg %in% drop) %>%
      mutate(hair_score = 0)

    train_set <-
      df %>%
      filter(!full_reg %in% drop)

    bind_rows(train_set, val_set)

  }

#### Ped ####

## ------------------------------------------------------------------------
ped <-
  start %>%
  left_join(
    hair_ped %>%
      select(full_reg, sire_reg, dam_reg)
  )  %>%
  three_gen(full_ped = hair_ped) %>%
  # left_join(hair_ped %>%
  #             select(full_reg, et_dam_reg)) %>%
  mutate_all(~ replace_na(., "0"))



## ------------------------------------------------------------------------
ped %>%
  write_delim(here::here(glue("data/derived_data/bias/iter{iter}/ped.txt")),
              delim = " ",
              col_names = FALSE)


#### List of genotypes to pull ####
ped %>%
  filter(full_reg %in% genotyped) %>%
  select(full_reg) %>%
  write_delim(here::here(glue("data/derived_data/bias/iter{iter}/pull_list.txt")), col_names = FALSE)


#### Data ####


start %>%
  choose_validation_set(frac = 0.25) %>%
  select(full_reg, cg_num, hair_score) %>%
  write_delim(here::here(glue("data/derived_data/bias/iter{iter}/data.txt")),
              delim = " ",
              col_names = FALSE)
