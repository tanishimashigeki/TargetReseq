#!/bin/bash

MY_NAME=`basename $0`
CMD_PATH=${0%%${MY_NAME}}
#echo $CMD_PATH

# Database
GENOME_VERSION=hg19
REFERENCE_FASTA=${CMD_PATH}/${GENOME_VERSION}.fa
#
_GNOMAD_VCF=gnomad.exomes.r2.1.1.sites.vcf.bgz
_CLINVAR_VCF=clinvar_20210828.vcf
_CIVIC_VCF=nightly-civic_accepted_and_submitted.sorted.vcf
#
GNOMAD_VCF=$CMD_PATH/$_GNOMAD_VCF
CLINVAR_VCF=$CMD_PATH/$_CLINVAR_VCF
CIVIC_VCF=$CMD_PATH/$_CIVIC_VCF

# env params
#THREADS=4

##
#input
if [ $# -ne 1 ]
then
	echo "ARGUMENTS ERROR : $MY_NAME [input raw VCF]"
	exit 1
fi

INPUT_VCF=$1

#output file name
PREFIX=${INPUT_VCF%%.vcf}
OUTPUT_VCF=${PREFIX}.annotated.vcf
OUTPUT_NORMAL_VCF=${PREFIX}.normal.tsv
OUTPUT_COLLAPSE_VCF=${PREFIX}.collapse.tsv
OUTPUT_CIVIC_VCF=${PREFIX}.civic.tsv

## Annotation Pile Command
# annotation params
_SNPEFF_JAR=snpEff.jar
SNPEFF_JAR=$CMD_PATH/$_SNPEFF_JAR
SNPEFF_OPT="-canon"
_SNPSIFT_JAR=SnpSift.jar
SNPSIFT_JAR=$CMD_PATH/$_SNPSIFT_JAR

# run annotation 
DO_CMD="java -Xmx4g -jar $SNPEFF_JAR $SNPEFF_OPT $GENOME_VERSION $INPUT_VCF \
	| java -jar $SNPSIFT_JAR annotate $GNOMAD_VCF - \
	| java -jar $SNPSIFT_JAR annotate $CLINVAR_VCF - \
	| java -jar $SNPSIFT_JAR annotate $CIVIC_VCF - > $OUTPUT_VCF"

echo $DO_CMD
eval $DO_CMD
CODE=$?
if [ $CODE != 0 ]
then
	echo "error: $MY_NAME exit with $CODE"
	exit $CODE
fi

## Generate Report
#
_VCFILTER2_AWK=vcfilter2.awk
VCFILTER2_AWK=$CMD_PATH/$_VCFILTER2_AWK
echo "$MY_NAME : generating reports..."
awk -f $VCFILTER2_AWK -v mode=normal $OUTPUT_VCF > $OUTPUT_NORMAL_VCF
awk -f $VCFILTER2_AWK -v mode=collapse $OUTPUT_VCF > $OUTPUT_COLLAPSE_VCF
awk -f $VCFILTER2_AWK -v mode=civic $OUTPUT_VCF > $OUTPUT_CIVIC_VCF
echo "$MY_NAME : wrote $OUTPUT_NORMAL_VCF $OUTPUT_COLLAPSE_VCF $OUTPUT_CIVIC_VCF"
exit 0
