"""
A convenience module to run the inference step. 
"""

def config_to_string(config):
	"""Convert all options given in the configuration 
	file to a string to just pass to the wrapper. A little easier
	than manually editing the rule each time."""
	string = ""
	for key, value in config["inference_parameters"].items():
		string += f"-{key} {str(value)} "		
	
	return string

rule Run_IMa:
	input: ima3 = "run/{name}/ima_all_loci.ima.u"
	params: options = config_to_string(config)
	output: table = "run/{name}/inference/ima3"
	shell: """
		ima3_wrapper.py \
			-i {input.ima3}\
			-o {output.table}\
			{params.options}
		"""
