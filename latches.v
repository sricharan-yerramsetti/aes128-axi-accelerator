module latches(
    input stall,
    input clk,
    input areset,
    input valid_in,
    input[127:0] text_in,
    input[127:0] addr_in,
    output reg valid,
    output reg[127:0] text,
    output reg[127:0] addr

);

always@(posedge clk or negedge areset) begin
    if(!areset) begin
        valid <= 0;
        text <= 0;
        addr <= 0;
    end
    else if(!stall) begin
        valid <= valid_in;
        text  <= text_in;
        addr  <= addr_in;
    end
end




endmodule