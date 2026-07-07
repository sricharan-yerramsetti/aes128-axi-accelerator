module mem #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] wr_addr,
    input wire [DATA_WIDTH-1:0] wr_data,
    input wire rd_en,
    input wire [ADDR_WIDTH-1:0] rd_addr,
    output reg [DATA_WIDTH-1:0] rd_data 
);
reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

always@(posedge clk) begin
    if(wr_en) begin
        ram[wr_addr] <= wr_data;
    end
    if(rd_en) begin
        rd_data <= ram[rd_addr];
    end
end

endmodule