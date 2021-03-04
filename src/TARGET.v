`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:05:18 02/24/2021 
// Design Name: 
// Module Name:    Top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Top(clk,rst,
			  ad,c_be,
			  frame,irdy,trdy,stop,perr,devsel,par
    );
	 
	 input clk,rst;
	 input frame,irdy;
	 output trdy,stop,perr,par,devsel;
	 inout [31:0] ad;
	 inout [3:0]  c_be;
	 
	 
	 wire [31:0] data_wr_ram,data_ram_wr,addr_wr_ram;
	 wire        last_word,par_data,par_add,ram_devsel,we_wr_ram;
	 wire [3:0]  be_wr_ram;
	 
	 pci_rw   rw(.rst(rst),.clk(clk),                   
				  .ad(ad),.c_be(c_be),                 
				  .frame(frame),.irdy(irdy),
				  .par_d(par_data),.par_addr(par_add),.devsel_ram(ram_devsel), .last_add(last_word), .trdy(trdy),.devsel(devsel),.data_ram(data_ram_wr),  .stop(stop),
				  .par(par),.perr(perr),.we(we_wr_ram), .be_out(be_wr_ram) ,  .addr_out(addr_wr_ram),.data_out(data_wr_ram));
				  
	sram     ram1(    .data_in(data_wr_ram),
    .add_in(addr_wr_ram),
	 .add_start(30'h00000000),.add_end(30'h000000ff),
    .be(be_wr_ram),
    .we(we_wr_ram),.clk(clk),
	 
    .data_out(data_ram_wr),
    .devsel(ram_devsel),
    .last_add(last_word));
	 

	 
	 par_gen p_gen(
    .data(data_wr_ram),
    .addr(addr_wr_ram),
    .data_p(par_data),
    .addr_p(par_add)
    );


endmodule
