import pandas as pd

configfile: "config.yaml"


rule DownloadChromSizes:
    output: sizes = "data/hg19.chrom.sizes"
    params: url = "https://hgdownload.cse.ucsc.edu/goldenpath/hg19/bigZips/hg19.chrom.sizes"
    shell: "wget {params.url} -O {output.sizes}"

rule TiledBed:
    input: sizes = rules.DownloadChromSizes.output.sizes
    output: bed = "data/tiled_bed.bed"
    params: step = 2000
    run:
        sizes = pd.read_csv(input.sizes, sep = "\t", header = None)
        valid = [f"chr{i}" for i in range(1, 23)]

        dfs = []
        for i, row in sizes.iterrows():
            if row[0] in valid:
                dfs.append(
                    pd.DataFrame({
                        "chr": row[0],
                        "start": range(0, int(row[1])-params.step, params.step ),
                        "end": range(params.step, int(row[1]), params.step)
                    })
                )
        
        df = pd.concat(dfs)
        df.to_csv(output.bed, sep = "\t", header = False, index = False)


rule test:
    input: "data/tiled_bed.bed" 



rule FourGameteTest:
    input: vcf = config["input"], bed = rules.TiledBed.output.bed
    output: fgt = "run/fgt.txt"
    shell: "vcf_four_gamete.py --vcfreg {input.vcf} {input.bed} -o {output.fgt}"