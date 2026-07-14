`timescale 1ns/1ps
module tb_aes_top;


reg clk;
reg areset;

initial clk = 0;

reg  [31:0] S_CTRL_ARADDR;
reg S_CTRL_ARVALID;
wire S_CTRL_ARREADY;
wire [31:0] S_CTRL_RDATA;
wire S_CTRL_RVALID;
reg S_CTRL_RREADY;
wire [ 1:0] S_CTRL_RRESP;
reg  [31:0] S_CTRL_AWADDR;
reg S_CTRL_AWVALID;
wire S_CTRL_AWREADY;
reg  [31:0] S_CTRL_WDATA;
reg S_CTRL_WVALID;
wire S_CTRL_WREADY;
wire S_CTRL_BVALID;
reg S_CTRL_BREADY;
wire [ 1:0] S_CTRL_BRESP;
wire [31:0] M_RD_ARADDR;
wire M_RD_ARVALID;
wire M_RD_ARREADY;
wire [31:0] M_RD_RDATA;
wire M_RD_RVALID;
wire [ 1:0] M_RD_RRESP;
wire M_RD_RREADY;
wire [31:0] M_WR_AWADDR;
wire M_WR_AWVALID;
wire M_WR_AWREADY;
wire [31:0] M_WR_WDATA;
wire M_WR_WVALID;
wire M_WR_WREADY;
wire M_WR_BVALID;
wire [ 1:0] M_WR_BRESP;
wire M_WR_BREADY;
reg tb_mem_active;   // 1 = testbench drives memory_top, 0 = aes_ip drives it

reg  [31:0] tb_ARADDR;
reg tb_ARVALID;
reg  [31:0] tb_AWADDR;
reg tb_AWVALID;
reg  [31:0] tb_WDATA;
reg tb_WVALID;
reg tb_RREADY;
reg tb_BREADY;
wire [31:0] MEM_ARADDR  = tb_mem_active ? tb_ARADDR  : M_RD_ARADDR;
wire MEM_ARVALID = tb_mem_active ? tb_ARVALID : M_RD_ARVALID;
wire MEM_RREADY  = tb_mem_active ? tb_RREADY  : M_RD_RREADY;
wire [31:0] MEM_AWADDR  = tb_mem_active ? tb_AWADDR  : M_WR_AWADDR;
wire MEM_AWVALID = tb_mem_active ? tb_AWVALID : M_WR_AWVALID;
wire [31:0] MEM_WDATA   = tb_mem_active ? tb_WDATA   : M_WR_WDATA;
wire MEM_WVALID  = tb_mem_active ? tb_WVALID  : M_WR_WVALID;
wire MEM_BREADY  = tb_mem_active ? tb_BREADY  : M_WR_BREADY;
wire MEM_ARREADY;
wire [31:0] MEM_RDATA;
wire MEM_RVALID;
wire [ 1:0] MEM_RRESP;
wire MEM_AWREADY;
wire MEM_WREADY;
wire MEM_BVALID;
wire [ 1:0] MEM_BRESP;
    
assign M_RD_ARREADY = tb_mem_active ? 1'b0 : MEM_ARREADY;
assign M_RD_RDATA    = MEM_RDATA;
assign M_RD_RVALID   = tb_mem_active ? 1'b0 : MEM_RVALID;
assign M_RD_RRESP    = MEM_RRESP;

assign M_WR_AWREADY = tb_mem_active ? 1'b0 : MEM_AWREADY;
assign M_WR_WREADY  = tb_mem_active ? 1'b0 : MEM_WREADY;
assign M_WR_BVALID  = tb_mem_active ? 1'b0 : MEM_BVALID;
assign M_WR_BRESP   = MEM_BRESP;

wire tb_ARREADY = MEM_ARREADY;
wire [31:0] tb_RDATA   = MEM_RDATA;
wire tb_RVALID  = tb_mem_active ? MEM_RVALID : 1'b0;
wire [ 1:0] tb_RRESP   = MEM_RRESP;

wire tb_AWREADY = MEM_AWREADY;
wire tb_WREADY  = MEM_WREADY;
wire tb_BVALID  = tb_mem_active ? MEM_BVALID : 1'b0;
wire [ 1:0] tb_BRESP   = MEM_BRESP;

aes_ip u_aes_ip (
    .clk            (clk),
    .areset         (areset),

    .S_CTRL_ARADDR  (S_CTRL_ARADDR),
    .S_CTRL_ARVALID (S_CTRL_ARVALID),
    .S_CTRL_ARREADY (S_CTRL_ARREADY),
    .S_CTRL_RDATA   (S_CTRL_RDATA),
    .S_CTRL_RVALID  (S_CTRL_RVALID),
    .S_CTRL_RREADY  (S_CTRL_RREADY),
    .S_CTRL_RRESP   (S_CTRL_RRESP),

    .S_CTRL_AWADDR  (S_CTRL_AWADDR),
    .S_CTRL_AWVALID (S_CTRL_AWVALID),
    .S_CTRL_AWREADY (S_CTRL_AWREADY),
    .S_CTRL_WDATA   (S_CTRL_WDATA),
    .S_CTRL_WVALID  (S_CTRL_WVALID),
    .S_CTRL_WREADY  (S_CTRL_WREADY),
    .S_CTRL_BVALID  (S_CTRL_BVALID),
    .S_CTRL_BREADY  (S_CTRL_BREADY),
    .S_CTRL_BRESP   (S_CTRL_BRESP),

    .M_RD_ARADDR    (M_RD_ARADDR),
    .M_RD_ARVALID   (M_RD_ARVALID),
    .M_RD_ARREADY   (M_RD_ARREADY),
    .M_RD_RDATA     (M_RD_RDATA),
    .M_RD_RVALID    (M_RD_RVALID),
    .M_RD_RRESP     (M_RD_RRESP),
    .M_RD_RREADY    (M_RD_RREADY),

    .M_WR_AWADDR    (M_WR_AWADDR),
    .M_WR_AWVALID   (M_WR_AWVALID),
    .M_WR_AWREADY   (M_WR_AWREADY),
    .M_WR_WDATA     (M_WR_WDATA),
    .M_WR_WVALID    (M_WR_WVALID),
    .M_WR_WREADY    (M_WR_WREADY),
    .M_WR_BVALID    (M_WR_BVALID),
    .M_WR_BRESP     (M_WR_BRESP),
    .M_WR_BREADY    (M_WR_BREADY)
);


memory_top u_memory_top (
    .clk     (clk),
    .areset  (areset),

    .ARADDR  (MEM_ARADDR),
    .ARVALID (MEM_ARVALID),
    .ARREADY (MEM_ARREADY),
    .RDATA   (MEM_RDATA),
    .RVALID  (MEM_RVALID),
    .RREADY  (MEM_RREADY),
    .RRESP   (MEM_RRESP),

    .AWADDR  (MEM_AWADDR),
    .AWVALID (MEM_AWVALID),
    .AWREADY (MEM_AWREADY),
    .WDATA   (MEM_WDATA),
    .WVALID  (MEM_WVALID),
    .WREADY  (MEM_WREADY),
    .BVALID  (MEM_BVALID),
    .BREADY  (MEM_BREADY),
    .BRESP   (MEM_BRESP)
);

// ═══════════════════════════════════════════════════════════════════════
// Test vectors  (single AES-128 key, 6 plaintext blocks)
// Key + all PT/CT pairs independently verified against PyCryptodome.
// ═══════════════════════════════════════════════════════════════════════
localparam [127:0] AES_KEY = 128'h2b7e151628aed2a6abf7158809cf4f3c;

localparam NUM_BLOCKS = 6;
reg [127:0] plaintext  [0:NUM_BLOCKS-1];
reg [127:0] expected_ct[0:NUM_BLOCKS-1];

initial begin
    plaintext[0]   = 128'h000102030405060708090a0b0c0d0e0f;
    expected_ct[0] = 128'h50fe67cc996d32b6da0937e99bafec60;

    plaintext[1]   = 128'h1112131415161718191a1b1c1d1ewrite_interfaceab26;

    plaintext[2]   = 128'h22232425262728292a2b2c2d2e2fwrite_interface3031;
    expected_ct[2] = 128'heb97ffb0f5a23cc59da8652cc2057b7b;

    plaintext[3]   = 128'h333435363738393a3b3c3d3e3f404142;
    expected_ct[3] = 128'h3b658250bf2c33c926aba739d8e09c6f;

    plaintext[4]   = 128'h4445464748494a4b4c4d4e4f50515253;
    expected_ct[4] = 128'h0605202d2ac4067a3513388043905a3c;

    plaintext[5]   = 128'h55565758595a5b5c5d5e5f6061626364;
    expected_ct[5] = 128'had1abdb2b71b114749e89a9bd9f2d819;
end

// Memory layout: read_controller steps addresses by 4 (byte-style stride)
// but memory_controller/mem index ram[] with the RAW address value
// (no >>2 shift). So word W of block B lives at ram index:
//      BASE_ADDR + 16*B + 4*W      (W = 0..3, W0 = MSB word of the block)
// We therefore must write the four 32-bit words of each plaintext block
// at addresses BASE+16B+0, +4, +8, +12 (word0=MSB ... word3=LSB), and the
// AES IP's START_ADDR/END_ADDR must use that same stride-of-4 addressing.
localparam [31:0] BASE_ADDR = 32'h0;
localparam [31:0] BLOCK_STRIDE = 32'd16;   // address gap between consecutive blocks
localparam [31:0] END_ADDR = BASE_ADDR + BLOCK_STRIDE * NUM_BLOCKS;

// ═══════════════════════════════════════════════════════════════════════
// Low-level AXI4-Lite master tasks driving memory_top directly
// (only valid while tb_mem_active = 1)
// ═══════════════════════════════════════════════════════════════════════
task automatic mem_write_word(input [31:0] addr, input [31:0] data);
begin
    @(posedge clk);
    tb_AWADDR  = addr;
    tb_AWVALID = 1'b1;
    tb_WDATA   = data;
    tb_WVALID  = 1'b1;
    tb_BREADY  = 1'b1;
    @(posedge clk);
    while (!(tb_AWREADY && tb_WREADY)) @(posedge clk);
    tb_AWVALID = 1'b0;
    tb_WVALID  = 1'b0;
    while (!tb_BVALID) @(posedge clk);
    @(posedge clk);
    tb_BREADY  = 1'b0;
end
endtask

task automatic mem_read_word(input [31:0] addr, output [31:0] data);
begin
    @(posedge clk);
    tb_ARADDR  = addr;
    tb_ARVALID = 1'b1;
    tb_RREADY  = 1'b1;
    @(posedge clk);
    while (!tb_ARREADY) @(posedge clk);
    tb_ARVALID = 1'b0;
    while (!tb_RVALID) @(posedge clk);
    data = tb_RDATA;
    @(posedge clk);
    tb_RREADY = 1'b0;
end
endtask

// ═══════════════════════════════════════════════════════════════════════
// Low-level AXI4-Lite master tasks driving aes_ip's S_CTRL register port
// ═══════════════════════════════════════════════════════════════════════
task automatic ctrl_write_reg(input [2:0] reg_idx, input [31:0] data);
begin
    @(posedge clk);
    S_CTRL_AWADDR  = {29'h0, reg_idx} + 32'h00010000; // base 0x00010000, word index via low 3 bits
    S_CTRL_AWVALID = 1'b1;
    S_CTRL_WDATA   = data;
    S_CTRL_WVALID  = 1'b1;
    S_CTRL_BREADY  = 1'b1;
    @(posedge clk);
    while (!(S_CTRL_AWREADY && S_CTRL_WREADY)) @(posedge clk);
    S_CTRL_AWVALID = 1'b0;
    S_CTRL_WVALID  = 1'b0;
    while (!S_CTRL_BVALID) @(posedge clk);
    @(posedge clk);
    S_CTRL_BREADY  = 1'b0;
end
endtask

task automatic ctrl_read_reg(input [2:0] reg_idx, output [31:0] data);
begin
    @(posedge clk);
    S_CTRL_ARADDR  = {29'h0, reg_idx} + 32'h00010000;
    S_CTRL_ARVALID = 1'b1;
    S_CTRL_RREADY  = 1'b1;
    @(posedge clk);
    while (!S_CTRL_ARREADY) @(posedge clk);
    S_CTRL_ARVALID = 1'b0;
    while (!S_CTRL_RVALID) @(posedge clk);
    data = S_CTRL_RDATA;
    @(posedge clk);
    S_CTRL_RREADY = 1'b0;
end
endtask

// Register map (from controller.v)
localparam REG_CTRL   = 3'd0;
localparam REG_STATUS = 3'd1;
localparam REG_START  = 3'd2;
localparam REG_END    = 3'd3;
localparam REG_KEY0   = 3'd4;
localparam REG_KEY1   = 3'd5;
localparam REG_KEY2   = 3'd6;
localparam REG_KEY3   = 3'd7;

localparam STATUS_IDLE  = 32'd0;
localparam STATUS_BUSY  = 32'd1;
localparam STATUS_ERROR = 32'd2;
localparam STATUS_DONE  = 32'd3;

// ═══════════════════════════════════════════════════════════════════════
// Main test sequence
// ═══════════════════════════════════════════════════════════════════════
integer b, w;
reg [31:0] word_val;
reg [31:0] rdback;
reg [127:0] got_ct [0:NUM_BLOCKS-1];
integer pass_count, fail_count;

// ═══════════════════════════════════════════════════════════════════════
// Optional debug tracing — set VERBOSE=1 (e.g. `+define+VERBOSE` or edit
// below) to dump cycle-by-cycle AXI/FIFO activity. Off by default so the
// pass/fail summary at the end is easy to read.
//
// KNOWN RTL HAZARD (see README / chat write-up for full analysis):
// read_controller.v's ar_idle state reloads req_addr <= start_address
// and re-arms next_state_1 = ar_run on EVERY cycle that `start` is still
// high and `full` is low -- it has no "already completed one pass"
// latch, only edge-detection via state, which collides with the fact
// that `start` is held high for the whole busy window (not pulsed).
// On long-enough back-to-back transfers, once the FIFO drains enough to
// look "not full" again after the legitimate pass finishes, the read
// side silently starts a SECOND pass over [start_address, end_address)
// before write_controller's `done` actually fires. In an in-place
// encrypt (write address == read address, as wired in this design),
// that second pass can re-read words the write side already overwrote
// with ciphertext, corrupting the tail end of the run. This testbench
// reproduces the hazard with 6 back-to-back blocks; it disappears with
// very small block counts because the FIFO simply never re-empties
// before `done`.
// ═══════════════════════════════════════════════════════════════════════
localparam VERBOSE = 0;

generate if (VERBOSE) begin : dbg
    always @(posedge clk) begin
        if (areset && (u_aes_ip.start || u_aes_ip.aes_done || u_aes_ip.aes_error))
            $display("[%0t] start=%b stall=%b done=%b error=%b STATUS=%0d",
                $time, u_aes_ip.start, u_aes_ip.stall, u_aes_ip.aes_done,
                u_aes_ip.aes_error, u_aes_ip.u_ctrl.regs[1]);
    end
    always @(posedge clk) begin
        if (areset && M_RD_ARVALID && M_RD_ARREADY)
            $display("[%0t] AES RD ARADDR=%0d", $time, M_RD_ARADDR);
        if (areset && u_aes_ip.valid_in)
            $display("[%0t] read_mem FIFO drain: plain_text=%h addr_in=%h",
                $time, u_aes_ip.plain_text, u_aes_ip.addr_in);
    end
end endgenerate

initial begin
    // ─── init ───
    areset         = 1'b0;   // assert reset (active-low)
    tb_mem_active  = 1'b1;   // testbench owns the memory bus first

    S_CTRL_ARADDR  = 0; S_CTRL_ARVALID = 0; S_CTRL_RREADY = 0;
    S_CTRL_AWADDR  = 0; S_CTRL_AWVALID = 0; S_CTRL_WDATA = 0; S_CTRL_WVALID = 0; S_CTRL_BREADY = 0;

    tb_ARADDR = 0; tb_ARVALID = 0; tb_RREADY = 0;
    tb_AWADDR = 0; tb_AWVALID = 0; tb_WDATA  = 0; tb_WVALID  = 0; tb_BREADY = 0;

    repeat (5) @(posedge clk);
    areset = 1'b1;            // release reset
    repeat (5) @(posedge clk);

    // ─── Step 1: fill memory with plaintext test vectors ───
    $display("=========================================================");
    $display(" STEP 1: Loading %0d plaintext blocks into memory_top", NUM_BLOCKS);
    $display("=========================================================");
    for (b = 0; b < NUM_BLOCKS; b = b + 1) begin
        for (w = 0; w < 4; w = w + 1) begin
            // word0 = MSB 32 bits of the 128-bit block ... word3 = LSB
            word_val = plaintext[b][127 - 32*w -: 32];
            mem_write_word(BASE_ADDR + BLOCK_STRIDE*b + 4*w, word_val);
        end
        $display("  Block %0d  PT = %h  written at addr 0x%08h..0x%08h",
                  b, plaintext[b], BASE_ADDR+BLOCK_STRIDE*b, BASE_ADDR+BLOCK_STRIDE*b+12);
    end

    // ─── Step 2: configure aes_ip registers ───
    $display("=========================================================");
    $display(" STEP 2: Configuring aes_ip (key / start / end addr)");
    $display("=========================================================");
    tb_mem_active = 1'b0;  // hand the memory bus over to aes_ip's master ports

    // Key word order per controller.v: static_key = {KEY3,KEY2,KEY1,KEY0}
    // i.e. KEY3 = MSB 32 bits of the 128-bit key, KEY0 = LSB 32 bits.
    ctrl_write_reg(REG_KEY0, AES_KEY[31:0]);
    ctrl_write_reg(REG_KEY1, AES_KEY[63:32]);
    ctrl_write_reg(REG_KEY2, AES_KEY[95:64]);
    ctrl_write_reg(REG_KEY3, AES_KEY[127:96]);
    ctrl_write_reg(REG_START, BASE_ADDR);
    ctrl_write_reg(REG_END,   END_ADDR);

    $display("  KEY        = %h", AES_KEY);
    $display("  START_ADDR = 0x%08h", BASE_ADDR);
    $display("  END_ADDR   = 0x%08h", END_ADDR);

    // ─── Step 3: kick off the run ───
    $display("=========================================================");
    $display(" STEP 3: Starting AES IP (CTRL.start = 1)");
    $display("=========================================================");
    ctrl_write_reg(REG_CTRL, 32'h1);

    // ─── Step 4: wait for completion ───
    // NOTE: controller.v's STATUS register only holds the DONE value for
    // ONE clock cycle before auto-clearing back to IDLE (see controller.v
    // lines 69-71). An AXI-Lite register *read* transaction takes several
    // clock cycles to complete, so polling STATUS over the bus can race
    // past that single-cycle DONE pulse and hang forever. We therefore
    // wait on the internal aes_done/aes_error pulse directly (the same
    // pulse that drives the STATUS register), which is both faster and
    // immune to that race. We still do one confirming bus read afterward
    // to show STATUS from the CPU's point of view.
    fork : wait_done
        begin
            @(posedge u_aes_ip.aes_done);
            disable wait_done;
        end
        begin
            @(posedge u_aes_ip.aes_error);
            $display("!!! AES IP reported ERROR pulse — aborting test.");
            $finish;
        end
    join_any
    $display("  AES IP DONE pulse observed at time %0t", $time);
    @(posedge clk); // let STATUS settle back to idle, matching real RTL behavior

    // ─── Step 5: read back ciphertext from memory and compare ───
    $display("=========================================================");
    $display(" STEP 4: Reading back ciphertext & comparing");
    $display("=========================================================");
    tb_mem_active = 1'b1;  // take the memory bus back for readback
    repeat (3) @(posedge clk);

    pass_count = 0;
    fail_count = 0;

    for (b = 0; b < NUM_BLOCKS; b = b + 1) begin
        for (w = 0; w < 4; w = w + 1) begin
            mem_read_word(BASE_ADDR + BLOCK_STRIDE*b + 4*w, word_val);
            got_ct[b][127 - 32*w -: 32] = word_val;
        end

        if (got_ct[b] === expected_ct[b]) begin
            pass_count = pass_count + 1;
            $display("  Block %0d  PASS", b);
        end else begin
            fail_count = fail_count + 1;
            $display("  Block %0d  FAIL", b);
        end
        $display("           Plaintext : %h", plaintext[b]);
        $display("           Expected  : %h", expected_ct[b]);
        $display("           Got       : %h", got_ct[b]);
    end

    $display("=========================================================");
    $display(" RESULT: %0d / %0d blocks PASSED", pass_count, NUM_BLOCKS);
    if (fail_count == 0)
        $display(" *** ALL TEST VECTORS PASSED ***");
    else
        $display(" *** %0d TEST VECTOR(S) FAILED ***", fail_count);
    $display("=========================================================");

    $finish;
end

// Safety watchdog
initial begin
    #200000;
    $display("!!! WATCHDOG TIMEOUT — simulation did not finish in time.");
    $finish;
end

endmodule
