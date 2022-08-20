# TargetReseq (編集中です
# がんのターゲットりシークエンスのデータ解析
### コマンドライン編
### 2.8 データ解析の手順

**テキストP.52**
```
cd
mkdir CancerGenome
ls CancerGenome
sudo apt update
sudo apt install default-jre
```
実行中のユーザのパスワードを入力する。
Javaバージョンが出力されることを確認する。
```
java -version
```
**テキストP.53**
```
sudo apt install make
sudo apt install maven
sudo apt install g++
sudo apt install default-jdk
javac -version
```
**テキストP.54**
```
cd ~/Downloads
cp hg19.fa.gz ~/CancerGenome 
cd ~/CancerGenome
gunzip hg19.fa.gz
cd ~/Downloads
gunzip BT-474_S13_L001_R1_001.fastq.gz
gunzip BT-474_S13_L001_R2_001.fastq.gz
mv BT-474_S13_L001_R1_001.fastq ~/CancerGenome/input_1.fq 
mv BT-474_S13_L001_R2_001.fastq ~/CancerGenome/input_2.fq
```
**P.55**
```
cd ~/CancerGenome
wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.39.zip
unzip Trimmomatic-0.39.zip
```
Trimmomatic-0.39というディレクトリが生成される。
```
mv Trimmomatic-0.39/trimmomatic-0.39.jar .
mv Trimmomatic-0.39/adapters .
```
**P.56**
```
cd ~/CancerGenome
java -jar trimmomatic-0.39.jar \
	PE \
	-threads 4 \
	-phred33 \
	input_1.fq \
	input_2.fq \
	paired_out_1.fq \
	unpaired_out_1.fq \
	paired_out_2.fq \
	unpaired_out_2.fq \
	ILLUMINACLIP:TruSeq3-PE-2.fa:2:30:10 \
	LEADING:30 \
	TRAILING:30 \
	SLIDINGWINDOW:5:30 \
	MINLEN:75

sudo apt update
sudo apt install bwa
sudo apt install samtools

bwa index -p hg19 hg19.fa
```
**P.57**
```
ls hg19.*
```
```
bwa mem -t 4 hg19 paired_out_1.fq paired_out_2.fq > paired_out.sam
samtools sort -O bam -o paired_out.sorted.bam paired_out.sam
samtools index paired_out.sorted.bam
```
abra2-2.24.tar.gzを展開する
```
tar zxvf abra2-2.24.tar.gz
```
lsでソースコードが展開されていることを確認する
```
ls abra2-2.24
```
```
cd abra2-2.24
JAVA_HOME=/usr/lib/jvm/default-java/ make
```
**P.58**
```
cd ~/CancerGenome
ln -s abra2-2.24/target/abra2-2.24-jar-with-dependencies.jar abra2.jar 
```
以下のコマンドでバージョンとコマンドラインオプションが表示されることを確認する
```
java -jar abra2.jar
```
パネルシークエンスの領域を定義した bed ファイルをダウンロードする。
（ダウンロード方法の例）
```
wget https://raw.githubusercontent.com/tanishimashigeki/TargetReseq/main/QIAGEN_panel.bed
```
```
java	-Xmx12G -Xms8M -jar abra2.jar \
	--in paired_out.sorted.bam \
	--out abra.bam \
	--ref hg19.fa \
	--targets QIAGEN_panel.bed \
	--threads 4 \
	--undup \
	--nosort
```
BAMファイルのインデックスを作成する
```
samtools sort abra.bam -o AnalysisReady.bam
samtools index AnalysisReady.bam
```
**P.59**
```
ln -s VarScan.v2.4.2.jar VarScan2.jar
samtools mpileup -l QIAGEN_panel.bed -f hg19.fa -BAQ 0 AnalysisReady.bam | java -jar VarScan2.jar mpileup2snp --output-vcf > snp.vcf
samtools mpileup -l QIAGEN_panel.bed -f hg19.fa -BAQ 0 AnalysisReady.bam | java -jar VarScan2.jar mpileup2indel --output-vcf > indel.vcf
ls -l snp.vcf indel.vcf
```
**P.60**
```
cd ~/Downloads
mv snpEff_latest_core.zip ~/CancerGenome
cd ~/CancerGenome
unzip snpEff_latest_core.zip
```
展開のメッセージが流れ，snpEffというフォルダに展開される

カレントディレクトリに実行用jarファイルのリンクを張る
```
ln -s snpEff/snpEff.jar
ln -s snpEff/SnpSift.jar
```
snpEff のコマンドでアノテーションファイルをダウンロードする
**少し時間がかかる**
```
java -jar snpEff.jar download -v hg19
```
snpEffの中に新たにdata ディレクトリができていることを確認する 
```
ls snpEff
```
**P.61**
```
sudo apt update
sudo apt install vcftools

sed 's/^chr//' QIAGEN_panel.bed > QIAGEN_panel_chrNo.bed
```
**P.62**
```
vcftools --gzvcf gnomad.exomes.r2.1.1.sites.vcf.bgz --bed \
	QIAGEN_panel_chrNo.bed --recode --recode-INFO-all --out \
	gnomad.exomes.r2.1.1.QIAGEN
```

```
vcf-sort nightly-civic_accepted_and_submitted.vcf \
	> nightly-civic_accepted_and_submitted.sorted.vcf
```
```
vcf-concat snp.vcf indel.vcf | vcf-sort > BT-474.vcf


java -Xmx4g -jar snpEff.jar -canon hg19 BT-474.vcf | \
	java -jar SnpSift.jar annotate gnomad.exomes.r2.1.1.QIAGEN.recode.vcf | \
	java -jar SnpSift.jar annotate clinvar_20220624.vcf | \
	java -jar SnpSift.jar annotate nightly-civic_accepted_and_submitted.sorted.vcf \
	> BT-474.snpEff.gnomAD.clinvar.civic.vcf
```

**P.63**
本課題のGitHubよりダウンロードする。
（ダウンロード方法の例）
```
wget https://raw.githubusercontent.com/tanishimashigeki/TargetReseq/main/vcfilter2.awk
```
```
awk -f vcfilter2.awk -v mode="normal" BT-474.snpEff.gnomAD.clinvar.civic.vcf \
	> BT-474.mutation.tsv
awk -f vcfilter2.awk -v mode="civic" BT-474.snpEff.gnomAD.clinvar.civic.vcf \
	> BT-474.civic.tsv
awk -f vcfilter2.awk -v mode="collapse" BT-474.snpEff.gnomAD.clinvar.civic.vcf \
	> BT-474.collapse.tsv
```
