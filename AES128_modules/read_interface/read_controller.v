module read_controller(
    input clk,
    input areset,
    input start,
    input [31:0] start_address,
    input [31:0] end_address,
    input full,
    input stall,
    input ARREADY,
    input [31:0] RDATA,
    input [1:0] RRESP,
    input RVALID,
    output done_1,
    output [31:0] wr_data,
    output [31:0] wr_addr,
    output reg wr_en,
    output [31:0] ARADDR,
    output ARVALID,
    output reg RREADY
);


reg state_1,next_state_1;
reg state_2,next_state_2;

localparam ar_idle = 1'b0;
localparam ar_run = 1'b1;
localparam r_idle = 1'b0;
localparam r_run = 1'b1;

localparam OKAY = 2'b00;
reg[31:0] req_addr,resp_addr;

reg start_d;
wire start_pulse = start & ~start_d;

always@(posedge clk or negedge areset) begin
    if(areset == 0)
        start_d <= 1'b0;
    else
        start_d <= start;
end

assign ARADDR = req_addr;
assign ARVALID = (state_1 == ar_run);
assign wr_data = RDATA;
assign wr_addr = resp_addr;
assign done_1 = (state_1 == ar_idle) && (state_2 == r_idle);

always@(*) begin
    next_state_1 = state_1;
    if(start) begin
    case(state_1) 
        ar_idle : begin
                    next_state_1 = ((start_pulse == 1)&&(!full))? ar_run:ar_idle;
                  end
        ar_run : begin
                    if((ARREADY)&&(!stall)&&(!full)) begin
                        if(req_addr < end_address) begin
                            next_state_1 =ar_run;
                        end
                        else begin
                            next_state_1 = ar_idle;
                        end
                    end
                    else begin
                        next_state_1 = ar_run;
                    end
                 end
    endcase
    end
end

always@(*) begin
    wr_en = 0;
    next_state_2 = state_2;
    RREADY = 0;
    if(start) begin
    case(state_2)
        r_idle : begin
                    RREADY = 0;
                    next_state_2 = (start_pulse == 1)? r_run : r_idle;
                 end
        r_run : begin
                    RREADY = (!(stall || full));
                    if(RREADY && RVALID) begin
                        next_state_2 =(resp_addr < end_address) ? r_run : r_idle;
                    end
                    else begin
                        next_state_2 = r_run; 
                    end
                    wr_en = (RREADY && RVALID && (RRESP == OKAY));

                end
    endcase
    end
end

always@(posedge clk or negedge areset) begin
    if(areset == 0) begin
        state_1 <= ar_idle;
        req_addr <= 0;
    end
    else begin
        state_1 <= next_state_1; 
    case(state_1)
        ar_idle : begin
                    req_addr <= (start == 1)? start_address :0;
                  end
        ar_run : begin
                    if((ARREADY)&&(!stall)&&(!full)) begin
                        if(req_addr < end_address) begin
                            req_addr <= req_addr + 4;
                        end
                        else begin
                            req_addr <= req_addr;
                        end
                    end
                    else begin
                        req_addr <= req_addr;
                    end
                 end
    endcase
    end

end

always@(posedge clk or negedge areset) begin
    if(areset == 0) begin
        state_2 <=  r_idle;
        resp_addr <= 0;
    end
    else begin
        state_2 <= next_state_2;
    

    case(state_2)
        r_idle : begin
                    resp_addr <= (start == 1)?start_address : 0;
                 end
        r_run : begin
                    if(RREADY&&RVALID) begin
                        resp_addr <= (resp_addr < end_address)? resp_addr + 4 : resp_addr;
                    end
                    else begin
                        resp_addr <= resp_addr;
                    end
                end
    endcase
    end
end

endmodule
