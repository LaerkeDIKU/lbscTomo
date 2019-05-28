#!/bin/bash
cd ~/synkrotomo/futhark
outpath=~/synkrotomo/output/lbsc/futlog
mkdir -p $outpath

echo 'Old version moderate flattening' >> $outpath/timings
futhark opencl SIRT.fut
./SIRT < data/sirtinputf32rad4096 > /dev/null
timeout -t 600 nvidia-smi -l 5 -f $outpath/log

git add $outpath/*
git commit -m 'futhark log' $outpath/*
git pull
git push
