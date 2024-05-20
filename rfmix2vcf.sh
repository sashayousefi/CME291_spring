#!/bin/bash

## USAGE: qsub -q b-students.q -N r2v_chr# -m ae rfmix2vcf.sh CHR 0.1

chr=$1 # chromosome number (enter chr4_smallsubs and chr1_smallsubs for 1 and 4)
wdw=$2 # RFMix window size

# setup file names
resDir=/projects/topmed/analysts/grindek/local_ancestry/rfmix_results/
outDir=${resDir}chr${chr}_${wdw}

subVit=`ls -v ${resDir}chr${chr}_*_${wdw}.0.Viterbi.txt`
allVit=${outDir}.all.Viterbi.txt
eurVit=${outDir}.eur.Viterbi.txt
afrVit=${outDir}.afr.Viterbi.txt
namVit=${outDir}.nam.Viterbi.txt

outVCF=/projects/topmed/analysts/grindek/local_ancestry/rfmix_vcf/chr${chr}_${wdw}
eurVCF=${outVCF}.eur.vcf
afrVCF=${outVCF}.afr.vcf
namVCF=${outVCF}.nam.vcf

##############################################################
########## Reformat Viterbi Files ############################
##############################################################

# paste together all group files (HL_sub1, HL_sub2, ...)
echo "Paste together subset viterbi files"
paste -d '' $subVit > $allVit

# create one file per ancestry
# (in Viterbi file, 1 = AFR, 2 = EUR, 3 = NAM)
echo "Create one-vs-other viterbi files"

# create AFR vs Other (set 2 and 3 to 0)
echo "... AFR vs Other"
sed 's/2\|3/0/g' $allVit > $afrVit

# create EUR vs Other (set 1 and 3 to 0, change 2 to 1)
echo "... EUR vs Other"
sed 's/1\|3/0/g' $allVit > $eurVit
sed -i 's/2/1/g' $eurVit

# create NAM vs Other (set 1 and 2 to 0, change 3 to 1)
echo "... NAM vs Other"
sed 's/1\|2/0/g' $allVit > $namVit
sed -i 's/3/1/g' $namVit


###########################################################
########### Re-order VCF to match Viterbi order ###########
###########################################################

echo "Re-order VCF to match Viterbi sample order"

# admixed genotype VCF locations
vcfDir=/projects/topmed/analysts/grindek/local_ancestry/admixed_genotypes/final_vcf
vcfgz=`ls -v ${vcfDir}/chr${chr}_*sub*.vcf.gz`

# unzip and remove header for .gz files
echo "... Unzipping .vcf.gz files"
for gz in $vcfgz
do
  zcat ${gz} | grep -v '##' > ${gz}_unzip
done

# paste together new unzipped VCF files
echo "... Pasting together .vcf files"
vcf=`ls -v ${vcfDir}/chr${chr}_*sub*.vcf.gz_unzip`
orderedvcf=${vcfDir}/chr${chr}_ordered.vcf
paste=/projects/browning/brwnlab/kelsey/unix_files/paste.jar

java -jar $paste 9 $vcf | tr ' ' '\t' > $orderedvcf

# gzip final vcf
echo "... Gzipping final .vcf file"
gzip $orderedvcf

# remove temporary subset .vcf files
echo "... Removing temporary .vcf files"
rm $vcf


############################################################
############# Viterbi > VCF ################################
############################################################

echo "Converting Viterbi to VCF"

# afr
echo "... AFR vs Other"
cat $afrVit | python rfmix2vcf.py ${orderedvcf}.gz > $afrVCF

# eur
echo "... EUR vs Other"
cat $eurVit | python rfmix2vcf.py ${orderedvcf}.gz > $eurVCF

# nam
echo "... NAM vs Other"
cat $namVit | python rfmix2vcf.py ${orderedvcf}.gz > $namVCF




#############################################################
############# Remove duplicate IDs ##########################
#############################################################

## 2 individuals were in both AA and HL lists (NWD128208,NWD208786)
## check that they have same calls and/or remove
echo "Removing duplicate samples"
filtercols=/projects/browning/software/filtercolumns.jar
dups=/projects/topmed/analysts/grindek/local_ancestry/duplicates.txt

echo "... from AFR vcf file"
cat $afrVCF | java -jar $filtercols '##' -1 $dups > ${afrVCF}_nodup
echo "... from EUR vcf file"
cat $eurVCF | java -jar $filtercols '##' -1 $dups > ${eurVCF}_nodup
echo "... from NAM vcf file"
cat $namVCF | java -jar $filtercols '##' -1 $dups > ${namVCF}_nodup


