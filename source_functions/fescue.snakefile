
#nohup snakemake -s source_functions/fescue.snakefile --latency-wait 90 --jobs 10 --config --keep-going --resources load=100 &> log/snakemake_log/200317.fescue.log &

#export LD_LIBRARY_PATH=/home/agiintern/.conda/envs/regionsenv/lib
import os

configfile: "source_functions/config/fescue.yaml"

# Make directories if they don't exist
for x in expand("data/derived_data/fescue/{model}", model = ['fixed', 'bivariate']):
    os.makedirs(x, exist_ok = True)

rule target:
    input:
        targ = expand("data/derived_data/fescue/{model}/airemlf90.fescue_{model}.log", model = config['model'])

rule copy_par:
    resources:
        load = 1
    input:
        par = "source_functions/par/fescue_{model}.par"
    output:
        par = "data/derived_data/fescue/{model}/fescue_{model}.par"
    shell:
        "cp {input.par} {output.par}"

rule fescue_start:
    resources:
        load = 1
    input:
        angus_join = "data/derived_data/angus_join.rds",
        genotyped_id = "data/derived_data/genotyped_id.txt"
    output:
        ped = expand("data/derived_data/fescue/{model}/ped.txt", model = config['model']),
        data = expand("data/derived_data/fescue/{model}/data.txt", model = config['model']),
        pull_list = "data/derived_data/fescue/pull_list.txt"
    shell:
        """
        Rscript --vanilla source_functions/fescue_start.R &> log/rule_log/fescue_start/fescue_start.log
        """

rule pull_genotypes:
    resources:
        load = 1
    input:
        pull_list = "data/derived_data/fescue/pull_list.txt",
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/fescue/genotypes.txt"
    shell:
    # https://www.gnu.org/software/gawk/manual/html_node/Printf-Examples.html
        """
        grep -Fwf {input.pull_list} {input.master_geno} | awk '{{printf "%-20s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

rule renumf90:
    resources:
        load = 1
    input:
        input_par = "data/derived_data/fescue/{model}/fescue_{model}.par",
        reduced_geno = "data/derived_data/fescue/genotypes.txt",
        datafile = "data/derived_data/fescue/{model}/data.txt",
        pedfile = "data/derived_data/fescue/{model}/ped.txt",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt"
    params:
        dir = "data/derived_data/fescue/{model}",
        renf90_out_name = "renf90.fescue_{model}.out",
        par_name = "fescue_{model}.par",
        renumf90_path = config['renumf90_path']
    output:
        renf90_par = "data/derived_data/fescue/{model}/renf90.par",
        moved_geno = "data/derived_data/fescue/{model}/genotypes.txt"
    shell:
        """
        cp {input.reduced_geno} {params.dir}
        cd {params.dir}
        {params.renumf90_path} {params.par_name} &> {params.renf90_out_name}
        """

rule airemlf90:
    resources:
        load = 100
    input:
        renf90_par = "data/derived_data/fescue/{model}/renf90.par",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt",
        moved_geno = "data/derived_data/fescue/{model}/genotypes.txt"
    params:
        dir = "data/derived_data/fescue/{model}",
        aireml_out_name = "aireml.fescue_{model}.out",
        aireml_log_name = "airemlf90.fescue_{model}.log",
        aireml_path = config['aireml_path']
    output:
        aireml_solutions = "data/derived_data/fescue/{model}/solutions",
        aireml_log = "data/derived_data/fescue/{model}/airemlf90.fescue_{model}.log"
    shell:
        """
        cd {params.dir}
        {params.aireml_path} renf90.par &> {params.aireml_out_name}
        mv airemlf90.log {params.aireml_log_name}
        rm genotypes*
        """
