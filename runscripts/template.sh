#!/bin/bash
#SBATCH --job-name=Template
# normal cpu stuff: allocate cpus, memory
#SBATCH --ntasks=1 --cpus-per-task=1 --mem=6000M
# we run on the gpu partition and we allocate 1 titanx gpus
#SBATCH -p gpu --gres=gpu:titanx:1
#Note that a program will be killed once it exceeds this time!
#SBATCH --time=11:00:00

#your script, in this case: write the hostname and the ids of the chosen gpus.
hostname
echo $CUDA_VISIBLE_DEVICES

#root folder so the folders can be in whatever folder needed
root=../..

# timing the script, nothing will be printed to the slurm file until the script is done, outcomment when not needed
# time {

#cd to somewhere
# cd $root/

#do stuff

#example commit with message
#git commit -m "updates" $now/*

# end of timing
# }
