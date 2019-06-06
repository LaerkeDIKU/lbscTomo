import numpy as np
import sys
import math
import tomo_lib
import dataprint_lib
import os

def main(argv):
    size = 1024
    root = os.path.expanduser(argv[1])
    if not os.path.exists(root):
        os.makedirs(root)
    for num_angles in np.concatenate((np.linspace(1,5,2),np.linspace(10,100,18,endpoint=False))):
        num_angles = int(num_angles)
        print("working on data for size "+str(num_angles))
        filenamesirt = "sirtinputf32rad"+str(num_angles)
        #filenamesirt3D = "..//synkrotomo//data//sirt3Dinputf32rad"+str(i)
        filenamebp = "bpsparseinputf32rad"+str(num_angles)
        filenamefp = "fpsparseinputf32rad"+str(num_angles)

        angles = tomo_lib.get_angles(size, False, num_angles)
        numrhos = int(np.ceil(np.sqrt(2*(size**2))))
        rhozero = -(numrhos-1)/2.0
        deltarho = 1.0
        initialimg = np.zeros(size*size)
        (phantom, originalimg) = tomo_lib.get_phantom(size)
        # print(phantom)
        # print(phantom.shape)
        sino = tomo_lib.get_sinogram(phantom,deltarho,numrhos,angles).flatten()
        phantom = phantom.flatten()

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

        f = open(os.path.join(root,filenamesirt),"w+")
        f.write(dataprint_lib.print_f32array(angles)+" "\
            +dataprint_lib.print_f32(rhozero)+" "\
            +dataprint_lib.print_f32(deltarho)+" "\
            +dataprint_lib.print_f32array(initialimg)+" "\
            +dataprint_lib.print_f32array(sino)+" "\
            +dataprint_lib.print_i32(200))
if __name__ == '__main__':
    main(sys.argv)
