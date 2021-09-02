BEGIN{
	FS="\t"
	print "#CHROM\tSTART\tEND\tREF\tALT\tgenome_mut\tRSID\tVAF\tDEPTH\tP-VAL\tSO\tIMPACT\tGENE\tNT_CHANGE\tAA_CHANGE\tLOF\tNMD\t1000Genomes\tExAC\tGnomAD\tClinVar\tRemark"
	ClinvarSig["."]="None"
	ClinvarSig[0]="Uncertain significance"
	ClinvarSig[1]="not provided"
	ClinvarSig[2]="Benign"
	ClinvarSig[3]="Likely benign"
	ClinvarSig[4]="Likely pathogenic"
	ClinvarSig[5]="Pathogenic"
	ClinvarSig[6]="drug response"
	ClinvarSig[8]="confers sensitivity"
	ClinvarSig[9]="risk-factor"
	ClinvarSig[10]="association"
	ClinvarSig[11]="protective"
	ClinvarSig[12]="conflict"
	ClinvarSig[13]="affects"
	ClinvarSig[255]="other"
}

/^#/{
       #print $0
}       
!/^#/{ 
	CHROM=$1
	POS=$2
	ID=$3
	REF=$4
	ALT=$5
	QUAL=$6
	FILTER=$7
	INFO_row=$8
	FORMAT_row=$9
	Sample1_row=$10

	# INFO
	n=split(INFO_row,tmp,";")
	n_of_fields = n
	INFO["LOF"]="."
	INFO["NMD"]="."
	for(i=1;i<=n;i++) {
		#printf("info[%s]=%s\n",i,tmp[i])
		split(tmp[i],tmptmp,"=")
		INFO[tmptmp[1]]=tmptmp[2]
		if(tmptmp[1] == "LOF")
			INFO["LOF"]="LOF"
		if(tmptmp[1] == "NMD")
			INFO["NMD"]="NMD"
		
	}
	delete tmp
	delete tmptmp
	n=split(INFO["ANN"],ANN,"|")
	# end of INFO

	n=split(FORMAT_row,FORMAT,":")
	n=split(Sample1_row,Sample1,":")
	for(i=1;i<=n;i++) {
		MUT[FORMAT[i]]=Sample1[i]
	}
	POS2=POS + length(REF) - 1
	printf("%s\t%s\t%s\t%s\t%s",CHROM,POS,POS2,REF,ALT)
	printf("\t%s:g.%s%s>%s\t%s",CHROM,POS,REF,ALT,ID)
	printf("\t%s\t%s\t%s",MUT["FREQ"],MUT["AD"],MUT["PVAL"])
	AA_CHANGE=ANN[11]
	if(AA_CHANGE == "")
	    AA_CHANGE = "."
	printf("\t%s\t%s\t%s\t%s\t%s",ANN[2],ANN[3],ANN[4],ANN[10],AA_CHANGE)
	if(n_of_fields > 6) {
		printf("\t%s\t%s",INFO["LOF"],INFO["NMD"])
		n=split(INFO["FREQ"],FREQ_array,"|")

		for(i=1;i<=n;i++) {
			split(FREQ_array[i],FREQ_elem,":")
			split(FREQ_elem[2],tmp,",")
			FREQ_value[FREQ_elem[1]]=tmp[1]
			delete tmp
			delete FREQ_elem
		}
		if(FREQ_value["1000Genomes"] == "")
			FREQ_value["1000Genomes"]=-1
		if(FREQ_value["ExAC"] == "")
			FREQ_value["ExAC"]=-1
		if(FREQ_value["GnomAD"] == "")
			FREQ_value["GnomAD"]=-1
		printf("\t%s\t%s\t%s",FREQ_value["1000Genomes"],FREQ_value["ExAC"],FREQ_value["GnomAD"])
		split(INFO["CLNSIG"],tmp,/[,|]/)
		if(tmp[1] == "")
			tmp[1] ="."
		printf("\t%s",ClinvarSig[tmp[1]])
		delete tmp
		delete FREQ_value
	}
	else {
		printf("\t%s\t%s\t-1\t-1\t-1\t.",INFO["LOF"],INFO["NMD"])
	}
	printf("\t%s",n_of_fields)
	printf("\n")


	delete INFO
	delete ANN
	delete FORMAT
	delete Sample1
	delete FREQ_array

}
