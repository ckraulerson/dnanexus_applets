#!/bin/bash
# STARalign 0.5.9
# Generated by dx-app-wizard.

main() {

    dx download "$fq1" -o ${pair_id}.trim.R1.fastq.gz
    dx download "$fq2" -o ${pair_id}.trim.R2.fastq.gz
    dx download "$reference" -o dnaref.tar.gz

    tar xvfz dnaref.tar.gz

    if [[ ${mdup} == 'fgbio_umi' ]]
    then
        docker run -v ${PWD}:/data docker.io/goalconsortium/ralign:0.5.9 /usr/local/bin/rnaseqalign.sh -a ${aligner} -p ${pair_id} -r dnaref -x ${pair_id}.trim.R1.fastq.gz -y ${pair_id}.trim.R2.fastq.gz -u
    else
        docker run -v ${PWD}:/data docker.io/goalconsortium/ralign:0.5.9 /usr/local/bin/rnaseqalign.sh -a ${aligner} -p ${pair_id} -r dnaref -x ${pair_id}.trim.R1.fastq.gz -y ${pair_id}.trim.R2.fastq.gz
    fi
    docker run -v ${PWD}:/data docker.io/goalconsortium/ralign:0.5.9 /usr/local/bin/starfusion.sh -p ${pair_id} -r dnaref -a ${pair_id}.trim.R1.fastq.gz -b ${pair_id}.trim.R2.fastq.gz -m trinity -f

    bam=$(dx upload ${pair_id}.bam --brief)
    bai=$(dx upload ${pair_id}.bam.bai --brief)
    alignstats=$(dx upload ${pair_id}.alignerout.txt --brief)
    starfusion=$(dx upload ${pair_id}.starfusion.txt --brief)

    dx-jobutil-add-output bam "$bam" --class=file
    dx-jobutil-add-output bai "$bai" --class=file
    dx-jobutil-add-output alignstats "$alignstats" --class=file
    dx-jobutil-add-output starfusion "$starfusion" --class=file
}
