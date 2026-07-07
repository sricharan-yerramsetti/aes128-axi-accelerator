module key_scheduler(
    input clk,
    input stall,
    input areset,
    input start,
    input [127:0] static_key,
    input         static_key_valid,
    output reg [127:0] round_key_0,
    output     [127:0] round_key_1,
    output     [127:0] round_key_2,
    output     [127:0] round_key_3,
    output     [127:0] round_key_4,
    output     [127:0] round_key_5,
    output     [127:0] round_key_6,
    output     [127:0] round_key_7,
    output     [127:0] round_key_8,
    output     [127:0] round_key_9,
    output     [127:0] round_key_10
);

    wire [127:0] data_out_0;
    wire [127:0] data_out_1;
    wire [127:0] data_out_2;
    wire [127:0] data_out_3;
    wire [127:0] data_out_4;
    wire [127:0] data_out_5;
    wire [127:0] data_out_6;
    wire [127:0] data_out_7;
    wire [127:0] data_out_8;
    wire [127:0] data_out_9;

    always @(posedge clk or negedge areset) begin
        if (!areset) begin
            round_key_0 <= 128'h0;
        end
        else if (!stall && start && static_key_valid) begin
            round_key_0 <= static_key;
        end
    end



    key_stage stage_0 (
        .data_in(round_key_0),
        .data_out(data_out_0),
        .round_constant(32'h01000000)
    );
    key_latch latch_1 (
        .clk(clk), .stall(stall), .areset(areset), .start(start),
        .data_in(data_out_0),
        .round_key(round_key_1)
    );

    key_stage stage_1 (
        .data_in(round_key_1),
        .data_out(data_out_1),
        .round_constant(32'h02000000)
    );
    key_latch latch_2 (
        .clk(clk), .stall(stall), .areset(areset), .start(start),
        .data_in(data_out_1),
        .round_key(round_key_2)
    );

    key_stage stage_2 (
        .data_in(round_key_2),
        .data_out(data_out_2),
        .round_constant(32'h04000000)
    );
    key_latch latch_3 (
        .clk(clk), .stall(stall), .areset(areset), .start(start),
        .data_in(data_out_2),
        .round_key(round_key_3)
    );

    key_stage stage_3 (
        .data_in(round_key_3),
        .data_out(data_out_3),
        .round_constant(32'h08000000)
    );
    key_latch latch_4 (
        .clk(clk), .stall(stall), .areset(areset), .start(start),
        .data_in(data_out_3),
        .round_key(round_key_4)
    );

    key_stage stage_4 (
        .data_in(round_key_4),
        .data_out(data_out_4),
        .round_constant(32'h10000000)
    );
    key_latch latch_5 (
        .clk(clk), .stall(stall), .areset(areset), .start(start),
        .data_in(data_out_4),
        .round_key(round_key_5)
    );

    key_stage stage_5 (
        .data_in(round_key_5),
        .data_out(data_out_5),
        .round_constant(32'h20000000)
    );
    key_latch latch_6 (
        .clk(clk), .stall(stall), .areset(areset), .start(start),
        .data_in(data_out_5),
        .round_key(round_key_6)
    );

    key_stage stage_6 (
        .data_in(round_key_6),
        .data_out(data_out_6),
        .round_constant(32'h40000000)
    );
    key_latch latch_7 (
        .clk(clk), .stall(stall), .areset(areset), .start(start),
        .data_in(data_out_6),
        .round_key(round_key_7)
    );

    key_stage stage_7 (
        .data_in(round_key_7),
        .data_out(data_out_7),
        .round_constant(32'h80000000)
    );
    key_latch latch_8 (
        .clk(clk), .stall(stall), .areset(areset), .start(start),
        .data_in(data_out_7),
        .round_key(round_key_8)
    );

    key_stage stage_8 (
        .data_in(round_key_8),
        .data_out(data_out_8),
        .round_constant(32'h1b000000)
    );
    key_latch latch_9 (
        .clk(clk), .stall(stall), .areset(areset), .start(start),
        .data_in(data_out_8),
        .round_key(round_key_9)
    );

    key_stage stage_9 (
        .data_in(round_key_9),
        .data_out(data_out_9),
        .round_constant(32'h36000000)
    );
    key_latch latch_10 (
        .clk(clk), .stall(stall), .areset(areset), .start(start),
        .data_in(data_out_9),
        .round_key(round_key_10)
    );

endmodule