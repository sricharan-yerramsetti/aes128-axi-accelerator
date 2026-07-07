module write_mem(
    input clk,
    input stall,
    input areset,
    input [127:0] cipher_text,
    input [127:0] addr_out,
    input wr_en,// valid_out
    input rd_en,
    output full,
    output empty,
    output reg [31:0] rd_data,
    output reg [31:0] addr
);

reg[2:0] read_ptr;
reg[2:0] write_ptr;
reg[63:0] mem[0:3];

assign full = (read_ptr[1:0] == write_ptr[1:0]) && (read_ptr[2] != write_ptr[2]);
assign empty = (read_ptr == write_ptr);


always@(posedge clk or negedge areset) begin
    if(areset == 1'b0) begin
        rd_data <= 0;
        addr <= 0;
        read_ptr <= 0;
    end 

    else if(!stall) begin
        if((rd_en)&&(!empty)) begin
            rd_data <= mem[read_ptr[1:0]][31:0];
            addr <= mem[read_ptr[1:0]][63:32];
            read_ptr <= read_ptr + 1;
        end
    end
end


always@(posedge clk or negedge areset) begin
    if(areset == 1'b0) begin
        write_ptr <= 0;
    end

    else if(!stall) begin
        if((wr_en)&&(empty)) begin
            {mem[0][31:0],mem[1][31:0],mem[2][31:0],mem[3][31:0]} <= cipher_text;
            {mem[0][63:32],mem[1][63:32],mem[2][63:32],mem[3][63:32]} <= addr_out;
            write_ptr <= write_ptr + 4;
        end
    end



end

endmodule