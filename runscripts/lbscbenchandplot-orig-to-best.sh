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
jobs="benchmarks started"
# bash slackpost.sh https://hooks.slack.com/services/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 $jobs
hostname
echo $CUDA_VISIBLE_DEVICES
#make data
echo "generate data"
# python ~/tomography/data_input.py "~/synkrotomo/futhark/data"
# python ~/tomography/data_input_sparse.py "~/synkrotomo/futhark/data/sparse"
#use now as directory name so somewhat unique and we have a timestamp
now=$(date +%Y%m%d_%H%M%S)
outputpath=~/synkrotomo/output/lbsc/astravsfut/gpu04/$now
### make output directory and sparse folder -p is also parents.
mkdir -p $outputpath
cd ~/samples/1_Utilities/deviceQuery
./deviceQuery >  $outputpath/deviceInfo.out
### Do benchmarks with many angles
echo "benchmark with all angles for different sizes"
# python ~/tomography/bench_astra_fp.py -d ~/synkrotomo/futhark/data -i "fp" | tee $outputpath/astra_fp.csv
# python ~/tomography/bench_astra_bp.py -d ~/synkrotomo/futhark/data -i "bp" | tee $outputpath/astra_bp.csv


futhark opencl /tmp/crj/archive/synkrotomo-25dec/futhark/backprojection.fut
futhark bench --runs=10 --skip-compilation /tmp/crj/archive/synkrotomo-25dec/futhark/backprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_bp_b.csv
# futhark opencl ~/synkrotomo/futhark/forwardprojection.fut
# futhark bench --runs=10 --skip-compilation /tmp/crj/forwardprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_fp.csv
futhark opencl /tmp/crj/divergence/backprojection.fut
futhark bench --runs=10 --skip-compilation /tmp/crj/divergence/backprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_bp_nob.csv
# futhark opencl /tmp/crj/forwardprojection.fut
# futhark bench --runs=10 --skip-compilation /tmp/crj/forwardprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_fp.csv
### Do benchmarks on sparse
# echo "benchmark with sparse angles for size 1024"
# python ~/tomography/bench_astra_fp.py -d ~/synkrotomo/futhark/data/sparse -i "fpsparse" -x 1| tee $outputpath/sparse/astra_fp.csv
# python ~/tomography/bench_astra_bp.py -d ~/synkrotomo/futhark/data/sparse -i "bpsparse" -x 1| tee $outputpath/sparse/astra_bp.csv
# # futhark opencl ~/synkrotomo/futhark/backprojection_sparse.fut
# futhark bench --runs=10 --skip-compilation ~/synkrotomo/futhark/backprojection_sparse.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/sparse/fut_bp.csv
# # futhark opencl ~/synkrotomo/futhark/forwardprojection_sparse.fut
# futhark bench --runs=10 --skip-compilation ~/synkrotomo/futhark/forwardprojection_sparse.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/sparse/fut_fp.csv
echo "plot runtimes gpu04 bp divergence"
python lbscplot.py -d $outputpath -t "backprojection, Divergence and no Divergence GPU04" -x "Pixels"
# echo "plot runtimes sparse angles"
# python plot.py -d $outputpath/sparse -t "Comparison of runtimes" -x "angles"
# echo "plot speedup bp sparse"
# python plot_speedup_same_graf.py -d $outputpath/sparse -t "Speedup sparse angles" -x "angles" -y "speedup"
echo "plot speedup gpu04 bp divergence"
python lbsc_plot_speedup_same_graf_branch.py -d $outputpath -t "Speedup backprojection, Divergence and no Divergence GPU04" -x "N" -y "speedup"
cd ~/synkrotomo
git add $outputpath/*
git commit -m "Results of test for automatic plot script" $outputpath/*
git push
jobs="benchmarks ending"
# bash slackpost.sh https://hooks.slack.com/services/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 $jobs
