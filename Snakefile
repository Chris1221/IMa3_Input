import pandas as pd

configfile: "config.yaml"

include: "rules/conversion.smk"

rule input:
	input: expand("run/{name}/ima_all_loci.ima.u", name = config["analysis_name"])


