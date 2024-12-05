// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_ki = 3;
parameter len_onij = 8; //coordinates of output feature map
parameter len_oni = 8; //coordinates of output feature map
parameter col = 8;
parameter row = 8;
parameter len_nij = 9; //coordinates of input feature map
parameter len_ni = 8; //coordinates of input feature map
parameter len_ic = 3;

reg clk = 0;
reg reset = 1;

wire [35:0] inst_q; 

reg [1:0]  inst_w_q = 0; 
//Input SRAM variables:
reg [bw*row-1:0] D_xmem_q = 0;//input
reg CEN_xmem = 1; //clock enable i think. enabled when CEN=0
reg WEN_xmem = 1; // write enable. enabled when WEN=0
reg [10:0] A_xmem = 0;//address
reg CEN_xmem_q = 1; 
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;

//output SRAM variables:
reg CEN_pmem = 1;//clock enable
reg WEN_pmem = 1;//write enable
reg [10:0] A_pmem = 0;//address
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg [10:0] A_pmem_q = 0;

//commands for various core components
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg acc = 0;
reg mode = 1;
reg mode_q = 1;
reg output_en = 0;
reg output_en_q = 0;

reg [1:0]  inst_w; 
reg [bw*row-1:0] D_xmem; //output of input memory
reg [psum_bw*col-1:0] answer;


reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [8*30:1] w_file_name;
reg [8*30:1] x_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer p_file, p_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, ic;
integer error;
reg [bw*col-1:0]temp;
reg [bw*col-1:0]temp_q;

assign inst_q[35] = output_en_q;
assign inst_q[34] = mode_q;
assign inst_q[33] = acc_q;
assign inst_q[32] = CEN_pmem_q;
assign inst_q[31] = WEN_pmem_q;
assign inst_q[30:20] = A_pmem_q;
assign inst_q[19]   = CEN_xmem_q;
assign inst_q[18]   = WEN_xmem_q;
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6]   = ofifo_rd_q;
assign inst_q[5]   = ififo_wr_q;
assign inst_q[4]   = ififo_rd_q;
assign inst_q[3]   = l0_rd_q;
assign inst_q[2]   = l0_wr_q;
assign inst_q[1]   = execute_q; 
assign inst_q[0]   = load_q; 


core  #(.bw(bw), .psum_bw(psum_bw), .col(col), .row(row)) core_instance (
	.clk(clk), 
	.inst(inst_q),
	.ofifo_valid(ofifo_valid),
  .D_xmem(D_xmem_q), 
  .sfp_out(sfp_out), 
	.reset(reset)); 
  

initial begin 

  inst_w   = 0; 
  D_xmem   = 0;
  CEN_xmem = 1;
  WEN_xmem = 1;
  A_xmem   = 0;
  ofifo_rd = 0;
  ififo_wr = 0;
  ififo_rd = 0;
  l0_rd    = 0;
  l0_wr    = 0;
  execute  = 0;
  load     = 0;
  temp_q   = 0;
  mode     = 1;
  output_en= 0;

  error = 0;
  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);

;

  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 

  for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;   
  /////////////////////////
    #0.5 clk = 1'b0;   reset = 1;
    #0.5 clk = 1'b1; 

    for (i=0; i<10 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   reset = 0;
    #0.5 clk = 1'b1; 

    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;  


//loop through all of our input channel values 
  //$display("############ Verification Start during Partial Sum Calculation #############");
  for (ic=0; ic < len_ic ; ic=ic+1) begin  // kij loop

    case(ic)
     0: begin w_file_name = "weight_os_ic0.txt"; x_file_name = "activation_os_ic0.txt"; end
     1: begin w_file_name = "weight_os_ic1.txt"; x_file_name = "activation_os_ic1.txt"; end
     2: begin w_file_name = "weight_os_ic2.txt"; x_file_name = "activation_os_ic2.txt"; end
    endcase
    
    x_file = $fopen(x_file_name, "r");
    // Following three lines are to remove the first three comment lines of the file
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);

    w_file = $fopen(w_file_name, "r");
    // Following three lines are to remove the first three comment lines of the file
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);

 

    
    /////// Activation data writing to memory ///////
    A_xmem=0;
    for (t=0; t<len_nij; t=t+1) begin  
      #0.5 clk = 1'b0;  x_scan_file = $fscanf(x_file,"%32b", D_xmem); WEN_xmem = 0; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1;
      //$display("Mem addr: %11b", core_instance.xmem_addr);
      //$display("Mem input: %32b", core_instance.D_xmem);
      #0.5 clk = 1'b1;   
    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1; 

    $fclose(x_file);
    /////////////////////////////////////////////////


    /////// Kernel data writing to memory ///////

    A_xmem = 11'b10000000000;

    for (t=0; t<len_kij; t=t+1) begin  
      #0.5 clk = 1'b0;  w_scan_file = $fscanf(w_file,"%32b", D_xmem); WEN_xmem = 0; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1;
      //$display("Mem addr: %11b", core_instance.xmem_addr);
      //$display("Mem input: %32b", core_instance.D_xmem);
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////
    $fclose(w_file);


    /////// Kernel data writing to IFIFO ///////
    A_xmem = 11'b10000000000;
    /*#0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 0; 
    #0.5 clk = 1'b1; */
    for (t=0; t<len_kij+3; t=t+1) begin  
      #0.5 clk = 1'b0;   WEN_xmem = 1; CEN_xmem = 0; 
      if (t>1) begin A_xmem = A_xmem + 1; ififo_wr = 1; end
      if (t>2) begin   
        //$display("Mem addr: %11b", core_instance.xmem_addr);
        //$display("ic= %1d %1d : ififo W in: %32b",ic,t-3,core_instance.corelet_inst.weight_in);
        //$display("ififo_wr %b",core_instance.corelet_inst.ififo_wr);
      end
      #0.5 clk = 1'b1;  
    end
    //$display("SRAM first weight %32b",core_instance.xmem_sram.memory[11'b10000000000]);
    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0; ififo_wr = 0;
    #0.5 clk = 1'b1; 


    /////////////////////////////////////

    #0.5 clk = 1'b0;   l0_rd = 0;load = 0;
    #0.5 clk = 1'b1;

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1;



    /////// Activation data writing to L0 ///////
    A_xmem = 0;
    for (t=0; t<len_nij+3; t=t+1) begin  
      #0.5 clk = 1'b0;   WEN_xmem = 1; CEN_xmem = 0; 
      if (t>1)  begin A_xmem = A_xmem + 1;  l0_wr = 1; end
      if (t>2) begin   l0_wr = 1;
        //$display("Mem addr: %11b", core_instance.xmem_addr);
        //$display("ic= %1d %1d : l0 A in: %32b",ic,t-3,core_instance.corelet_inst.activation_in);
        //$display("l0_wr %b",core_instance.corelet_inst.l0_wr);
      end
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0; l0_wr = 0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////


    /////// Execution ///////    
    #0.5 clk = 1'b0;  ififo_rd = 1;l0_rd = 1; execute = 1;
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0; //ififo_rd = 1;l0_rd = 1;
    #0.5 clk = 1'b1;

    for (t=0; t<3*row-3; t=t+1) begin  
      #0.5 clk = 1'b0;    load = 0; // 
      l0_rd = 1; ififo_rd = 1; execute=1;
      if(t>len_nij-1)      begin l0_rd = 0; ififo_rd = 0; execute=0; end 
      else if(t>len_nij-3) begin l0_rd = 1; ififo_rd = 1; execute=0; end
      else                 begin l0_rd = 1; ififo_rd = 1; execute=1; end
      //$display("%2d : ififo_rd %b",t,core_instance.corelet_inst.ififo_rd);
      //$display("%2d : inst %16b",t,core_instance.corelet_inst.mac_array_inst.inst_w_temp);
      //$display("%2d : MAC in_n: %32b",t,core_instance.corelet_inst.ififo_out);
      //temp = core_instance.corelet_inst.ififo_out;
      //$display("%2d : MAC in_n: %d %d %d %d %d %d %d %d",t,$signed(temp[8*bw-1:7*bw]),$signed(temp[7*bw-1:6*bw]),$signed(temp[6*bw-1:5*bw]),$signed(temp[5*bw-1:4*bw]),$signed(temp[4*bw-1:3*bw]),$signed(temp[3*bw-1:2*bw]),$signed(temp[2*bw-1:1*bw]),$signed(temp[1*bw-1:0*bw]));
      //$display("%2d : MAC in_n: %128b",t,core_instance.corelet_inst.mac_array_inst.in_n);
      //$display("%2d : MACin_n1: %128b",t,core_instance.corelet_inst.mac_array_inst.temp[8*col*psum_bw-1 :7*col*psum_bw]);
      //temp = core_instance.corelet_inst.mac_array_inst.in_w;
      //$display("%2d : MAC in_w:  %d %d %d %d %d %d %d %d",t,$signed(temp[8*bw-1:7*bw]),$signed(temp[7*bw-1:6*bw]),$signed(temp[6*bw-1:5*bw]),$signed(temp[5*bw-1:4*bw]),$signed(temp[4*bw-1:3*bw]),$signed(temp[3*bw-1:2*bw]),$signed(temp[2*bw-1:1*bw]),$signed(temp[1*bw-1:0*bw]));
      //$display("%2d : MAC in_w: %32b",t,core_instance.corelet_inst.mac_array_inst.in_w);
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  load = 0; l0_rd = 0; execute=0; ififo_rd = 0;
    #0.5 clk = 1'b1;  


  end  // end of kij loop

  #0.5 clk = 1'b0;   l0_rd = 0; load = 0; execute=0;  output_en=1; WEN_pmem = 0; CEN_pmem = 0; A_pmem = len_onij ; load = 0;ofifo_rd = 1;
  #0.5 clk = 1'b1; 
  #0.5 clk = 1'b0; A_pmem = len_onij-1;
  #0.5 clk = 1'b1; 
    
////////////////Start moving outputs to the mem/////////////////////

  for (i=0; i<len_onij ; i=i+1) begin
    #0.5 clk = 1'b0; WEN_pmem = 0; CEN_pmem = 0;  A_pmem = A_pmem - 1;
    //if(i>col) load = 0;
    //$display("%2d : MAC valid: %8b",i,core_instance.corelet_inst.mac_array_inst.valid);
    //$display("%2d : MAC out: %128b",i,core_instance.corelet_inst.mac_array_inst.out_s);
    //$display("%2d : MAC out7 %128b",i,core_instance.corelet_inst.mac_array_inst.temp[psum_bw*8*col-1:psum_bw*7*col]);
    #0.5 clk = 1'b1;  
  end
  #0.5 clk = 1'b0;   load=0; output_en=0; #0.5 clk = 1'b0;   ofifo_rd = 0;  WEN_pmem = 1; CEN_pmem = 1; A_pmem = 0;
  #0.5 clk = 1'b1; 

//We no longer need OFIFO!  
//kernal values are all computed now we sum them up to get our output

  ////////// Accumulation /////////
  out_file = $fopen("out_os.txt", "r");  

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;



  $display("############ Verification Start by reading PMEM #############"); 
//$display("SRAM first output %128b",core_instance.pmem_sram.memory[11'b00000000000]);
  #0.5 clk = 1'b0 ;A_pmem=0; CEN_pmem = 0; WEN_pmem = 1;
  #0.5 clk = 1'b1;
  #0.5 clk = 1'b0; A_pmem=1; CEN_pmem = 0; WEN_pmem = 1;
  #0.5 clk = 1'b1;
  for (i=0; i<len_onij; i=i+1) begin 
    #0.5 clk = 1'b0;
    A_pmem=A_pmem + 1;

     out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
       if (sfp_out == answer)
         $display("%2d-th output featuremap Data matched! :D", i); 
       else begin
         $display("%2d-th output featuremap Data ERROR!!", i); 
         $display("sfpout  : %16b %16b %16b %16b %16b %16b %16b %16b", 
         sfp_out[psum_bw*8-1:psum_bw*7],sfp_out[psum_bw*7-1:psum_bw*6],sfp_out[psum_bw*6-1:psum_bw*5],sfp_out[psum_bw*5-1:psum_bw*4],sfp_out[psum_bw*4-1:psum_bw*3],sfp_out[psum_bw*3-1:psum_bw*2],sfp_out[psum_bw*2-1:psum_bw*1],sfp_out[psum_bw*1-1:psum_bw*0]
         );
         $display("answer  : %16b %16b %16b %16b %16b %16b %16b %16b", answer[psum_bw*8-1:psum_bw*7],answer[psum_bw*7-1:psum_bw*6],answer[psum_bw*6-1:psum_bw*5],answer[psum_bw*5-1:psum_bw*4],answer[psum_bw*4-1:psum_bw*3],answer[psum_bw*3-1:psum_bw*2],answer[psum_bw*2-1:psum_bw*1],answer[psum_bw*1-1:psum_bw*0]);

         error = 1;
       end
    #0.5 clk = 1'b1;
  end


  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 

  end

  $fclose(out_file);
  //////////////////////////////////

  for (t=0; t<10; t=t+1) begin  
    #0.5 clk = 1'b0;  
    #0.5 clk = 1'b1;  
  end

  #10 $finish;

end

always @ (posedge clk) begin
   inst_w_q   <= inst_w; 
   D_xmem_q   <= D_xmem;
   CEN_xmem_q <= CEN_xmem;
   WEN_xmem_q <= WEN_xmem;
   A_pmem_q   <= A_pmem;
   CEN_pmem_q <= CEN_pmem;
   WEN_pmem_q <= WEN_pmem;
   A_xmem_q   <= A_xmem;
   ofifo_rd_q <= ofifo_rd;
   acc_q      <= acc;
   ififo_wr_q <= ififo_wr;
   ififo_rd_q <= ififo_rd;
   l0_rd_q    <= l0_rd;
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
   temp_q     <= temp;
   mode_q     <= mode;
   output_en_q<= output_en;
end


endmodule




