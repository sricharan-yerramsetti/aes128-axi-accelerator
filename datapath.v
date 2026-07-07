module datapath(
    input clk,
    input areset,
    input stall,
    input [127:0] plain_text,
    input[127:0] addr_in,
    input valid_in,
    input [127:0] round_key_0,
    input [127:0] round_key_1,
    input [127:0] round_key_2,
    input [127:0] round_key_3,
    input [127:0] round_key_4,
    input [127:0] round_key_5,
    input [127:0] round_key_6,
    input [127:0] round_key_7,
    input [127:0] round_key_8,
    input [127:0] round_key_9,
    input [127:0] round_key_10,
    output [127:0] cipher_text,
    output [127:0] addr_out,
    output valid_out
);
wire[127:0] data_out_0;
wire[127:0] data_out_1;
wire[127:0] data_out_2;
wire[127:0] data_out_3;
wire[127:0] data_out_4;
wire[127:0] data_out_5;
wire[127:0] data_out_6;
wire[127:0] data_out_7;
wire[127:0] data_out_8;
wire[127:0] data_out_9;
wire[127:0] data_out_10;

wire[127:0] data_out_10_1;
wire[127:0] data_out_10_2;

wire[127:0] data_in_1;
wire[127:0] data_in_2;
wire[127:0] data_in_3;
wire[127:0] data_in_4;
wire[127:0] data_in_5;
wire[127:0] data_in_6;
wire[127:0] data_in_7;
wire[127:0] data_in_8;
wire[127:0] data_in_9;
wire[127:0] data_in_10;

wire valid_1;
wire valid_2;
wire valid_3;
wire valid_4;
wire valid_5;
wire valid_6;
wire valid_7;
wire valid_8;
wire valid_9;
wire valid_10;

wire[127:0] addr_1;
wire[127:0] addr_2;
wire[127:0] addr_3;
wire[127:0] addr_4;
wire[127:0] addr_5;
wire[127:0] addr_6;
wire[127:0] addr_7;
wire[127:0] addr_8;
wire[127:0] addr_9;
wire[127:0] addr_10;



add_round_key add_round_key_0(
    .round_key(round_key_0),
    .data_in(plain_text),
    .data_out(data_out_0)
);

stage stage_1 (
    .round_key(round_key_1),
    .data_in(data_in_1),
    .data_out(data_out_1)
);

stage stage_2 (
    .round_key(round_key_2),
    .data_in(data_in_2),
    .data_out(data_out_2)
);

stage stage_3 (
    .round_key(round_key_3),
    .data_in(data_in_3),
    .data_out(data_out_3)
);

stage stage_4 (
    .round_key(round_key_4),
    .data_in(data_in_4),
    .data_out(data_out_4)
);

stage stage_5 (
    .round_key(round_key_5),
    .data_in(data_in_5),
    .data_out(data_out_5)
);

stage stage_6 (
    .round_key(round_key_6),
    .data_in(data_in_6),
    .data_out(data_out_6)
);

stage stage_7 (
    .round_key(round_key_7),
    .data_in(data_in_7),
    .data_out(data_out_7)
);

stage stage_8 (
    .round_key(round_key_8),
    .data_in(data_in_8),
    .data_out(data_out_8)
);

stage stage_9 (
    .round_key(round_key_9),
    .data_in(data_in_9),
    .data_out(data_out_9)
);

sub_bytes sub_bytes_inst_10(
    .data_in(data_in_10),
    .data_out(data_out_10_1)
);

shift_rows shift_rows_inst_10(
    .data_in(data_out_10_1),
    .data_out(data_out_10_2)
);

add_round_key add_round_key_inst_10(
    .round_key(round_key_10),
    .data_in(data_out_10_2),
    .data_out(data_out_10)
);

latches latch_0(
    .clk(clk),
    .stall(stall),
    .text_in(data_out_0),
    .valid_in(valid_in),
    .addr_in(addr_in),
    .text(data_in_1),
    .valid(valid_1),
    .addr(addr_1),
    .areset(areset)
);

latches latch_1 (
    .clk(clk),
    .stall(stall),
    .text_in(data_out_1),
    .valid_in(valid_1),
    .addr_in(addr_1),
    .text(data_in_2),
    .valid(valid_2),
    .addr(addr_2),
    .areset(areset)
);

latches latch_2 (
    .clk(clk),
    .stall(stall),
    .text_in(data_out_2),
    .valid_in(valid_2),
    .addr_in(addr_2),
    .text(data_in_3),
    .valid(valid_3),
    .addr(addr_3),
    .areset(areset)
);

latches latch_3 (
    .clk(clk),
    .stall(stall),
    .text_in(data_out_3),
    .valid_in(valid_3),
    .addr_in(addr_3),
    .text(data_in_4),
    .valid(valid_4),
    .addr(addr_4),
    .areset(areset)
);

latches latch_4 (
    .clk(clk),
    .stall(stall),
    .text_in(data_out_4),
    .valid_in(valid_4),
    .addr_in(addr_4),
    .text(data_in_5),
    .valid(valid_5),
    .addr(addr_5),
    .areset(areset)
);

latches latch_5 (
    .clk(clk),
    .stall(stall),
    .text_in(data_out_5),
    .valid_in(valid_5),
    .addr_in(addr_5),
    .text(data_in_6),
    .valid(valid_6),
    .addr(addr_6),
    .areset(areset)
);

latches latch_6 (
    .clk(clk),
    .stall(stall),
    .text_in(data_out_6),
    .valid_in(valid_6),
    .addr_in(addr_6),
    .text(data_in_7),
    .valid(valid_7),
    .addr(addr_7),
    .areset(areset)
);

latches latch_7 (
    .clk(clk),
    .stall(stall),
    .text_in(data_out_7),
    .valid_in(valid_7),
    .addr_in(addr_7),
    .text(data_in_8),
    .valid(valid_8),
    .addr(addr_8),
    .areset(areset)
);

latches latch_8 (
    .clk(clk),
    .stall(stall),
    .text_in(data_out_8),
    .valid_in(valid_8),
    .addr_in(addr_8),
    .text(data_in_9),
    .valid(valid_9),
    .addr(addr_9),
    .areset(areset)
);

latches latch_9 (
    .clk(clk),
    .stall(stall),
    .text_in(data_out_9),
    .valid_in(valid_9),
    .addr_in(addr_9),
    .text(data_in_10),
    .valid(valid_10),
    .addr(addr_10),
    .areset(areset)
);

latches latch_10 (
    .clk(clk),
    .stall(stall),
    .text_in(data_out_10),
    .valid_in(valid_10),
    .addr_in(addr_10),
    .text(cipher_text),
    .valid(valid_out),
    .addr(addr_out),
    .areset(areset)
);




endmodule