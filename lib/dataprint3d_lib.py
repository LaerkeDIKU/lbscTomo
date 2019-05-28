import math
from skimage.transform import rotate
from skimage.draw import random_shapes
import numpy as np
import scipy.io
import scipy.misc

def dataprint(angles, rhozero, deltarho, size, iterations, sinogram, filename):
    file = open(filename, "w+")
    file.write("[")
    file.close()
    file = open(filename, "a")
    write_angles(angles, file)
    file.write(" " + str(rhozero) + " ")
    file.write(str(deltarho) + " ")
    file.write(str(size) + " ")
    file.write(str(iterations) + "\n")
    slicelen = int(len(sinogram)/size)
    for i in range(size):
        write_proj(sinogram[i*slicelen:(i+1)*slicelen], file)
    file.close()

def write_angles(angles, file):
    for i in angles[:-1]:
        file.write(str(i) + "f32,")
    file.write(str(angles[-1]) + "f32]")

def write_proj(proj, file):
    file.write("[")
    for i in proj[:-1]:
        file.write(str(i)+"f32,")
    file.write(str(proj[-1])+"f32]\n")
