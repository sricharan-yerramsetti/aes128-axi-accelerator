module memory_controller(
    // Global signals
    input  wire        clk,
    input  wire        areset,

    // AXI4-Lite Read Address Channel
    input  wire [31:0] ARADDR,
    input  wire        ARVALID,
    output wire        ARREADY,

    // AXI4-Lite Read Data Channel
    output wire [31:0] RDATA,
    output wire        RVALID,
    input  wire        RREADY,
    output reg  [ 1:0] RRESP,

    // AXI4-Lite Write Address Channel
    input  wire [31:0] AWADDR,
    input  wire        AWVALID,
    output wire        AWREADY,

    // AXI4-Lite Write Data Channel
    input  wire [31:0] WDATA,
    input  wire        WVALID,
    output wire        WREADY,

    // AXI4-Lite Write Response Channel
    output wire        BVALID,
    input  wire        BREADY,
    output reg  [ 1:0] BRESP,

    // Memory interface (to backend SRAM/ROM)
    input  wire [31:0] rd_data,
    output wire [15:0] rd_addr,
    output reg         rd_en,

    output wire [15:0] wr_addr,
    output wire [31:0] wr_data,
    output reg         wr_en
);
localparam OKAY = 2'd0;
localparam DEERR = 2'd3;
localparam receive = 1'b0;
localparam send = 1'b1;

wire valid_1;
wire valid_2;

assign valid_1 = (ARADDR[31:16] == 0);
assign RDATA = rd_data;
assign rd_addr = ARADDR[15:0];
assign ARREADY = (state_1 == receive) || ((state_1 == send) && RREADY); 
assign RVALID = (state_1 == send);

assign valid_2 = (AWADDR[31:16] == 0);
assign AWREADY = (state_2 == receive) || ((state_2 == send) && BREADY);
assign WREADY = (state_2 == receive) || ((state_2 == send) && BREADY);
assign BVALID = (state_2 == send);
assign wr_data = WDATA;
assign wr_addr = AWADDR[15:0];


reg state_1, next_state_1;
reg addr_status_1;
reg state_2,next_state_2;
reg addr_status_2;


always@(*) begin
    rd_en = 0;
    RRESP = OKAY;
    next_state_1 = receive;
    case(state_1) 
        receive : begin
                    rd_en = ((ARVALID)&&(valid_1));
                    next_state_1 = (ARVALID) ? send : receive;
                  end
        send : begin
                    RRESP = (addr_status_1) ? OKAY : DEERR;

                    if (RREADY) begin
                        rd_en = (ARVALID && valid_1); 
                        next_state_1 = (ARVALID) ? send : receive; 
                    end 
                    else begin
                        rd_en = 0;
                        next_state_1 = send;
                    end
               end
    endcase
end

always@(*) begin
    wr_en = 0;
    BRESP = OKAY;
    next_state_2 = receive;
    case(state_2)
        receive : begin
                    wr_en  =((AWVALID)&&(WVALID)&&(valid_2));
                    next_state_2 = ((AWVALID)&&(WVALID)) ? send : receive;
                  end
        send    : begin
                    BRESP = (addr_status_2) ? OKAY : DEERR;
                    if(BREADY) begin
                        wr_en = (AWVALID && WVALID && valid_2);
                        next_state_2 = (AWVALID && WVALID) ?  send : receive;
                    end
                    else begin
                        wr_en = 0;
                        next_state_2 = send;
                    end
                  end
    endcase
end

always@(posedge clk or negedge areset) begin
    if(areset == 0) begin
        state_1 <= receive;
        addr_status_1 <= 0;
    end
    else begin
        state_1 <= next_state_1;
        case(state_1)
            receive : begin
                        if (ARVALID) addr_status_1 <= (valid_1);
                      end
            send : begin

                        if (RREADY && ARVALID) begin
                            addr_status_1 <= (valid_1);
                        end 
                        else begin
                            addr_status_1 <= addr_status_1;
                        end
                   end
        endcase
    end
end

always@(posedge clk or negedge areset) begin
    if(areset == 0) begin
        state_2 <= receive;
        addr_status_2 <= 0;
    end
    else begin
        state_2 <= next_state_2;
        case(state_2)
            receive : begin
                        if(AWVALID && WVALID) begin
                            addr_status_2 <= valid_2;
                        end
                      end
            send    : begin
                        if(BREADY && AWVALID && WVALID) begin
                            addr_status_2 <= (valid_2);
                        end
                        else begin
                            addr_status_2 <= addr_status_2;
                        end
                      end
        endcase
    end
end
endmodule