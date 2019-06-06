#!/bin/bash
conda activate virt
cd ..
#make data
echo "generate data"
python data_input.py "data/"
python ~/tomography/data_input_sparse.py "data/sparse"
