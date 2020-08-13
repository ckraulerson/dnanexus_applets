#!/bin/bash
# variant_profiling
# Generated by dx-app-wizard.

main() {

    dx download "$tbam" -o ${caseid}.tumor.bam
    dx download "$reference" -o ref.tar.gz
    
    normopt=''
    if [ -n "$nbam" ]
    then
        dx download "$nbam" -o ${caseid}.normal.bam
	normopt=" -n ${caseid}.normal.bam"
    fi

    mkdir dnaref
    docker run -v ${PWD}:/data docker.io/goalconsortium/profiling_qc:1.0.0 tar -I pigz -xvf ref.tar.gz --strip-components=1 -C dnaref

    if [ -n "$panel" ]
    then
        dx download "$panel" -o panel.tar.gz
         docker run -v ${PWD}:/data docker.io/goalconsortium/profiling_qc:1.0.0 tar -I pigz -xvf panel.tar.gz
    fi

    docker run -v ${PWD}:/data docker.io/goalconsortium/profiling_qc:1.0.0 bash /seqprg/school/process_scripts/alignment/indexbams.sh

    if [[ -n "$nbam" ]]
    then
	
	docker run -v ${PWD}:/data docker.io/goalconsortium/profiling_qc:1.0.0 bash /seqprg/school/process_scripts/variants/checkmate.sh -r dnaref -p ${caseid} -c dnaref/NGSCheckMate.bed -f
	echo -e "TumorFILE\t${tbam}" >> ${caseid}.sequence.stats.txt
	echo -e "NormalFILE\t${nbam}" >> ${caseid}.sequence.stats.txt
	
        matched=$(dx upload ${caseid}_matched.txt --brief)
        all=$(dx upload ${caseid}_all.txt --brief)
        seqstats=$(dx upload ${caseid}.sequence.stats.txt --brief)
	
        dx-jobutil-add-output matched "$matched" --class=file
        dx-jobutil-add-output all "$all" --class=file
        dx-jobutil-add-output seqstats "$seqstats" --class=file
    fi
    docker run -v ${PWD}:/data docker.io/goalconsortium/profiling_qc:1.0.0 bash /seqprg/school/process_scripts/variants/msisensor.sh -r dnaref -p ${caseid} -b ${caseid}.tumor.bam -c targetpanel.bed $normopt
    msiout=$(dx upload ${caseid}.msi --brief)
    dx-jobutil-add-output msiout "$msiout" --class=file
}
