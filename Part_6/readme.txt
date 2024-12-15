Our Alpha 1 is primarily a software optimization that includes training and pruning a Resnet20 quantized network. You can find the ipynb and pdf in the sim folder along with all of our generated hardware stimulus. All the stimulus are tested on a testbench based on Part 3.

Our Alpha 2 is hardware/FIFO optimizations for weight and output stationary data flows. To run the weight stationary, run the filelist in sim_weight_stationary and to run output stationary, run the file list in the respective sim folder. 

Our Alpha 3 is a hardware optimization to compute the accumulation of partial sums as they exit the OFIFO to do this we use a dual port SRAM.
