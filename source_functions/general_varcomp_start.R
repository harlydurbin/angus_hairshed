
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


genotyped <-
  read_table2(here::here("data/derived_data/genotyped_id.txt"), col_names = FALSE) %>%
  pull(X1)

## ------------------------------------------------------------------------



#### Starting data ####

## ------------------------------------------------------------------------
general <- 
  read_rds(here::here("data/derived_data/start.rds"))




#### Ped ####

## ------------------------------------------------------------------------
general_ped <-
  general %>% 
  left_join(
    hair_ped %>% 
      select(full_reg, sire_reg, dam_reg)
  )  %>%
  three_gen(full_ped = hair_ped) %>% 
  # left_join(hair_ped %>% 
  #             select(full_reg, et_dam_reg)) %>% 
  mutate_all(~ replace_na(., "0"))



## ------------------------------------------------------------------------
c("normal", "collapsed") %>% 
  purrr::map(~ write_delim(general_ped, here::here(glue::glue("data/derived_data/general_varcomp/{.x}/ped.txt")),
                         delim = " ",
                         col_names = FALSE))

#### List of genotypes to pull ####

general_ped %>%
  filter(full_reg %in% genotyped) %>%
  select(full_reg) %>%
  write_delim(here::here("data/derived_data/general_varcomp/pull_list.txt"), col_names = FALSE)


#### Data ####

# Normal 
 general %>%
   select(full_reg, cg_num, hair_score) %>%
   write_delim(here::here("data/derived_data/general_varcomp/normal/data.txt"),
               delim = " ",
               col_names = FALSE)
 
# Collapse hair scores
general %>%
  select(full_reg, cg_num, hair_score) %>%
  mutate(hair_score =
           case_when(
             # If hair score is 3 or below, call them the same score
             3 >= hair_score ~ 3,
             # If hair score greater than 3, keep the same
             TRUE ~ hair_score
           )) %>% 
  write_delim(here::here("data/derived_data/general_varcomp/collapsed/data.txt"),
              delim = " ",
              col_names = FALSE)

