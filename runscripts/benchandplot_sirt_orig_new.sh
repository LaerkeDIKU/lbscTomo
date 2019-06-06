#!/bin/bash
now=$(date +%Y%m%d_%H%M%S)
outputpath=output/gpu04/$now
### make output directory and sparse folder -p is also parents.
mkdir -p $outputpath
cd ..
futhark opencl futhark/originalVersion/SIRT.fut
futhark bench --runs=1 --skip-compilation futhark/originalVersion/SIRT.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_SIRT_orig.csv
futhark opencl futhark/SIRT.fut
futhark bench --runs=1 --skip-compilation futhark/SIRT.fut | bash ~/tomography/runscripts/formatfuthark.sh $outputpath/fut_SIRT_new.csv
echo "plot runtimes many angles"
python lbscplot.py -d $outputpath -t "Comparison of runtimes gpu04, SIRT," -x "Pixels"
echo "plot speedup bp"
python lbsc_plot_speedup_same_graf_orig_to_new.py -d $outputpath -t "Speedup gpu04, SIRT, new and original" -x "N" -y "speedup"
cd ~/synkrotomo
git add $outputpath/*
git commit -m "Results of test for automatic plot script" $outputpath/*
git push
