`timescale 1ns / 1ps

////////////////////////////
//// A TARGET TESTBENCH WORKS AS MASTER  
///////////////////////////

module MASTER_tb;
	
	// Outputs
	wire T_RDY;
	wire STOP;
	wire perr;
	wire DEV_SEL;
	wire par;
	
	// Inputs
	reg CLK;
	reg RST;
	reg FRAME;
	reg I_RDY;


	// Bidirs
	wire [31:0] AD;
	wire [3:0] C_BE;

	// Instantiate the Unit Under Test (UUT)
	Top uut (
		.CLK(CLK), 
		.RST(RST), 
		.AD(AD), 
		.C_BE(C_BE), 
		.FRAME(FRAME), 
		.I_RDY(I_RDY), 
		.T_RDY(T_RDY), 
		.STOP(STOP), 
		.perr(perr), 
		.DEV_SEL(DEV_SEL), 
		.par(par)
	);
	
	//Internal Regs//
   reg [31:0] AD_reg;
	reg AD_oe,C_BE_oe;
	reg [3:0]  C_BE_reg;
	
	//Clocking block//
	initial CLK = 0;
	always 
		begin
		#10 CLK =~ CLK;
		end
	/***************/
	
	//Assign stimuli for tri-state	
	assign AD   = AD_oe ? AD_reg : 32'bz; 
   assign C_BE = C_BE_oe ? C_BE_reg : 4'bz;	
	/**************************************/
	
	initial begin
	
	
		//INITIAL TRI-STATE MODE
		C_BE_oe = 1;
		AD_oe =1;
		
		//IDLE
		#10
		FRAME = 1;
		RST = 0;
		I_RDY = 1;
		AD_reg = 32'bz;
		C_BE_reg =4'bz;
		
		//IDLE
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'bz;
		C_BE_reg =4'bz;
		#1
		
		#10
		
		//ADDRESS
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'b0;
		C_BE_reg =4'b0111;
		#1
		
		#10
	/************************************WRITE OPERATION ******************************/	
		//WRITE_1
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'h1A2B3C4D;
		C_BE_reg =4'b1001;
		#1

		#10
		
		//WRITE_2
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'hEEEEEEEE;
		C_BE_reg =4'b1111;
		#1
		
		#10
		
		//WRITE_3
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'hAAAABBBB;
		C_BE_reg =4'b0011;
		#1
		
		#10
		
		//WRITE_4_wait
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'hFFFFFFFF;
		C_BE_reg =4'b0001;
		#1
		
		#10
		//WRITE_4
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'hFFFFFFFF;
		C_BE_reg =4'b0001;
		#1
		
		#10
		
		//WRITE_5
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'hABCDEF01;
		C_BE_reg =4'b1110;
		#1
		
		#10
		//WRITE_6
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'hEE33FF55;
		C_BE_reg =4'b0000;
		#1
		
		#10
		//WRITE_7
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'hD123456E;
		C_BE_reg =4'b1111;
		#1
		
		#10
		
		//WRITE_8
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'h98765432;
		C_BE_reg =4'b1010;
		#1
		
		#10

		//WRITE_9
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'h13061997;
		C_BE_reg =4'b1111;
		#1
		
		#10
		
		//LAST_WRITE_1
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'hFFFFFFFF;
		C_BE_reg =4'b0001;
		#1
		
		#10
		//TERMINATE
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'hFFFFFFFF;
		C_BE_reg =4'b0001;
		#1
		/***********************************************************/
		#10
		//IDLE
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'hzzzzzzzz;
		C_BE_reg =4'bz;
		#1
		
		#10
		/********READ TEST**********/
		//IDLE
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'bz;
		C_BE_reg =4'bz;
		#1
		
		#10
		//ADDRESS
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'h00000006;
		C_BE_reg =4'b1110;
		#1
		/*************************READ OPERATION**************************/
		#10
		//TURN AROUND
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'bz;
		C_BE_reg =4'b1110;
		#1
		
		#10
		//DATA cycle 1
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		AD_oe = 1'b0;
		#1
		
		#10
		//DATA cycle 2
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 3
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 4
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 1;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 5
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 6
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 7
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 8
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 9
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 0;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 9
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'bz;
		C_BE_reg =4'bzzzz;
		AD_oe = 1'b1;
		#1
		
		#10
		/*************************************************************************************************/
		/****READ Scenario_2 (Normal _ READ) ****/
		//IDLE
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'bz;
		C_BE_reg =4'bz;
		#1
		
		#10
		//ADDRESS
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'h0000000c;   //ADdress 3 witth mode 10--wrap
		C_BE_reg =4'b0110;       
		#1
		
		#10
		//TURN AROUND
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'bz;
		C_BE_reg =4'b1110;
		#1
		
		#10
		//DATA cycle 1
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		AD_oe = 1'b0;
		#1
		
		#10
		//DATA cycle 2
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 3
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 8
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 9
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 0;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 9
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'bz;
		C_BE_reg =4'bzzzz;
		AD_oe = 1'b1;
		#1
		
		#10
		/************************************************************************************************/
		
		/****Error scenario_1 (Terminate with data) ****/
		//IDLE
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'bz;
		C_BE_reg =4'bz;
		#1
		
		#10
		//ADDRESS
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'h000003fc;   //ADdress 3 witth mode 10--wrap
		C_BE_reg =4'b0110;       
		#1
		
		#10
		//TURN AROUND
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'bz;
		C_BE_reg =4'b1110;
		#1
		
		#10
		//DATA cycle 1
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		AD_oe = 1'b0;
		#1
		
		#10
		//DATA cycle 2
		#9
		FRAME = 0;
		RST = 1;
		I_RDY = 0;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		/*************************/
		//DATA cycle 8
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 9
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		//AD_reg = 32'bz;
		C_BE_reg =4'b0110;
		#1
		
		#10
		//DATA cycle 9
		#9
		FRAME = 1;
		RST = 1;
		I_RDY = 1;
		AD_reg = 32'bz;
		C_BE_reg =4'bzzzz;
		AD_oe = 1'b1;
		#1
		
		#10
		// Wait 100 ns for global reset to finish
		#100;
        
		// ADd stimulus here

	end
      
endmodule

