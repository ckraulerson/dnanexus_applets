#!/bin/bash
# bamct_alignQC 0.0.1
# Generated by dx-app-wizard.

main() {

    dx download "$Aligned_BAM" -o aligned.bam
    dx download "$reference" -o dnaref.tar.gz
    dx download "$Align_Stats" -o alignerout.txt

    tar xvfz dnaref.tar.gz

    USER+$(dx whoami)

    if [[ ${bamct} == 1 ]]
    then
        docker run -v ${PWD}:/data docker.io/goalconsortium/vcfannot:1.0.0 samtools index aligned.bam
        docker run -v ${PWD}:/data docker.io/goalconsortium/vcfannot:1.0.0 bam-readcount -w 0 -q 0 -b 25 -f dnaref/genome.fa aligned.bam > ${pair_id}.bamreadcount.txt
    fi

    docker run -v ${PWD}:/data docker.io/goalconsortium/vcfannot:1.0.0 bash /usr/local/bin/bamqc.sh -p ${pair_id} -b aligned.bam -n rna
    docker run -v ${PWD}:/data docker.io/goalconsortium/gatk:1.0.0 perl /usr/local/bin/sequenceqc_rnaseq.pl *.flagstat.txt -r dnaref -e /project/PHG/PHG_Clinical/genomeseer -u $USER

    bamreadct=$(dx upload ${pair_id}.bamreadcount.txt --brief)
    fastqczip=$(dx upload ${pair_id}_fastqc.zip --brief)
    fastqchtml=$(dx upload ${pair_id}_fastqc.html --brief)
    seqstats=$(dx upload ${pair_id}.sequence.stats.txt --brief)

    dx-jobutil-add-output bamreadct "$bamreadct" --class=file
    dx-jobutil-add-output fastqczip "$fastqczip" --class=file
    dx-jobutil-add-output fastqchtml "$fastqchtml" --class=file
    dx-jobutil-add-output seqstats "$seqstats" --class=file
}
