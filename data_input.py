import numpy as np
import sys
import math
import tomo_lib
import dataprint_lib
import os
import matplotlib.pyplot as plt


def main(argv):
    sizes = [64,128,256,512,1024,1500,2000,2048,2500,3000,3500,4000,4096]
    iterations = 200
    root = os.path.expanduser(argv[1])
    if not os.path.exists(root):
        os.makedirs(root)
    for size in sizes:
        print("working on data for size "+str(size))
        filenamesirt = "sirtinputf32rad"+str(size)
        #filenamesirt3D = "..//synkrotomo//data//sirt3Dinputf32rad"+str(i)
        filenamebp = "bpinputf32rad"+str(size)
        filenamefp = "fpinputf32rad"+str(size)

        angles = tomo_lib.get_angles(size, False)
        numrhos = int(np.ceil(np.sqrt(2*(size**2))))
        rhozero = -(numrhos-1)/2.0
        deltarho = 1.0
        initialimg = np.zeros(size*size)
        (phantom, originalimg) = tomo_lib.get_phantom(size)
        sino = tomo_lib.get_sinogram(phantom,deltarho,numrhos,angles).flatten()
        phantom = phantom.flatten()
        #print sirt data
        reshaped = originalimg.reshape((size,size))
        plt.imsave(os.path.join(root, "originalimg" + str(size) + ".png"), reshaped, cmap='Greys_r')
        f = open(os.path.join(root,filenamesirt),"w+")
        f.write(dataprint_lib.print_f32array(angles)+" "\
            +dataprint_lib.print_f32(rhozero)+" "\
            +dataprint_lib.print_f32(deltarho)+" "\
            +dataprint_lib.print_f32array(initialimg)+" "\
            +dataprint_lib.print_f32array(sino)+" "\
            +dataprint_lib.print_i32(iterations))
        #print bp data
        f = open(os.path.join(root,filenamebp),"w+")
        f.write(dataprint_lib.print_f32array(angles)+" "\
            +dataprint_lib.print_f32(rhozero)+" "\
            +dataprint_lib.print_f32(deltarho)+" "\
            +dataprint_lib.print_i32(size)+" "\
            +dataprint_lib.print_f32array(sino))
        #print fp data
        f = open(os.path.join(root,filenamefp),"w+")
        f.write(dataprint_lib.print_f32array(angles)+" "\
            +dataprint_lib.print_f32(rhozero)+" "\
            +dataprint_lib.print_f32(deltarho)+" "\
            +dataprint_lib.print_i32(numrhos)+" "\
            +dataprint_lib.print_f32array(phantom))

if __name__ == '__main__':
    main(sys.argv)
