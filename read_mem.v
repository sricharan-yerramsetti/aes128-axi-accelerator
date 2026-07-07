module read_mem(
    input clk,
    input stall,
    input[31:0] wr_data,
    input[31:0] wr_addr,
    input wr_en,
    input areset,
    output empty,
    output full,
    output reg valid_in,
    output reg [127:0] plain_text,
    output reg [127:0] addr_in
);


reg[2:0] read_ptr;
reg[2:0] write_ptr;
reg[63:0] mem[0:3];

assign full = (read_ptr[1:0] == write_ptr[1:0]) && (read_ptr[2] != write_ptr[2]);
assign empty = (read_ptr == write_ptr);





always@(posedge clk or negedge areset) begin

    if(areset == 1'b0) begin
        write_ptr <= 0;
        
    end

    else if (!stall) begin
        if(wr_en && (!full)) begin
            mem[write_ptr[1:0]] <= {wr_addr,wr_data};
            write_ptr <= write_ptr + 1;
        end
    end

    

end

always@(posedge clk or negedge areset) begin

    if(areset == 1'b0) begin
            read_ptr   <= 3'b000;
            valid_in   <= 1'b0;
            plain_text <= 128'h0;
            addr_in    <= 128'h0;
        end

    else if(!stall) begin
        if(full) begin
            plain_text <= {mem[0][31:0],mem[1][31:0],mem[2][31:0],mem[3][31:0]};
            addr_in <= {mem[0][63:32],mem[1][63:32],mem[2][63:32],mem[3][63:32]};
            valid_in <= 1;
            read_ptr <= read_ptr + 4;
        end

        else begin
            valid_in <= 0;
            plain_text <= 128'h0; 
            addr_in    <= 128'h0;
        end
    end
end


endmodule