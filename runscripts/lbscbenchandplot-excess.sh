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

futhark bench --runs=10 --skip-compilation futhark/backprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_bp_excess.csv
futhark bench --runs=10 --backend=opencl futhark/backprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_bp.csv


echo "plot runtimes gpu04 divergence"
python lbscplot.py -d $outputpath -t "gpu03 Excess Parallelism and none" -x "Pixels"
echo "plot speedup gpu0 bp divergence"
python lbsc_plot_speedup_same_graf_excess.py -d $outputpath -t "Speedup backprojection, no excess" -x "N" -y "speedup"
cd ~/synkrotomo
git add $outputpath/*
git commit -m "Results of test for automatic plot script" $outputpath/*
git push
