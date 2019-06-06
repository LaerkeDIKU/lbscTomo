#!/bin/bash
now=$(date +%Y%m%d_%H%M%S)
outputpath=output/gpu04/$now
### make output directory and sparse folder -p is also parents.
mkdir -p $outputpath
cd ~/samples/1_Utilities/deviceQuery
./deviceQuery >  $outputpath/deviceInfo.out
echo "benchmark with all angles for different sizes"
cd ../
futhark opencl futhark/originalVersion/SIRT.fut
futhark bench --runs=1 --skip-compilation futhark/originalVersion/SIRT.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_SIRT_orig.csv
# futhark opencl ~/synkrotomo/futhark/forwardprojection.fut
# futhark bench --runs=10 --skip-compilation /tmp/crj/forwardprojection.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_fp.csv
futhark opencl futhark/SIRT.fut
futhark bench --runs=1 --skip-compilation futhark/SIRT.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_SIRT_new.csv
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
cd ~/tomography
echo "plot runtimes many angles"
python lbscplot.py -d $outputpath -t "Comparison of runtimes gpu04, SIRT," -x "Pixels"
# echo "plot runtimes sparse angles"
# python plot.py -d $outputpath/sparse -t "Comparison of runtimes" -x "angles"
# echo "plot speedup bp sparse"
# python plot_speedup_same_graf.py -d $outputpath/sparse -t "Speedup sparse angles" -x "angles" -y "speedup"
echo "plot speedup bp"
python lbscplot_speedup_same_graf.py -d $outputpath -t "Speedup full angles gpu03, SIRT, moderate and incremental" -x "N" -y "speedup"
cd ~/synkrotomo
git add $outputpath/*
git commit -m "Results of test for automatic plot script" $outputpath/*
git push
jobs="benchmarks ending"
cd ~/tomography/runscripts
# bash slackpost.sh https://hooks.slack.com/services/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 $jobs
