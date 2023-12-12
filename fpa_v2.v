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
// bias all 1's, significand first bit = 1 and significand != 0
//signaling NaN
// bias all 1's, significand first bit = 0 and significand != 0 

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

//INTERNAL REGISTERS
reg sign_x, sign_x_next;
reg [7:0] exp_x, exp_x_next;
reg [23:0] significand_x, significand_x_next;
reg sign_y, sign_y_next;
reg [7:0] exp_y, exp_y_next;
reg [23:0] significand_y, significand_y_next;
reg  addition_state, addition_state_next;

//SEQUANTIAL PART
always @(posedge clk) begin
	sign_x <= sign_x_next;
	exp_x <= exp_x_next;
	significand_x <= significand_x_next;
	sign_y <= sign_y_next;
	exp_y <= exp_y_next;
	significand_y <= significand_y_next;
    addition_state <= addition_state_next;
end

//COMBINATIONAL PART
always @* begin
	if(rst)begin
		sign_x_next = X[31];
		exp_x_next = X[30:23]
		significand_x_next = X[22:0];
		sign_y_next = Y[31];
		exp_y_next = Y[30:23];
		significand_y_next = Y[22:0];
        addition_state_next = 0;
		out_valid = 0;
		result = 0;
	end
	else begin
		sign_x_next = X[31];
		exp_x_next = X[30:23]
		significand_x_next = X[22:0];
		sign_y_next = Y[31];
		exp_y_next = Y[30:23];
		significand_y_next = Y[22:0];
        addition_state_next = addition_state;
		
		//NaN Out
		//quiet NaN
		if((exp_x_next == 255 && significand_x_next[22] == 1) || (exp_y_next == 255 && significand_y_next[22] == 1)) begin
			result = 32'bx111111111xxxxxxxxxxxxxxxxxxxxxx;
			out_valid = 1;
		end
		//signaling NaN
		else if(exp_x_next == 255 && significand_x_next[22] == 0 && significand_x_next != 0) || (exp_y_next == 255 && significand_y_next[22] == 0 && significand_y_next != 0) begin
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
		//ADDITION ALGORITHM
		else begin
            case (addition_state)
                0: begin
					if(exp_x_next = exp_y_next) begin
						
					end
					else if(exp_x_next > exp_y_next) begin
						exp_y_next = exp_y + 1;
						significand_y_next = significand_y >> 1;
						if (significand_y_next == 0) begin
							result = X;
							out_valid = 1;
						end
					end
					else begin
						exp_x_next = exp_x + 1;
						significand_x_next = significand_x >> 1;
						if (significand_x_next == 0) begin
							result = Y;
							out_valid = 1;
						end
					end
                    addition_state_next = 1;
                end
                1: begin
					if(exp_x = exp_y) begin
						
					end
					else if(exp_x > exp_y) begin
						exp_y_next = exp_y + 1;
						significand_y_next = significand_y >> 1;
						if (significand_y_next == 0) begin
							result = X;
							out_valid = 1;
						end
					end
					else begin
						exp_x_next = exp_x + 1;
						significand_x_next = significand_x >> 1;
						if (significand_x_next == 0) begin
							result = Y;
							out_valid = 1;
						end
					end
					addition_state_next = 1;
                end 
            endcase           
		end
	end
end



endmodule

 