#!/bin/bash
# align_markdups 0.5.30
# Generated by dx-app-wizard.

main() {

    dx download "$bam" -o ${pair_id}.bam
    dx download "$bai" -o ${pair_id}.bam.bai
    alignopt=''
    if [[ ${mdup} == 'fgbio_umi' ]]
    then
	alignopt=" -u"
    fi
    dx download "$humanref" -o humanref.tar.gz

    mkdir humanref
    docker run -v ${PWD}:/data docker.io/goalconsortium/alignment:0.5.30 tar -I pigz -xvf humanref.tar.gz --strip-components=1 -C humanref
    
    docker run -v ${PWD}:/data docker.io/goalconsortium/alignment:0.5.30 bash /seqprg/school/process_scripts/alignment/markdups.sh -a ${mdup} -b ${pair_id}.bam -p ${pair_id} -r humanref
    
    mv ${pair_id}.dedup.bam ${pair_id}.consensus.bam
    mv ${pair_id}.dedup.bam.bai ${pair_id}.consensus.bam.bai

    conbam=$(dx upload ${pair_id}.consensus.bam --brief)
    conbai=$(dx upload ${pair_id}.consensus.bam.bai --brief)
    dx-jobutil-add-output conbam "$conbam" --class=file
    dx-jobutil-add-output conbai "$conbai" --class=file
}
