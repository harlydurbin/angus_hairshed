#nohup snakemake -s source_functions/snp1101_gwas.snakefile --latency-wait 30 --jobs 10 --config --resources load=100 &> log/snakemake_log/200423.snp1101_gwas.log &

import os

configfile: "source_functions/config/snp1101_gwas.yaml"

rule target:
    input:
        "data/derived_data/snp1101_gwas/test.txt"

# Make directories if they don't exist
os.makedirs("log/rule_log/snp1101_gwas_start", exist_ok = True)

rule start:
    input:
        solutions = config['blupf90_dir'] + "/solutions",
        renadd = config['blupf90_dir'] + "/renadd0" + config['animal_effect'] + ".ped",
        sample_list = "data/raw_data/imputed_F250+/sample_order.txt",
        rscript = "source_functions/snp1101_gwas_start.R"
    params:
        blupf90_dir = config['blupf90_dir'],
        animal_effect = config['animal_effect']
    output:
        traitfile = "data/derived_data/snp1101_gwas/trait.txt",
        pull_list = "data/derived_data/snp1101_gwas/pull_list.txt",
        ped = "data/derived_data/snp1101_gwas/ped.txt"
    shell:
        "Rscript --vanilla source_functions/snp1101_gwas_start.R {params.blupf90_dir} {params.animal_effect} &> log/rule_log/snp1101_gwas_start/snp1101_gwas_start.log"

rule format_geno:
    input:
        master_geno = config['master_geno']
    output:
        format_geno = "data/raw_data/imputed_F250+/genotypes.snp1101.txt"
    shell:
        """
        awk '{{print $1, $3}}' {input.master_geno} | tr -d '~' &> {output.format_geno}
        """

rule map:
    input:
        master_mapfile = config['master_mapfile']
    output:
        snp1101_map = "data/derived_data/snp1101_gwas/snp1101_gwas.map"
    shell:
        """
         awk '{{print $1"\t"$2"\t"$3}}' {input.master_mapfile} &> {output.snp1101_map}
        """

rule pull_genotypes:
    resources:
        load = 1
    input:
        pull_list = "data/derived_data/snp1101_gwas/pull_list.txt",
        format_geno = "data/raw_data/imputed_F250+/genotypes.snp1101.txt"
    output:
        reduced_geno = "data/derived_data/snp1101_gwas/genotypes.txt"
    shell:
        "grep -Fwf {input.pull_list} {input.format_geno} &> {output.reduced_geno}"

rule gwas:
    input:
        traitfile = "data/derived_data/snp1101_gwas/trait.txt",
        reduced_geno = "data/derived_data/snp1101_gwas/genotypes.txt",
        snp1101_map = "data/derived_data/snp1101_gwas/snp1101_gwas.map",
        ctr_file = config['ctr_file']
    params:
        ctr_file = config['ctr_file'],
        snp1101_path = config['snp1101_path'],
        # Has to be in an empty folder so fkn dumb
        snp1101_out = "data/derived_data/snp1101_gwas/snp1101_gwas.out",
        snp1101_out_dir = "data/derived_data/snp1101_gwas/out"
    output:
        test = "data/derived_data/snp1101_gwas/test.txt"
    #{{mca {{gwise}} {{{params.mca}}}}}
    shell:
        """
        cat {output.test}
        {params.snp1101_path} {params.ctr_file} &> {params.snp1101_out}
        """
