
rule DownloadChromSizes:
    output: sizes = "data/hg19.chrom.sizes"
    params: url = "https://hgdownload.cse.ucsc.edu/goldenpath/hg19/bigZips/hg19.chrom.sizes"
    shell: "wget {params.url} -O {output.sizes}"

rule TiledBed:
    input: sizes = rules.DownloadChromSizes.output.sizes
    output: bed = "data/tiled_bed.bed"
    params: step = 20000000
    run:
        sizes = pd.read_csv(input.sizes, sep = "\t", header = None)
        valid = [f"chr{i}" for i in range(1, 23)]

        dfs = []
        for i, row in sizes.iterrows():
            if row[0] in valid:
                dfs.append(
                    pd.DataFrame({
                        "chr": row[0][3:],
                        "start": range(0, int(row[1])-params.step, params.step ),
                        "end": range(params.step, int(row[1]), params.step)
                    })
                )
        
        df = pd.concat(dfs)
        df.to_csv(output.bed, sep = "\t", header = False, index = False)



rule SubsetVCF:
	input: sgdp = "vcf/chr_ALL.filtered.vcf"
	output: subset = "run/{name}/subset.vcf"
	run:
		col_names = ["#CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT"] + config["samples"]
		sgdp = pd.read_csv(input.sgdp, skiprows=30, sep = "\t", usecols = col_names)
		sgdp.to_csv(output.subset, sep = "\t", header = True, index = False) 

rule CompressAndIndexVCF:
	input: vcf = "vcf/chr_ALL.filtered.vcf", subset = rules.SubsetVCF.output.subset
	output: vcf = "run/{name}/subset.vcf.gz", idx = "run/{name}/subset.vcf.gz.tbi"
	shell:  """
		head -n 30 {input.vcf} > .tmp 
		cat {input.subset} >> .tmp
		bgzip -c .tmp > {output.vcf}
		tabix -p vcf {output.vcf}
		rm .tmp
		"""


rule FourGameteTest:
    input: vcf = "run/{name}/subset.vcf", bed = rules.TiledBed.output.bed
    output: fgt = "run/{name}/fgt.txt"
    shell: """
		#vcf_four_gamete.py --vcfreg {input.vcf} {input.bed} --out-prefix {output.fgt} --reti --fourgcompat --ovlps
		vcf_four_gamete.py --vcfs {input.vcf} --out-prefix {output.fgt} --reti --fourgcompat --ovlps
		"""

rule test:
	input: f"run/{config['analysis_name']}/fgt.txt"
