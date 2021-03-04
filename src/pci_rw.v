`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// PCI_READ_WRITE MODULE 
//////////////////////////////////////////////////////////////////////////////////
module pci_rw(RST,CLK,                   //Global inputs
				  AD,C_BE,                   //Top    inouts
				  FRAME,I_RDY,
				  par_d,par_addr,DEV_SEL_ram, last_ADd, T_RDY,DEV_SEL,data_ram,  STOP,
				  par,perr,we, be_out ,  addr_out,data_out
              );
			///////////////////////////////Inputs,outputs and inouts//////////////////////////

			/*************************************Outputts*****************************************/
			output  reg [3:0]  be_out ;                             //To RAM for byte enable                               --RAM_1
			output  reg        we , par;                              //Write enable signal to ram                           --RAM_2
			output  reg [31:0] addr_out , data_out;               //Data or address to be sent to the RAM/Parity gen     --RAM_3/Par
			output  reg        T_RDY , DEV_SEL , perr , STOP;           //To top module                                        --Top
			//output  reg  par;                                 

			/*************************************Inouts********************************************/
			inout [31:0] AD;                                 //Data or address from top                             --Top_1
			inout [3:0]  C_BE;                               //Command or Byte enable from top                      --Top_2

			/**************************************inputs******************************************/
			input        FRAME , I_RDY;                         //Signals related to tthe mmaster fromm top module     --Parity                  
			input        par_d , par_addr;                     //Calculated data & address parity                     --Top
			input        DEV_SEL_ram ,  last_ADd;               //Signals from RAM (Slave)                             --RAM_1
			input [31:0] data_ram ;                          //Data from RAM                                        --RAM_2                         
			input        CLK , RST;                            //Global signals for timming and reset                 --Global

			//////////////////////////////////////////////////////////////////////////////////

			///////////////////////////////Internal regs and wires////////////////////////////
			reg [31:0] address_next,address_base,data_next;        //Regs to save addresses and data required for operations
			reg [3:0]  C_BE_r, command;                          //Regs to save the command in ADddress phase or BE in data phase

			reg        AD_oe = 0;                                //To control tri-state AD as in or out
			reg        C_BE_oe = 0;                              //To control tri-state C_BE as in or out

			reg        reserved = 0;
			reg        flag = 0;
			reg        last_write_flag = 0;
			reg        last_reAD_flag  = 0;

			reg [2:0]  counter_reAD = 2'b00;                     //Starts with 2 words as reAD maxes at 2 words

			//////////////////////////////////////////////////////////////////////////////////

			//////////////////////////////Local params and states/command/////////////////////////////

			localparam [4:0]   idle = 5'b11000 ,
							address = 5'b11001 ,
							wr_data = 5'b11010 ,
							terminate = 5'b11011 ,
							turn_around = 5'b11100 ,   //States
							r_data = 5'b11101 ,
							last_write = 5'b11110 ,
							last_reAD = 5'b11111 , 
							interrupt_state = 5'b00000 ,
							STOP_state = 5'b00001 ;
									  
			localparam [3:0]  int_ack = 4'b0000 ,
							  mem_r = 4'b0110 ,
							  mem_w = 4'b0111 ,
							  mem_r_mult = 4'b1100 ,
							  mem_r_line = 4'b1110 ,
							  dual = 4'b1101, 
							  interrupt = 4'b 0000; //Commands
			//////////////////////////////////////////////////////////////////////////////////

			///////////////////////////////////Tri state assignments//////////////////
			assign   AD   = AD_oe   ? data_next   : 32'bz ;

			assign   C_BE = C_BE_oe ? C_BE_r     : 4'bz  ;
			//////////////////////////////////////////////////////////////////////////////////
			reg [4:0]         state      = idle;

			reg [4:0]         next_state = idle;

			//////////////////////////////negedge state/reg evaluation////////////////////////

			////////////////////////////////////////////////////////////////////////////////////////


					//////////////////////////////////////////CONTROL  FSM ////////////////////////////////////////
					always@(negedge CLK)
						begin
						if(!RST)
							begin
							next_state    <= idle;
							end
						else
							begin
							case(next_state)
								idle : 
									begin
									/*********************Next state(s) selection***********************/
									if(FRAME == 1'b0 )
										begin
										next_state <= address;         //Moves to address phase when FRAME asserted
										end
									else
										begin
										next_state <= idle;            //Stay idle if FRAME not asserted (No master yet)
										flag       <=~ flag;
										end
									end
								/*****************************ADDERSS STATE ******************************/
								
								address :
									begin
									/*********************Next state(s) selection***********************/
									if(FRAME == 1'b1 )
										begin
										next_state <= idle; 
										end
									else if (command == mem_w)
										begin
										next_state <= wr_data;           
										end
									else if (command == mem_r  || command == mem_r_line || command == mem_r_mult )
										begin
										next_state <= turn_around;
										end
									else if (command == interrupt )
										begin
										next_state <= interrupt_state;
										end
									else
										begin
										next_state <= idle;            //May be handled differently
										end
										
									end
								/*****************************INTERRUPT STATE ******************************/

									
								interrupt_state : ;
								
								wr_data :
									begin
										
									/*********************Next state(s) selection***********************/
									if (STOP== 1'b0)
										begin
										next_state <= STOP_state;           
										end
									if(FRAME == 1'b1)
										begin
										next_state <= last_write;         
										end
									else
										begin
										next_state <= wr_data; 
										flag <=~ flag ;
										end
										
									end
								/*****************************End of WRITE STATE ******************************/
									
								last_write : 
									begin	
									/*********************Next state(s) selection***********************/
									if(last_write_flag == 1'b1 || STOP==1'b0)
										begin
										next_state <= terminate;         
										end
									else
										begin
										next_state <= last_write; 
										flag       <=~ flag;
										end
										
									end
								/*****************************TURN AROUND STATE ******************************/
								
								
									
								turn_around :
									begin
									/*********************Next state(s) selection***********************/
									if(FRAME == 1'b1 )
										begin
										next_state <= idle;                         //Fram deasserted so operation terminated (Fault by master)
										end
									else if (I_RDY == 1'b1)
										begin
										next_state <=  turn_around ;                 //If not rdy wait until master is reADy  
										flag       <=~ flag        ;					
										end
									else if (DEV_SEL_ram == 1'b0  && I_RDY == 1'b0 )
										begin
										next_state <= r_data;                      //If rdy start the reAD data phases
										end
									else
										begin
										next_state <= idle;                       //Means that address wasn't found in the address space
										end
										
									end
								/****************************READ STATE ******************************/

									
								r_data :
									begin
										
									/*********************Next state(s) selection***********************/
									if (STOP== 1'b0)
										begin
										next_state <= STOP_state;           
										end
									if(FRAME == 1'b1)
										begin
										next_state <= last_reAD;         
										end
									else
										begin
										next_state <= r_data; 
										flag <=~ flag ;
										end
										
									end
								/*****************************LAST READ *****************************/
								
									
								last_reAD :  
									begin	
									/*********************Next state(s) selection***********************/
									if(last_reAD_flag == 1'b1 || STOP == 1'b0)
										begin
										next_state <= terminate;         
										end
									else
										begin
										next_state <= last_reAD; 
										flag       <=~ flag;
										end
										
									end
								/***************************STOP STATE ******************************/

								
								STOP_state  :
									begin
									/*********************Next state(s) selection***********************/
									if(FRAME == 1'b1 && command==mem_w )
										begin
										next_state <= last_write;                         //Fram deasserted so operation terminated (Fault by master)
										end
									else if (FRAME == 1'b1 && (command==mem_r || command==mem_r_line || command==mem_r_mult))
										begin
										next_state <= last_reAD;                 //If not rdy wait until master is reADy      
										end
									else
										begin
										next_state <= STOP_state;                      //If rdy start the reAD data phases
										flag <=~ flag;
										end
										
									end
								/*****************************TERMINATION STATE ******************************/	
								
								terminate :
									begin
									/*********************Next state(s) selection***********************/
								 next_state <= idle;
										
									end
								/*****************************End of LAST_WRITE******************************/
								endcase
							end
					end 
					/************************************************************************************************************************************/

							/***************************************COMBINATIONAL FSM *************************************************/


						always @(next_state,flag)
						begin
						case(next_state)
									idle : 
										begin
											/********************Outputs/Signals to change*********************/
											perr         <= 1'b1 ;          //Not yet of use
											DEV_SEL       <= 1'b1 ;          //No target yet attached so Pulled up
											T_RDY         <= 1'b1 ;          //Same as DEV_SEL
											
											reserved     <= 1'b0  ;
											
											AD_oe        <= 1'b0 ;          //Won't write on the inout port so it's set to O.C. (Input mode)
											C_BE_oe      <= 1'b0 ;          //Same as AD_oe
											
											addr_out     <= 32'bz;          //No address to send yet to ram
											data_out     <= 32'bz;          //Same as addr_out
											
											address_base <= 32'bz;          //Will be set in address phase
											address_next <= 32'bz;          //same as base addr.
											data_next    <= 32'bz;          //Same as 2 prev.
											command      <= 4'bz ;          //will be set in address phase
											
											STOP         <= 1'b1;
											
											last_write_flag <= 0;
											last_reAD_flag  <= 0;
											
											we           <= 1'b0 ;          //Not writting on RAM so defaulted to reAD
											be_out       <= 4'b0 ;          //Not writing so it is don't care value
											
											counter_reAD <= 2'b00;          //Reset to 2 max words for reAD cmd
										end
									/*****************************ADDERSS STATE ******************************/
									
									address :
										begin
																			/********************Outputs/Signals to change*********************/
											perr         <= 1'b1 ;          //Not yet of use
											DEV_SEL       <= 1'b1 ;          //Waitting RAM to verify the address on next +ve edge
											T_RDY         <= 1'b1 ;          //Will be asserted when the ADress is confirmed valid
											
											AD_oe        <= 1'b0 ;          //Won't write on the inout port so it's set to O.C. (Input mode)
											C_BE_oe      <= 1'b0 ;          //Same as AD_oe
											
											addr_out     <= AD;             //capture address from the AD port
											data_out     <= 32'bz;          //Not yet data phase so no change
											
											address_base <= AD;             //The base address to start the operations from
											address_next <= AD;             //Initial value in as base
											data_next    <= 32'bz;          //Same as data_out
											command      <= C_BE ;          //Capture the command for operation from C_BE port
											
											we           <= 1'b0 ;          //Not writting on RAM so defaulted to reAD	
										end
									/*****************************INTERRUPT STATE ******************************/

										
							//		interrupt_state : ;
									/**********************************WRITE DATA STATE****************************************/
									
									wr_data :
										begin
										/********************Outputs/Signals to change*********************/
											perr         <= 1'b1 ;          //Not yet of use
											if (DEV_SEL_ram == 1'b0)            //Confirms with RAM weither the sent address is within the address space or not
												begin
												DEV_SEL       <= 1'b0 ;          //address is within the address space of the slave
												T_RDY         <= 1'b0 ;          //Target is reADy
												end
											else
												begin
												DEV_SEL       <= 1'b1 ;          //address isn't in tthe address space
												T_RDY         <= 1'b1 ;          //No slave so target not reADy
												end
												
												AD_oe        <= 1'b0 ;          //Won't write on the inout port so it's set to O.C. (Input mode)
												C_BE_oe      <= 1'b0 ;          //Same as AD_oe

											if (I_RDY == 1'b0 && DEV_SEL_ram ==1'b0)
												begin
							
												be_out   <= C_BE ;         //To selectt which bytes to write to the RAM
												data_out <= AD;
												case (address_base[1:0])    //Those 2 bits deccide how data 
													00 :     begin           //Linear inc.
																 if ( last_ADd == 1'b0 ) 
																	begin
																   addr_out  <= address_next ;
																	address_next <= address_next +4;
																	we         <= 1'b1 ;          //Not writting on RAM so defaulted to reAD
																	end
																 else
																	begin
																   addr_out  <= addr_out ;
																	STOP      <=  1'b0    ;
																	we         <= 1'b0 ;          //Not writting on RAM so defaulted to reAD
																	end
																end
														  
												   10 :      begin        //Wrap
																 if ( last_ADd == 1'b0 ) 
																	begin
																   addr_out  <= address_next ;
																	address_next <= address_next +4;
																	we         <= 1'b1 ;          //Not writting on RAM so defaulted to reAD
																	end
																 else
																	begin
																   addr_out  <= addr_out ;
																	STOP      <=  1'b0    ;
																	we         <= 1'b0 ;          //Not writting on RAM so defaulted to reAD
																	end
															   end
												
													default : begin        //Reserved
																 we         <= 1'b0 ;          //Not writting on RAM so defaulted to reAD
																 STOP       <= 1'b0 ;
																 end
													endcase
												end
											else if (DEV_SEL_ram == 1'b1)
													begin
													we       <= 1'b0;
													be_out   <= 4'b0;
													//STOP     <= 1'b0;
													end
											else
													begin
													we           <=1'b0;
													addr_out  <= addr_out;
													be_out       <= be_out;
													end
											
										end
									/*****************************LAST WRITE DATA STATE ******************************/
										
									last_write : 
										begin
										/********************Outputs/Signals to change*********************/
											perr         <= 1'b1 ;          //Not yet of use
											if (DEV_SEL_ram == 1'b0)            //Confirms with RAM weither the sent address is within the address space or not
												begin
												DEV_SEL       <= 1'b0 ;          //address is within the address space of the slave
												T_RDY         <= 1'b0 ;          //Target is reADy
												end
											else
												begin
												DEV_SEL       <= 1'b1 ;          //address isn't in tthe address space
												T_RDY         <= 1'b1 ;          //No slave so target not reADy
												end
											
											AD_oe        <= 1'b0 ;          //Won't write on the inout port so it's set to O.C. (Input mode)
											C_BE_oe      <= 1'b0 ;          //Same as AD_oe
											
											
											if(I_RDY == 1'b0 && DEV_SEL_ram ==1'b0)
												begin
												be_out <=C_BE;
												data_out <=AD;
												we<= 1'b1 ;
												addr_out <=address_next;
												last_write_flag <= 1'b1;
												end
											else
												begin
												we <=1'b0;
												end
												

										end
									/****************************TURN AROUND STATE ******************************/
									
									
										
									turn_around :
										begin
														/********************Outputs/Signals to change*********************/
											perr         <= 1'b1 ;          //Should be calculated                                         --To be changed

											
											AD_oe        <= 1'b0 ;          //O.C. preparing for ooutput mode in the reAD sttatte
											C_BE_oe      <= 1'b0 ;          //O.C.
											
											addr_out     <= address_base;   //Just to assure we got the correct base address for op.
											data_out     <= 32'bz;          //Not yet data phase so no change
											
											address_next <= address_base;   //To make sure it hasn't changed
											data_next    <= 32'bz;          //Same as data_out
											
											we           <= 1'b0 ;          //Not writting on RAM so defaulted to reAD	
											
											if (DEV_SEL_ram == 1'b0)            //Confirms with RAM weither the sent address is within the address space or not
												begin
												DEV_SEL       <= 1'b0 ;          //address is within the address space of the slave
												T_RDY         <= 1'b0 ;          //Target is reADy
												end
											else
												begin
												DEV_SEL       <= 1'b1 ;          //address isn't in tthe address space
												T_RDY         <= 1'b1 ;          //No slave so target not reADy
												STOP         <= 1'b0 ;
												end
											
											case (command)
												mem_r       : counter_reAD <= 2'b01;    //2 wordsmax
												mem_r_line  : counter_reAD <= 2'b11;    //4 words
												default     : counter_reAD <= 2'b00;    //ReAD mult depends on FRAME
												endcase
										end
										
									/***************************READ DATA STATE ******************************/

										
									r_data :
										begin
										/********************Outputs/Signals to change*********************/
											perr         <= 1'b1 ;          //Not yet of use
											if (DEV_SEL_ram == 1'b0)            //Confirms with RAM weither the sent address is within the address space or not
												begin
												DEV_SEL       <= 1'b0 ;          //address is within the address space of the slave
												T_RDY         <= 1'b0 ;          //Target is reADy
												end
											else
												begin
												DEV_SEL       <= 1'b1 ;          //address isn't in tthe address space
												T_RDY         <= 1'b1 ;          //No slave so target not reADy
												end
											
											AD_oe        <= 1'b1 ;          //Outt mode
											C_BE_oe      <= 1'b0 ;          //Same as AD_oe
											data_next <= data_ram;
											
											we <= 1'b0;

											if (I_RDY == 1'b0 && DEV_SEL_ram ==1'b0)
												begin
												case (command)
													mem_r: begin
														case (address_base[1:0])    //Those 2 bits deccide how data 
															2'b00 :     begin           //Linear inc.
																		 if ( last_ADd == 1'b0 ) 
																			begin
																			addr_out     <= (counter_reAD == 2'b00 ) ? addr_out     : addr_out + 4 ;
																			counter_reAD <= (counter_reAD == 2'b00 ) ? counter_reAD : counter_reAD-1;
																			end
																		 else
																			begin
																			addr_out  <= addr_out ;
																			STOP      <= (counter_reAD == 2'b00 )    ? 1'b1         : 1'b0         ;
																			end
																		end
																  
															2'b10 :      begin        //Wrap
																		 if ( last_ADd == 1'b0 ) 
																			begin
																			addr_out     <= (counter_reAD == 2'b00 ) ? address_base : addr_out + 4 ;
																			counter_reAD <= (counter_reAD == 2'b00 ) ? 2'b01        : counter_reAD - 1;
																			end
																		 else
																			begin
																			addr_out     <= (counter_reAD == 2'b00 ) ? address_base     : addr_out    ;
																			STOP         <= (counter_reAD == 2'b00 )    ? 1'b1         : 1'b0         ;
																			end
																		 end
														
															default : begin        //Reserved
																		 addr_out   <= addr_out ;
																		 STOP       <= 1'b0     ;
																		 end
															
															endcase
															end
													/*************************MEM READ LINE *****************************/

													mem_r_line : begin
														case (address_base[1:0])    //Those 2 bits deccide how data 
															2'b00 :     begin           //Linear inc.
																		 if ( last_ADd == 1'b0 ) 
																			begin
																			addr_out     <= (counter_reAD == 2'b00 ) ? addr_out     : addr_out + 4 ;
																			counter_reAD <= (counter_reAD == 2'b00 ) ? counter_reAD : counter_reAD-1  ;
																			end
																		 else
																			begin
																			addr_out  <= addr_out ;
																			STOP      <= (counter_reAD == 2'b00 )    ? 1'b1         : 1'b0         ;
																			end
																		end
																  
															2'b10 :      begin        //Wrap
																		 if ( last_ADd == 1'b0 ) 
																			begin
																			addr_out     <= (counter_reAD == 2'b00 ) ? address_base : addr_out  + 4   ;
																			counter_reAD <= (counter_reAD == 2'b00 ) ? 2'b11        : counter_reAD - 1;
																			end
																		 else
																			begin
																			addr_out     <= (counter_reAD == 2'b00 ) ? address_base     : addr_out+4    ;
																			STOP         <= (counter_reAD == 2'b00 )    ? 1'b1         : 1'b0         ;
																			end
																		 end
														
															default : begin        //Reserved
																		 addr_out   <= addr_out ;
																		 STOP       <= 1'b0     ;
																		 end
															
															endcase
															end
															
															
													default: begin
														case (address_base[1:0])    //Those 2 bits deccide how data 
															2'b00 :     begin           //Linear inc.
																			addr_out     <= (last_ADd == 1'b0 ) ? addr_out + 4    : addr_out ;
																			STOP         <= (last_ADd == 1'b0 ) ? 1'b1            : 1'b0        ;
																			end
																  
															2'b10 :      begin        //Wrap
																			addr_out     <= (last_ADd == 1'b0 ) ? addr_out + 4    : addr_out ;
																			STOP         <= (last_ADd == 1'b0 ) ? 1'b1            : 1'b0        ;
																			end
														
															default : begin        //Reserved
																		 addr_out   <= addr_out ;
																		 STOP       <= 1'b0     ;
																		 end
															
															endcase
															end
												endcase
								
												end
											else
													begin
													addr_out  <= addr_out;
													end
											
										end
									/*****************************LAST READ STATE *****************************/
									
										
									last_reAD :
										begin
										/********************Outputs/Signals to change*********************/
											perr         <= 1'b1 ;          //Not yet of use
											if (DEV_SEL_ram == 1'b0)            //Confirms with RAM weither the sent address is within the address space or not
												begin
												DEV_SEL       <= 1'b0 ;          //address is within the address space of the slave
												T_RDY         <= 1'b0 ;          //Target is reADy
												end
											else
												begin
												DEV_SEL       <= 1'b1 ;          //address isn't in tthe address space
												T_RDY         <= 1'b1 ;          //No slave so target not reADy
												end
											
												AD_oe        <= 1'b1 ;          //Won't write on the inout port so it's set to O.C. (Input mode)
												C_BE_oe      <= 1'b0 ;          //Same as AD_oe
												
												we <=1'b0;
												
											if(I_RDY == 1'b0 && DEV_SEL_ram ==1'b0)
											
												begin
												addr_out <= addr_out + 4;
												last_reAD_flag <= 1'b1  ;
												end
											else
												begin
												last_reAD_flag <= 1'b0;
												we <=1'b0;
												end
												

										end
									/**************************STOP STATE ******************************/

										
									STOP_state  :
										begin
														/********************Outputs/Signals to change*********************/
											perr         <= 1'b1 ;          //No transaction                                         --To be changed

											case (command)
												mem_w : begin
															AD_oe        <= 1'b0 ;          //O.C. preparing for ooutput mode in the reAD sttatte
															C_BE_oe      <= 1'b0 ;          //O.C.
															data_out     <= data_out;          //Not yet data phase so no change
															addr_out     <= address_next;   //Just to assure we got the correct base address for op.
															end
											   
												mem_r : begin
															AD_oe        <= 1'b1 ;          //O.C. preparing for ooutput mode in the reAD sttatte
															C_BE_oe      <= 1'b0 ;          //O.C.
															addr_out     <= address_next;   //Just to assure we got the correct base address for op.
															data_next    <= data_ram;          //Same as data_out
														   end
												 
											   mem_r_line : begin
															AD_oe        <= 1'b1 ;          //O.C. preparing for ooutput mode in the reAD sttatte
															C_BE_oe      <= 1'b0 ;          //O.C.
														   addr_out     <= address_next;   //Just to assure we got the correct base address for op.
														   data_next    <= data_ram;          //Same as data_out
														   end
												
												mem_r_mult : begin
															AD_oe        <= 1'b1 ;          //O.C. preparing for ooutput mode in the reAD sttatte
															C_BE_oe      <= 1'b0 ;          //O.C.
															addr_out     <= address_next;   //Just to assure we got the correct base address for op.
															data_next    <= data_ram;          //Same as data_out
														   end
												default :begin
															AD_oe        <= 1'b0 ;          //O.C. preparing for ooutput mode in the reAD sttatte
															C_BE_oe      <= 1'b0 ;          //O.C.
														   end
												endcase
											
											we           <= 1'b0 ;          //Not writting on RAM so defaulted to reAD	
											
											if (DEV_SEL_ram == 1'b0)            //Confirms with RAM weither the sent address is within the address space or not
												begin
												DEV_SEL       <= 1'b0 ;          //address is within the address space of the slave
												T_RDY         <= 1'b0 ;          //Target is reADy
												end
											else
												begin
												DEV_SEL       <= 1'b1 ;          //address isn't in tthe address space
												T_RDY         <= 1'b1 ;          //No slave so target not reADy
												STOP         <= 1'b0 ;
												end
										end
									/*****************************TERMINATION STATE ******************************/	
									
									terminate :
										begin
										/********************Outputs/Signals to change*********************/
											perr         <= 1'b1 ;          //Not yet of use
											DEV_SEL       <= 1'b1;
											T_RDY         <= 1'b1;
											STOP         <= 1'b1;
											AD_oe        <=1'b0;
											C_BE_oe      <=1'b0;
											
											address_base <= 32'bz;
											address_next <= 32'bz;
											addr_out <= 32'bz;
											
											data_out   <=32'bz;
											data_next   <=32'bz;
											
											command   <=4'bz;
											
											we        <=1'b0;
											be_out    <=4'b0;

										end
									/***********************************************************/
									endcase
						end
			
////////////////////////////////////////////////////////////////////////////////////////
endmodule
