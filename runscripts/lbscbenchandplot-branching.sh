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
#use now as directory name so somewhat unique and we have a timestamp
now=$(date +%Y%m%d_%H%M%S)
outputpath=~/synkrotomo/output/lbsc/astravsfut/gpu04/$now
### make output directory and sparse folder -p is also parents.
mkdir -p $outputpath
echo "benchmark with all angles for different sizes"
 cd ..

futhark bench --runs=10 --backend=opencl futhark/originalVersion/forwardprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_fp_div.csv
futhark bench --runs=10 --backend=opencl futhark/originalVersion/backprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_bp_div.csv
futhark bench --runs=10 --backend=opencl futhark/noDivergence/forwardprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_fp_nodiv.csv
futhark bench --runs=10 --backend=opencl futhark/noDivergence/backprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_bp_nodiv.csv


echo "plot runtimes gpu04 divergence"
python lbscplot.py -d $outputpath -t "bp and fp, Divergence and no Divergence GPU04" -x "Pixels"
echo "plot speedup gpu04 bp divergence"
python lbsc_plot_speedup_same_graf_divergence.py -d $outputpath -t "Speedup backprojection, Divergence and no Divergence GPU04" -x "N" -y "speedup"
cd ~/synkrotomo
git add $outputpath/*
git commit -m "Results of test for automatic plot script" $outputpath/*
git push
