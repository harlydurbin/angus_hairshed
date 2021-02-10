
#nohup snakemake -s source_functions/gwas_hair.snakefile --latency-wait 90 --resources load=100 --jobs 10 --config --keep-going &> log/snakemake_log/200407.gwas_hair.log &

#export LD_LIBRARY_PATH=/home/agiintern/.conda/envs/regionsenv/lib

# nohup psrecord 61255 --log data/derived_data/gwas_hair/activity.postgsf90.txt --plot data/derived_data/gwas_hair/activity_plot.postgsf90.png &
configfile: "source_functions/config/gwas_hair.yaml"

rule all:
    input:
        expand("data/derived_data/gwas_hair/iter{iter}/snp_sol", iter = config['iter'])

rule start:
    input:
        angus_join = "data/derived_data/angus_join.rds"
    output:
        start = "data/derived_data/start.rds"
    shell:
        """
        Rscript --vanilla source_functions/start.R &> log/rule_log/start/start.log
        """

# Generate data, ped, list of genotypes to pull from master file
# Copy blupf90 par file
rule gwas_start:
    input:
        start = "data/derived_data/start.rds"
    output:
        ped = "data/derived_data/gwas_hair/ped.txt",
        data = "data/derived_data/gwas_hair/data.txt",
        pull_list = "data/derived_data/gwas_hair/pull_list.txt"
    shell:
        """
        Rscript --vanilla source_functions/gwas_hair_start.R &> log/rule_log/gwas_hair_start/gwas_hair_start.log
        """
rule copy_par:
    input:
        par = "source_functions/par/gwas_hair.par"
    output:
        par = "data/derived_data/gwas_hair/gwas_hair.par"
    shell:
        "cp {input.par} {output.par}"


# Generate file of genotypes
rule pull_genotypes:
    resources:
        load = 1
    input:
        pull_list = "data/derived_data/gwas_hair/pull_list.txt",
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/gwas_hair/genotypes.txt"
    shell:
    # https://www.gnu.org/software/gawk/manual/html_node/Printf-Examples.html
        """
        grep -Fwf {input.pull_list} {input.master_geno} | awk '{{printf "%-20s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """
# Create file intial weights (just a column of 1s the length of the number of SNPs)
rule initial_weights:
    resources:
        load = 1
    input: "data/derived_data/chrinfo.imputed_hair.txt"
    output:
        weights = "data/derived_data/gwas_hair/iter0/weights.txt"
        # 233,246 SNPs prior to filtering
    shell:
        """
        awk 'BEGIN {{ for (i==1;i<233246;i++) print 1}}' > {output.weights}
        """

rule renum_blupf90:
    resources:
        load = 20
    input:
        input_par = "data/derived_data/gwas_hair/gwas_hair.par",
        genotypes = "data/derived_data/gwas_hair/genotypes.txt",
        datafile = "data/derived_data/gwas_hair/data.txt",
        pedfile = "data/derived_data/gwas_hair/ped.txt",
        initial_weights = "data/derived_data/gwas_hair/iter0/weights.txt",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt"
    params:
        dir = "data/derived_data/gwas_hair",
        renumf90_path = config['renumf90_path']
    output:
        blupf90_par = "data/derived_data/gwas_hair/renf90.blup.par"
    shell:
        """
        cd {params.dir}
        {params.renumf90_path} gwas_hair.par &> renf90.blup.out
        mv renf90.par renf90.blup.par
        """

rule blupf90:
    resources:
        load = 100
    input:
        blupf90_par = "data/derived_data/gwas_hair/renf90.blup.par",
        genotypes = "data/derived_data/gwas_hair/genotypes.txt",
        datafile = "data/derived_data/gwas_hair/data.txt",
        pedfile = "data/derived_data/gwas_hair/ped.txt",
        initial_weights = "data/derived_data/gwas_hair/iter0/weights.txt",
        format_map = "data/derived_data/chrinfo.imputed_hair.txt"
    params:
        dir = "data/derived_data/gwas_hair",
        blupf90_out_name = "blupf90.hair.out",
        blupf90_path = config['blupf90_path']
    output:
        blupf90_solutions = "data/derived_data/gwas_hair/solutions",
        xx_ija = "data/derived_data/gwas_hair/xx_ija",
        sum2pq = "data/derived_data/gwas_hair/sum2pq"
    shell:
        """
        cd {params.dir}
        {params.blupf90_path} renf90.blup.par &> {params.blupf90_out_name}
        """

rule postgsf90_par_0:
    resources:
        load = 10
    input:
        blupf90_solutions = "data/derived_data/gwas_hair/solutions",
        blupf90_par = "data/derived_data/gwas_hair/renf90.blup.par",
        postgsf90_options = "source_functions/par/postgsf90_options.txt"
    output:
        postgsf90_par = "data/derived_data/gwas_hair/iter0/renf90.postgs.par"
    # Copy first 33 lines of BLUPF90 parameter file
    # Add postgsf90 options
    # Replace dat and ped file locations
    shell:
        """
        head -n 33 {input.blupf90_par} &> {output.postgsf90_par}
        cat {input.postgsf90_options} >> {output.postgsf90_par}
        sed -i '3s/renf90/\.\.\/renf90/' {output.postgsf90_par}
        sed -i '23s/renadd02/\.\.\/renadd02/' {output.postgsf90_par}
        """

rule postgsf90_0:
    resources:
        load = 100
    input:
        blupf90_solutions = "data/derived_data/gwas_hair/solutions",
        postgsf90_par = "data/derived_data/gwas_hair/iter0/renf90.postgs.par",
        xx_ija = "data/derived_data/gwas_hair/xx_ija",
        sum2pq = "data/derived_data/gwas_hair/sum2pq"
    params:
        dir = "data/derived_data/gwas_hair/iter0",
        postgsf90_out_name = "postgsf90.0.out",
        postgsf90_path = config['postgsf90_path']
    output:
        snp_sol = "data/derived_data/gwas_hair/iter0/snp_sol",
        xx_ija = temp("data/derived_data/gwas_hair/iter0/xx_ija"),
        sum2pq = temp("data/derived_data/gwas_hair/iter0/sum2pq")
    shell:
        """
        cp {input.xx_ija} {output.xx_ija}
        cp {input.sum2pq} {output.sum2pq}
        cd {params.dir}
        {params.postgsf90_path} renf90.postgs.par &> {params.postgsf90_out_name}
        """

#https://stackoverflow.com/questions/56274065/snakemake-using-a-rule-in-a-loop
def recurse_weights1(input_n):
    n = int(input_n)
    if n == 1:
        return "data/derived_data/gwas_hair/iter0/snp_sol"
    elif n > 1:
        return "data/derived_data/gwas_hair/iter%s/snp_sol" % (n-1)
    else:
        raise ValueError("loop numbers must be 1 or greater: received %d" % wcs.iter)

# Pull SNP weights from the previous iteration
rule pull_weights:
    input:
        snp_sol = lambda wildcards: recurse_weights1("{iter}".format(iter = wildcards.iter))
    output:
        weights = "data/derived_data/gwas_hair/iter{iter}/weights.txt"
    shell:
        """
        awk 'NR>1 {{print $7}}' {input.snp_sol} &> {output.weights}
        """

rule postgsf90_iterate:
    resources:
        load = 100
    input:
        blupf90_solutions = "data/derived_data/gwas_hair/solutions",
        weights = "data/derived_data/gwas_hair/iter{iter}/weights.txt",
        postgsf90_par = "data/derived_data/gwas_hair/iter0/renf90.postgs.par",
        xx_ija = "data/derived_data/gwas_hair/xx_ija",
        sum2pq = "data/derived_data/gwas_hair/sum2pq"
    params:
        dir = "data/derived_data/gwas_hair/iter{iter}",
        postgsf90_out_name = "postgsf90.{iter}.out",
        postgsf90_path = config['postgsf90_path']
    output:
        snp_sol = "data/derived_data/gwas_hair/iter{iter}/snp_sol"
    shell:
        """
        cp {input.postgsf90_par} {params.dir}
        cp {input.xx_ija} {params.dir}
        cp {input.sum2pq} {params.dir}
        cd {params.dir}
        {params.postgsf90_path} renf90.postgs.par &> {params.postgsf90_out_name}
        rm *.R
        rm *.gnuplot
        rm xx_ija
        rm sum2pq
        """
