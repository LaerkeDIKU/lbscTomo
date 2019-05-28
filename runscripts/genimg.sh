#!/bin/bash
# normal cpu stuff: allocate cpus, memory
#SBATCH --ntasks=1 --cpus-per-task=1 --mem=6000M
#SBATCH --job-name=genimg
# we run on the gpu partition and we allocate 2 titanx gpus
#SBATCH -p gpu --gres=gpu:titanx:1
#We expect that our program should not run langer than 30 min
#Note that a program will be killed once it exceeds this time!
#SBATCH --time=04:00:00

################################################################################
### generate an image to prove that streaming works
################################################################################

cd ~/tomography/runscripts
hostname
echo $CUDA_VISIBLE_DEVICES
source activate tomography

#use now as directory name so somewhat unique and we have a timestamp
now=$(date +%Y%m%d_%H%M%S)
outputpath=~/synkrotomo/output/lbsc/$now

### make output directory and sparse folder -p is also parents.
mkdir -p $outputpath

cd ~/samples/1_Utilities/deviceQuery
./deviceQuery >  $outputpath/deviceInfo.out

cd ~/synkrotomo/futhark/
indir=~/synkrotomo/futhark/data

echo "generating"
python ~/tomography/streamingworks.py $indir $outputpath

cd ~/synkrotomo
git pull
git add $outputpath/*
git commit -m "generated images to prove working 3d" $outputpath/*
git push
