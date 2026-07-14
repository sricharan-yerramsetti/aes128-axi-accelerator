module write_controller(
    input  wire        clk,
    input  wire        areset,
    input  wire        start,
    input  wire        empty,
    input  wire [31:0] end_address,
    input  wire        AWREADY,
    input  wire        WREADY,
    input  wire        BVALID,
    input  wire [1:0]  BRESP,
    input  wire [31:0] rd_data,
    input  wire [31:0] addr,
    output wire [31:0] AWADDR,
    output wire [31:0] WDATA,
    output reg         AWVALID,
    output reg         WVALID,
    output wire        BREADY,
    output reg         rd_en,
    output reg         stall,
    output reg         done,
    output wire        error
);

localparam aw_idle = 1'b0;
localparam aw_run = 1'b1;
localparam OKAY = 2'b00;


reg state_1,next_state_1;

reg aw_done;
reg w_done;

assign BREADY = (start);
assign error = (BREADY && BVALID && (BRESP != OKAY));
assign WDATA = rd_data;
assign AWADDR = addr;

always@(*) begin
    rd_en = 0;
    stall = 0;
    aw_done = 0;
    w_done = 0;
    next_state_1 = aw_idle;
    if(start) begin
        case(state_1)
            aw_idle : begin
                        rd_en = ((start)&&(!empty)) ? 1 : 0;
                        next_state_1 = ((start)&&(!empty)) ? aw_run : aw_idle;
                        
                      end
            aw_run : begin
                        aw_done = (AWVALID) ? (AWVALID && AWREADY) : 1;
                        w_done = (WVALID) ? (WVALID && WREADY) : 1;
                        if(aw_done && w_done) begin
                            stall = 0;
                            rd_en = (AWADDR < end_address) ? ((empty) ? 0 : 1) : 0 ;
                            next_state_1 = ((AWADDR < end_address) && (!empty)) ? aw_run : aw_idle;
                        end
                        else begin
                            stall = 1;
                            rd_en = 0;
                            next_state_1 = aw_run;
                        end
                     end
        endcase
    end
end


always@(posedge clk or negedge areset) begin
    if(areset == 0) begin
        state_1 <= aw_idle;
        AWVALID <= 0;
        WVALID <= 0;
        done <= 0;
    end
    else begin
        state_1 <= next_state_1;
        case(state_1)
            aw_idle : begin
                        AWVALID <= ((start) && (!empty)) ? 1 : 0;
                        WVALID <= ((start) && (!empty)) ? 1 : 0;
                        done <= 0;
                      end
            aw_run : begin
                        if(aw_done && w_done) begin
                            AWVALID <= ((AWADDR < end_address) && (!empty)) ? 1 : 0;
                            WVALID <= ((AWADDR < end_address) && (!empty)) ? 1 : 0;
                            done <= (AWADDR < end_address) ? done : 1;
                        end
                        else begin
                            AWVALID <= (AWVALID && (!AWREADY));
                            WVALID <= (WVALID && (!WREADY));
                            done <= 0;
                        end
                     end
        endcase
    end
end

endmodule