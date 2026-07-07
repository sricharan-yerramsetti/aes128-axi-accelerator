module memory_top (
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
    output wire [ 1:0] RRESP,

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
    output wire [ 1:0] BRESP
);

// ─────────────────────────────────────────────
// memory_controller <-> mem
// ─────────────────────────────────────────────
wire [15:0] rd_addr;   // memory_controller → mem
wire        rd_en;     // memory_controller → mem
wire [31:0] rd_data;   // mem → memory_controller

wire [15:0] wr_addr;   // memory_controller → mem
wire [31:0] wr_data;   // memory_controller → mem
wire        wr_en;     // memory_controller → mem

// ═════════════════════════════════════════════
// memory_controller
// Ports: clk, areset,
//        ARADDR, ARVALID, ARREADY,
//        RDATA, RVALID, RREADY, RRESP,
//        AWADDR, AWVALID, AWREADY,
//        WDATA, WVALID, WREADY,
//        BVALID, BREADY, BRESP,
//        rd_data[31:0], rd_addr[15:0], rd_en,
//        wr_addr[15:0], wr_data[31:0], wr_en
// ═════════════════════════════════════════════
memory_controller u_mem_ctrl (
    .clk     (clk),
    .areset  (areset),

    .ARADDR  (ARADDR),
    .ARVALID (ARVALID),
    .ARREADY (ARREADY),
    .RDATA   (RDATA),
    .RVALID  (RVALID),
    .RREADY  (RREADY),
    .RRESP   (RRESP),

    .AWADDR  (AWADDR),
    .AWVALID (AWVALID),
    .AWREADY (AWREADY),
    .WDATA   (WDATA),
    .WVALID  (WVALID),
    .WREADY  (WREADY),
    .BVALID  (BVALID),
    .BREADY  (BREADY),
    .BRESP   (BRESP),

    .rd_data (rd_data),
    .rd_addr (rd_addr),
    .rd_en   (rd_en),
    .wr_addr (wr_addr),
    .wr_data (wr_data),
    .wr_en   (wr_en)
);

// ═════════════════════════════════════════════
// mem  (ADDR_WIDTH=16 → 64K×32-bit = 256KB)
// Ports: clk,
//        wr_en, wr_addr[15:0], wr_data[31:0],
//        rd_en, rd_addr[15:0],
//        rd_data[31:0]
// ═════════════════════════════════════════════
mem #(
    .ADDR_WIDTH (16),
    .DATA_WIDTH (32)
) u_mem (
    .clk     (clk),
    .wr_en   (wr_en),
    .wr_addr (wr_addr),
    .wr_data (wr_data),
    .rd_en   (rd_en),
    .rd_addr (rd_addr),
    .rd_data (rd_data)
);

endmodule