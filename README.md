# vcf_to_ima3

Filtered for:
- Less than 5x coverage for all individuals
- regions within 10k basepairs of refseq loci
- No human / chimpanzee synteny
- Recent segmental duplications
- CpGs (probably exclude repeat masker)
- conserved non-coding elements 
- CG-biased gene conversion. 
- Sequences were phased and sub-sampled using the 4-gamete criterion. 

They used 200 regions with a mean length of 1490 basepairs