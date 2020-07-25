#!/bin/bash
# geneabund 0.5.26
# Generated by dx-app-wizard.

main() {

    dx download "$Aligned_BAM" -o ${pair_id}.bam
    dx download "$gtf" -o gencode.gtf.gz

    gunzip gencode.gtf.gz
    cp /datadir/gene_info.human.txt.gz .
    gunzip gene_info.human.txt.gz

    if [[ -z "${glist}" ]]
    then
        docker run -v ${PWD}:/data docker.io/goalconsortium/geneabund:0.5.26 -s ${stranded} -g /data/gencode.gtf -p ${pair_id} -b ${pair_id}.bam -i /data/gene_info.human.txt
    else
        dx download "$glist" -o genelist.txt
        docker run -v ${PWD}:/data docker.io/goalconsortium/geneabund:0.5.26 -s ${stranded} -g /data/gencode.gtf -p ${pair_id} -b ${pair_id}.bam -f /data/genelist.txt -i /data/gene_info.human.txt
    fi

    counts=$(dx upload ${pair_id}.cts --brief)
    strcts=$(dx upload ${pair_id}_stringtie --brief)
    fpkm=$(dx upload ${pair_id}.fpkm.txt --brief)

    dx-jobutil-add-output counts "$counts" --class=file
    dx-jobutil-add-output strcts "$strcts" --class=file
    dx-jobutil-add-output fpkm "$fpkm" --class=file
}
