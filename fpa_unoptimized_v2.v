module fpa_unoptimized_v2(
    X,
    Y,
    result,
	 s_amount
);
// I/O ports
input [31:0] X, Y;
output reg [31:0] result;
output [4:0] s_amount;
// Operand Decoding
reg sign_x, sign_y;
reg [7:0] exp_x, exp_y;
reg [22:0] mantissa_x, mantissa_y;
// Temporary Variables
reg b_sign, s_sign;
reg [7:0] b_exp, s_exp;
reg [23:0] b_mantissa, s_mantissa;
reg [7:0] exp_difference;
reg [47:0] ts_mantissa;
reg [47:0] tb_mantissa;
reg [47:0] temp_mantissa;
reg [23:0] lzc_in_m;
reg carry;
wire [4:0] shift_amount;
wire [23:0] lzc_in;
reg state;
//Result Variables
reg f_sign;
reg [7:0] f_exp;
reg [22:0] f_mantissa;

assign s_amount = shift_amount;
assign lzc_in = (state == 1) ? lzc_in_m:0;

lzc_counter lzc_counter_0(
    .X(lzc_in),
    .lzc_count(shift_amount)
);

always @*begin
    sign_x = X[31];
    sign_y = Y[31];
    exp_x = X[30:23];
    exp_y = Y[30:23];
    mantissa_x = X[22:0];
    mantissa_y = Y[22:0];
    state = 0;
	 lzc_in_m = 0;
    if(exp_x > exp_y) begin
        b_sign = sign_x;
        b_exp = exp_x;
        b_mantissa = mantissa_x;
        s_sign = sign_y;
        s_exp = exp_y;
        s_mantissa = mantissa_y;
    end 
    else begin
        b_sign = sign_y;
        b_exp = exp_y;
        b_mantissa = mantissa_y;
        s_sign = sign_x;
        s_exp = exp_x;
        s_mantissa = mantissa_x;
    end
    exp_difference = b_exp - s_exp;
    if(exp_difference > 24) begin
        result = {b_sign, b_exp, b_mantissa};
    end
    else begin
        ts_mantissa = {1'b1, s_mantissa, 24'b0}; //significand alignment
        ts_mantissa = ts_mantissa >> shift_amount;
        tb_mantissa = {1'b1, b_mantissa, 24'b0};
        if(b_sign == s_sign) begin //addition
            {carry, temp_mantissa} = tb_mantissa + ts_mantissa;
            if(carry == 1'b1) begin //significand overflow
                temp_mantissa = temp_mantissa >> 1;
                f_exp = b_exp + 1;
            end
            else begin
					 temp_mantissa = temp_mantissa;
                f_exp = b_exp;
            end
        end
        else begin //subtracion
			   state = 1;
            temp_mantissa = tb_mantissa - ts_mantissa;
				lzc_in_m = temp_mantissa[47:24];
            temp_mantissa = temp_mantissa << shift_amount;
            f_exp = b_exp - shift_amount;
        end
        f_sign = b_sign;
        if(temp_mantissa[23:0] >= 24'b100000000000000000000000) begin //round to nearest even
            temp_mantissa[47:24] = temp_mantissa[47:24] + 1;
        end
		  else begin
            temp_mantissa[47:24] = temp_mantissa[47:24];
        end
        f_mantissa = temp_mantissa[46:24];
        result = {f_sign, f_exp, f_mantissa};
    end
end



endmodule