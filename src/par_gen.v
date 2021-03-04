`timescale 1ns / 1ps
//////////////////////////////////////
//// PARITY GENERATOR 
//////////////////////////////////////
module par_gen(
    output reg data_p,
    output reg addr_p,
	input [31:0] data,
    input [31:0] addr

    );

always@(data,addr)
	begin
	data_p = ^data; 
	addr_p = ^addr;
	end

endmodule
