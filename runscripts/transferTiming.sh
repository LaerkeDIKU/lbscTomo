#!/bin/bash
# normal cpu stuff: allocate cpus, memory
#SBATCH --ntasks=1 --cpus-per-task=1 --mem=6000M
#SBATCH --job-name=transtiming
# we run on the gpu partition and we allocate 2 titanx gpus
#SBATCH -p gpu --gres=gpu:titanx:1
#We expect that our program should not run langer than 30 min
#Note that a program will be killed once it exceeds this time!
#SBATCH --time=04:00:00

#your script, in this case: write the hostname and the ids of the chosen gpus.
cd ~/tomography/runscripts
hostname
echo $CUDA_VISIBLE_DEVICES
source activate tomography

#make data
# echo "generate data"
# python ~/tomography/data_input.py "~/synkrotomo/futhark/data"
# python ~/tomography/data_input_sparse.py "~/synkrotomo/futhark/data/sparse"
#use now as directory name so somewhat unique and we have a timestamp
now=$(date +%Y%m%d_%H%M%S)
outputpath=~/synkrotomo/output/lbsc/$now
# outputpath=~/uni/tomo/synkrotomo/output/lbsc/$now
### make output directory and sparse folder -p is also parents.
mkdir -p $outputpath

cd ~/samples/1_Utilities/deviceQuery
./deviceQuery >  $outputpath/deviceInfo.out

# echo "preparing"
# cd ~/tomography/runscripts
# bash updatelibs.sh
# echo "generate data"
# python ~/tomography/data_input.py "~/synkrotomo/futhark/data"
# cd ~/uni/tomo/tomography/runscripts


cd ~/synkrotomo/futhark/
# cd ~/uni/tomo/synkrotomo/futhark/


indir=~/synkrotomo/futhark/data
echo "timing"
python ~/tomography/transfertiming.py $indir $outputpath > $outputpath/timings



cd ~/synkrotomo
git pull
git add $outputpath/*
git commit -m "Results of test for transfer timing - single iter" $outputpath/*
git push
