// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_onij = 16; //coordinates of output feature map
parameter col = 8;
parameter row = 8;
parameter len_nij = 36; //coordinates of input feature map

reg clk = 0;
reg reset = 1;

wire [33:0] inst_q; 

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
reg [8*30:1] p_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer p_file, p_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij;
integer error;
reg [psum_bw*col-1:0]temp;

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


core  #(.bw(bw), .col(col), .row(row)) core_instance (
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

  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);

  x_file = $fopen("activation.txt", "r");
  // Following three lines are to remove the first three comment lines of the file
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);

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

  /////// Activation data writing to memory ///////
  for (t=0; t<len_nij; t=t+1) begin  
    #0.5 clk = 1'b0;  x_scan_file = $fscanf(x_file,"%32b", D_xmem); WEN_xmem = 0; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1;
    #0.5 clk = 1'b1;   
  end

  #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
  #0.5 clk = 1'b1; 

  $fclose(x_file);
  /////////////////////////////////////////////////

//loop through all of our kernal values and check the psum for each one
  for (kij=0; kij<9; kij=kij+1) begin  // kij loop

    case(kij)
     0: begin w_file_name = "weight_kij0.txt"; p_file_name = "psum_kij0.txt"; end
     1: begin w_file_name = "weight_kij1.txt"; p_file_name = "psum_kij1.txt"; end
     2: begin w_file_name = "weight_kij2.txt"; p_file_name = "psum_kij2.txt"; end
     3: begin w_file_name = "weight_kij3.txt"; p_file_name = "psum_kij3.txt"; end
     4: begin w_file_name = "weight_kij4.txt"; p_file_name = "psum_kij4.txt"; end
     5: begin w_file_name = "weight_kij5.txt"; p_file_name = "psum_kij5.txt"; end
     6: begin w_file_name = "weight_kij6.txt"; p_file_name = "psum_kij6.txt"; end
     7: begin w_file_name = "weight_kij7.txt"; p_file_name = "psum_kij7.txt"; end
     8: begin w_file_name = "weight_kij8.txt"; p_file_name = "psum_kij8.txt"; end
    endcase
    

    w_file = $fopen(w_file_name, "r");
    // Following three lines are to remove the first three comment lines of the file
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);

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





    /////// Kernel data writing to memory ///////

    A_xmem = 11'b10000000000;

    for (t=0; t<col; t=t+1) begin  
      #0.5 clk = 1'b0;  w_scan_file = $fscanf(w_file,"%32b", D_xmem); WEN_xmem = 0; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1;
      $display("Mem addr: %11b", core_instance.xmem_addr);
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////
    $fclose(w_file);


    /////// Kernel data writing to L0 ///////
    A_xmem = 11'b10000000000;
    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 0; 
    #0.5 clk = 1'b1; 
    for (t=0; t<col; t=t+1) begin  
      #0.5 clk = 1'b0;   WEN_xmem = 1; CEN_xmem = 0; l0_wr = 1;  if (t>0) A_xmem = A_xmem + 1; 
      //$display("%2d : l0 W in: %32b",t,core_instance.corelet_inst.activation_in);
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0; l0_wr = 0;
    #0.5 clk = 1'b1; 


    /////////////////////////////////////



    /////// Kernel loading to PEs ///////
    for (t=0; t<3*col; t=t+1) begin  
      #0.5 clk = 1'b0;   l0_rd = 1; load = 1; execute=0;
      //$display("Kernal loading: %32b",core_instance.corelet_inst.mac_array_inst.in_w);
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   l0_rd = 0; load = 0; execute=0;
    #0.5 clk = 1'b1; 

    /////////////////////////////////////
  


    ////// provide some intermission to clear up the kernel loading ///
    #0.5 clk = 1'b0;  load = 0; l0_rd = 0;
    #0.5 clk = 1'b1;  
  

    for (i=0; i<12 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end
    /////////////////////////////////////



    /////// Activation data writing to L0 ///////
    A_xmem = 0;
    #0.5 clk = 1'b0;WEN_xmem = 1; CEN_xmem = 0;
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0;WEN_xmem = 1; CEN_xmem = 0;
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0;WEN_xmem = 1; CEN_xmem = 0;A_xmem = A_xmem + 1;
    #0.5 clk = 1'b1;
    for (t=0; t<len_nij; t=t+1) begin  
      #0.5 clk = 1'b0;   WEN_xmem = 1; CEN_xmem = 0; l0_wr = 1; /*if (t>0)*/  A_xmem = A_xmem + 1; 
      //$display("%2d : l0 in: %32b",t,core_instance.corelet_inst.activation_in);
      #0.5 clk = 1'b1;  
    end
    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0; l0_wr = 0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////

    p_file = $fopen(p_file_name, "r");
    // Following three lines are to remove the first three comment lines of the file
    p_scan_file = $fscanf(p_file,"%s", captured_data);
    p_scan_file = $fscanf(p_file,"%s", captured_data);
    p_scan_file = $fscanf(p_file,"%s", captured_data);

    /////// Execution ///////
    for (t=0; t<len_nij; t=t+1) begin  
      #0.5 clk = 1'b0;   l0_rd = 1; load = 0; execute=1;
      //$display("%2d : MAC in: %32b",t,core_instance.corelet_inst.mac_array_inst.in_w);
      //$display("%2d : MAC out: %128b",t,core_instance.corelet_inst.mac_array_inst.out_s);
      /*p_scan_file = $fscanf(p_file,"%128b", answer); // reading from out file to answer
      temp = core_instance.corelet_inst.mac_array_out;
      if (temp === answer)
         $display("%d kij: %d-th psum featuremap Data matched! :D", kij, t); 
       else begin
         $display("%d-th psum featuremap Data ERROR!!", t); 
         $display("OFIO out: %128b", temp);
         $display("answer  : %128b", answer);
         error = 1;
       end*/
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   l0_rd = 0; load = 0; execute=0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////

    /*#0.5 clk = 1'b0;   ofifo_rd=1;
    #0.5 clk = 1'b1; */

    //////// OFIFO READ ////////
    // Ideally, OFIFO should be read while execution, but we have enough ofifo
    // depth so we can fetch out after execution.
    A_pmem = 11'b00000000000;
    for (t=0; t<len_nij+2; t=t+1) begin  
      #0.5 clk = 1'b0;   ofifo_rd = 1; WEN_pmem = 1; CEN_pmem = 0; if (t>0) A_pmem = A_pmem + 1; 
      //$display("OFIFO out: %128b", core_instance.corelet_out);
      /*if(t>2) begin
      p_scan_file = $fscanf(p_file,"%128b", answer); // reading from out file to answer
      temp = core_instance.corelet_out;
      if (temp === answer)
         $display("%d kij: %d-th psum featuremap Data matched! :D", kij, t-3); 
       else begin
         $display("%d-th psum featuremap Data ERROR!!", t-3); 
         $display("OFIO out: %128b", temp);
         $display("answer  : %128b", answer);
         error = 1;
       end
      end*/
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   ofifo_rd = 0;  WEN_pmem = 1; CEN_pmem = 0; A_pmem = 0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////
    $fclose(p_file);

  end  // end of kij loop
//kernal values are all computed now we sum them up to get our output

  ////////// Accumulation /////////
  out_file = $fopen("out.txt", "r");  

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;



  $display("############ Verification Start during accumulation #############"); 

  for (i=0; i<len_onij+1; i=i+1) begin 

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1; 

    if (i>0) begin
     out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
       if (sfp_out == answer)
         $display("%2d-th output featuremap Data matched! :D", i); 
       else begin
         $display("%2d-th output featuremap Data ERROR!!", i); 
         $display("sfpout: %128b", sfp_out);
         $display("answer: %128b", answer);
         error = 1;
       end
    end
   
 
    #0.5 clk = 1'b0; reset = 1;
    #0.5 clk = 1'b1;  
    #0.5 clk = 1'b0; reset = 0; 
    #0.5 clk = 1'b1;  

    /*for (j=0; j<len_kij+1; j=j+1) begin 

      #0.5 clk = 1'b0;   
        if (j<len_kij) begin CEN_pmem = 0; WEN_pmem = 1; acc_scan_file = $fscanf(acc_file,"%11b", A_pmem); end
                       else  begin CEN_pmem = 1; WEN_pmem = 1; end

        if (j>0)  acc = 1;  
      #0.5 clk = 1'b1;   
    end

    #0.5 clk = 1'b0; acc = 0;
    #0.5 clk = 1'b1; */
  end


  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 

  end

  //$fclose(acc_file);
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
end


endmodule




