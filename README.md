# Code and analyses associated with "Development of a genetic evaluation for hair shedding in American Angus cattle to improve thermotolerance" (Durbin et al., 2020)

Current version of the manuscript can be found on [bioRxiv](https://www.biorxiv.org/content/10.1101/2020.05.21.109553v1?rss=1)

## Data cleaning

* Initial data cleaning performed in `notebooks/angus_join.Rmd`. A rendered walk-through of initial data cleaning can found at `html/angus_join.html`.
* Some formatting of genotype files for various programs in `notebooks/geno_format.Rmd`
* Some genotyped sample metadata formatting in `notebooks/f250_ids.Rmd`

## Analyses 

* Contemporary grouping
  + Age analyses performed in `source_functions/age.snakefile`
  + Calving season analyses performed in `source_functions/calving_season.snakefile`
  + Grazing vs. not grazing toxic fescue analyses performed in `source_functions/fescue.snakefile` 
* Variance component & breeding value estimation using final contemporary group definition performed in `source_functions/general_varcomp.snakefile`
* Iterative variance component estimation for calculation of bias performed in `source_functions/bias.snakefile`
* Weaning weight
  + All analyses involving the genetic relationship between hair shedding and weaning weight performed in `source_functions/ww_genetic_corr.snakefile`
  + Analyses involving the phenotypic relationship between hair shedding and weaning weight, including simple linear models, performed in `notebooks/ww_pheno_corr.Rmd`
* GWAS using SNP1101 performed in `source_functions/snp1101_gwas.snakefile`

For each analysis Snakefile, the corresponding config file can be found in `source_functions/config` and the corresponding BLUPF90 parameter file with starting variances in `source_functions/par`. Each analysis also has a corresponding RMarkdown of results at `notebooks/` with rendered results at `html/`. For most analyses, raw variance component and genetic correlation estimates can be found in `data/derived_data/`. 