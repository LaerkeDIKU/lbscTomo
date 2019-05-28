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

now=$(date +%Y%m%d_%H%M%S)
outputpath=~/synkrotomo/output/lbsc/$now
mkdir -p $outputpath

cd ~/samples/1_Utilities/deviceQuery
./deviceQuery >  $outputpath/deviceInfo.out


cd ~/synkrotomo/futhark/

indir=~/synkrotomo/futhark/data

echo "timing"
python ~/tomography/tomosirt.py -w -s 64 128 256 512 > $outputpath/timings



cd ~/synkrotomo
git pull
git add $outputpath/*
git commit -m "comparing single gpu to multipgu" $outputpath/*
git push
