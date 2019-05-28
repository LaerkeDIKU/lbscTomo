#!/bin/bash
#SBATCH --job-name=UpdateLibs
# normal cpu stuff: allocate cpus, memory
#SBATCH --ntasks=1 --cpus-per-task=2 --mem=6000M
#SBATCH -p gpu --gres=gpu:titanx:1
#SBATCH --time=00:05:00

hostname
echo $CUDA_VISIBLE_DEVICES
#root folder so the folders can be in whatever folder needed
dir=libs_tomo

cd ../..
mkdir -p $dir

# source activate tomography
source activate virt
cd synkrotomo #synkrotomo
#root pointer
rp=..
make lib
python setup.py sdist
cd $rp/$dir #dir
cp ../synkrotomo/dist/synkrotomo-1.0.tar.gz ./
tar -xf synkrotomo-1.0.tar.gz
cd synkrotomo-1.0 #/dir/synkrotomo-1.0
rp=$rp/..
python setup.py install
cd $rp/tomography/lib #tomography/lib
python setup.py sdist
cd $rp/$dir
rp=..
cp $rp/tomography/lib/dist/tomo_utils-1.0.tar.gz ./
tar -xf tomo_utils-1.0.tar.gz
cd tomo_utils-1.0
rp=$rp/..
python setup.py install
cd $rp
rm -fr $dir
