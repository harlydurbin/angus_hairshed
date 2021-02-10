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

#install.packages("forcats", repos="http://cran.r-project.org", lib= "~/R/x86_64-redhat-linux-gnu-library/3.6")

source(here::here("source_functions/hair_ped.R"))
source(here::here("source_functions/three_gen.R"))

#### Set up data & pedigree for gwas_hair


general <-
  read_rds(here::here("data/derived_data/start.rds"))

genotyped <-
  read_table2(here::here("data/derived_data/genotyped_id.txt"), col_names = FALSE) %>%
  pull(X1)


### Pedigree

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

general_ped %>%
  write_delim(here::here("data/derived_data/gwas_hair/ped.txt"),
              delim = " ",
              col_names = FALSE)

#### List of genotypes to pull ####

general_ped %>%
  filter(full_reg %in% genotyped) %>%
  select(full_reg) %>%
  write_delim(here::here("data/derived_data/gwas_hair/pull_list.txt"), col_names = FALSE)

### Data

general %>%
  select(full_reg, cg_num, hair_score) %>%
  write_delim(here::here("data/derived_data/gwas_hair/data.txt"),
              delim = " ",
              col_names = FALSE)
