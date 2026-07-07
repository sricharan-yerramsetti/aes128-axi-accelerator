module key_stage(
    input [127:0] data_in,
    input[31:0] round_constant,
    output [127:0] data_out
);

wire[31:0] rot_word;
wire[31:0] data_out_1;
wire[31:0] data_out_2;

assign rot_word = {data_in[23:0],data_in[31:24]};

sbox_lut lut_0(
    .in(rot_word[31:24]),
    .out(data_out_1[31:24])
);

sbox_lut lut_1(
    .in(rot_word[23:16]),
    .out(data_out_1[23:16])
);

sbox_lut lut_2(
    .in(rot_word[15:8]),
    .out(data_out_1[15:8])
);

sbox_lut lut_3(
    .in(rot_word[7:0]),
    .out(data_out_1[7:0])
);

assign data_out_2 = data_out_1 ^ round_constant;

assign data_out[127:96] = (data_in[127:96])^(data_out_2);
assign data_out[95:64] = (data_in[95:64])^(data_out[127:96]);
assign data_out[63:32] = (data_in[63:32])^(data_out[95:64]);
assign data_out[31:0] = (data_in[31:0])^(data_out[63:32]);


endmodule