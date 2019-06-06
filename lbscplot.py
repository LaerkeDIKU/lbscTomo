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
    frames = []
    for filename in os.listdir(root):
        name, extension = os.path.splitext(filename)
        if extension == ".csv":
            try:
                x, y = np.loadtxt(os.path.join(root,filename), skiprows=0, delimiter=';', unpack=True)
            except:
                print(("Could not load values from "+filename))
                continue
            frame = pd.DataFrame(data=y,columns=[name],index=x)
            frames.append(frame)
    dataframe = pd.concat(frames,axis=1)

    dataframe.plot()
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.savefig(os.path.join(root,title))

def main(argv):
    parser = argparse.ArgumentParser(description="Generate a plot of the data in a specified folder")
    parser.add_argument('-d', '--directory', help="Path to the folder for reading the data for the plot. Will take all files of type .out in the directory and assume the name of the file is the name of the algorithm, and the file contains a two columns x_var, y_var. The plot will be placed in the same folder", default = "")
    parser.add_argument('-t', '--title', help="Title to use for the plot - the file will get the same name", default = "Plot")
    parser.add_argument('-x', '--xlabel', help="Specify the xaxis label", default = "size")
    parser.add_argument('-y', '--ylabel', help="Specify the xaxis label", default = (r'$\mu$'+"s"))


    args, unknown = parser.parse_known_args(argv)
    plot(args.directory,args.title,args.xlabel,args.ylabel)

if __name__ == '__main__':
    main(sys.argv)
