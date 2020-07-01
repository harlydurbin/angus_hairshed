
#nohup snakemake -s source_functions/bias.snakefile --latency-wait 30 --jobs 5 --config --resources load=100 --keep-going &> log/snakemake_log/200218.bias.log &

#export LD_LIBRARY_PATH=/home/agiintern/.conda/envs/regionsenv/lib


configfile: "source_functions/config/bias.yaml"

rule target:
    input:
        targ = expand("data/derived_data/bias/iter{iter}/airemlf90.bias.iter{iter}.log", iter = config['iter'])

rule start:
    input:
        angus_join = "data/derived_data/angus_join.rds"
    output:
        start = "data/derived_data/start.rds"
    shell:
        """
        Rscript --vanilla source_functions/start.R &> log/rule_log/start/start.log
        """

rule general_start:
    input:
        start = "data/derived_data/start.rds",
        genotyped_id = "data/derived_data/genotyped_id.txt",
        par = "source_functions/par/bias.par"
    params:
        log = "log/rule_log/bias_start/bias_start_iter{iter}.log",
        iter = "{iter}"
    output:
        ped = "data/derived_data/bias/iter{iter}/ped.txt",
        data = "data/derived_data/bias/iter{iter}/data.txt",
        pull_list = "data/derived_data/bias/iter{iter}/pull_list.txt",
        par = "data/derived_data/bias/iter{iter}/bias.par"
    shell:
        """
        Rscript --vanilla source_functions/bias_start.R {params.iter} &> {params.log}
        cp {input.par} {output.par}
        """

rule pull_genotypes:
    resources:
        load = 1
    input:
        pull_list = "data/derived_data/bias/iter{iter}/pull_list.txt",
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/bias/iter{iter}/genotypes.txt"
    shell:
    # https://www.gnu.org/software/gawk/manual/html_node/Printf-Examples.html
        """
        grep -Fwf {input.pull_list} {input.master_geno} | awk '{{printf "%-20s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

rule renumf90:
    resources:
        load = 1
    input:
        input_par = "data/derived_data/bias/iter{iter}/bias.par",
        reduced_geno = "data/derived_data/bias/iter{iter}/genotypes.txt",
        datafile = "data/derived_data/bias/iter{iter}/data.txt",
        pedfile = "data/derived_data/bias/iter{iter}/ped.txt",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt"
    params:
        dir = "data/derived_data/bias/iter{iter}",
        renumf90_path = config['renumf90_path']
    output:
        renf90_par = "data/derived_data/bias/iter{iter}/renf90.par"
    shell:
        """
        cd {params.dir}
        {params.renumf90_path} bias.par &> renf90.bias.out
        """

rule airemlf90:
    resources:
        load = 50
    input:
        renf90_par = "data/derived_data/bias/iter{iter}/renf90.par",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt",
        reduced_geno = "data/derived_data/bias/iter{iter}/genotypes.txt"
    params:
        dir = "data/derived_data/bias/iter{iter}",
        aireml_out_name = "aireml.bias.iter{iter}.out",
        aireml_log = "airemlf90.bias.iter{iter}.log",
        aireml_path = config['aireml_path']
    output:
        aireml_solutions = "data/derived_data/bias/iter{iter}/solutions",
        aireml_log = "data/derived_data/bias/iter{iter}/airemlf90.bias.iter{iter}.log"
    shell:
        """
        cd {params.dir}
        {params.aireml_path} renf90.par &> {params.aireml_out_name}
        mv airemlf90.log {params.aireml_log}
        rm genotypes*
        """
