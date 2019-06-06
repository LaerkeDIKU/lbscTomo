import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import sys
import argparse
import os
import pandas as pd


def plot(directory,title,xlabel,ylabel):
    root = os.path.expanduser(directory)
    fut_fp_x, fut_fp_y = np.loadtxt(os.path.join(root,"fut_fp_spa.csv"), skiprows=0, delimiter=';', unpack=True)
    fut_bp_x, fut_bp_y = np.loadtxt(os.path.join(root,"fut_bp_spa.csv"), skiprows=0, delimiter=';', unpack=True)
    astra_fp_x, astra_fp_y = np.loadtxt(os.path.join(root,"fut_fp_nospa.csv"), skiprows=0, delimiter=';', unpack=True)
    astra_bp_x, astra_bp_y = np.loadtxt(os.path.join(root,"fut_bp_nospa.csv"), skiprows=0, delimiter=';', unpack=True)

    frames = []

    fut_fp = pd.DataFrame(data=fut_fp_y,columns=['fut_fp_y'],index=fut_fp_x)
    fut_bp = pd.DataFrame(data=fut_bp_y,columns=['fut_bp_y'],index=fut_bp_x)
    astra_fp = pd.DataFrame(data=astra_fp_y,columns=['astra_fp_y'],index=astra_fp_x)
    astra_bp = pd.DataFrame(data=astra_bp_y,columns=['astra_bp_y'],index=astra_bp_x)
    frames.append(fut_fp)
    frames.append(fut_bp)
    frames.append(astra_fp)
    frames.append(astra_bp)
    dataframe = pd.concat(frames,axis=1)
    dataframe['speedup_fp'] = dataframe['astra_fp_y']/dataframe['fut_fp_y']
    dataframe['speedup_bp'] = dataframe['astra_bp_y']/dataframe['fut_bp_y']

    plt.plot(dataframe['speedup_fp'], color='orange')
    plt.plot(dataframe['speedup_bp'], color='darkcyan')
    plt.axhline(y=1, color="red")
    plt.legend(["spatial_optim_fp", "spatial_optim_bp", "original"])
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.savefig(os.path.join(root, title))

def main(argv):
    parser = argparse.ArgumentParser(description="Generate a plot of the data in a specified folder")
    parser.add_argument('-d', '--directory', help="The directory where to find the data", default = "")
    parser.add_argument('-t', '--title', help="Title to use for the plot - the file will get the same name", default = "Plot")
    parser.add_argument('-x', '--xlabel', help="Specify the xaxis label", default = "Size")
    parser.add_argument('-y', '--ylabel', help="Specify the xaxis label", default = "Speedup")


    args, unknown = parser.parse_known_args(argv)
    plot(args.directory,args.title,args.xlabel,args.ylabel)

if __name__ == '__main__':
    main(sys.argv)
