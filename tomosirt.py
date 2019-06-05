###################################################################################
### python code for tomographic reconstruction in Futhark.###
###############################################################################

from futhark import SIRT
import numpy as np
import time
import matplotlib.pyplot as plt
import sys
import argparse
import re
import os
import dataread3d_lib
import pyopencl.array as pycl_array
import pyopencl as cl
import math
import queue
import threading
import gc

maxqlen = 50
exitFlag = 0
queueLock = threading.Lock()
workQueue = queue.Queue(maxqlen)

# preLock = threading.Lock()
transLock = threading.Lock()
# execLock = threading.Lock()
# postLock = threading.Lock()
#
# preLock2 = threading.Lock()
# transLock2 = threading.Lock()
# execLock2 = threading.Lock()
# postLock2 = threading.Lock()

def data_generator2D(f):
    content = dataread3d_lib.clean_str(f.readline())
    angles, rhozero, deltarho, initialimg, sino, iterations = [str for str in content.split(" ")]
    angles = np.fromstring( angles, dtype=np.float32, sep=',' )
    rhozero = float(rhozero)
    deltarho = float(deltarho)
    initialimg = np.fromstring( initialimg, dtype=np.float32, sep=',' )
    sino = np.fromstring( sino, dtype=np.float32, sep=',' )
    iterations = int(iterations)
    return angles, rhozero, deltarho, initialimg, sino, iterations

class myThread (threading.Thread):
    def __init__(self, workQueue, outdir, size, preLock, execLock , postLock, threadID=0, resQueue=None, offset=0.0, device=0, functionNum=0):
    # def __init__(self, workQueue, outdir, size, preLock, execLock , postLock, transLock, threadID=0, resQueue=None, offset=0.0, device=0, functionNum=0):
        threading.Thread.__init__(self)
        self.workQueue = workQueue
        self.outdir = outdir
        self.size = size
        self.threadID = threadID
        self.resQueue = resQueue
        self.offset = offset
        self.device = device
        self.preLock = preLock
        self.execLock = execLock
        self.postLock = postLock
        # self.transLock = transLock
    def run(self):
        process_data(self.workQueue, self.outdir, self.size, self.threadID, self.resQueue, self.offset, self.device, self.preLock, self.execLock , self.postLock)
        # process_data(self.workQueue, self.outdir, self.size, self.threadID, self.resQueue, self.offset, self.device, self.preLock, self.execLock , self.postLock, self.transLock)

def process_data(workQueue, outdir, size, threadID, resQueue, offset, device, preLock, execLock, postLock):
# def process_data(workQueue, outdir, size, threadID, resQueue, offset, device, preLock, execLock, postLock, transLock):
    dev = cl.get_platforms()[0].get_devices(device_type=cl.device_type.GPU)
    ctx = cl.Context([dev[device]])
    queue = cl.CommandQueue(ctx)
    sirt = SIRT.SIRT(command_queue=queue)
    while not exitFlag:
        preLock.acquire()

        queueLock.acquire()
        try:
            (slice, angles, rhozero, deltarho, initialimg, sino, iterations) = workQueue.get(block=True, timeout=0.3)
            workQueue.task_done()
            queueLock.release()
        except:
            queueLock.release()
            preLock.release()
            continue

        transLock.acquire()

        theta_gpu = pycl_array.to_device(queue, angles)
        img_gpu = pycl_array.to_device(queue, initialimg)
        sinogram_gpu = pycl_array.to_device(queue, sino)
        cl.enqueue_barrier(queue).wait()

        transLock.release()
        execLock.acquire()
        preLock.release()

        res = sirt.main(theta_gpu, rhozero, deltarho, img_gpu, sinogram_gpu, iterations)
        cl.enqueue_barrier(queue).wait()

        postLock.acquire()
        transLock.acquire()
        execLock.release()

        result = res.get(queue=queue)
        cl.enqueue_barrier(queue).wait()
        transLock.release()

        reshaped = result.reshape((size,size))
        plt.imsave(outdir + str(slice) + ".png", reshaped, cmap='Greys_r')
        # print("device %s has finished slice %s" %(str(device), str(slice)) )
        postLock.release()

def pipeline(indir, outdir, size, dim=2, numDev=1):
    start = time.time()
    global exitFlag
    o = os.path.join(outdir, "sirtinputf32rad" + str(size) + "-slice-")

    if dim == 2:
        f = open(os.path.join(indir, "sirtinputf32rad" + str(size)))
        angles, rhozero, deltarho, initialimg, sino, iterations = data_generator2D(f)
        f.close()
    elif dim == 3:
        f = open(indir, 'r')
        angles, rhozero, deltarho, initialimg, iterations = dataread3d_lib.data_generator(f)
    # Create new threads
    threads = []
    for devNum in range(numDev):
        preLock = threading.Lock()
        transLock = threading.Lock()
        execLock = threading.Lock()
        postLock = threading.Lock()
        thread0 = myThread(workQueue, o, size, preLock, execLock, postLock, threadID=0, device=devNum)
        thread1 = myThread(workQueue, o, size, preLock, execLock, postLock, threadID=1, device=devNum)
        thread2 = myThread(workQueue, o, size, preLock, execLock, postLock, threadID=2, device=devNum)
        # thread0 = myThread(workQueue, o, size, preLock, execLock, postLock, transLock, threadID=0, device=devNum)
        # thread1 = myThread(workQueue, o, size, preLock, execLock, postLock, transLock, threadID=1, device=devNum)
        # thread2 = myThread(workQueue, o, size, preLock, execLock, postLock, transLock, threadID=2, device=devNum)
        thread0.start()
        thread1.start()
        thread2.start()
        threads.append(thread0)
        threads.append(thread1)
        threads.append(thread2)

    # Fill the queue
    if dim == 2:
        for i in range(size):
            workQueue.put((i, angles.copy(), rhozero, deltarho, initialimg.copy(), sino.copy(), iterations), block=True)
    elif dim == 3:
        l = f.readline()
        i = 0
        while l:
            sino = dataread3d_lib.clean_str(l)
            sino = np.fromstring( sino, dtype=np.float32, sep=',' )
            workQueue.put((i, angles.copy(), rhozero, deltarho, initialimg.copy(), sino.copy(), iterations), block=True)
            i += 1
            l = f.readline()


    # Wait for queue to empty
    workQueue.join()

    # kill threads
    exitFlag = 1

    # Wait for all threads to complete
    for t in threads:
        t.join()

    # reset exitFlag
    exitFlag = 0
    end = time.time()

    print("- runtime:\t{}".format(end-start))
    if dim == 3:
        f.close()
    return end-start

def singlet(indir, outdir, size, dim=2):
    start = time.time()
    global exitFlag
    o = os.path.join(outdir, "singlethreaded" + str(size) + "-slice-")

    if dim == 2:
        f = open(os.path.join(indir, "sirtinputf32rad" + str(size)))
        angles, rhozero, deltarho, initialimg, sino, iterations = data_generator2D(f)
        f.close()
    # elif dim == 3:

    dev = cl.get_platforms()[0].get_devices(device_type=cl.device_type.GPU)
    ctx = cl.Context([dev[0]])
    queue = cl.CommandQueue(ctx)
    sirt = SIRT.SIRT(command_queue=queue)
    for slice in range(size):

        theta_gpu = pycl_array.to_device(queue, angles.copy())
        img_gpu = pycl_array.to_device(queue, initialimg.copy())
        sinogram_gpu = pycl_array.to_device(queue, sino.copy())
        queue.finish()
        cl.enqueue_barrier(queue).wait()

        res = sirt.main(theta_gpu, rhozero, deltarho, img_gpu, sinogram_gpu, iterations)
        queue.finish()
        cl.enqueue_barrier(queue).wait()

        result = res.get(queue=queue)
        queue.finish()
        cl.enqueue_barrier(queue).wait()
        reshaped = result.reshape((size,size))
        plt.imsave(o + str(slice) + ".png", reshaped, cmap='Greys_r')

    end = time.time()

    print("- runtime:\t{}".format(end-start))
    return end-start

def main(argv):
    parser = argparse.ArgumentParser(description="SIRT recontruction using data streaming to Futhark, benchmarking and proof of correctness and overlapping")
    parser.add_argument('-id', '--inputdirectory', help="Directory containing input data", default='~/synkrotomo/futhark/data')
    parser.add_argument('-if', '--inputfile', help="file containing input data", default=None)
    parser.add_argument('-od', '--outputdirectory', help="Directory in which to store the output data", default='~/tomography/img')
    parser.add_argument('-fd', '--filedirectory', help="Directory in which to store the timings file", default=None)
    parser.add_argument('-s', '--sizes', nargs='*', help="The sizes to run the recontruction for, 640 is the tooth dataset", type=int, default=[128])
    parser.add_argument('-x', '--repeat', help="number of repetitions, for testing", type=int, default=1)
    parser.add_argument('-d', '--devices', help="number of devices, max 2 atm", type=int, default=1)
    parser.add_argument('-r', '--reconstruct', help="multithreaded reconstruction", action='store_true')
    parser.add_argument('-c', '--compare', help="compare multithreaded to single threaded", action='store_true')
    parser.add_argument('-nm', '--nomulti', help="singlethreaded reconstruction", action='store_true')
    parser.add_argument('-p', '--prin', help="used for printing", action='store_true')

    args, unknown = parser.parse_known_args(argv)
    indir = os.path.expanduser(args.inputdirectory)
    od = os.path.expanduser(args.outputdirectory)
    filedir = args.filedirectory
    infile = args.inputfile

    sizes = args.sizes
    repeat = args.repeat
    dev = args.devices

    # gc.disable()
    if args.prin:
        d = cl.get_platforms()[0].get_devices(device_type=cl.device_type.GPU)
        print(cl.get_platforms())
        print(d)
    if args.reconstruct:
        if not filedir is None:
            filedir = os.path.expanduser(args.filedirectory)
            try:
                os.makedirs(filedir)
            except:
                pass
            try:
                ft = open(os.path.join(filedir, "timings" ), 'a+')
            except:
                pass

        if infile is None:
            for size in sizes:
                outdir = os.path.join(od, "recon-" + str(size))
                try:
                    os.makedirs(outdir)
                except:
                    pass
                print("\nsize %s began at %s" % (size, time.ctime()))
                pt = pipeline(indir, outdir, size, numDev=dev)
                if not filedir is None:
                    ft.write("size %s runtime:\t%s\n" % (size, pt))

            if not filedir is None:
                ft.close()
        else:
            infile = os.path.expanduser(args.inputfile)
            for size in sizes:

                outdir = os.path.join(od, "mette")
                try:
                    os.makedirs(outdir)
                except:
                    pass
                print("\nbegan at %s" % (time.ctime()))
                pt = pipeline(infile, outdir, size, numDev=dev, dim=3)


    if args.compare:
        if not filedir is None:
            filedir = os.path.expanduser(args.filedirectory)
            try:
                os.makedirs(filedir)
            except:
                pass
            try:
                ft = open(os.path.join(filedir, "timings" ), 'a+')
            except:
                pass
        for size in sizes:
            outdir = os.path.join(od, "pipeline-slices-" + str(size))
            outdir2 = os.path.join(od, "single-slices-" + str(size))
            try:
                os.makedirs(outdir)
                os.makedirs(outdir2)
            except:
                pass
            print("\nmultithreaded size %s began at %s" % (size, time.ctime()))
            pt = pipeline(indir, outdir, size, numDev=dev)
            print("\nsinglethreaded size %s began at %s" % (size, time.ctime()))
            st = singlet(indir, outdir2, size)
            print("\nSpeedup = %s" % (st/pt))
            if not filedir is None:
                ft.write("multithreaded size %s\n- runtime:\t%s\n" % (size, pt))
                ft.write("singlethreaded size %s\n- runtime:\t%s\n" % (size, st))
                ft.write("speedup %s\n" % (st/pt))

    if args.nomulti:
        for size in sizes:
            outdir = os.path.join(od, "slices-" + str(size))
            try:
                os.makedirs(outdir)
            except:
                pass
            print("\nsinglethreaded size %s began at %s" % (size, time.ctime()))
            singlet(indir, outdir, size)



if __name__ == '__main__':
    main(sys.argv)
