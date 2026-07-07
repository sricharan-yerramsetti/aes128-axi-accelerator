module single_col_mix(
    input  [31:0] in,
    output [31:0] out
);

wire [7:0] b0, b1, b2, b3;
wire [7:0] m2_b0, m2_b1, m2_b2, m2_b3;
wire [7:0] a0, a1, a2, a3;



assign b0 = in[31:24];
assign b1 = in[23:16];
assign b2 = in[15:8];
assign b3 = in[7:0];

assign m2_b0 = (b0[7] == 1'b1) ? ((b0 << 1) ^ 8'h1b) : (b0 << 1);
assign m2_b1 = (b1[7] == 1'b1) ? ((b1 << 1) ^ 8'h1b) : (b1 << 1);
assign m2_b2 = (b2[7] == 1'b1) ? ((b2 << 1) ^ 8'h1b) : (b2 << 1);
assign m2_b3 = (b3[7] == 1'b1) ? ((b3 << 1) ^ 8'h1b) : (b3 << 1);


assign a0 = m2_b0 ^ (m2_b1 ^ b1) ^ b2 ^ b3;
assign a1 = b0 ^ m2_b1 ^ (m2_b2 ^ b2) ^ b3;
assign a2 = b0 ^ b1 ^ m2_b2 ^ (m2_b3 ^ b3);
assign a3 = (m2_b0 ^ b0) ^ b1 ^ b2 ^ m2_b3;

assign out = {a0, a1, a2, a3};

endmodule