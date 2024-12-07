// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_ki = 3;
parameter len_onij = 16; //coordinates of output feature map
parameter len_oni = 4; //coordinates of output feature map
parameter col = 8;
parameter row = 8;
parameter len_nij = 36; //coordinates of input feature map
parameter len_ni = 6; //coordinates of input feature map

reg clk = 0;
reg reset = 1;

wire [46:0] inst_q; 

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
reg REN_pmem = 1;//read enable
reg [10:0] A_rd_pmem_q = 0; //adress
reg [10:0] A_wr_pmem_q = 0;
reg [10:0] A_rd_pmem = 0; //adress
reg [10:0] A_wr_pmem = 0;
reg [10:0] A_temp = 0;
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg REN_pmem_q = 1;


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
reg en_relu = 0;
reg en_relu_q = 0;

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
reg [15:0] nij;
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
reg [psum_bw*col-1:0]temp_q;

assign inst_q[46] = en_relu_q;
assign inst_q[45] = acc_q;
assign inst_q[44] = CEN_pmem_q;
assign inst_q[43] = REN_pmem_q;
assign inst_q[42] = WEN_pmem_q;
assign inst_q[30:20] = A_rd_pmem_q;
assign inst_q[41:31] = A_wr_pmem_q;
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
  CEN_pmem = 1;
  WEN_pmem = 1;
  A_xmem   = 0;
  A_rd_pmem = 0;
  A_wr_pmem = 0;
  ofifo_rd = 0;
  ififo_wr = 0;
  ififo_rd = 0;
  l0_rd    = 0;
  l0_wr    = 0;
  execute  = 0;
  load     = 0;
  temp_q   = 0;
  nij      = 0;
  en_relu  = 0;

  error = 0;
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
  //$display("############ Verification Start during Partial Sum Calculation #############");
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
      //$display("Mem addr: %11b", core_instance.xmem_addr);
      //$display("Mem input: %32b", core_instance.D_xmem);
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////
    $fclose(w_file);


    /////// Kernel data writing to L0 ///////
    A_xmem = 11'b10000000000;
    /*#0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 0; 
    #0.5 clk = 1'b1; */
    for (t=0; t<col+3; t=t+1) begin  
      #0.5 clk = 1'b0;   WEN_xmem = 1; CEN_xmem = 0; 
      if (t>1) begin A_xmem = A_xmem + 1; l0_wr = 1; end
      if (t>2) begin   
        //$display("Mem addr: %11b", core_instance.xmem_addr);
        //$display("kij= %1d %1d : l0 W in: %32b",kij,t-3,core_instance.corelet_inst.activation_in);
      end
      #0.5 clk = 1'b1;  
    end
    //$display("SRAM first weight %32b",core_instance.xmem_sram.memory[11'b10000000000]);
    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0; l0_wr = 0;
    #0.5 clk = 1'b1; 


    /////////////////////////////////////

    #0.5 clk = 1'b0;   l0_rd = 1;load = 1;
    #0.5 clk = 1'b1;

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1;


    /////// Kernel loading to PEs ///////
    for (t=0; t<2*col-1; t=t+1) begin  
      #0.5 clk = 1'b0; execute=0;  
      if(t>1*col-3)begin l0_rd = 0; load = 0;end 
      else begin l0_rd = 1; load = 1;end
      //$display("Kernal loading: %32b and load= %16b",core_instance.corelet_inst.mac_array_inst.in_w,core_instance.corelet_inst.mac_array_inst.inst_w_temp);
       
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   l0_rd = 0; load = 0; execute=0;
    #0.5 clk = 1'b1; 

    /////////////////////////////////////
  


    ////// provide some intermission to clear up the kernel loading ///
    #0.5 clk = 1'b0;  load = 0; l0_rd = 0;
    #0.5 clk = 1'b1;  
  

    for (i=0; i<16 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end
    /////////////////////////////////////



    /////// Activation data writing to L0 ///////
    A_xmem = 0;
    for (t=0; t<len_nij+3; t=t+1) begin  
      #0.5 clk = 1'b0;   WEN_xmem = 1; CEN_xmem = 0; 
      if (t>1)  A_xmem = A_xmem + 1;
      if (t>2) begin l0_wr = 1;  
        //$display("Mem addr: %11b", core_instance.xmem_addr);
        //$display("kij= %1d %1d : l0 A in: %32b",kij,t-3,core_instance.corelet_inst.activation_in);
      end
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
    #0.5 clk = 1'b0;    l0_rd = 1; execute=0;// 
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1;

    #0.5 clk = 1'b0; //
    #0.5 clk = 1'b1;

    for (t=0; t<len_nij+2*(row+2); t=t+1) begin // increase the loop cycle anyhow
      #0.5 clk = 1'b0; load = 0; execute=1; acc = 1; CEN_pmem = 0; WEN_pmem = 0; REN_pmem = 0;
      if(t>len_nij-col+1)begin l0_rd = 0; end 
      else begin l0_rd = 1; end

        if (t>2*row+2) begin
          ofifo_rd = 1; 
        end
        if (t>2*row) begin
          nij = nij + 1;
        A_wr_pmem = A_temp; A_temp = A_rd_pmem;
        A_rd_pmem = (((nij-1)/len_ni+1)+(1-kij/3))*(len_ni+2)+(((nij-1)%len_ni+1)+(1-kij%len_ki));

        $display("kij%1d : %2d rd Mem addr: %2d", kij, t, A_rd_pmem);
        //$display("%2d : temp 1 addr: %2d", t, A_temp);
        $display("kij%1d : %2d wr Mem addr: %2d", kij, t, A_wr_pmem);
        
        //$display("%2d : nij %2d: ofifo_valid: %1b",t,nij-1,ofifo_valid);
        //$display("%2d : nij %2d: ofifo_read:  %1b",t,nij-1,ofifo_rd);
        //$display("%2d : nij %2d: array_valid: %1b",t,nij-1,core_instance.corelet_inst.mac_array_valid);
        //$display("%2d, nij %2d: fifo_ptr: %2d",t,nij-1,core_instance.corelet_inst.ofifo_inst.fifo_instance[0].rd_ptr);
        //$display("%2d, nij %2d: core_out: %128b",t,nij-1,core_instance.corelet_inst.ofifo_out);
        //$display("%2d, nij %2d: pmem_out: %128b",t,nij-1,core_instance.pmem_out);
        //$display("%2d, nij %2d: sfp_in_p: %128b",t,nij-1,core_instance.corelet_inst.sfp_in);
        //$display("%2d, nij %2d: sfp_in_of:%128b",t,nij-1,core_instance.corelet_inst.sfp_in_temp);
        //$display("%2d, nij %2d: sfp_old:  %128b",t,nij-1,core_instance.corelet_inst.sfp_row.in_old);
        //$display("%2d, nij %2d: sfp_acc:  %128b",t,nij-1,core_instance.corelet_inst.sfp_row.acc);
        //$display("%2d, nij %2d: sfp_in_p: %128b",t,nij-1,core_instance.corelet_inst.sfp_row.in_pmem);
        //$display("%2d, nij %2d: sfp_out:  %128b",t,nij-1,core_instance.corelet_inst.sfp_out);

        //$display("%2d : in_pmem: %128b",t,core_instance.corelet_inst.in_pmem);
        $display("kij%1d : %2d pmem out :  %128b",kij, t,core_instance.pmem_sram.Q);
        $display("kij%1d : %2d pmem in  :  %128b",kij, t,core_instance.pmem_sram.D);
      end
      //$display("%2d : MAC in: %32b",t,core_instance.corelet_inst.mac_array_inst.in_w);
      //$display("%2d : MAC out: %128b",t,core_instance.corelet_inst.mac_array_inst.out_s);
      //$display("%2d : MAC out: %11b",t,core_instance.corelet_inst.mac_array_inst.out_s);
      
      #0.5 clk = 1'b1;  
    end

    

    #0.5 clk = 1'b0; l0_rd = 0; load = 0; execute=0; WEN_pmem = 1; acc = 0; ofifo_rd = 0; nij = 0; // reset nij after each kij loop
    #0.5 clk = 1'b1; 
    /////////////////////////////////////

    /*#0.5 clk = 1'b0;   ofifo_rd=1;
    #0.5 clk = 1'b1; */

    //////// OFIFO READ ////////
    // Ideally, OFIFO should be read while execution, but we have enough ofifo
    // depth so we can fetch out after execution.
    /*
    #0.5 clk = 1'b0; WEN_pmem = 0; CEN_pmem = 0; A_pmem = 11'b00000000000 + len_nij*kij;
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0; A_pmem = 11'b00000000001 + len_nij*kij; temp = core_instance.corelet_out;
    #0.5 clk = 1'b1;
    for (t=0; t<len_nij; t=t+1) begin  
      #0.5 clk = 1'b0;   ofifo_rd = 1; WEN_pmem = 0; CEN_pmem = 0;  A_pmem = A_pmem + 1; 
      //$display("OFIFO out: %128b", core_instance.corelet_out);
      //if(t>0) begin
      p_scan_file = $fscanf(p_file,"%128b", answer); // reading from out file to answer
      temp = core_instance.corelet_out;
      if (temp_q === answer) begin
         //$display("%d kij: %d-th psum featuremap Data matched! :D", kij, t); 
      end
       else begin
         $display("%1d-th psum featuremap Data ERROR!!", t); 
         $display("OFIO out: %16b %16b %16b %16b %16b %16b %16b %16b", 
         temp_q[psum_bw*8-1:psum_bw*7],temp_q[psum_bw*7-1:psum_bw*6],temp_q[psum_bw*6-1:psum_bw*5],temp_q[psum_bw*5-1:psum_bw*4],temp_q[psum_bw*4-1:psum_bw*3],temp_q[psum_bw*3-1:psum_bw*2],temp_q[psum_bw*2-1:psum_bw*1],temp_q[psum_bw*1-1:psum_bw*0]
         );
         $display("answer  : %16b %16b %16b %16b %16b %16b %16b %16b", answer[psum_bw*8-1:psum_bw*7],answer[psum_bw*7-1:psum_bw*6],answer[psum_bw*6-1:psum_bw*5],answer[psum_bw*5-1:psum_bw*4],answer[psum_bw*4-1:psum_bw*3],answer[psum_bw*3-1:psum_bw*2],answer[psum_bw*2-1:psum_bw*1],answer[psum_bw*1-1:psum_bw*0]);
         error = 1;
       end
      //end
      #0.5 clk = 1'b1;  

    end
      if(error < 1) begin
        $display("%1d kij: psum featuremap Data matched! :D", kij);
      end
      else error =0;
    #0.5 clk = 1'b0;   ofifo_rd = 0;  WEN_pmem = 1; CEN_pmem = 1; A_pmem = 0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////
    $fclose(p_file);
    */
  end  // end of kij loop
//kernal values are all computed now we sum them up to get our output

  ////////// Accumulation /////////
  out_file = $fopen("out.txt", "r");  

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;



  $display("############ Verification Start /*during accumulation*/ #############"); 
//$display("SRAM eigth PSUM %32b",core_instance.pmem_sram.memory[11'b00000001000]);
  for (i=0; i<len_onij; i=i+1) begin 

    A_rd_pmem=(2+i/len_oni)*(len_ni+2)+(2+i%len_oni);
    #0.5 clk = 1'b0; CEN_pmem = 0; WEN_pmem = 1; REN_pmem = 0; en_relu = 1; acc = 0;
    #0.5 clk = 1'b1; #0.5 clk = 1'b0; // wait for pmem output
    #0.5 clk = 1'b1; #0.5 clk = 1'b0;
    #0.5 clk = 1'b1; #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;
     out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
       if (sfp_out == answer)
         $display("%2d-th output featuremap Data matched! :D", i); 
       else begin
         $display("%2d-th output featuremap Data ERROR!!", i); 
         $display("%2d-th addr: %2d", i, A_rd_pmem); 
         $display("sfpout  : %16b %16b %16b %16b %16b %16b %16b %16b", 
         sfp_out[psum_bw*8-1:psum_bw*7],sfp_out[psum_bw*7-1:psum_bw*6],sfp_out[psum_bw*6-1:psum_bw*5],sfp_out[psum_bw*5-1:psum_bw*4],sfp_out[psum_bw*4-1:psum_bw*3],sfp_out[psum_bw*3-1:psum_bw*2],sfp_out[psum_bw*2-1:psum_bw*1],sfp_out[psum_bw*1-1:psum_bw*0]
         );
         $display("answer  : %16b %16b %16b %16b %16b %16b %16b %16b", answer[psum_bw*8-1:psum_bw*7],answer[psum_bw*7-1:psum_bw*6],answer[psum_bw*6-1:psum_bw*5],answer[psum_bw*5-1:psum_bw*4],answer[psum_bw*4-1:psum_bw*3],answer[psum_bw*3-1:psum_bw*2],answer[psum_bw*2-1:psum_bw*1],answer[psum_bw*1-1:psum_bw*0]);

         error = 1;
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
   A_rd_pmem_q<= A_rd_pmem;
   A_wr_pmem_q<= A_wr_pmem;
   CEN_pmem_q <= CEN_pmem;
   REN_pmem_q <= REN_pmem;
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
   en_relu_q  <= en_relu;
end


endmodule




