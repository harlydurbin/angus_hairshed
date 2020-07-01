
#nohup snakemake -s source_functions/ww_genetic_corr.snakefile --latency-wait 30 --jobs 10 --config --keep-going --resources load=100 &> log/snakemake_log/200206.ww_genetic_corr.log &

#export LD_LIBRARY_PATH=/home/agiintern/.conda/envs/regionsenv/lib


configfile: "source_functions/config/ww_genetic_corr.yaml"

rule target:
    input:
        targ = expand("data/derived_data/ww_genetic_corr/single_step/{model}/airemlf90.{model}.log", model = config['model'])

rule start:
    input:
        angus_join = "data/derived_data/angus_join.rds"
    output:
        start = "data/derived_data/start.rds"
    shell:
        """
        Rscript --vanilla source_functions/start.R &> log/rule_log/start/start.log
        """

rule ww_genetic_corr_start:
    resources:
        load = 1
    input:
        start = "data/derived_data/start.rds",
        genotyped_id = "data/derived_data/genotyped_id.txt"
    output:
        ped = expand("data/derived_data/ww_genetic_corr/single_step/{model}/ped.txt", model = config['model']),
        data = expand("data/derived_data/ww_genetic_corr/single_step/{model}/data.txt", model = config['model']),
        pull_list = "data/derived_data/ww_genetic_corr/single_step/pull_list.txt"
    shell:
        """
        Rscript --vanilla source_functions/ww_genetic_corr_start.R &> log/rule_log/ww_genetic_corr_start/ww_genetic_corr_start.log
        """

rule copy_par:
    resources:
        load = 1
    input:
        par = "source_functions/par/ww_genetic_corr.{model}.par"
    output:
        par = "data/derived_data/ww_genetic_corr/single_step/{model}/ww_genetic_corr.{model}.par"
    shell:
        "cp {input.par} {output.par}"

rule pull_genotypes:
    resources:
        load = 1
    input:
        pull_list = "data/derived_data/ww_genetic_corr/single_step/pull_list.txt",
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/ww_genetic_corr/single_step/genotypes.txt"
    shell:
    # https://www.gnu.org/software/gawk/manual/html_node/Printf-Examples.html
        """
        grep -Fwf {input.pull_list} {input.master_geno} | awk '{{printf "%-20s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

rule renumf90:
    resources:
        load = 1
    input:
        input_par = "data/derived_data/ww_genetic_corr/single_step/{model}/ww_genetic_corr.{model}.par",
        reduced_geno = "data/derived_data/ww_genetic_corr/single_step/genotypes.txt",
        datafile = "data/derived_data/ww_genetic_corr/single_step/{model}/data.txt",
        pedfile = "data/derived_data/ww_genetic_corr/single_step/{model}/ped.txt",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt"
    params:
        dir = "data/derived_data/ww_genetic_corr/single_step/{model}",
        par = "ww_genetic_corr.{model}.par",
        renf90_out = "renf90.{model}.out",
        renumf90_path = config['renumf90_path']
    output:
        renf90_par = "data/derived_data/ww_genetic_corr/single_step/{model}/renf90.par",
        moved_geno = "data/derived_data/ww_genetic_corr/single_step/{model}/genotypes.txt",
    shell:
        """
        cp {input.reduced_geno} {params.dir}
        cd {params.dir}
        {params.renumf90_path} {params.par} &> {params.renf90_out}
        """
# Have to manually edit two par files
rule edit_renumf90:
    resources:
        load = 1
    input:
        renf90_model1 = "data/derived_data/ww_genetic_corr/single_step/model1/renf90.par",
        renf90_model3 = "data/derived_data/ww_genetic_corr/single_step/model3/renf90.par"
    output:
        yeet1 = "data/derived_data/ww_genetic_corr/single_step/model1/yeet.txt",
        yeet2 = "data/derived_data/ww_genetic_corr/single_step/model2/yeet.txt",
        yeet3 = "data/derived_data/ww_genetic_corr/single_step/model3/yeet.txt"
        # Replace effects for model 1 & model 3 par
    shell:
        """
        sed -i '17s/5 5/5 0/' {input.renf90_model1}
        sed -i '14s/5 5/0 5/' {input.renf90_model3}
        touch {output.yeet1}
        touch {output.yeet2}
        touch {output.yeet3}
        """
rule airemlf90:
    resources:
        load = 50
    input:
        renf90_par = "data/derived_data/ww_genetic_corr/single_step/{model}/renf90.par",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt",
        moved_geno = "data/derived_data/ww_genetic_corr/single_step/{model}/genotypes.txt",
        yeet = "data/derived_data/ww_genetic_corr/single_step/{model}/yeet.txt"
    params:
        dir = "data/derived_data/ww_genetic_corr/single_step/{model}",
        aireml_out_name = "aireml.{model}.out",
        aireml_log = "airemlf90.{model}.log",
        aireml_path = config['aireml_path']
    output:
        aireml_solutions = "data/derived_data/ww_genetic_corr/single_step/{model}/solutions",
        aireml_log = "data/derived_data/ww_genetic_corr/single_step/{model}/airemlf90.{model}.log"
    shell:
        """
        cd {params.dir}
        {params.aireml_path} renf90.par &> {params.aireml_out_name}
        mv airemlf90.log {params.aireml_log}
        rm genotypes*
        """
