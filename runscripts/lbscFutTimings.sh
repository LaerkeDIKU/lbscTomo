#!/bin/bash
cd ~/synkrotomo/
outpath=~/synkrotomo/output/lbsc/futComp25dec
mkdir -p $outpath

echo '25 dec version incremental flattening' >> $outpath/timings
futhark bench --runs=10 --skip-compilation ~/archive/synkrotomo-25dec/futhark/SIRT.fut >> $outpath/timings

echo '' >> $outpath/timings
echo 'New version incremental flattening' >> $outpath/timings
futhark bench --runs=10 --skip-compilation futhark/SIRT.fut >> $outpath/timings

echo '' >> $outpath/timings
echo '25 dec version moderate flattening' >> $outpath/timings
futhark bench --runs=10 --backend=opencl ~/archive/synkrotomo-25dec/futhark/SIRT.fut >> $outpath/timings

echo '' >> $outpath/timings
echo 'New version moderate flattening' >> $outpath/timings
futhark bench --runs=10 --backend=opencl futhark/SIRT.fut >> $outpath/timings

# echo '' >> $outpath/timings
# echo 'Old version moderate flattening' >> $outpath/timings
# futhark bench --runs=10 --backend=opencl archive/SIRT.fut >> $outpath/timings


# echo 'New version incremental flattening' >> $outpath/timings
# # cd futhark
# # FUTHARK_INCREMENTAL_FLATTENING=1 bash -c 'futhark opencl SIRT.fut'
# # cd..
# futhark bench --runs=10 --skip-compilation futhark/SIRT.fut >> $outpath/timings
# #
# echo 'Old version incremental flattening' >> $outpath/timings
# # cd archive
# # FUTHARK_INCREMENTAL_FLATTENING=1 bash -c 'futhark opencl SIRT.fut'
# # cd..
# futhark bench --runs=10 --skip-compilation archive/SIRT.fut >> $outpath/timings


git add $outpath/*
git commit -m 'futhark comparisons new vs 25 of december' $outpath/*
git pull
git push
