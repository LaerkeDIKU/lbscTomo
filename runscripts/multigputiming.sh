#!/bin/bash
# normal cpu stuff: allocate cpus, memory
#SBATCH --ntasks=1 --cpus-per-task=6 --mem=8000M
#SBATCH --job-name=CompMult
# we run on the gpu partition and we allocate 2 titanx gpus
#SBATCH -p gpu --gres=gpu:titanx:4
#We expect that our program should not run langer than 30 min
#Note that a program will be killed once it exceeds this time!
#SBATCH --time=12:00:00

#your script, in this case: write the hostname and the ids of the chosen gpus.
cd ~/tomography/runscripts
hostname
echo $CUDA_VISIBLE_DEVICES
source activate virt

now=$(date +%Y%m%d_%H%M%S)
outputpath=~/synkrotomo/output/lbsc/$now
mkdir -p $outputpath

cd ~/samples/1_Utilities/deviceQuery
./deviceQuery >  $outputpath/deviceInfo.out
# >>  $outputpath/deviceInfo.out
#
#
# cd ~/synkrotomo/futhark/
#
# indir=~/synkrotomo/futhark/data

echo "timing"
python -u ~/tomography/tomosirt.py -c -p -d 4 -od ~/tomography/img/multiTitanTest/ -s 1024 > $outputpath/timings
# python ~/tomography/tomosirt.py -p -r -d 2 -od ~/tomography/img/multiTitan/ -fd $outputpath -s 64 128 256 512 1024 1500 2000 2048 2500 3000 3500 4000 4096
# git pull && python tomosirt.py -r -p -fd ~/tomography/timing-multiGPU -od ~/tomography/img/dual-gpu -s 64 128 256 512 1024 1500 2000 2048 2500 3000 3500 4000 4096 -d 2 &



cd ~/synkrotomo
git pull
git add $outputpath/*
git commit -m "multipgu bench test 1024 4 dev" $outputpath/*
git push
