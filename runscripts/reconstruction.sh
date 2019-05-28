#!/bin/bash
# normal cpu stuff: allocate cpus, memory
#SBATCH --ntasks=1 --cpus-per-task=1 --mem=6000M
#SBATCH --job-name=Reconstruct
#SBATCH -p gpu --gres=gpu:titanx:1
#Note that a program will be killed once it exceeds this time!
#SBATCH --time=00:05:00

#your script, in this case: write the hostname and the ids of the chosen gpus.
jobs="reconstruction starting"
cd ~/tomography/runscripts
bash slackpost.sh https://hooks.slack.com/services/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 $jobs
hostname
echo $CUDA_VISIBLE_DEVICES
now=$(date +%Y%m%d_%H%M%S)
outputpath=~/synkrotomo/output/$now
### make output directory and sparse folder -p is also parents.
mkdir -p $outputpath
#cd ~/samples/1_Utilities/deviceQuery
#./deviceQuery >  $outputpath/deviceInfo.out
source activate tomography
cd ~/tomography
python reconstruction.py $outputpath
cd ~/synkrotomo/futhark
futhark opencl SIRT.fut
cd ~/synkrotomo/futhark
./SIRT < ~/synkrotomo/futhark/data/tooth.in | python ~/synkrotomo/topng.py $outputpath
futhark bench --runs=10 --skip-compilation ~/synkrotomo/futhark/SIRT.fut > $outputpath/benchresult.out
cd ~/synkrotomo
# git add $outputpath/*
# git commit -m "Results of test for automatic plot script" $outputpath/*
# git push
# cd ~/tomography/runscripts
# jobs="reconstruction ending"
# bash slackpost.sh https://hooks.slack.com/services/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 $jobs
