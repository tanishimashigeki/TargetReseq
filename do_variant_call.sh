#!/bin/bash

MY_NAME=`basename $0`
CMD_PATH=${0%%${MY_NAME}}
#echo $CMD_PATH

# Panel params
PANEL_BED_FILE=QIAGEN_panel.bed
PANEL_BED=$CMD_PATH/$PANEL_BED_FILE
# Database
GENOME_VERSION=hg19
REFERENCE_FASTA=${CMD_PATH}/${GENOME_VERSION}.fa
# env params
THREADS=4

##
#input
if [ $# -ne 3 ]
then
	echo "ARGUMENTS ERROR : $MY_NAME [fasq R1] [fastq R2] [Prefix]"
	exit 1
fi

INPUT_FASTQ_1=$1
INPUT_FASTQ_2=$2
PREFIX=$3
ANALYSIS_READY_BAM=${PREFIX}.bam

## TRIMMOMATIC
# trimmomaric params
_TRIMMO_JAR=trimmomatic-0.39.jar
TRIMMO_JAR=$CMD_PATH/$_TRIMMO_JAR
TRIMMO_OPT1="PE -threads 4 -phred33"
TRIMMO_ADAPTER=${CMD_PATH}/adapters/TruSeq3-PE-2.fa
TRIMMO_OPT2="ILLUMINACLIP:${TRIMMO_ADAPTER}:2:30:10 LEADING:30 TRAILING:30 SLIDINGWINDOW:5:30 MINLEN:75"

# run trimmomaric 
OUT_FASTQ_1=$$.${PREFIX}_1.fq
UNPAIR_FASTQ_1=$$.${PREFIX}_unpaired_1.fq
OUT_FASTQ_2=$$.${PREFIX}_2.fq
UNPAIR_FASTQ_2=$$.${PREFIX}_unpaired_2.fq

DO_CMD="java -jar $TRIMMO_JAR $TRIMMO_OPT1 $INPUT_FASTQ_1 $INPUT_FASTQ_2 $OUT_FASTQ_1 $UNPAIR_FASTQ_1 $OUT_FASTQ_2 $UNPAIR_FASTQ_2 $TRIMMO_OPT2"
echo $DO_CMD
eval $DO_CMD
CODE=$?
if [ $CODE != 0 ]
then
	echo "error: $_TRIMMO_JAR exit with $CODE"
	exit $CODE
else
	rm $UNPAIR_FASTQ_1
	rm $UNPAIR_FASTQ_2
fi

## BWA
# BWA params
BWA_INDEX=${CMD_PATH}/${GENOME_VERSION}
BAM1=$$.${PREFIX}.sorted.bam

# run BWA
DO_CMD="bwa mem -t 4 $BWA_INDEX $OUT_FASTQ_1 $OUT_FASTQ_2 | samtools sort -O bam -o $BAM1 -"
echo $DO_CMD
eval $DO_CMD
samtools index $BAM1

## ABRA2
# abra2 params
_ABRA2_JAR=abra2.jar
ABRA2_JAR=$CMD_PATH/$_ABRA2_JAR
BAM2=$$.${PREFIX}.abra2.bam
# run abra2
DO_CMD="java -Xmx12G -Xms8M -jar $ABRA2_JAR --in $BAM1 --out $BAM2 --ref $REFERENCE_FASTA --targets $PANEL_BED --threads $THREADS --undup --nosort"
echo $DO_CMD
eval $DO_CMD
samtools sort $BAM2 -o $ANALYSIS_READY_BAM
samtools index $ANALYSIS_READY_BAM
DO_CMD="samtools flagstat $ANALYSIS_READY_BAM"
echo $DO_CMD
eval $DO_CMD

## VarScan2
# varascan2 params
_VARSCAN2_JAR=VarScan2.jar
VARSCAN2_JAR=$CMD_PATH/$_VARSCAN2_JAR
SNV_VCF=$$.${PREFIX}.snv.vcf
INDEL_VCF=$$.${PREFIX}.indel.vcf
MPILEUP_FILE=$$.${PREFIX}.mileup
RAW_VCF=${PREFIX}.vcf
# run VarScan2
DO_CMD="samtools mpileup -l $PANEL_BED -f $REFERENCE_FASTA -BAQ 0 $ANALYSIS_READY_BAM | tee $MPILEUP_FILE | java -jar $VARSCAN2_JAR mpileup2snp --output-vcf > $SNV_VCF"
echo $DO_CMD
eval $DO_CMD
DO_CMD="cat $MPILEUP_FILE | java -jar $VARSCAN2_JAR mpileup2indel --output-vcf > $INDEL_VCF"
echo $DO_CMD
eval $DO_CMD

vcf-concat $SNV_VCF $INDEL_VCF | vcf-sort > $RAW_VCF

MUT_COUNT=`grep -v ^# $RAW_VCF | wc -l`
echo "$MY_NAME : OUTPUT VCF : $RAW_VCF with $MUT_COUNT mutations"

# prepare exit
rm -f $OUT_FASTQ_1
rm -f $OUT_FASTQ_2
rm -f $BAM1
rm -f $BAM1.bai
rm -f $BAM2
rm -f $BAM2.bai
rm -f $SNV_VCF
rm -f $INDEL_VCF
rm -f $MPILEUP_FILE


