module key_latch(
    input clk,
    input stall,
    input areset,
    input start,
    input [127:0] data_in,
    output reg[127:0] round_key
);

always@(posedge clk or negedge areset) begin
    if(areset == 0) begin
        round_key <= 0;
    end
    else if((!stall)&&(start)) begin
        round_key <= data_in;
    end
end

endmodule