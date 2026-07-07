module controller_interface (
    // Global signals
    input  wire        clk,
    input  wire        areset,
    input not_avai,

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
    output wire [2:0] rd_addr,
    output reg         rd_en,

    output wire [2:0] wr_addr,
    output wire [31:0] wr_data,
    output reg         wr_en
);
wire valid_1;
wire valid_2;
localparam OKAY = 2'd0;
localparam DEERR = 2'd3;
localparam receive = 1'b0;
localparam send = 1'b1;

assign valid_1 = ((ARADDR >= 32'h00010000) && (ARADDR <= 32'h00010007));
assign RDATA = rd_data;
assign rd_addr = ARADDR[2:0];
assign ARREADY = (state_1 == receive) || ((state_1 == send) && RREADY); 
assign RVALID = (state_1 == send);

assign valid_2 = ((AWADDR >= 32'h00010000) && (AWADDR <= 32'h00010007));
assign AWREADY = ((state_2 == receive)&&(!not_avai)) || ((state_2 == send) && BREADY && (!not_avai));
assign WREADY = ((state_2 == receive)&&(!not_avai)) || ((state_2 == send) && BREADY && (!not_avai));
assign BVALID = (state_2 == send);
assign wr_data = WDATA;
assign wr_addr = AWADDR[2:0];


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
                    wr_en  =((AWREADY && AWVALID)&&(WREADY && WVALID)&&(valid_2));
                    next_state_2 = ((AWREADY && AWVALID)&&(WREADY && WVALID)) ? send : receive;
                  end
        send    : begin
                    BRESP = (addr_status_2) ? OKAY : DEERR;
                    if(BREADY) begin
                        wr_en = ((AWREADY && AWVALID) && (WREADY && WVALID) && valid_2);
                        next_state_2 = ((AWREADY && AWVALID) && (WREADY && WVALID)) ?  send : receive;
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
                        if((AWREADY && AWVALID) && (WREADY && WVALID)) begin
                            addr_status_2 <= valid_2;
                        end
                      end
            send    : begin
                        if(BREADY && (AWREADY && AWVALID) && (WREADY && WVALID)) begin
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