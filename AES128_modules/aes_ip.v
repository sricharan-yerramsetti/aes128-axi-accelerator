module aes_ip (
    input  wire        clk,
    input  wire        areset,

    // CPU-facing AXI4-Lite slave port (register map)
    input  wire [31:0] S_CTRL_ARADDR,
    input  wire        S_CTRL_ARVALID,
    output wire        S_CTRL_ARREADY,
    output wire [31:0] S_CTRL_RDATA,
    output wire        S_CTRL_RVALID,
    input  wire        S_CTRL_RREADY,
    output wire [ 1:0] S_CTRL_RRESP,

    input  wire [31:0] S_CTRL_AWADDR,
    input  wire        S_CTRL_AWVALID,
    output wire        S_CTRL_AWREADY,
    input  wire [31:0] S_CTRL_WDATA,
    input  wire        S_CTRL_WVALID,
    output wire        S_CTRL_WREADY,
    output wire        S_CTRL_BVALID,
    input  wire        S_CTRL_BREADY,
    output wire [ 1:0] S_CTRL_BRESP,

    // AXI4-Lite master read port (reads plaintext from external memory)
    output wire [31:0] M_RD_ARADDR,
    output wire        M_RD_ARVALID,
    input  wire        M_RD_ARREADY,
    input  wire [31:0] M_RD_RDATA,
    input  wire        M_RD_RVALID,
    input  wire [ 1:0] M_RD_RRESP,
    output wire        M_RD_RREADY,

    // AXI4-Lite master write port (writes ciphertext to external memory)
    output wire [31:0] M_WR_AWADDR,
    output wire        M_WR_AWVALID,
    input  wire        M_WR_AWREADY,
    output wire [31:0] M_WR_WDATA,
    output wire        M_WR_WVALID,
    input  wire        M_WR_WREADY,
    input  wire        M_WR_BVALID,
    input  wire [ 1:0] M_WR_BRESP,
    output wire        M_WR_BREADY
);

// ─────────────────────────────────────────────────────────────
// controller_interface <-> controller
// ─────────────────────────────────────────────────────────────
wire [2:0]   ctrl_rd_addr;      // interface → controller
wire         ctrl_rd_en;        // interface → controller
wire [31:0]  ctrl_rd_data;      // controller → interface
wire [2:0]   ctrl_wr_addr;      // interface → controller
wire [31:0]  ctrl_wr_data;      // interface → controller
wire         ctrl_wr_en;        // interface → controller

// ─────────────────────────────────────────────────────────────
// controller outputs
// ─────────────────────────────────────────────────────────────
wire         not_avai;          // → controller_interface
wire         start;             // → read_controller, write_controller, key_scheduler
wire [127:0] static_key;        // → key_scheduler
wire         static_key_valid;  // → key_scheduler
wire [31:0]  start_address;     // → read_controller
wire [31:0]  end_address;       // → read_controller, write_controller

// ─────────────────────────────────────────────────────────────
// controller inputs (status feedback)
// ─────────────────────────────────────────────────────────────
wire         aes_done;          // write_controller.done  → controller.DONE
wire         aes_error;         // write_controller.error → controller.ERROR

// ─────────────────────────────────────────────────────────────
// key_scheduler → datapath
// ─────────────────────────────────────────────────────────────
wire [127:0] round_key_0;
wire [127:0] round_key_1;
wire [127:0] round_key_2;
wire [127:0] round_key_3;
wire [127:0] round_key_4;
wire [127:0] round_key_5;
wire [127:0] round_key_6;
wire [127:0] round_key_7;
wire [127:0] round_key_8;
wire [127:0] round_key_9;
wire [127:0] round_key_10;

// ─────────────────────────────────────────────────────────────
// read_controller → read_mem
// ─────────────────────────────────────────────────────────────
wire [31:0]  rc_wr_data;        // read_controller.wr_data → read_mem.wr_data
wire [31:0]  rc_wr_addr;        // read_controller.wr_addr → read_mem.wr_addr
wire         rc_wr_en;          // read_controller.wr_en   → read_mem.wr_en
wire         rc_done;           // read_controller.done_1  (unused in top, for monitoring)

// ─────────────────────────────────────────────────────────────
// read_mem outputs
// ─────────────────────────────────────────────────────────────
wire         rm_full;           // → read_controller.full
wire         rm_empty;          // (unused externally — read_mem drains itself when full)
wire         valid_in;          // → datapath.valid_in
wire [127:0] plain_text;        // → datapath.plain_text
wire [127:0] addr_in;           // → datapath.addr_in

// ─────────────────────────────────────────────────────────────
// datapath outputs
// ─────────────────────────────────────────────────────────────
wire [127:0] cipher_text;       // → write_mem.cipher_text
wire [127:0] addr_out;          // → write_mem.addr_out
wire         valid_out;         // → write_mem.wr_en

// ─────────────────────────────────────────────────────────────
// write_mem outputs
// ─────────────────────────────────────────────────────────────
wire         wm_full;           // (unused — write_controller checks empty, not full)
wire         wm_empty;          // → write_controller.empty
wire [31:0]  wm_rd_data;        // → write_controller.rd_data
wire [31:0]  wm_addr;           // → write_controller.addr

// ─────────────────────────────────────────────────────────────
// write_controller outputs
// ─────────────────────────────────────────────────────────────
wire         wc_rd_en;          // → write_mem.rd_en
wire         stall;             // write_controller.stall → datapath, read_controller,
                                //                          read_mem, write_mem, key_scheduler
assign aes_done  = wc_done;
assign aes_error = wc_error;
wire         wc_done;
wire         wc_error;

// ═════════════════════════════════════════════════════════════
// controller_interface
// Ports: clk, areset, not_avai,
//        ARADDR, ARVALID, ARREADY,
//        RDATA, RVALID, RREADY, RRESP,
//        AWADDR, AWVALID, AWREADY,
//        WDATA, WVALID, WREADY,
//        BVALID, BREADY, BRESP,
//        rd_data[31:0], rd_addr[2:0], rd_en,
//        wr_addr[2:0], wr_data[31:0], wr_en
// ═════════════════════════════════════════════════════════════
controller_interface u_ctrl_if (
    .clk      (clk),
    .areset   (areset),
    .not_avai (not_avai),

    .ARADDR   (S_CTRL_ARADDR),
    .ARVALID  (S_CTRL_ARVALID),
    .ARREADY  (S_CTRL_ARREADY),
    .RDATA    (S_CTRL_RDATA),
    .RVALID   (S_CTRL_RVALID),
    .RREADY   (S_CTRL_RREADY),
    .RRESP    (S_CTRL_RRESP),

    .AWADDR   (S_CTRL_AWADDR),
    .AWVALID  (S_CTRL_AWVALID),
    .AWREADY  (S_CTRL_AWREADY),
    .WDATA    (S_CTRL_WDATA),
    .WVALID   (S_CTRL_WVALID),
    .WREADY   (S_CTRL_WREADY),
    .BVALID   (S_CTRL_BVALID),
    .BREADY   (S_CTRL_BREADY),
    .BRESP    (S_CTRL_BRESP),

    .rd_data  (ctrl_rd_data),
    .rd_addr  (ctrl_rd_addr),
    .rd_en    (ctrl_rd_en),
    .wr_addr  (ctrl_wr_addr),
    .wr_data  (ctrl_wr_data),
    .wr_en    (ctrl_wr_en)
);

// ═════════════════════════════════════════════════════════════
// controller
// Ports: clk, areset,
//        rd_en, rd_addr[2:0], rd_data[31:0],
//        wr_en, wr_addr[2:0], wr_data[31:0],
//        ERROR, DONE,
//        not_avai, static_key[127:0], static_key_valid,
//        start, start_address[31:0], end_address[31:0]
// ═════════════════════════════════════════════════════════════
controller u_ctrl (
    .clk              (clk),
    .areset           (areset),
    .rd_en            (ctrl_rd_en),
    .rd_addr          (ctrl_rd_addr),
    .rd_data          (ctrl_rd_data),
    .wr_en            (ctrl_wr_en),
    .wr_addr          (ctrl_wr_addr),
    .wr_data          (ctrl_wr_data),
    .ERROR            (aes_error),
    .DONE             (aes_done),
    .not_avai         (not_avai),
    .static_key       (static_key),
    .static_key_valid (static_key_valid),
    .start            (start),
    .start_address    (start_address),
    .end_address      (end_address)
);

// ═════════════════════════════════════════════════════════════
// key_scheduler
// Ports: clk, stall, areset, start,
//        static_key[127:0], static_key_valid,
//        round_key_0..10 [127:0]
// ═════════════════════════════════════════════════════════════
key_scheduler u_key_sched (
    .clk              (clk),
    .areset           (areset),
    .stall            (stall),
    .start            (start),
    .static_key       (static_key),
    .static_key_valid (static_key_valid),
    .round_key_0      (round_key_0),
    .round_key_1      (round_key_1),
    .round_key_2      (round_key_2),
    .round_key_3      (round_key_3),
    .round_key_4      (round_key_4),
    .round_key_5      (round_key_5),
    .round_key_6      (round_key_6),
    .round_key_7      (round_key_7),
    .round_key_8      (round_key_8),
    .round_key_9      (round_key_9),
    .round_key_10     (round_key_10)
);

// ═════════════════════════════════════════════════════════════
// read_controller
// Ports: clk, areset, start,
//        start_address[31:0], end_address[31:0],
//        full, stall,
//        ARREADY, RDATA[31:0], RRESP[1:0], RVALID,
//        done_1,
//        wr_data[31:0], wr_addr[31:0], wr_en,
//        ARADDR[31:0], ARVALID, RREADY
// ═════════════════════════════════════════════════════════════
read_controller u_read_ctrl (
    .clk           (clk),
    .areset        (areset),
    .start         (start),
    .start_address (start_address),
    .end_address   (end_address),
    .full          (rm_full),
    .stall         (stall),
    .ARREADY       (M_RD_ARREADY),
    .RDATA         (M_RD_RDATA),
    .RRESP         (M_RD_RRESP),
    .RVALID        (M_RD_RVALID),
    .done_1        (rc_done),
    .wr_data       (rc_wr_data),
    .wr_addr       (rc_wr_addr),
    .wr_en         (rc_wr_en),
    .ARADDR        (M_RD_ARADDR),
    .ARVALID       (M_RD_ARVALID),
    .RREADY        (M_RD_RREADY)
);

// ═════════════════════════════════════════════════════════════
// read_mem
// Ports: clk, stall, wr_data[31:0], wr_addr[31:0], wr_en,
//        areset,
//        empty, full,
//        valid_in, plain_text[127:0], addr_in[127:0]
// ═════════════════════════════════════════════════════════════
read_mem u_read_mem (
    .clk        (clk),
    .areset     (areset),
    .stall      (stall),
    .wr_data    (rc_wr_data),
    .wr_addr    (rc_wr_addr),
    .wr_en      (rc_wr_en),
    .empty      (rm_empty),
    .full       (rm_full),
    .valid_in   (valid_in),
    .plain_text (plain_text),
    .addr_in    (addr_in)
);

// ═════════════════════════════════════════════════════════════
// datapath
// Ports: clk, areset, stall,
//        plain_text[127:0], addr_in[127:0], valid_in,
//        round_key_0..10 [127:0],
//        cipher_text[127:0], addr_out[127:0], valid_out
// ═════════════════════════════════════════════════════════════
datapath u_datapath (
    .clk          (clk),
    .areset       (areset),
    .stall        (stall),
    .plain_text   (plain_text),
    .addr_in      (addr_in),
    .valid_in     (valid_in),
    .round_key_0  (round_key_0),
    .round_key_1  (round_key_1),
    .round_key_2  (round_key_2),
    .round_key_3  (round_key_3),
    .round_key_4  (round_key_4),
    .round_key_5  (round_key_5),
    .round_key_6  (round_key_6),
    .round_key_7  (round_key_7),
    .round_key_8  (round_key_8),
    .round_key_9  (round_key_9),
    .round_key_10 (round_key_10),
    .cipher_text  (cipher_text),
    .addr_out     (addr_out),
    .valid_out    (valid_out)
);

// ═════════════════════════════════════════════════════════════
// write_mem
// Ports: clk, stall, areset,
//        cipher_text[127:0], addr_out[127:0],
//        wr_en, rd_en,
//        full, empty,
//        rd_data[31:0], addr[31:0]
// ═════════════════════════════════════════════════════════════
write_mem u_write_mem (
    .clk         (clk),
    .areset      (areset),
    .stall       (stall),
    .cipher_text (cipher_text),
    .addr_out    (addr_out),
    .wr_en       (valid_out),
    .rd_en       (wc_rd_en),
    .full        (wm_full),
    .empty       (wm_empty),
    .rd_data     (wm_rd_data),
    .addr        (wm_addr)
);

// ═════════════════════════════════════════════════════════════
// write_controller
// Ports: clk, areset, start, empty, end_address[31:0],
//        AWREADY, WREADY, BVALID, BRESP[1:0],
//        rd_data[31:0], addr[31:0],
//        AWADDR[31:0], WDATA[31:0],
//        AWVALID, WVALID, BREADY,
//        rd_en, stall, done, error
// ═════════════════════════════════════════════════════════════
write_controller u_write_ctrl (
    .clk         (clk),
    .areset      (areset),
    .start       (start),
    .empty       (wm_empty),
    .end_address (end_address),
    .AWREADY     (M_WR_AWREADY),
    .WREADY      (M_WR_WREADY),
    .BVALID      (M_WR_BVALID),
    .BRESP       (M_WR_BRESP),
    .rd_data     (wm_rd_data),
    .addr        (wm_addr),
    .AWADDR      (M_WR_AWADDR),
    .WDATA       (M_WR_WDATA),
    .AWVALID     (M_WR_AWVALID),
    .WVALID      (M_WR_WVALID),
    .BREADY      (M_WR_BREADY),
    .rd_en       (wc_rd_en),
    .stall       (stall),
    .done        (wc_done),
    .error       (wc_error)
);

endmodule