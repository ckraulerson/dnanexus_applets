#!/bin/bash
# Variant_Calling 0.5.31
# Generated by dx-app-wizard.

main() {
    
    dx download "$Tumor_BAM" -o ${pair_id}.tumor.bam
    dx download "$reference" -o ref.tar.gz
    
    mkdir dnaref
    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:0.5.31 tar -I pigz -xvf ref.tar.gz --strip-components=1 -C dnaref
    
    panelopt=''
    if [ -n "$panel" ]
    then
        dx download "$panel" -o panel.tar.gz
        docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:0.5.31 tar -I pigz -xvf panel.tar.gz
	capturebed=targetpanel.bed
	pon=mutect2.pon.vcf.gz
	panelopt="-b $capturebed"
    fi
    
    normopt=''
    if [ -n "$Normal_BAM" ]
    then
        dx download "$Normal_BAM" -o ${pair_id}.normal.bam
        normopt=" -n ${pair_id}.normal.bam"
    fi
    
    ponopt=''
    if [ -f "$pon" ]
    then
        ponopt="-q $pon"
    fi

    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:0.5.31 bash /seqprg/school/process_scripts/alignment/indexbams.sh
    
    vcfout=''
    vcfori=''
    outfile=''
    
    echo "$algo"
    
    for a in $algo
    do
        echo "Starting ${a}"
	vcfout+=" ${pair_id}.${a}.vcf.gz"
	vcfori+=" ${pair_id}.${a}.ori.vcf.gz"
	outfile+=".${a}"
	if [[ "${a}" == "mutect" ]] 
	then
	    for i in *.bam
	    do
		docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:0.5.31 bash /seqprg/school/process_scripts/variants/gatkrunner.sh -a gatkbam -b ${i} -r dnaref -p ${pair_id}
		mv $i $i.ori
		mv ${pair_id}.final.bam $i
	    done
	fi
	if [[ "${a}" == "fb" ]] || [[ "${a}" == "platypus" ]]
	then
	    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:0.5.31 bash /seqprg/school/process_scripts/variants/germline_vc.sh -r dnaref -p ${pair_id} -a ${a} ${panelopt}
	    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:0.5.31 bash /seqprg/school/process_scripts/variants/uni_norm_annot.sh -g 'GRCh38.92' -r dnaref -p ${pair_id}.${a} -v ${pair_id}.${a}.vcf.gz
	    
	elif [[ "${a}" == "strelka2" ]] || [[ "${a}" == "mutect" ]] || [[ "${a}" == "shimmer" ]]
	then
	    if [[ -z "$Normal_BAM" ]]
	    then
		docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:0.5.31 bash /seqprg/school/process_scripts/variants/germline_vc.sh -r dnaref -p ${pair_id} -a ${a} ${panelopt} ${ponopt}
	    else
		docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:0.5.31 bash /seqprg/school/process_scripts/variants/somatic_vc.sh -r dnaref -p ${pair_id} -n ${pair_id}.normal.bam -t ${pair_id}.tumor.bam -a ${a} ${panelopt} ${ponopt}
	    fi
	    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:0.5.31 bash /seqprg/school/process_scripts/variants/uni_norm_annot.sh -g 'GRCh38.92' -r dnaref -p ${pair_id}.${a} -v ${pair_id}.${a}.vcf.gz
	else
	    echo "Incorrect algorithm selection. Please select 1 of the following algorithms: fb platypus strelka2 mutect shimmer"
	fi
    done
    
    tar cf ${pair_id}${outfile}.vcfout.tar $vcfout
    tar cf ${pair_id}${outfile}.ori.tar $vcfori
    gzip ${pair_id}${outfile}.vcfout.tar
    gzip ${pair_id}${outfile}.ori.tar
    
    
    vcf=$(dx upload ${pair_id}${outfile}.vcfout.tar.gz --brief)
    ori=$(dx upload ${pair_id}${outfile}.ori.tar.gz --brief)
    
    dx-jobutil-add-output vcf "$vcf" --class=file
    dx-jobutil-add-output ori "$ori" --class=file
}
