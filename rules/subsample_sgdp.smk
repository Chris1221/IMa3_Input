'''
Some logic for taking samples from the SGDP dataset. Not useful in the general case.'''

rule DownloadChromSizes:
    output: sizes = "data/hg19.chrom.sizes"
    params: url = "https://hgdownload.cse.ucsc.edu/goldenpath/hg19/bigZips/hg19.chrom.sizes"
    shell: "wget {params.url} -O {output.sizes}"

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
