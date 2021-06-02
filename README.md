# Input generator for IMa3

This is a [Snakemake](https://snakemake.readthedocs.io/en/stable/) pipeline to convert genetic variant information in VCF format to a format used for inference in [IMa3](https://github.com/jodyhey/IMa3). Essentially, this is an automated application of the [Popgen Pipeline Platform](https://github.com/jaredgk/PPP) for a specific application. 

## Installation

There are no specific installation steps required for this pipeline other than having the required dependencies. One can begin by cloning the repository to their local machine:

```sh
git clone git@github.com:Chris1221/IMa3_Input.git
cd IMa3_Input
```

To install all of the required dependencies, you may use the [conda](https://docs.conda.io/en/latest/) environment provided.

Assuming that you have [conda](https://docs.conda.io/en/latest/) installed locally, activate the environment by using the provided file.

```sh
conda env create --file=env.yml
conda activate ima3_input
```

## Usage

For basic usage, the only file you need to edit is `config.yaml`. This file is read by the pipeline and steps are performed according to your personal set up.

The required options that you need to edit are:

- `input`: The file path to your VCF.
- `analysis_name`: A unique identifier for this run of the pipeline.

Edit the configuration file to give your options:

```diff
- name: 
+ name: /path/to/your/file.vcf.gz

- analysis_name: 
+ analysis_name: my_first_run
```

Run the pipeline by using either the `input` or `run` directives.

```sh
snakemake input -j1 # -j1 means to use a single core
snakemake run -j20
```

The `inference_parameters` section of the configuration file is flexible. If you include an option here, it will be given as a flag to `IMa3`. 
