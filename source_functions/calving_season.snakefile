
#nohup snakemake -s source_functions/calving_season.snakefile --latency-wait 30 --jobs 10 --config --keep-going &> log/snakemake_log/200205.calving_season.log &

#export LD_LIBRARY_PATH=/home/agiintern/.conda/envs/regionsenv/lib


configfile: "source_functions/config/calving_season.yaml"

rule target:
    input:
        targ = expand("data/derived_data/calving_season/{model}/airemlf90.calving_season.{model}.log", model = config['model'])

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
    input:
        par = "source_functions/par/calving_season.{model}.par"
    output:
        par = "data/derived_data/calving_season/{model}/calving_season.{model}.par"
    shell:
        "cp {input.par} {output.par}"

rule calving_season_start:
    input:
        angus_join = "data/derived_data/angus_join.rds",
        genotyped_id = "data/derived_data/genotyped_id.txt"
    output:
        ped = expand("data/derived_data/calving_season/{model}/ped.txt", model = config['model']),
        data = expand("data/derived_data/calving_season/{model}/data.txt", model = config['model']),
        pull_list = "data/derived_data/calving_season/pull_list.txt"
    shell:
        """
        Rscript --vanilla source_functions/calving_season_start.R &> log/rule_log/calving_season_start/calving_season_start.log
        """

rule pull_genotypes:
    input:
        pull_list = "data/derived_data/calving_season/pull_list.txt",
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/calving_season/genotypes.txt"
    shell:
    # https://www.gnu.org/software/gawk/manual/html_node/Printf-Examples.html
        """
        grep -Fwf {input.pull_list} {input.master_geno} | awk '{{printf "%-20s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

rule renumf90:
    input:
        input_par = "data/derived_data/calving_season/{model}/calving_season.{model}.par",
        reduced_geno = "data/derived_data/calving_season/genotypes.txt",
        datafile = "data/derived_data/calving_season/{model}/data.txt",
        pedfile = "data/derived_data/calving_season/{model}/ped.txt",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt"
    params:
        dir = "data/derived_data/calving_season/{model}",
        renf90_out_name = "renf90.calving_season.{model}.out",
        par_name = "calving_season.{model}.par",
        renumf90_path = config['renumf90_path']
    output:
        renf90_par = "data/derived_data/calving_season/{model}/renf90.par",
        moved_geno = "data/derived_data/calving_season/{model}/genotypes.txt"
    shell:
        """
        cp {input.reduced_geno} {params.dir}
        cd {params.dir}
        {params.renumf90_path} {params.par_name} &> {params.renf90_out_name}
        """

rule airemlf90:
    input:
        renf90_par = "data/derived_data/calving_season/{model}/renf90.par",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt",
        moved_geno = "data/derived_data/calving_season/{model}/genotypes.txt"
    params:
        dir = "data/derived_data/calving_season/{model}",
        aireml_out_name = "aireml.calving_season.{model}.out",
        aireml_log_name = "airemlf90.calving_season.{model}.log",
        aireml_path = config['aireml_path']
    output:
        aireml_solutions = "data/derived_data/calving_season/{model}/solutions",
        aireml_log = "data/derived_data/calving_season/{model}/airemlf90.calving_season.{model}.log"
    shell:
        """
        cd {params.dir}
        {params.aireml_path} renf90.par &> {params.aireml_out_name}
        mv airemlf90.log {params.aireml_log_name}
        rm genotypes*
        """
