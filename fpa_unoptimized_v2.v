module fpa_unoptimized_v2(
    X,
    Y,
    result
);
// I/O ports
input [31:0] X, Y;
output reg [31:0] result;
// Operand Decoding
reg sign_x, sign_y;
reg [7:0] exp_x, exp_y;
reg [22:0] mantissa_x, mantissa_y;
// Temporary Variables
reg b_sign, s_sign;
reg [7:0] b_exp, s_exp;
reg [22:0] b_mantissa, s_mantissa;
reg [7:0] exp_difference;
reg [47:0] ts_mantissa;
reg [47:0] tb_mantissa;
reg [47:0] temp_mantissa;
reg carry;
reg [4:0] lzc_count;
//Result Variables
reg f_sign;
reg [7:0] f_exp;
reg [22:0] f_mantissa;


always @*begin
    sign_x = X[31];
    sign_y = Y[31];
    exp_x = X[30:23];
    exp_y = Y[30:23];
    mantissa_x = X[22:0];
    mantissa_y = Y[22:0];
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
        ts_mantissa = ts_mantissa >> exp_difference;
        tb_mantissa = {1'b1, b_mantissa, 24'b0};
        if(b_sign == s_sign) begin //addition
            {carry, temp_mantissa} = tb_mantissa + ts_mantissa;
            if(carry == 1'b1) begin //significand overflow
                temp_mantissa = {carry, temp_mantissa} >> 1;
                f_exp = b_exp + 1;
            end
            else begin
                f_exp = b_exp;
            end
        end
        else begin //subtracion
            temp_mantissa = tb_mantissa - ts_mantissa;
            lzc_count = 0;
            if(temp_mantissa[47] == 1) begin
                lzc_count = 0;
            end
            else if(temp_mantissa[46] == 1) begin
                lzc_count = 1;
            end
            else if(temp_mantissa[45] == 1) begin
                lzc_count = 2;
            end
            else if(temp_mantissa[44] == 1) begin
                lzc_count = 3;
            end
            else if(temp_mantissa[43] == 1) begin
                lzc_count = 4;
            end
            else if(temp_mantissa[42] == 1) begin
                lzc_count = 5;
            end
            else if(temp_mantissa[41] == 1) begin
                lzc_count = 6;
            end
            else if(temp_mantissa[40] == 1) begin
                lzc_count = 7;
            end
            else if(temp_mantissa[39] == 1) begin
                lzc_count = 8;
            end
            else if(temp_mantissa[38] == 1) begin
                lzc_count = 9;
            end
            else if(temp_mantissa[37] == 1) begin
                lzc_count = 10;
            end
            else if(temp_mantissa[36] == 1) begin
                lzc_count = 11;
            end
            else if(temp_mantissa[35] == 1) begin
                lzc_count = 12;
            end
            else if(temp_mantissa[34] == 1) begin
                lzc_count = 13;
            end
            else if(temp_mantissa[33] == 1) begin
                lzc_count = 14;
            end
            else if(temp_mantissa[32] == 1) begin
                lzc_count = 15;
            end
            else if(temp_mantissa[31] == 1) begin
                lzc_count = 16;
            end
            else if(temp_mantissa[30] == 1) begin
                lzc_count = 17;
            end
            else if(temp_mantissa[29] == 1) begin
                lzc_count = 18;
            end
            else if(temp_mantissa[28] == 1) begin
                lzc_count = 19;
            end
            else if(temp_mantissa[27] == 1) begin
                lzc_count = 20;
            end
            else if(temp_mantissa[26] == 1) begin
                lzc_count = 21;
            end
            else if(temp_mantissa[25] == 1) begin
                lzc_count = 22;
            end
            else if(temp_mantissa[24] == 1) begin
                lzc_count = 23;
            end
            else begin
                lzc_count = 24;
            end
            temp_mantissa = temp_mantissa << lzc_count;
            f_exp = b_exp - lzc_count;
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