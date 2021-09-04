function emit_civic(CSQ, csq_array,evid,i,j,n,m) {

    # 1 Allele
    # 2 Consequence
    # 3 SYMBOL
    # 4 Entrez Gene ID
    # 5 Feature_type
    # 6 Feature
    # 7 HGVSc
    # 8 HGVSp
    # 9 CIViC Variant Name
    # 10 CIViC Variant ID
    # 11 CIViC Variant Aliases
    # 12 CIViC HGVS
    # 13 Allele Registry ID
    # 14 ClinVar IDs
    # 15 CIViC Variant Evidence Score
    # 16 CIViC Entity Type
    # 17 CIViC Entity ID
    # 18 CIViC Entity URL
    # 19 CIViC Entity Source
    # 20 CIViC Entity Variant Origin
    # 21 CIViC Entity Status
    # 22 CIViC Entity Clinical Significance
    # 23 CIViC Entity Direction
    # 24 CIViC Entity Disease
    # 25 CIViC Entity Drugs
    # 26 CIViC Entity Drug Interaction Type
    # 27 CIViC Evidence Phenotypes
    # 28 CIViC Evidence Level
    # 29 CIViC Evidence Rating
    # 30 CIViC Assertion ACMG Codes
    # 31 CIViC Assertion AMP Category
    # 32 CIViC Assertion NCCN Guideline
    # 33 CIVIC Assertion Regulatory Approval
    # 34 CIVIC Assertion FDA Companion Test

        # emit header
        print "\t#CIViC Evidence"
	    print "\t#HGVSc\tVariant Name\tURL\tSource\tVariant Origin\tClinical Significance\tEntity Direction\tDisease\tDrugs\tEvidence Level\tEvidence Rating"

	    n = split(CSQ,csq_array,",")
	    for(i=1;i<=n;i++) {
		m=split(csq_array[i],evid,"|")
		printf("\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",evid[7],evid[9],evid[18],evid[19],evid[20],evid[22],evid[23],evid[24],evid[25],evid[28],evid[29])
	    }
}

BEGIN{
	FS="\t"
	MutHeader="#CHROM\tSTART\tEND\tREF\tALT\tGenomic Pos\tRSID;ClinID\tVAF\tDEPTH\tP-VAL\tSO\tIMPACT\tGENE\tTRANSCRIPT\tNT_CHANGE\tAA_CHANGE\tLOF\tNMD\tGnomAD\tClinVar\tOrigin\tRemark"
	cMutHeader="#Genomic Pos\tRSID;ClinID\tVAF\tDEPTH\tP-VAL\tSO\tIMPACT\tGENE\tTRANSCRIPT\tNT_CHANGE\tAA_CHANGE\tLOF\tNMD\tGnomAD\tClinVar\tOrigin\tRemark"

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

	ClinOrigin[0]="unknown"
	ClinOrigin[1]="germline"
	ClinOrigin[2]="somatic"
	ClinOrigin[3]="both"
	ClinOrigin[4]="inherited"
	ClinOrigin[8]="paternal"
	ClinOrigin[16]="maternal"
	ClinOrigin[32]="de-novo"
	ClinOrigin[64]="biparental"
	ClinOrigin[128]="uniparental"
	ClinOrigin[256]="not-tested"
	ClinOrigin[512]="tested-inconclusive"
	ClinOrigin[1073741824]="other"
	ClinOrigin["."]="."

	CIVIC_HITS=0
	
	if( mode != "civic")
	    print MutHeader
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


	INFO["AF"]=-1
	INFO["CLNSIG"]="."
	INFO["ORIGIN"]="."
	
	for(i=1;i<=n;i++) {
		split(tmp[i],tmptmp,"=")
		INFO[tmptmp[1]]=tmptmp[2]
		if(tmptmp[1] == "LOF")
			INFO["LOF"]="LOF"
		if(tmptmp[1] == "NMD")
			INFO["NMD"]="NMD"
	}
	delete tmp
	delete tmptmp
	# end of INFO

	n_of_ANN=split(INFO["ANN"],ANN_array,",")

	# is civic report mode ? 
	if(mode == "civic") {
	    if(INFO["CSQ"] == "") {
		delete INFO
		next
	    }
	    else {
		print cMutHeader
		CIVIC_HITS++
	    }
	}
	    
	for(k=1;k<=n_of_ANN;k++) {
	    n=split(ANN_array[k],ANN,"|")
	    n=split(FORMAT_row,FORMAT,":")
	    n=split(Sample1_row,Sample1,":")
	    for(i=1;i<=n;i++) {
		MUT[FORMAT[i]]=Sample1[i]
	    }
	    POS2=POS + length(REF) - 1

	    if(mode == "collapse" && k>=2) {
		AA_CHANGE=ANN[11]
		if(AA_CHANGE == "")
		    AA_CHANGE = "."
		if(k>=3)
		    printf("|")
		printf("%s,%s:%s(%s)",ANN[4],ANN[7],ANN[10],AA_CHANGE)
		continue
	    }

	    if(k>=2)
		printf("\n")
	    
	    if(mode == "civic") {
		printf("%s:g.%s%s>%s",CHROM,POS,REF,ALT)
		#if(k > 1)
		#    printf("(%d)",k)
		printf("\t%s",ID)
	    }
	    else {
		printf("%s\t%s\t%s\t%s\t%s",CHROM,POS,POS2,REF,ALT)
		printf("\t%s:g.%s%s>%s",CHROM,POS,REF,ALT)
		#if(k > 1)
		#    printf("(%d)",k)
		printf("\t%s",ID)
	    }
	    
	    printf("\t%s\t%s\t%s",MUT["FREQ"],MUT["AD"],MUT["PVAL"])
	    AA_CHANGE=ANN[11]
	    if(AA_CHANGE == "")
		AA_CHANGE = "."
	    printf("\t%s\t%s\t%s\t%s\t%s\t%s",ANN[2],ANN[3],ANN[4],ANN[7],ANN[10],AA_CHANGE)
	    printf("\t%s\t%s\t%s\t%s\t%s",INFO["LOF"],INFO["NMD"],INFO["AF"],INFO["CLNSIG"],ClinOrigin[INFO["ORIGIN"]])
	    if(mode == "collapse") {
		printf("\t")
	    }
	    else if(k>=2) {
		printf("\tTranscript(%d)",k)
	    }
	    else {
		printf("\t")
	    }
	    #printf("\t%s",n_of_fields)
	}
	printf("\n")


	if(mode == "civic") {
	    emit_civic(INFO["CSQ"])
	    printf("\n")
	}
	
	delete ANN_array
	delete INFO
	delete ANN
	delete FORMAT
	delete Sample1
	delete FREQ_array

}

END {
    if(mode == "civic") {
	print "vcfilter2.awk reports " CIVIC_HITS " civic mutation hits" > "/dev/stderr"
    }
}
