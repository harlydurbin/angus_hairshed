
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(tibble)
library(glue)
library(rlang)
library(lubridate)
library(magrittr)
library(purrr)
library(readxl)
library(tidylog)

source(here::here("source_functions/hair_weights.R"))
source(here::here("source_functions/three_gen.R"))

#### Setup ####

## ---------------------------------------------------------------------------------------------------------------------------
source(here::here("source_functions/hair_ped.R"))

bw_start <-
  read_rds(here::here("data/derived_data/start.rds")) %>% 
  filter(calving_season == "FALL") %>% 
  filter(toxic_fescue == "YES")

genotyped <-
  read_table2(here::here("data/derived_data/genotyped_id.txt"), col_names = FALSE) %>%
  pull(X1)

## ---------------------------------------------------------------------------------------------------------------------------
## Weights

# All hair shedding growth data
hair_weights <-
  melt_hair_weights(path = here::here("data/raw_data/HairShedGrowthData_090919.csv"), full_ped = hair_ped)

bw_dat <-
  hair_weights %>%
  # Create a list of CGs containing dams with hair scores or their calves
  filter(dam_reg %in% bw_start$full_reg | full_reg %in% bw_start$full_reg) %>%
  filter(trait == "bw") %>%
  group_by(cg_num) %>%
  # Drop BW CGs with fewer than 5 animals
  filter(n() >= 5) %>%
  ungroup() %>%
  distinct(cg_num) %>%
  # Re-join data for animals in remaining CGs
  left_join(hair_weights %>%
              filter(trait == "bw")) %>%
  distinct()

#### Data ####

## model 3

model3dat <-
  bw_start %>%
  select(dam_reg = full_reg, hair_cg = cg_num, hair_score, year) %>%
  full_join(
    bw_dat %>%
      # Join by hair shedding scoring year of dam, weaning year of calf
      mutate(year = lubridate::year(weigh_date)) %>%
      select(full_reg, dam_reg, bw_cg = cg_num, adj_weight, year),
    by = c("dam_reg", "year")
  ) %>%
  rownames_to_column(var = "rowname") %>%
  # FDC for fake dummy calf
  mutate(
    full_reg =
      case_when(
        is.na(full_reg) ~ as.character(glue("FDC{rowname}")),
        TRUE ~ full_reg)
  ) %>%
  select(full_reg, dam_reg, hair_cg, bw_cg, hair_score, adj_weight) %>%
  mutate_all(~ replace_na(., "0"))

purrr::map(.x = c("model3"),
           ~ write_delim(x = model3dat %>%
                           select(-dam_reg),
                         path = here::here(glue("data/derived_data/bw_genetic_corr/{.x}/data.txt")),
                         delim = " ",
                         col_names = FALSE))


#### Ped ####

## Model 3

fdc_dummy_ped <-
  model3dat %>%
  filter(str_detect(full_reg, "^FDC")) %>%
  mutate(sire_reg = "0") %>%
  select(full_reg, sire_reg, dam_reg) %>%
  bind_rows(hair_ped)


model3ped <-
  model3dat %>%
  select(full_reg) %>%
  distinct() %>%
  left_join(
    fdc_dummy_ped %>%
      select(full_reg, sire_reg, dam_reg)
  ) %>%
  # Three generation pedigree
  three_gen(full_ped = fdc_dummy_ped) %>%
  mutate_all(~ replace_na(., "0"))

purrr::map(.x = c("model3"),
           ~ write_delim(x = model3ped,
                         path = here::here(glue("data/derived_data/bw_genetic_corr/{.x}/ped.txt")),
                         delim = " ",
                         col_names = FALSE))


#### List of genotypes to pull ####

model3ped %>% 
  select(full_reg) %>%
  filter(full_reg %in% genotyped) %>%
  distinct() %>%
  write_delim(here::here("data/derived_data/bw_genetic_corr/pull_list.txt"), col_names = FALSE)
