
#nohup snakemake -s source_functions/ww_fescue.snakefile --latency-wait 30 --jobs 10 --config --resources load=100 --until &> log/snakemake_log/200410.ww_fescue.log &

#export LD_LIBRARY_PATH=/home/agiintern/.conda/envs/regionsenv/lib

import os

configfile: "source_functions/config/ww_fescue.yaml"

for x in expand("data/derived_data/ww_fescue/{model}", model = config['model']):
    os.makedirs(x, exist_ok = True)

os.makedirs("log/rule_log/ww_fescue_start", exist_ok = True)

rule target:
    input:
        targ = expand("data/derived_data/ww_fescue/{model}/airemlf90.{model}.log", model = config['model'])

rule start:
    input:
        angus_join = "data/derived_data/angus_join.rds"
    output:
        start = "data/derived_data/start.rds"
    shell:
        """
        Rscript --vanilla source_functions/start.R &> log/rule_log/start/start.log
        """

rule ww_fescue_start:
    resources:
        load = 1
    input:
        start = "data/derived_data/start.rds",
        genotyped_id = "data/derived_data/genotyped_id.txt"
    output:
        ped = expand("data/derived_data/ww_fescue/{model}/ped.txt", model = config['model']),
        data = expand("data/derived_data/ww_fescue/{model}/data.txt", model = config['model']),
        pull_list = expand("data/derived_data/ww_fescue/{model}/pull_list.txt", model = config['model'])
    shell:
        """
        Rscript --vanilla source_functions/ww_fescue_start.R &> log/rule_log/ww_fescue_start/ww_fescue_start.log
        """

rule copy_par:
    resources:
        load = 1
    input:
        par = "source_functions/par/ww_fescue_univariate.par"
    output:
        par = "data/derived_data/ww_fescue/{model}/ww_fescue_univariate.par"
    shell:
        "cp {input.par} {output.par}"

rule pull_genotypes:
    resources:
        load = 1
    input:
        pull_list = "data/derived_data/ww_fescue/{model}/pull_list.txt",
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/ww_fescue/{model}/genotypes.txt"
    shell:
    # https://www.gnu.org/software/gawk/manual/html_node/Printf-Examples.html
        """
        grep -Fwf {input.pull_list} {input.master_geno} | awk '{{printf "%-20s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

rule renumf90:
    resources:
        load = 1
    input:
        input_par = "data/derived_data/ww_fescue/{model}/ww_fescue_univariate.par",
        reduced_geno = "data/derived_data/ww_fescue/{model}/genotypes.txt",
        datafile = "data/derived_data/ww_fescue/{model}/data.txt",
        pedfile = "data/derived_data/ww_fescue/{model}/ped.txt",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt"
    params:
        dir = "data/derived_data/ww_fescue/{model}",
        par = "ww_fescue_univariate.par",
        renf90_out = "renf90.{model}.out",
        renumf90_path = config['renumf90_path']
    output:
        renf90_par = "data/derived_data/ww_fescue/{model}/renf90.par"
    shell:
        """
        cd {params.dir}
        {params.renumf90_path} {params.par} &> {params.renf90_out}
        """
# Have to manually edit two par files
# rule edit_renumf90:
#     resources:
#         load = 1
#     input:
#         renf90 = "data/derived_data/ww_fescue/{model}/renf90.par"
#     output:
#         yeet = "data/derived_data/ww_fescue/{model}/yeet.txt"
#         # Replace effects for model 1 & model 3 par
#     shell:
#         """
#         sed -i '14s/5 5/0 5/' {input.renf90}
#         touch {output.yeet}
#         """
rule airemlf90:
    resources:
        load = 100
    input:
        renf90_par = "data/derived_data/ww_fescue/{model}/renf90.par",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt",
        moved_geno = "data/derived_data/ww_fescue/{model}/genotypes.txt"
        #yeet = "data/derived_data/ww_fescue/{model}/yeet.txt"
    params:
        dir = "data/derived_data/ww_fescue/{model}",
        aireml_out_name = "aireml.{model}.out",
        aireml_log = "airemlf90.{model}.log",
        aireml_path = config['aireml_path']
    output:
        aireml_solutions = "data/derived_data/ww_fescue/{model}/solutions",
        aireml_log = "data/derived_data/ww_fescue/{model}/airemlf90.{model}.log"
    shell:
        """
        cd {params.dir}
        {params.aireml_path} renf90.par &> {params.aireml_out_name}
        mv airemlf90.log {params.aireml_log}
        rm genotypes*
        """
