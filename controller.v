module controller(
    input clk,
    input areset,
    input rd_en,
    input [2:0] rd_addr,
    input wr_en,
    input [2:0] wr_addr,
    input [31:0] wr_data,
    input ERROR,
    input DONE,
    output reg [31:0] rd_data,
    output not_avai,
    output [127:0] static_key,
    output static_key_valid,
    output start,
    output [31:0] start_address,
    output [31:0] end_address
);

localparam CTRL_ADDR   = 3'd0;
localparam STATUS_ADDR = 3'd1;
localparam START_ADDR  = 3'd2;
localparam END_ADDR    = 3'd3;
localparam KEY_0_ADDR  = 3'd4;
localparam KEY_1_ADDR  = 3'd5;
localparam KEY_2_ADDR  = 3'd6;
localparam KEY_3_ADDR  = 3'd7;

localparam idle = 32'd0;
localparam busy = 32'd1;
localparam error = 32'd2;
localparam done = 32'd3;

assign start = regs[CTRL_ADDR][0];
assign static_key_valid = regs[CTRL_ADDR][0];
assign static_key = {regs[KEY_3_ADDR],regs[KEY_2_ADDR],regs[KEY_1_ADDR],regs[KEY_0_ADDR]};
assign not_avai = (regs[STATUS_ADDR] != idle);
assign start_address = regs[START_ADDR];
assign end_address = regs[END_ADDR];

reg[31:0] regs[0:7];

always@(posedge clk or negedge areset) begin
    if(!areset) begin
        regs[CTRL_ADDR] <= 0;
        regs[STATUS_ADDR] <= idle;
        regs[START_ADDR] <= 0;
        regs[END_ADDR] <= 0;
        regs[KEY_0_ADDR] <= 0;
        regs[KEY_1_ADDR] <= 0;
        regs[KEY_2_ADDR] <= 0;
        regs[KEY_3_ADDR] <= 0;
    end
    else begin
       
        if (wr_en && (wr_addr != STATUS_ADDR) && !(wr_addr == CTRL_ADDR && regs[STATUS_ADDR] == busy)) begin
            regs[wr_addr] <= wr_data;
        end


        case(regs[STATUS_ADDR])
            idle : begin
                    regs[STATUS_ADDR] <= (start) ? busy : idle;
                   end
            busy : begin
                    regs[STATUS_ADDR] <= (ERROR) ? error : ((DONE) ? done : busy);
                    regs[CTRL_ADDR] <= (ERROR || DONE) ? 0 : regs[CTRL_ADDR];
                   end
            done : begin
                    regs[STATUS_ADDR] <= idle;
                   end
            error : begin
                     regs[STATUS_ADDR] <= idle;
                    end
        endcase

        if(rd_en) begin
            rd_data <= regs[rd_addr];
        end
    end
    
end

endmodule