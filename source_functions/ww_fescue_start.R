## ----setup, include=FALSE-------------------------------------------------------
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

source(here::here("source_functions/three_gen.R"))
source(here::here("source_functions/hair_weights.R"))


## -------------------------------------------------------------------------------
source(here::here("source_functions/hair_ped.R"))

start <-
  read_rds(here::here("data/derived_data/start.rds"))

genotyped <-
  read_table2(here::here("data/derived_data/genotyped_id.txt"), col_names = FALSE) %>%
  pull(X1)


## -------------------------------------------------------------------------------
# All hair shedding growth data
hair_weights <-
  melt_hair_weights(path = here::here("data/raw_data/HairShedGrowthData_090919.csv"), full_ped = hair_ped)


## -------------------------------------------------------------------------------
start <- read_rds(here::here("data/derived_data/start.rds"))


## -------------------------------------------------------------------------------
## Only from calves whose dams grazed fescue + their contemporaries
wean_yes <-
  hair_weights %>%
  # Create a list of CGs containing dams with hair scores or their calves
  # filter(dam_reg %in% start[start$toxic_fescue == "YES",]$full_reg | full_reg %in% start[start$toxic_fescue == "YES",]$full_reg) %>%
  filter(dam_reg %in% start[start$toxic_fescue == "YES" & !is.na(start$toxic_fescue),]$full_reg) %>%
  filter(trait == "ww") %>%
  group_by(cg_num) %>%
  # Drop WW CGs with fewer than 5 animals
  filter(n() >= 5) %>%
  ungroup() %>%
  distinct(cg_num) %>%
  # Re-join data for animals in remaining CGs
  left_join(hair_weights %>%
              filter(trait == "ww")) %>%
  distinct()



## -------------------------------------------------------------------------------

yes_dat <-
  start %>%
  filter(toxic_fescue == "YES") %>%
  select(dam_reg = full_reg, hair_cg = cg_num, hair_score, year) %>%
  full_join(
    wean_yes %>%
      # Join by hair shedding scoring year of dam, weaning year of calf
      mutate(year = lubridate::year(weigh_date)) %>%
      select(full_reg, dam_reg, ww_cg = cg_num, adj_weight, year),
    by = c("dam_reg", "year")
  ) %>%
  rownames_to_column(var = "rowname") %>%
  # FDC for fake dummy calf
  mutate(
    full_reg =
      case_when(
        is.na(full_reg) ~ as.character(glue("FDC{rowname}_yes")),
        TRUE ~ full_reg)
  ) %>%
  select(full_reg, dam_reg, hair_cg, ww_cg, hair_score, adj_weight) %>%
  mutate_all(~ replace_na(., "0"))

print("got this far")

## -------------------------------------------------------------------------------
write_delim(yes_dat %>%
              select(-dam_reg),
            path = here::here(glue("data/derived_data/ww_fescue/model3_yes/data.txt")),
            delim = " ",
            col_names = FALSE)


write_delim(yes_dat %>% 
              select(full_reg, ww_cg, adj_weight) %>% 
              filter(!str_detect(full_reg, "^FDC")),
            path = here::here(glue("data/derived_data/ww_fescue/model3_yes_ww/data.txt")),
            delim = " ",
            col_names = FALSE)

## -------------------------------------------------------------------------------
## Only from calves whose dams grazed fescue + their contemporaries
wean_no <-
  hair_weights %>%
  # Create a list of CGs containing dams with hair scores or their calves
  # filter(dam_reg %in% start[start$toxic_fescue == "YES",]$full_reg | full_reg %in% start[start$toxic_fescue == "YES",]$full_reg) %>%
  filter(dam_reg %in% start[start$toxic_fescue == "NO" & !is.na(start$toxic_fescue),]$full_reg) %>%
  filter(trait == "ww") %>%
  group_by(cg_num) %>%
  # Drop WW CGs with fewer than 5 animals
  filter(n() >= 5) %>%
  ungroup() %>%
  distinct(cg_num) %>%
  # Re-join data for animals in remaining CGs
  left_join(hair_weights %>%
              filter(trait == "ww")) %>%
  distinct()



## -------------------------------------------------------------------------------
no_dat <-
  start %>%
  filter(toxic_fescue == "NO") %>%
  select(dam_reg = full_reg, hair_cg = cg_num, hair_score, year) %>%
  full_join(
    wean_no %>%
      # Join by hair shedding scoring year of dam, weaning year of calf
      mutate(year = lubridate::year(weigh_date)) %>%
      select(full_reg, dam_reg, ww_cg = cg_num, adj_weight, year),
    by = c("dam_reg", "year")
  ) %>%
  rownames_to_column(var = "rowname") %>%
  # FDC for fake dummy calf
  mutate(
    full_reg =
      case_when(
        is.na(full_reg) ~ as.character(glue("FDC{rowname}_no")),
        TRUE ~ full_reg)
  ) %>%
  select(full_reg, dam_reg, hair_cg, ww_cg, hair_score, adj_weight) %>%
  mutate_all(~ replace_na(., "0"))


## -------------------------------------------------------------------------------
write_delim(no_dat %>%
              select(-dam_reg),
            path = here::here(glue("data/derived_data/ww_fescue/model3_no/data.txt")),
            delim = " ",
            col_names = FALSE)

write_delim(no_dat %>% 
              select(full_reg, ww_cg, adj_weight) %>% 
              filter(!str_detect(full_reg, "^FDC")),
            path = here::here(glue("data/derived_data/ww_fescue/model3_no_ww/data.txt")),
            delim = " ",
            col_names = FALSE)


## -------------------------------------------------------------------------------

fdc_dummy_ped <-
  bind_rows(no_dat, yes_dat) %>%
  filter(str_detect(full_reg, "^FDC")) %>%
  mutate(sire_reg = "0") %>%
  select(full_reg, sire_reg, dam_reg) %>%
  bind_rows(hair_ped)




## -------------------------------------------------------------------------------
yes_ped <-
  yes_dat %>%
  select(full_reg) %>%
  distinct() %>%
  left_join(
    fdc_dummy_ped %>%
      select(full_reg, sire_reg, dam_reg)
  ) %>%
  # Three generation pedigree
  three_gen(full_ped = fdc_dummy_ped) %>%
  mutate_all(~ replace_na(., "0"))

purrr::map(
  .x = c("data/derived_data/ww_fescue/model3_yes_ww/ped.txt", "data/derived_data/ww_fescue/model3_yes/ped.txt"),
  ~ write_delim(
    yes_ped,
    path = .x,
    delim = " ",
    col_names = FALSE
  )
)



## -------------------------------------------------------------------------------

purrr::map(
  .x = c("data/derived_data/ww_fescue/model3_yes_ww/pull_list.txt", "data/derived_data/ww_fescue/model3_yes/pull_list.txt"),
  ~ write_delim(
    yes_ped %>%
      select(full_reg) %>%
      filter(full_reg %in% genotyped) %>%
      distinct(),
    path = .x,
    delim = " ",
    col_names = FALSE
  )
)


## -------------------------------------------------------------------------------
no_ped <-
  no_dat %>%
  select(full_reg) %>%
  distinct() %>%
  left_join(
    fdc_dummy_ped %>%
      select(full_reg, sire_reg, dam_reg)
  ) %>%
  # Three generation pedigree
  three_gen(full_ped = fdc_dummy_ped) %>%
  mutate_all(~ replace_na(., "0"))

purrr::map(
  .x = c("data/derived_data/ww_fescue/model3_no_ww/ped.txt", "data/derived_data/ww_fescue/model3_no/ped.txt"),
  ~ write_delim(
    yes_ped,
    path = .x,
    delim = " ",
    col_names = FALSE
  )
)



## -------------------------------------------------------------------------------

purrr::map(
  .x = c("data/derived_data/ww_fescue/model3_no_ww/pull_list.txt", "data/derived_data/ww_fescue/model3_no/pull_list.txt"),
  ~ write_delim(
    yes_ped %>%
      select(full_reg) %>%
      filter(full_reg %in% genotyped) %>%
      distinct(),
    path = .x,
    delim = " ",
    col_names = FALSE
  )
)
