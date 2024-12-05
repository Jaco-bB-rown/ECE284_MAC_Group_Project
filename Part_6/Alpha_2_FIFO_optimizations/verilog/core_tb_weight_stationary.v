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
reg mode = 0;
reg mode_q = 0;
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
reg [8*30:1] p_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer p_file, p_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij, temp_t;
integer error;
reg [psum_bw*col-1:0]temp;
reg [psum_bw*col-1:0]temp_q;

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
  mode     = 0;
  output_en= 0;

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
  $display("############ Verification Start during Partial Sum Calculation #############");
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
    #0.5 clk = 1'b0;   l0_rd = 1;
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0; WEN_pmem = 0; CEN_pmem = 0; A_pmem = 11'b00000000000 + len_nij*kij;
    #0.5 clk = 1'b1;

    for (t=0; t<len_nij+row*2+1; t=t+1) begin  
      #0.5 clk = 1'b0;    load = 0; execute=1; 
      if(t>len_nij-col+1)begin l0_rd = 0; end 
      else begin l0_rd = 1; end
      //$display("%2d : MAC in: %32b",t,core_instance.corelet_inst.mac_array_inst.in_w);
      //$display("%2d : MAC out: %128b",t,core_instance.corelet_inst.mac_array_inst.out_s);
      temp = core_instance.corelet_out;
      //OFIFO read during execution
      if(ofifo_valid) begin
        if(temp_t+1 <= t) begin//wait one cycle before reading so we can save to the right address
          ofifo_rd = 1; WEN_pmem = 0; CEN_pmem = 0;  A_pmem = A_pmem + 1;
          p_scan_file = $fscanf(p_file,"%128b", answer); // reading from out file to answer
          if (temp_q === answer) begin
            //$display("%d kij: %d-th psum featuremap Data matched! :D", kij, t); 
          end
          else begin
            $display("%1d kij: %1d-th psum featuremap Data ERROR!!",kij, t); 
            $display("OFIO out: %16b %16b %16b %16b %16b %16b %16b %16b", 
            temp_q[psum_bw*8-1:psum_bw*7],temp_q[psum_bw*7-1:psum_bw*6],temp_q[psum_bw*6-1:psum_bw*5],temp_q[psum_bw*5-1:psum_bw*4],temp_q[psum_bw*4-1:psum_bw*3],temp_q[psum_bw*3-1:psum_bw*2],temp_q[psum_bw*2-1:psum_bw*1],temp_q[psum_bw*1-1:psum_bw*0]
            );
            $display("answer  : %16b %16b %16b %16b %16b %16b %16b %16b", answer[psum_bw*8-1:psum_bw*7],answer[psum_bw*7-1:psum_bw*6],answer[psum_bw*6-1:psum_bw*5],answer[psum_bw*5-1:psum_bw*4],answer[psum_bw*4-1:psum_bw*3],answer[psum_bw*3-1:psum_bw*2],answer[psum_bw*2-1:psum_bw*1],answer[psum_bw*1-1:psum_bw*0]);
            error = 1;
          end
        end
        else begin
          temp_t = t; WEN_pmem = 0; CEN_pmem = 0;  A_pmem = A_pmem + 1;
        end
      end
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   l0_rd = 0; load = 0; execute=0; 
    #0.5 clk = 1'b1; 
    /////////////////////////////////////
      if(error < 1) begin
        $display("%1d kij: psum featuremap Data matched! :D", kij);
      end
      else error =0;
    #0.5 clk = 1'b0;   ofifo_rd = 0;  WEN_pmem = 1; CEN_pmem = 1; A_pmem = 0;
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
//$display("SRAM eigth PSUM %32b",core_instance.pmem_sram.memory[11'b00000001000]);
  for (i=0; i<len_onij; i=i+1) begin 

    A_pmem=len_nij*0 + (i/len_oni)*len_ni + i%len_oni + (0/len_ki)*len_ni + 0%len_ki;

    for(k=0; k < len_kij+3; k=k+1)begin//kernal loop
          #0.5 clk = 1'b0;  CEN_pmem = 0; WEN_pmem = 1;
          if(k>1 && k<len_kij+2) begin 
            A_pmem=len_nij*(k-1) + (i/len_oni)*len_ni + i%len_oni + ((k-1)/len_ki)*len_ni + (k-1)%len_ki;
            acc= 1;
            //$display("%2d-th,k=%1d Mem Address %11b", i,k-2, core_instance.pmem_addr);
          end
          //if(k>2)begin $display("%2d-th,k=%1d SFP In %128b", i,k-3, core_instance.sfp_in);end
          #0.5 clk = 1'b1;
    end
    #0.5 clk = 1'b0; CEN_pmem = 1; WEN_pmem = 1;
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0; CEN_pmem = 1; WEN_pmem = 1; acc=0;
    #0.5 clk = 1'b1;
     out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
       if (sfp_out === answer)
         $display("%2d-th output featuremap Data matched! :D", i); 
       else begin
         $display("%2d-th output featuremap Data ERROR!!", i); 
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




