
#nohup snakemake -s source_functions/age.snakefile --latency-wait 30 --jobs 10 --config --keep-going --resources load=100 &> log/snakemake_log/200318.age.log &

#export LD_LIBRARY_PATH=/home/agiintern/.conda/envs/regionsenv/lib


configfile: "source_functions/config/age.yaml"

rule target:
    input:
        targ = expand("data/derived_data/age/{model}/airemlf90.{model}.log", model = config['model'])

rule age_start:
    resources:
        load = 1
    input:
        start = "data/derived_data/angus_join.rds",
        genotyped_id = "data/derived_data/genotyped_id.txt"
    output:
        ped = expand("data/derived_data/age/{model}/ped.txt", model = config['model']),
        data = expand("data/derived_data/age/{model}/data.txt", model = config['model']),
        pull_list = "data/derived_data/age/pull_list.txt"
    shell:
        """
        Rscript --vanilla source_functions/age_start.R &> log/rule_log/age_start/age_start.log
        """

rule copy_par:
    resources:
        load = 1
    input:
        par = "source_functions/par/age.{model}.par"
    output:
        par = "data/derived_data/age/{model}/age.{model}.par"
    shell:
        "cp {input.par} {output.par}"

rule pull_genotypes:
    resources:
        load = 1
    input:
        pull_list = "data/derived_data/age/pull_list.txt",
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/age/genotypes.txt"
    shell:
    # https://www.gnu.org/software/gawk/manual/html_node/Printf-Examples.html
        """
        grep -Fwf {input.pull_list} {input.master_geno} | awk '{{printf "%-20s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

rule renumf90:
    resources:
        load = 1
    input:
        input_par = "data/derived_data/age/{model}/age.{model}.par",
        reduced_geno = "data/derived_data/age/genotypes.txt",
        datafile = "data/derived_data/age/{model}/data.txt",
        pedfile = "data/derived_data/age/{model}/ped.txt",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt"
    params:
        dir = "data/derived_data/age/{model}",
        par = "age.{model}.par",
        renf90_out = "renf90.{model}.out",
        renumf90_path = config['renumf90_path']
    output:
        renf90_par = "data/derived_data/age/{model}/renf90.par",
        moved_geno = "data/derived_data/age/{model}/genotypes.txt"

    shell:
        """
        cp {input.reduced_geno} {params.dir}
        cd {params.dir}
        {params.renumf90_path} {params.par} &> {params.renf90_out}
        """

rule airemlf90:
    resources:
        load = 100
    input:
        renf90_par = "data/derived_data/age/{model}/renf90.par",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt",
        moved_geno = "data/derived_data/age/{model}/genotypes.txt"
    params:
        dir = "data/derived_data/age/{model}",
        aireml_out_name = "aireml.{model}.out",
        aireml_log = "airemlf90.{model}.log",
        aireml_path = config['aireml_path']
    output:
        aireml_solutions = "data/derived_data/age/{model}/solutions",
        aireml_log = "data/derived_data/age/{model}/airemlf90.{model}.log"
    shell:
        """
        cd {params.dir}
        {params.aireml_path} renf90.par &> {params.aireml_out_name}
        mv airemlf90.log {params.aireml_log}
        rm genotypes*
        """
