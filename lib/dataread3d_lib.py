import math
from skimage.transform import rotate
from skimage.draw import random_shapes
import numpy as np
import scipy.io
import scipy.misc
import re

def clean_str(str):
    str = re.sub('f32', '', str)
    str = re.sub('i32', '', str)
    str = re.sub('\[', '', str)
    str = re.sub('\]', '', str)
    return str

def get_sin_slice(f):
    sinoslice = clean_str(f.readline())
    sino = np.fromstring( sinoslice, dtype=np.float32, sep=',' )
    return sino

def data_generator(f):
    content = clean_str(f.readline())
    angles, rhozero, deltarho, initialimg, iterations = [str for str in content.split(" ")]
    angles = np.fromstring( angles, dtype=np.float32, sep=',' )
    rhozero = float(rhozero)
    deltarho = float(deltarho)
    initialimg = np.fromstring( initialimg, dtype=np.float32, sep=',' )
    # initialimg = int(initialimg)
    iterations = int(iterations)
    return angles, rhozero, deltarho, initialimg, iterations
