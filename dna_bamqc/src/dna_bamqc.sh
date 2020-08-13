#!/bin/bash
# QC_Stats
# Generated by dx-app-wizard.

main() {

    dx download "$bam" -o ${sampleid}.bam
    dx download "$bai" -o ${sampleid}.bam.bai
    dx download "$refinfo" -o reference.tar.gz
    dx download "$panel" -o panel.tar.gz
    dx download "$trimstat" -o ${sampleid}.trimreport.txt
    
    tar xvfz panel.tar.gz
    tar xvfz reference.tar.gz
    
    USER=$(dx whoami)

    docker run -v ${PWD}:/data docker.io/goalconsortium/profiling_qc:1.0.0 bash /seqprg/school/process_scripts/alignment/bamqc.sh -c targetpanel.bed -n dna -r ./ -b ${sampleid}.bam -p ${sampleid} -u $USER
    tar -czvf ${sampleid}.sequence.stats.tar.gz ${sampleid}.flagstat.txt ${sampleid}.covhist.txt ${sampleid}.genomecov.txt ${sampleid}.ontarget.flagstat.txt ${sampleid}.sequence.stats.txt

    seqstats=$(dx upload ${sampleid}.sequence.stats.tar.gz --brief)
    dx-jobutil-add-output seqstats "$seqstats" --class=file
}
