
# nohup snakemake -s source_functions/ww_preadjust.snakefile --latency-wait 90 --jobs 10 --config --keep-going &> log/snakemake_log/200130.ww_preadjust.log &

#export LD_LIBRARY_PATH=/home/agiintern/.conda/envs/regionsenv/lib


configfile: "source_functions/config/ww_preadjust.yaml"

rule target:
    input:
        targ = "data/derived_data/ww_preadjust/solutions"

rule start:
    input:
        growth_data = "data/raw_data/HairShedGrowthData_090919.csv",
        par = "source_functions/par/ww_preadjust.par"
    output:
        ped = "data/derived_data/ww_preadjust/ped.txt",
        data = "data/derived_data/ww_preadjust/data.txt",
        par = "data/derived_data/ww_preadjust/ww_preadjust.par"
    shell:
        """
        Rscript --vanilla source_functions/ww_preadjust.R &> log/rule_log/ww_preadjust_start/ww_preadjust_start.log
        cp {input.par} {output.par}
        """

rule renumf90:
    input:
        input_par = "data/derived_data/ww_preadjust/ww_preadjust.par",
        data = "data/derived_data/ww_preadjust/data.txt",
        ped = "data/derived_data/ww_preadjust/ped.txt"
    params:
        dir = "data/derived_data/ww_preadjust",
        renumf90_path = config['renumf90_path']
    output:
        renf90_par = "data/derived_data/ww_preadjust/renf90.par"
    shell:
        """
        cd {params.dir}
        {params.renumf90_path} ww_preadjust.par &> renf90.ww_preadjust.out
        """

rule blupf90:
    input:
        renf90_par = "data/derived_data/ww_preadjust/renf90.par",
        data = "data/derived_data/ww_preadjust/data.txt",
        ped = "data/derived_data/ww_preadjust/ped.txt"
    params:
        dir = "data/derived_data/ww_preadjust",
        blupf90_out_name = "blupf90.ww_preadjust.out",
        blupf90_path = config['blupf90_path']
    output:
        solutions = "data/derived_data/ww_preadjust/solutions"
    shell:
        """
        cd {params.dir}
        {params.blupf90_path} renf90.par &> {params.blupf90_out_name}
        """
