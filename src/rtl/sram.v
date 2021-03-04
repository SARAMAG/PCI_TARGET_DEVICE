`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
////32-BIT MEMORY 
//
//////////////////////////////////////////////////////////////////////////////////
module MEM_32(
    input [31:0] DATA_in ,
    input [31:0] ADD-in ,
	 input [29:0] Strat_ADD,End_ADD,
    input [3:0] BE,
    input we,clk,req_64,
	 
    output reg [31:0] data_out,
    output reg devsel_32,
    output reg last_add
    );
	 
/////////////////////////////////regs and wires///////////////////////////////////
reg [31:0] mem [0:1024];
reg [29:0] add;
reg [31:0] data_d;
//////////////////////////////////////////////////////////////////////////////////

always @(posedge clk)
	BEgin
	add = ADD-in [31:2];
	if(add >= Strat_ADD && End_ADD>add ) //Checking if this device is the correct one
		BEgin
		devsel_32   = 1'b0;
		last_add = 1'b0;
		end
	else if (add == End_ADD)
		BEgin
		devsel_32   = 1'b0;
		last_add = 1'b1;
		end
	else
		BEgin
		devsel_32   = 1'b1;
		last_add = 1'b0;
		end
	
	if(devsel_32 == 1'b0 && we == 1'b1)    //Write command
		BEgin
		//////////////////////Keeps same value if BE=0////////////
		/*
		if(BE[0] == 1'b1) mem[add][7:0] = DATA_in [7:0];
		else              mem[add][7:0] = mem[add][7:0];
		
		if(BE[1] == 1'b1) mem[add][15:8] = DATA_in [15:8];
		else              mem[add][15:8] = mem[add][15:8];

		if(BE[2] == 1'b1) mem[add][23:16] = DATA_in [23:16];
		else              mem[add][23:16] = mem[add][23:16];

		if(BE[3] == 1'b1) mem[add][31:24] = DATA_in [31:24];
		else              mem[add][31:24] = mem[add][31:24];
		data_d   = mem[add];
		*/
		///////////////////////////////////////////////////////////
		
		/////////////////////changes data to 0 if BE=0/////////////
		
		mem[add] = DATA_in  & {{8{BE[3]}},{8{BE[2]}},{8{BE[1]}},{8{BE[0]}}};
		data_d   = DATA_in  & {{8{BE[3]}},{8{BE[2]}},{8{BE[1]}},{8{BE[0]}}};
		
		///////////////////////////////////////////////////////////
		end	
	else if(devsel_32 == 1'b0 && we == 1'b0) data_out = mem[add];
	else                                  data_out = 30'bz;
	
			
		
	
	end
endmodule
