#!/bin/bash
# normal cpu stuff: allocate cpus, memory
#SBATCH --ntasks=1 --cpus-per-task=1 --mem=8000M
#SBATCH --job-name=data
# we run on the gpu partition and we allocate 2 titanx gpus
#SBATCH -p gpu --gres=gpu:titanx:1
#We expect that our program should not run langer than 30 min
#Note that a program will be killed once it exceeds this time!
#SBATCH --time=03:00:00

#your script, in this case: write the hostname and the ids of the chosen gpus.
cd ~/tomography/runscripts
hostname
echo $CUDA_VISIBLE_DEVICES
# source activate tomography
source activate virt

#make data
echo "generate data"
python ~/tomography/data_input.py "~/synkrotomo/futhark/data"
# python ~/tomography/3d_proofItWorksInputdata.py "~/synkrotomo/futhark/data"
# python ~/tomography/3d_data_input.py "~/synkrotomo/futhark/data"
# python ~/tomography/data_input_sparse.py "~/synkrotomo/futhark/data/sparse"
#use now as directory name so somewhat unique and we have a timestamp
# now=$(date +%Y%m%d_%H%M%S)
# outputpath=~/synkrotomo/output/lbsc/$now
# ### make output directory and sparse folder -p is also parents.
# mkdir -p $outputpath
#
# cd ~/samples/1_Utilities/deviceQuery
# ./deviceQuery >  $outputpath/deviceInfo.out
#
# cd ~/tomography/runscripts
# ### Do benchmarks with many angles
#
# echo "benchmark with all angles for different sizes"
# futhark opencl ~/synkrotomo/archive/forwardprojection.fut
# futhark bench --runs=10 --skip-compilation ~/synkrotomo/archive/forwardprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_fp_old.csv
#
# futhark opencl ~/synkrotomo/futhark/forwardprojection.fut
# futhark bench --runs=10 --skip-compilation ~/synkrotomo/futhark/forwardprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_fp_new.csv
#
# # ### Do benchmarks on sparse
# # echo "benchmark with sparse angles for size 1024"
# # futhark opencl ~/synkrotomo/futhark/forwardprojection_sparse.fut
# # futhark bench --runs=10 --skip-compilation ~/synkrotomo/futhark/forwardprojection_sparse.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/sparse/fut_fp.csv
#
# cd ~/tomography
# echo "plot runtimes many angles"
# python plot.py -d $outputpath -t "Comparison of runtimes" -x "Pixels"
#
#
# echo "plot speedup fp"
# python plot_speedup.py -r $outputpath/fut_fp_old.csv -b $outputpath/fut_fp_new.csv -t "forwardprojection" -x "angles" -y "relative runtime"
#
# cd ~/synkrotomo
# git add $outputpath/*
# git commit -m "Results of test for automatic plot script" $outputpath/*
# git push
