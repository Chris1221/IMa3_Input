"""
Create IMa3 input from VCF via the Popgen Pipeline Platform (PPP).

This essentially replicates the process from the tutorial with arbitrary input and 
with some options parameterised. This is certainly not looking to replace the platform,
just to streamline some aspects of running data through it.
"""

import json

rule Create_Model_File:
	""" Create a basic model file for PPP. """
	output: model = "run/{name}/model_file.model"
	run:
		model = config["model"]
		json_out = [{}]
		json_out[0]["name"] = model["name"]
		json_out[0]["tree"] = model["tree"]
		json_out[0]["pops"] = {key: {"inds":value} for key, value in model["populations"].items()}

		with open(output.model, 'w') as j:
			json.dump(json_out, j)
			

rule Filter_VCF:
	""" Filter VCF file for missingness and sex chromosomes. """
	input: 
		vcf = config["input"],
		model = rules.Create_Model_File.output.model
	params: model_name = config["model"]["name"]
	output: vcf = "run/{name}/filtered.vcf.gz"
	shell: """
		vcf_filter.py \
			--vcf {input.vcf}\
			--filter-max-missing 1.0\
			--model-file {input.model}\
			--model {params.model_name}\
			--out-format vcf.gz\
			--out {output.vcf}
		"""

rule Index_Filter_VCF:
	input: vcf = rules.Filter_VCF.output.vcf
	output: index = "run/{name}/filtered.vcf.gz.tbi"
	shell: "tabix -p vcf {input.vcf}"
	
rule VCF_Calc:
	input: 
		filtered = rules.Filter_VCF.output.vcf,
		model = rules.Create_Model_File.output.model
	params: model_name = config["model"]["name"]
	output: regions = "run/{name}/stat_regions.bed"
	shell: """
		vcf_calc.py \
			--vcf {input.filtered}\
			--out {output.regions}\
			--calc-statistic windowed-weir-fst\
			--statistic-window-step 10000\
			--statistic-window-size 10000\
			--model-file {input.model}\
			--model {params.model_name}
		"""

rule Filter_for_Four_Gamete_Test:
	input: 
		vcf = rules.Filter_VCF.output.vcf,
		index = rules.Index_Filter_VCF.output.index,
		stat_file = rules.VCF_Calc.output.regions
	output: regions = "run/{name}/regions_for_sampling.bed"
	shell: """
		informative_loci_filter.py \
			--vcf {input.vcf}\
			--bed {input.stat_file}\
			--remove-indels\
			--minsites 3\
			--keep-full-line\
			--out {output.regions}\
			--randcount 5000\
			--remove-multi
		"""

rule DownloadChromSizes:
    output: sizes = "data/hg19.chrom.sizes"
    params: url = "https://hgdownload.cse.ucsc.edu/goldenpath/hg19/bigZips/hg19.chrom.sizes"
    shell: "wget {params.url} -O {output.sizes}"

rule Create_Genic_Slop:
	input: sizes = rules.DownloadChromSizes.output.sizes
	output: slop = "run/{name}/genic_regions_slop.bed"
	params: slop = 10000
	shell: """
		wget -c -O hg19.refGene.txt.gz http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/refGene.txt.gz
		gzip -cd hg19.refGene.txt.gz | cut -f 3,5,6 | bedtools slop -g {input.sizes} -b 10000 -i stdin > {output.slop}
		rm hg19.refGene.txt.gz
		"""


rule Remove_Genic_Regions:
	input: 
		regions = rules.Filter_for_Four_Gamete_Test.output.regions,
		slop = rules.Create_Genic_Slop.output.slop
	output: regions = "run/{name}/filtered_regions_for_sampling.bed"
	shell: """
		bedtools intersect -v -a {input.regions} -b {input.slop} > {output.regions}
		"""

rule test:
	input: expand("run/{name}/filtered_regions_for_sampling.bed", name = config["analysis_name"])


