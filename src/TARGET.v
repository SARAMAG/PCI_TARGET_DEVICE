`timescale 1ns / 1ps
/////////////////////////////////////////////////////
//// PCI TARGET DEVICE 
////////////////////////////////////////////////////
module TARGET(clk,RST,
			  AD,C_BE,
			  FRAME,
			  I_RDY,
			  T_RDY,
			  STARGET,
			  perr,
			  DEV_SEL,
			  par
    );
	 
	 output T_RDY,STARGET,perr,par,DEV_SEL;
	 input clk,RST;
	 input FRAME,I_RDY;
	 inout [31:0] AD;
	 inout [3:0]  C_BE;
	 
	/***********************************************************************************/ 
	 wire [31:0] data_wr_ram,data_ram_wr,ADdr_wr_ram;
	 wire        last_word,par_data,par_ADd,ram_DEV_SEL,we_wr_ram;
	 wire [3:0]  be_wr_ram;
	 
	 pci_rw   rw(.RST(RST),
				 .clk(clk),                   
				  .AD(AD),
				  .C_BE(C_BE),                 
				  .FRAME(FRAME),
				  .I_RDY(I_RDY),
				  .par_d(par_data),
				  .par_ADdr(par_ADd),
				  .DEV_SEL_ram(ram_DEV_SEL), 
				  .last_ADd(last_word), 
				  .T_RDY(T_RDY),
				  .DEV_SEL(DEV_SEL),
				  .data_ram(data_ram_wr), 
				  .STARGET(STARGET),
				  .par(par),
				  .perr(perr),
				  .we(we_wr_ram),
				  .be_out(be_wr_ram) ,
				  .ADdr_out(ADdr_wr_ram),
				  .data_out(data_wr_ram));
				  
	sram     ram1(    .data_in(data_wr_ram),
					  .ADd_in(ADdr_wr_ram),
					 .ADd_start(30'h00000000),
					 .ADd_end(30'h000000ff),
					 .be(be_wr_ram),
					 .we(we_wr_ram),
					 .clk(clk),
					 .data_out(data_ram_wr),
					 .DEV_SEL(ram_DEV_SEL),
					 .last_ADd(last_word));
	 

	 
	 par_gen p_gen(
					.data(data_wr_ram),
					.ADdr(ADdr_wr_ram),
					.data_p(par_data),
					.ADdr_p(par_ADd)
    );


endmodule
