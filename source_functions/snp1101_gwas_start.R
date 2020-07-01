library(readr)
library(dplyr)
library(glue)
library(purrr)
library(tidyr)
library(lubridate)
library(stringr)

source(here::here("source_functions/calculate_acc.R"))
source(here::here("source_functions/three_gen.R"))
source(here::here("source_functions/hair_ped.R"))

blupf90_dir <- as.character(commandArgs(trailingOnly = TRUE)[1])


#blupf90_dir <- "data/derived_data/general_varcomp/normal"
#animal_effect <- "2"

animal_effect <- as.character(commandArgs(trailingOnly = TRUE)[2])

# blupf90 solutions
trait <-
  read_table2(
  here::here(glue("{blupf90_dir}/solutions")),
  col_names = c("trait", "effect", "id_new", "solution", "se"),
  skip = 1
) %>%
  # limit to animal effect
  filter(effect == 2) %>%
  select(id_new, solution, se) %>%
  # Re-attach original IDs
  left_join(read_table2(
    here::here(glue("{blupf90_dir}/renadd0{animal_effect}.ped")),
    col_names = FALSE
  ) %>%
    select(id_new = X1, full_reg = X10)) %>%
  mutate(acc = purrr::map_dbl(
    .x = se,
    ~ calculate_acc(
      e = 0.53274,
      u = 0.37679,
      se = .x,
      option = "reliability"
    )
  ),
  Group = 1,
  acc = round(acc*100, digits = 0),
  solution = round(solution, digits = 3)) %>%
  select(ID = full_reg, Group, Obs = solution, Rel = acc) %>% 
  right_join(read_table2(here::here("data/raw_data/imputed_F250+/sample_order.txt"), col_names = "ID")) %>% 
  filter(!is.na(Obs))

trait %>% 
  select(full_reg = ID) %>% 
  left_join(hair_ped %>% 
              select(full_reg, sire_reg, dam_reg)) %>% 
  three_gen(full_ped = hair_ped) %>% 
  write_tsv(here::here("data/derived_data/snp1101_gwas/ped.txt"))


write_tsv(trait, here::here("data/derived_data/snp1101_gwas/trait.txt"))

trait %>% 
  select(ID) %>% 
  write_tsv(here::here("data/derived_data/snp1101_gwas/pull_list.txt"), col_names = FALSE)
  