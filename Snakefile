configfile: "config.yaml"

include: "rules/conversion.smk"
rule input:
	input: expand("run/{name}/ima_all_loci.ima.u", name = config["analysis_name"])

include: "rules/run_ima3.smk"
rule run:	
	input: expand("run/{name}/inference/ima3", name = config["analysis_name"])
