
#nohup snakemake -s source_functions/general_varcomp.snakefile --latency-wait 30 --jobs 10 --config --keep-going --resources load=100 &> log/snakemake_log/200824.general_varcomp.log &

#export LD_LIBRARY_PATH=/home/agiintern/.conda/envs/regionsenv/lib


configfile: "source_functions/config/general_varcomp.yaml"

for x in expand("data/derived_data/general_varcomp/{model}", model = ['normal', 'collapsed']):
    os.makedirs(x, exist_ok = True)

rule all:
    input:
        expand("data/derived_data/general_varcomp/{model}/airemlf90.general_varcomp.{model}.log", model = config['model'])

rule start:
    input:
        angus_join = "data/derived_data/angus_join.rds"
    output:
        start = "data/derived_data/start.rds"
    shell:
        """
        Rscript --vanilla source_functions/start.R &> log/rule_log/start/start.log
        """

rule copy_par:
    resources:
        load = 1
    input:
        par = "source_functions/par/general_varcomp.par"
    output:
        par = "data/derived_data/general_varcomp/{model}/general_varcomp.par"
    shell:
        "cp {input.par} {output.par}"

rule general_start:
    input:
        start = "data/derived_data/start.rds",
        genotyped_id = "data/derived_data/genotyped_id.txt"
    output:
        ped = expand("data/derived_data/general_varcomp/{model}/ped.txt", model = config['model']),
        data = expand("data/derived_data/general_varcomp/{model}/data.txt", model = config['model']),
        pull_list = "data/derived_data/general_varcomp/pull_list.txt"
    shell:
        """
        Rscript --vanilla source_functions/general_varcomp_start.R &> log/rule_log/general_varcomp_start/general_varcomp_start.log
        """

rule pull_genotypes:
    input:
        pull_list = "data/derived_data/general_varcomp/pull_list.txt",
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/general_varcomp/genotypes.txt"
    shell:
    # https://www.gnu.org/software/gawk/manual/html_node/Printf-Examples.html
        """
        grep -Fwf {input.pull_list} {input.master_geno} | awk '{{printf "%-20s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

rule renumf90:
    input:
        input_par = "data/derived_data/general_varcomp/{model}/general_varcomp.par",
        reduced_geno = "data/derived_data/general_varcomp/genotypes.txt",
        datafile = "data/derived_data/general_varcomp/{model}/data.txt",
        pedfile = "data/derived_data/general_varcomp/{model}/ped.txt",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt"
    params:
        dir = "data/derived_data/general_varcomp/{model}",
        renumf90_path = config['renumf90_path'],
        renf90_out_name = "renf90.general_varcomp.{model}.out"
    output:
        renf90_par = "data/derived_data/general_varcomp/{model}/renf90.par",
        moved_geno = "data/derived_data/general_varcomp/{model}/genotypes.txt"
    shell:
        """
        cp {input.reduced_geno} {params.dir}
        cd {params.dir}
        {params.renumf90_path} general_varcomp.par &> renf90.general_varcomp.out
        """

rule airemlf90:
    resources:
        load = 100
    input:
        renf90_par = "data/derived_data/general_varcomp/{model}/renf90.par",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt",
        moved_geno = "data/derived_data/general_varcomp/{model}/genotypes.txt"
    params:
        dir = "data/derived_data/general_varcomp/{model}",
        aireml_out_name = "aireml.general_varcomp.{model}.out",
        aireml_log_name = "airemlf90.general_varcomp.{model}.log",
        aireml_path = config['aireml_path']
    output:
        aireml_solutions = "data/derived_data/general_varcomp/{model}/solutions",
        aireml_log = "data/derived_data/general_varcomp/{model}/airemlf90.general_varcomp.{model}.log"
    shell:
        """
        cd {params.dir}
        {params.aireml_path} renf90.par &> {params.aireml_out_name}
        mv airemlf90.log {params.aireml_log_name}
        rm genotypes*
        """
