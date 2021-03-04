`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// PARITY GENERATOR 
//////////////////////////////////////////////////////////////////////////////////
module par_gen(
    input [31:0] data,
    input [31:0] addr,
    output reg data_p,
    output reg addr_p
    );

always@(data,addr)
	begin
	data_p = ^data; 
	addr_p = ^addr;
	end

endmodule
