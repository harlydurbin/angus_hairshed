library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(rlang)
library(lubridate)
library(forcats)
library(glue)
library(magrittr)
library(purrr)
library(readxl)
library(tidylog)

source(here::here("source_functions/three_gen.R"))
source(here::here("source_functions/hair_weights.R"))

is.wholenumber <- function(x, tol = .Machine$double.eps^0.5)  abs(x - round(x)) < tol

#### Setup ####

## ---------------------------------------------------------------------------------------------------------------------------------------
source(here::here("source_functions/hair_ped.R"))

## ---------------------------------------------------------------------------------------------------------------------------------------

wean_dat <-
  melt_hair_weights(
    path = here::here("data/raw_data/HairShedGrowthData_090919.csv"),
    full_ped = hair_ped
  ) %>%
  filter(trait == "ww") %>%
  # # Create a list of CGs containing dams with hair scores or their calves
  # filter(dam_reg %in% angus_join$full_reg | full_reg %in% angus_join$full_reg) %>% 
  # filter(trait == "ww") %>%
  group_by(cg_num) %>%
  # Drop WW CGs with fewer than 5 animals
  filter(n() >= 5) %>%
  filter(var(adj_weight) != 0) %>%
  ungroup() #%>%
  # distinct(cg_num) %>%
  # # Re-join data for animals in remaining CGs
  # left_join(melt_hair_weights(
  #   path = here::here("data/raw_data/HairShedGrowthData_090919.csv"),
  #   full_ped = hair_ped
  # ))  %>%
  # distinct()


#### Ped ####

## ---------------------------------------------------------------------------------------------------------------------------------------
wean_dat %>% 
  select(full_reg, sire_reg, dam_reg) %>% 
  distinct() %>% 
  # Three generation pedigree
  three_gen(full_ped = hair_ped) %>% 
  mutate_all(~ replace_na(., "0")) %>% 
  write_delim(here::here("data/derived_data/ww_preadjust/ped.txt"),
              delim = " ",
              col_names = FALSE)



#### Data ####

wean_dat %>% 
  select(full_reg, cg_num, adj_weight) %>% 
  mutate_all(~ replace_na(., "0")) %>% 
  arrange(desc(full_reg)) %>% 
  write_delim(here::here("data/derived_data/ww_preadjust/data.txt"),
              delim = " ",
              col_names = FALSE)