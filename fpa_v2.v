`timescale 1ns / 1ps
//SPECIAL VALUES
//subnormal numbers for result, not during the addition algorithm
//0<biased exponent<255
`define bias 127
//max biased exponent 254
`define max_be 8'b11111110
//min biased exponent 1
`define min_be 8'b00000001
//positive zero
`define pos_z 32'h00000000
//negative zero
`define neg_z 32'b10000000000000000000000000000000
//plus infinity
`define pos_i 32'b01111111100000000000000000000000
//minus infinity
`define neg_i 32'b11111111100000000000000000000000
//quiet NaN
// bias all 1's, mantissa first bit = 1 and mantissa != 0
//signaling NaN
// bias all 1's, mantissa first bit = 0 and mantissa != 0 


//NOTE TO SELF: Find a way to reduce number of if statements used in the code.
//make the distinction between smaller and bigger exponent at the start of the code.
//make the state transitions smoother and more efficient.
//maybe come up with temporary variables to store the values of the registers.
//ANOTHER DESIGN CHOICE: make the seperate state machines submodules 
//and connect them to the main module, and implement unit tests for them.
//possible submodules: exponent shift, addition, normalization, and rounding.
module fpa(
clk,
rst,
X,
Y,
result,
out_valid
);

//IO
input clk, rst;
input [31:0] X, Y;
output [31:0] result;
output out_valid;

//INTERNAL FIELD REGISTERS
reg sign_x, sign_x_next;
reg [7:0] exp_x, exp_x_next;
reg [23:0] mantissa_x, mantissa_x_next;
reg sign_y, sign_y_next;
reg [7:0] exp_y, exp_y_next;
reg [23:0] mantissa_y, mantissa_y_next;
reg result_sign, result_sign_next;
reg [23:0] result_mantissa, result_mantissa_next;
reg result_mantissa_overflow, result_mantissa_overflow_next;

//INTERNAL STATE REGISTERS
reg  exponent_shift_state, exponent_shift_state_next;
reg eSS_busy, eSS_busy_next;
reg addition_state, addition_state_next;
reg aS_busy, aS_busy_next;


//SEQUANTIAL PART
always @(posedge clk) begin
	//field registers
	//X
	sign_x <= sign_x_next;
	exp_x <= exp_x_next;
	mantissa_x <= mantissa_x_next;
	//Y
	sign_y <= sign_y_next;
	exp_y <= exp_y_next;
	mantissa_y <= mantissa_y_next;
	//result
	result_sign <= result_sign_next;
	result_mantissa <= result_mantissa_next;
	result_mantissa_overflow <= result_mantissa_overflow_next;
	//state registers
	eSS_busy <= eSS_busy_next;
	aS_busy <= aS_busy_next;
	addition_state <= addition_state_next;
	exponent_shift_state <= exponent_shift_state_next;
end

//COMBINATIONAL PART
always @* begin
	if(rst)begin
		//RESET VALUES
		//X
		sign_x_next = X[31];
		exp_x_next = X[30:23]
		mantissa_x_next = X[22:0];
		//Y
		sign_y_next = Y[31];
		exp_y_next = Y[30:23];
		mantissa_y_next = Y[22:0];
        //result
		result_sign_next = 0;
		result_mantissa_next = 0;
		result_mantissa_overflow_next = 0;
		//state registers
		eSS_busy_next = 1;
		aS_busy_next = 0;
		addition_state_next = 0;
		exponent_shift_state_next = 0;
		//output
		out_valid = 0;
		result = 0;
	end
	else begin
		//DEFAULT VALUES
		//X
		sign_x_next = X[31];
		exp_x_next = X[30:23]
		mantissa_x_next = X[22:0];
		//Y
		sign_y_next = Y[31];
		exp_y_next = Y[30:23];
		mantissa_y_next = Y[22:0];
		//result
		result_sign_next = result_sign;
		result_mantissa_next = result_mantissa;
		result_mantissa_overflow_next = result_mantissa_overflow;
		//state registers
        exponent_shift_state_next = exponent_shift_state;
		eSS_busy_next = eSS_busy;
		aS_busy_next = aS_busy;
		addition_state_next = addition_state;
		
		//NaN Out
		//quiet NaN
		if((exp_x_next == 255 && mantissa_x_next[22] == 1) || (exp_y_next == 255 && mantissa_y_next[22] == 1)) begin
			result = 32'bx111111111xxxxxxxxxxxxxxxxxxxxxx;
			out_valid = 1;
		end
		//signaling NaN
		else if(exp_x_next == 255 && mantissa_x_next[22] == 0 && mantissa_x_next != 0) || (exp_y_next == 255 && mantissa_y_next[22] == 0 && mantissa_y_next != 0) begin
			result = 32'bx111111110xxxxxxxxxxxxxxxxxxxxxx;
			outvalid = 1;
		end
		//X or Y == 0 Out
		else if(X == 0) begin
			result = Y;
			outvalid = 1;
		end
		else if(Y == 0) begin
			result = X;
			outvalid = 1;
		end
		else begin
			//EXPONENT SHIFT ALGORITHM
            case (exponent_shift_state)
                0: begin
					if(exp_x_next = exp_y_next) begin
						eSS_busy_next = 0;
						exponent_shift_state_next = 0;
					end
					else if(exp_x_next > exp_y_next) begin
						exp_y_next = exp_y + 1;
						mantissa_y_next = mantissa_y >> 1;
						eSS_busy_next = 1;
						if (mantissa_y_next == 0) begin
							result = X;
							out_valid = 1;
							eSS_busy_next = 0;
							exponent_shift_state_next = 0;
						end
						exponent_shift_state_next = 1;
					end
					else begin
						exp_x_next = exp_x + 1;
						mantissa_x_next = mantissa_x >> 1;
						eSS_busy_next = 1;
						if (mantissa_x_next == 0) begin
							result = Y;
							out_valid = 1;
							eSS_busy_next = 0;
							exponent_shift_state_next = 0;
						end
						exponent_shift_state_next = 1;
					end
                end
                1: begin
					if(exp_x = exp_y) begin
						eSS_busy_next = 0;
						exponent_shift_state_next = 0;
					end
					else if(exp_x > exp_y) begin
						exp_y_next = exp_y + 1;
						mantissa_y_next = mantissa_y >> 1;
						eSS_busy_next = 1;
						if (mantissa_y_next == 0) begin
							result = X;
							out_valid = 1;
							eSS_busy_next = 0;
							exponent_shift_state_next = 0;
						end
						exponent_shift_state_next = 1;
					end
					else begin
						exp_x_next = exp_x + 1;
						mantissa_x_next = mantissa_x >> 1;
						eSS_busy_next = 1;
						if (mantissa_x_next == 0) begin
							result = Y;
							out_valid = 1;
							eSS_busy_next = 0;
							exponent_shift_state_next = 0;
						end
						exponent_shift_state_next = 1;
					end
                end 
            endcase
			//ADDITION ALGORITHM
			case (addition_state)
				0: begin
					if(eSS_busy) addition_state_next = 0;
					else addition_state_next = 1;
				end
				1: begin
					
				end  
			endcase           
		end
	end
end



endmodule

 