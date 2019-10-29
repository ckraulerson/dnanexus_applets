#!/bin/bash
# freebayes 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://documentation.dnanexus.com/developer for tutorials on how
# to modify this file.

main() {

    echo "Value of Consensus_BAM: '$Consensus_BAM'"
    echo "Value of Consensus_BAM_index: '$Consensus_BAM_index'"
    echo "Value of ref_file: '$ref_file'"
    echo "Value of pair_id: '$pair_id'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    dx download "$Consensus_BAM" -o consensus.bam
    dx download "$Consensus_BAM_index" -o consensus.bam.bai
    dx download "$ref_file" -o reference.tar.gz

    tar xvfz reference.tar.gz
    gunzip reference/genome.fa.gz

    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:v1 cut -f 1 reference/genomefile.5M.txt | parallel --delay 2 -j 1 "freebayes -f reference/genome.fa --min-base-quality 20 --min-coverage 10 --min-alternate-fraction 0.01 -C 3 --use-best-n-alleles 3 -r {} consensus.bam > fb.vcf"
    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:v1 vcf-concat fb.*.vcf | vcf-sort | vcf-annotate -n --fill-type | bcftools norm -c s -f reference/genome.fa -w 10 -O z -o ${pair_id}.freebayes.vcf.gz -

    freebayes_vcf=$(dx upload ${pair_id}.freebayes.vcf.gz --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output freebayes_vcf "$freebayes_vcf" --class=file
}
