#!/bin/bash
# normal cpu stuff: allocate cpus, memory
#SBATCH --ntasks=1 --cpus-per-task=1 --mem=8000M
#SBATCH --job-name=Benchmark
# we run on the gpu partition and we allocate 2 titanx gpus
#SBATCH -p gpu --gres=gpu:titanx:1
#We expect that our program should not run langer than 30 min
#Note that a program will be killed once it exceeds this time!
#SBATCH --time=01:00:00

#your script, in this case: write the hostname and the ids of the chosen gpus.
hostname
echo $CUDA_VISIBLE_DEVICES
source activate tomography
#make data
echo "generate data"
# python ~/tomography/data_input.py "~/synkrotomo/futhark/data"
# python ~/tomography/data_input_sparse.py "~/synkrotomo/futhark/data/sparse"
#use now as directory name so somewhat unique and we have a timestamp
now=$(date +%Y%m%d_%H%M%S)
outputpath=~/synkrotomo/output/lbsc/astravsfut/gpu04/$now
### make output directory and sparse folder -p is also parents.
mkdir -p $outputpath
echo "benchmark with all angles for different sizes"
cd ..

futhark bench --runs=10 --backend=opencl futhark/noDivergence/forwardprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_fp_nospa.csv
futhark bench --runs=10 --backend=opencl futhark/noDivergence/backprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_bp_nospa.csv
futhark bench --runs=10 --backend=opencl futhark/forwardprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_fp_spa.csv
futhark bench --runs=10 --backend=opencl futhark/backprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_bp_spa.csv


echo "plot runtimes gpu04 divergence"
python lbscplot.py -d $outputpath -t "bp and fp, spatial optims GPU04" -x "Pixels"
# echo "plot runtimes sparse angles"
# python plot.py -d $outputpath/sparse -t "Comparison of runtimes" -x "angles"
# echo "plot speedup bp sparse"
# python plot_speedup_same_graf.py -d $outputpath/sparse -t "Speedup sparse angles" -x "angles" -y "speedup"
echo "plot speedup gpu04 bp divergence"
python lbsc_plot_speedup_same_graf_spatial.py -d $outputpath -t "Speedup bp and fp spatial GPU04" -x "N" -y "speedup"
cd ~/synkrotomo
git add $outputpath/*
git commit -m "Results of test for automatic plot script" $outputpath/*
git push
