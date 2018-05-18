#############
# This script is to merge bam files
# requiring arguments:
# input (directory for bams files),
# output directory (optional if different from the directory of initial bams),
# a text file that specifies according what to merge 
# (same sample ID or replicates, i.e., same condition) and file names after merging. 
############
while getopts ":hD:O:f:" opts; do
    case "$opts" in
        "h")
            echo "This script is to merge bam files requiring arguments: "
	    echo "input (directory for bams files) "
            echo "output directory (optional if different from the directory of initial bams) "
            echo "a text file that specifies according what to merge "
            echo "(same sample ID or replicates, i.e., same condition) and file names after merging." 
	    echo "....................";
            echo "Usage:"
            echo "$0 -D alignments/BAMs_All -O BAMs_merged -f file4merged.txt"
            exit 0
            ;;
        "D")
            DIR_Bams="$OPTARG"
            ;;
	"O")
	    DIR_OUT="$OPTARG";
	    ;;
	"f")
	    params="$OPTARG";
	    ;;
        "?")
            echo "Unknown option $opts"
            ;;
        ":")
            echo "No argument value for option -DOf "
	    exit 1;
            ;;
    esac
done

if [ -z "$DIR_OUT" ]; then 
    DIR_OUT=$DIR_Bams;
fi

cwd=$PWD;
nb_cores=2;

mkdir -p $DIR_OUT
mkdir -p $cwd/logs

#i=1;
#cd $DIR_Bams;
#for ss in $factors; 
#red=`tput setaf 1`
while read -r line; do   
    #echo $line;
    IFS=$'\t' read -r "id" "cond" <<< "$line"
    
    if [ "$id" != "sampleID" ]; then
	old=($(ls ${DIR_Bams}/*.bam | grep "$id"));
	
	echo ${#old[@]} "Files :  " $id "--" $cond
	#echo $cond
	#echo $bams
	#echo $old;
	#echo ${old[@]};
	
	out=${cond}_${id}_merged
	
	if [[ ${#old[@]} -gt 1 ]]; then
	    	    
	    #out=${out}_merged;
	    #echo $out;
	    #echo here
	    if [ ! -e "${DIR_OUT}/${out}.bam" ]; then
		#echo "here"
		qsub -q public.q -o $cwd/logs -j yes -pe smp $nb_cores -cwd -b y -shell y -N mergeBam "module load samtools/1.3.1; samtools merge ${DIR_OUT}/${out}_unsorted.bam ${old[@]}; samtools sort -o $DIR_OUT/${out}.bam $DIR_OUT/${out}_unsorted.bam; samtools index ${DIR_OUT}/${out}.bam; rm $DIR_OUT/${out}_unsorted.bam; "
	    fi;
	
	elif [[ ${#old[@]} -eq 1 ]]; then
	    #echo ${#old[@]};
	    echo "---------------WARNING: ONLY ONE file found--------- "
	    #echo "why is here"
	    #out=${}_merged
	    #ids=`echo "$old" | cut -d'_' -f3`
	    #out=${cond}${ss}_${ids}_merged
	    #echo ${old[@]};
	    #echo $ids
	    #echo $out;
	    if [ ! -e "${DIR_OUT}/${out}.bam" ]; then
		qsub -q public.q -o $cwd/logs -j yes -pe smp $nb_cores -cwd -b y -shell y -N mergeBam "cp ${old[@]} ${DIR_OUT}/${out}.bam; module load samtools/1.3.1; samtools index ${DIR_OUT}/${out}.bam; "
	    fi;
	else
	    echo "NOT FOUND Bam files for $ss and $cond "
	fi
	#echo ">>>>>"
	#break;
    fi
done < "$params" 

