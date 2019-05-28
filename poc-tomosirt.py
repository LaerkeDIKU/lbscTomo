###############################################################################
### python code for proof of concept of the pipeline                        ###
###############################################################################

from futhark import poc
import numpy as np
import time
import sys
import argparse
import os
import pyopencl.array as pycl_array
import pyopencl as cl
import queue
import threading

maxqlen = 50
exitFlag = 0
queueLock = threading.Lock()
workQueue = queue.Queue(maxqlen)
execLock = threading.Lock()
transLock = threading.Lock()
preLock = threading.Lock()
postLock = threading.Lock()


class myThread (threading.Thread):
    def __init__(self, threadID, qw, verbo):
        threading.Thread.__init__(self)
        self.threadID = threadID
        self.qw = qw
        self.verbo = verbo

    def run(self):
        process_data(self.threadID, self.qw)

def process_data(threadID, workQueue):
    dev = cl.get_platforms()[0].get_devices(device_type=cl.device_type.GPU)
    ctx = cl.Context([dev[0]])
    queue = cl.CommandQueue(ctx)

    prg = poc.poc(command_queue=queue)

    while not exitFlag:
        queueLock.acquire()
        if not workQueue.empty():
            preLock.acquire()

            (arr, iters) = workQueue.get()
            workQueue.task_done()
            queueLock.release()
            for i in range(6000):
                arr[i] += 1

            transLock.acquire()

            arr1_gpu = pycl_array.to_device(queue, arr)
            # wait for the enqueued action to finish - transfering to the device is not blocking
            cl.enqueue_barrier(queue).wait()
            transLock.release()
            execLock.acquire()
            preLock.release()

            res = prg.main(arr1_gpu, iters)
            # wait for the enqueued action to finish - the poc code is so simple it is non blocking
            cl.enqueue_barrier(queue).wait()

            postLock.acquire()
            execLock.release()
            transLock.acquire()

            result = res.get()
            # wait for the enqueued action to finish - transfering from the device is not blocking
            cl.enqueue_barrier(queue).wait()

            transLock.release()

            for i in range(6000):
                result[i] += 1
            postLock.release()
        else:
            queueLock.release()

def pipeline(size, runs, iters, verbo):
    start = time.time()
    arr1 = np.random.rand(size).astype(np.float32)

    global exitFlag

    # Fill queue
    for i in range(maxqlen):
        workQueue.put((arr1.copy(), iters))

    # Create new threads
    threads = []
    thread0 = myThread(0, workQueue, verbo)
    thread1 = myThread(1, workQueue, verbo)
    thread2 = myThread(2, workQueue, verbo)
    threads.append(thread0)
    threads.append(thread1)
    threads.append(thread2)
    thread0.start()
    thread1.start()
    thread2.start()

    # keep filling queue
    for i in range(runs-maxqlen):
        workQueue.put((arr1.copy(), iters), block=True)

    # Wait for queue to empty
    workQueue.join()
    exitFlag = 1

    # Wait for all threads to complete
    for t in threads:
        t.join()
    end = time.time()

    #reset exitFlag
    exitFlag = 0

    print("- pipeline runtime:\t{}".format(end-start))
    return (end-start)

def sequmin(size, runs, iters):
    start = time.time()
    arr = np.random.rand(size).astype(np.float32)

    test = cl.get_platforms()[0].get_devices(device_type=cl.device_type.GPU)
    ctx = cl.Context([test[0]])
    queue = cl.CommandQueue(ctx)
    prg = poc.poc(command_queue=queue)

    for i in range(runs):
        arr1 = arr.copy()
        for i in range(6000):
            arr1[i] += 1

        arr1_gpu = pycl_array.to_device(queue, arr1)
        # wait for the enqueued action to finish - transfering to the device is not blocking
        cl.enqueue_barrier(queue).wait()
        res = prg.main(arr1_gpu, iters)
        # wait for the enqueued action to finish - the poc code is so simple it is non blocking
        cl.enqueue_barrier(queue).wait()

        result = res.get()
        # wait for the enqueued action to finish - transfering from the device is not blocking
        cl.enqueue_barrier(queue).wait()
        for i in range(6000):
            result[i] += 1
    end = time.time()
    print("- sequentiel min runtime:\t{}".format(end-start))
    return (end-start)

def transtime(size, iters, verbo):
    arr1 = np.random.rand(100).astype(np.float32)

    test = cl.get_platforms()[0].get_devices(device_type=cl.device_type.GPU)

    ctx = cl.Context([test[0]])
    queue = cl.CommandQueue(ctx)
    prg = poc.poc(command_queue=queue)
    prec = 8
    for i in range(10):
        print("chunk " +str(i))
        arr1c = arr1.copy()

        start1 = time.time()
        arr1_gpu = pycl_array.to_device(queue, arr1c)
        cl.enqueue_barrier(queue).wait()
        end1 = time.time()
        if verbo:
            print("- runtime for data transfer (host->device): %f" % ( round(end1-start1, prec)))

        start2 = time.time()

        result = prg.main(arr1_gpu, iters)
        cl.enqueue_barrier(queue).wait()
        end2 = time.time()
        if verbo:
            print("- runtime for kernel execution: %f" % (round(end2-start2, prec)))

        kerneltime = ((end2-start2)/5)*4

        start3 = time.time()
        res = result.get()
        cl.enqueue_barrier(queue).wait()
        end3 = time.time()

        if verbo:
            print("- runtime for data transfer (device->host): %f" % (round(end3-start3, prec)))

    return kerneltime


def compare(size, runs, iters):
    print("compare sequential, and multithread pipeline, for the datasize %s, with %s iterations, running it %s times" % (size, iters, runs) )

    print ("\nsequential")
    st = sequmin(size, runs, iters)

    print("\nmultithread")
    pt = pipeline(size, runs, iters, False)

    print("\nSpeedup = %s \n" %(st/pt))

def main(argv):
    parser = argparse.ArgumentParser(description="3D SIRT recontruction using data streaming to Futhark, benchmarking and proof of correctness and overlapping")
    parser.add_argument('-id', '--inputdirectory', help="Directory containing input data", default='~/synkrotomo/futhark/data')
    parser.add_argument('-od', '--outputdirectory', help="Directory in which to store the output data", default='~/tomography/img')
    parser.add_argument('-i', '--iter', help="number of iterations", type=int, default=350)
    parser.add_argument('-r', '--runs', help="The sizes to run the recontruction for, 640 is the tooth dataset", type=int, default=500)
    parser.add_argument('-t', '--trans', help="print transfer timings", action='store_true')
    parser.add_argument('-p', '--pipeline', help="print transfer timings", action='store_true')
    parser.add_argument('-v', '--ver', help="print transfer timings", action='store_true')
    parser.add_argument('-c', '--comp', help="compare timings", action='store_true')

    args, unknown = parser.parse_known_args(argv)
    indir = os.path.expanduser(args.inputdirectory)
    outdir = os.path.expanduser(args.outputdirectory)
    runs = args.runs
    iter = args.iter
    ver = args.ver


    if args.trans:
        transtime(4096*4096, iter, True)
    if args.pipeline:
        pipeline(4096*4096, runs, iter, False)
    if args.comp:
        compare(4096*4096, runs, iter)



if __name__ == '__main__':
    main(sys.argv)
