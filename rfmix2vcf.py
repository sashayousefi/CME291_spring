# usage: cat rfmix_viterbi_file | python rfmix2vcf.py vcffile > outvcf

# the vcf file is the one with the admixed genotypes from which the rfmix input  data were obtained
# it is used to get the vcf header and initial columns
# e.g., admixed_genotypes/final_vcf/chr{CHR.NUM}_{GRP.NAME}.vcf.gz
#    or admixed_genotypes/final_vcf/chr{CHR.NUM}_simplify.vcf.gz

import sys,gzip

vcffilename = sys.argv[1]
if vcffilename[-3:] == ".gz":
    vcf = gzip.open(vcffilename)
else:
    vcf = open(vcffilename)

for line in vcf:
    if line[0] == '#':
        print line,
        continue
    bits = line.split()
    myline = '\t'.join(bits[:9])
    vitline = sys.stdin.readline().split()
    for i,x in enumerate(vitline):
        if i%2 == 0:
            #myline = '\t'.join([myline,str(int(x)-1)])
	    myline = '\t'.join([myline,str(int(x))])
        else:
            #myline = '|'.join([myline,str(int(x)-1)])
	    myline = '|'.join([myline,str(int(x))])
    print myline
