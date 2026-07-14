# aes128-axi-accelerator
**Architecture, memory mapping & slave memory design**

## Overview

This project implements a complete AES-128 encryption accelerator integrated with AXI4-Lite interfaces. The design operates as a hardware slave peripheral accessible by a CPU through standard AXI4-Lite register reads and writes. Internally, it maintains a 10-stage pipelined datapath that processes 128-bit plaintext blocks through all AES encryption rounds, while dedicated memory controllers manage bulk plaintext reads from external memory and bulk ciphertext writes back. The accelerator demonstrates how to cleanly separate control (register interface), data transformation (crypto pipeline), and memory subsystem concerns in a reusable IP block.

## High-Level Architecture

The accelerator consists of four main functional domains:

**Control Domain**
Handles CPU-facing AXI4-Lite register operations. The `controller_interface` manages read/write transactions on the CPU-facing AXI port, decoding addresses and forwarding register read/write requests to the internal controller, which maintains the register file and generates start/stop signals and configuration values (encryption key, memory boundaries).

**Key Expansion Domain**
Precomputes all ten 128-bit round keys from the user-supplied static AES-128 key. The `key_scheduler` module expands the 128-bit master key into eleven 128-bit round keys (including the original key as `round_key_0`) using the standard AES key schedule algorithm with S-box lookups. All round keys are made available combinationally to the datapath, eliminating latency during encryption.

**Memory Domain**
Manages bulk data transactions with external memory via two independent paths: the read controller reads plaintext blocks from external memory starting at `start_address` up to `end_address`, storing 32-bit words into the `read_mem` FIFO; the write controller reads encrypted blocks from the `write_mem` FIFO and writes them back to external memory at the corresponding addresses.

**Encryption Domain (Datapath)**
A 10-stage pipeline that processes plaintext through the AES-128 algorithm. Each stage implements one complete AES round (SubBytes, ShiftRows, MixColumns, AddRoundKey); the final stage omits MixColumns per the AES standard. `valid_in`/`valid_out` signals handshake data into and out of the pipeline, enabling smooth stalling when memory buffers are full.

## Slave Memory: Register Map & Addressing

The accelerator exposes an 8-register control interface to the CPU via a 3-bit address bus (`3'h0`–`3'h7`). Each register is 32 bits wide.

| Register | Address | R/W | Purpose | Remarks |
|---|---|---|---|---|
| `CTRL` | `3'h0` | RW | Control & Start | Bit [0]: START. Writing 1 initiates encryption. |
| `STATUS` | `3'h1` | RO | Status | 0=IDLE, 1=BUSY, 2=ERROR, 3=DONE. Transitions automatically. |
| `START_ADDR` | `3'h2` | RW | Start Address | 32-bit base address for plaintext reads in external memory. |
| `END_ADDR` | `3'h3` | RW | End Address | 32-bit end address (exclusive) for plaintext reads. |
| `KEY[0]` | `3'h4` | RW | AES Key Word 0 | Bits [31:0] of the 128-bit key. `KEY = {KEY[3],KEY[2],KEY[1],KEY[0]}`. |
| `KEY[1]` | `3'h5` | RW | AES Key Word 1 | Bits [63:32] of the 128-bit key. |
| `KEY[2]` | `3'h6` | RW | AES Key Word 2 | Bits [95:64] of the 128-bit key. |
| `KEY[3]` | `3'h7` | RW | AES Key Word 3 | Bits [127:96] of the 128-bit key. |

### Write Constraints & State Machine

The controller implements a state machine to protect against race conditions — registers cannot be written arbitrarily at any time:

- **CTRL (`3'h0`)** — Can only be written when `STATUS` is `IDLE`. Once the START bit is written, `STATUS` transitions to `BUSY`; START is automatically cleared on completion (`DONE` or `ERROR`). Writes during `BUSY` have no effect.
- **STATUS (`3'h1`)** — Read-only. The controller manages transitions internally: `IDLE → BUSY → (DONE or ERROR) → IDLE`.
- **KEY[0–3] (`3'h4`–`3'h7`)** — Should be written before initiating encryption. Once START is asserted, keys are latched and used immediately; writing new keys during `BUSY` does not affect the ongoing encryption.

### Typical Software Usage Flow

1. **Configure addresses** — Write the plaintext base address to `START_ADDR` and the (exclusive) end address to `END_ADDR`.
2. **Load the key** — Write four 32-bit words to `KEY[0]`–`KEY[3]` to set the 128-bit AES key (little-endian: `KEY[0]` is the LSB, `KEY[3]` is the MSB).
3. **Start encryption** — Write any value (typically `1`) to `CTRL` bit [0]. `STATUS` immediately transitions to `BUSY`.
4. **Poll for completion** — Poll `STATUS` until it's no longer `BUSY`. `DONE` (3) indicates success; `ERROR` (2) indicates a memory access error.
5. **Retrieve ciphertext** — Encrypted blocks are written back to external memory starting at `start_address`; read results from the same addresses.

## Slave Memory System Design

The accelerator features a dual-FIFO architecture for memory buffering, decoupling memory latency from encryption throughput: plaintext blocks are read and queued for processing, then processed results are drained back to memory asynchronously.

### Read Memory (Input FIFO)

- **Purpose** — Buffers plaintext blocks fetched from external memory before entering the encryption pipeline.
- **Architecture** — A 4-entry circular FIFO with dual-pointer logic (`write_ptr`, `read_ptr`). Each entry is 64 bits: upper 32 bits store the block address, lower 32 bits store the data word. 3-bit pointers allow wrap-around detection for full/empty states.
- **Full/Empty flags** — Empty when `read_ptr == write_ptr`; full when the low 2 bits of the pointers match but the MSB differs (indicating wrap-around).
- **Write port (from `read_controller`)** — Writes 32-bit words and source addresses; each write increments `write_ptr`. The FIFO stalls the `read_controller` when full.
- **Read port (to pipeline)** — Once 4 entries are present, outputs a combined 128-bit plaintext block and 128-bit address block, asserting `valid_in`. `read_ptr` increments by 4, draining all entries in one transaction.

### Write Memory (Output FIFO)

- **Purpose** — Buffers encrypted blocks from the pipeline before they're sent back to external memory.
- **Architecture** — Identical 4-entry circular FIFO structure and full/empty logic to the read FIFO.
- **Write port (from pipeline)** — Writes a 128-bit ciphertext block and address block when `valid_out` is high, filling all 4 entries at once and incrementing `write_ptr` by 4. Stalls the pipeline when empty.
- **Read port (to `write_controller`)** — Reads one 32-bit word and address at a time via `rd_en`, incrementing `read_ptr` by 1 — allowing interleaved, fine-grained AXI writes without waiting for the full 128-bit result.

**Asymmetry by design:** the read side drains all 4 words at once (128-bit granularity for the pipeline), while the write side feeds words individually (32-bit granularity for AXI compatibility), enabling fine-grained write pipelining.

### Stall Mechanism & Flow Control

The `write_controller` asserts a global stall signal when either FIFO reaches a critical state, synchronizing all domains (`key_scheduler`, datapath, `read_controller`, `read_mem`, `write_mem`):

- **Read-side stall** — When `read_mem` is full, the read controller can't fetch more plaintext; stall halts the pipeline and key scheduler, giving the write controller time to drain results.
- **Write-side stall** — When `write_mem` is empty (or near-underflow), the pipeline can't output results; stall halts the pipeline and read controller, preventing deadlock from a full read buffer with no room to deposit results.

Under normal operation the pipeline runs stall-free; slow external memory backs up `read_mem` (triggering read-side stall), while a slow write window backs up `write_mem` (triggering write-side stall).

## Data Flow Through the System

1. **CPU issues START** — Writes `CTRL` (`3'h0`) with the START bit set; controller transitions to `BUSY`.
2. **Read controller fetches plaintext** — Issues AXI4-Lite read transactions from `start_address`; each handshake brings one 32-bit word into `read_mem`.
3. **Read memory buffers & packs** — After 4 words arrive, `read_mem` combines them into a 128-bit plaintext + address block and asserts `valid_in` into the pipeline.
4. **Pipeline processes the block** — Plaintext enters stage 0 (`AddRoundKey` with `round_key_0`), progresses through stages 1–9 (full AES rounds), then stage 10 (final round, no `MixColumns`). Data and address propagate through all stages via latches.
5. **Result enters write memory** — After 10 cycles, ciphertext emerges with `valid_out` high; `write_mem` captures the block and address across 4 FIFO entries.
6. **Write controller drains & transmits** — Reads one 32-bit word at a time from `write_mem` and performs an AXI4-Lite write transaction to the corresponding external memory address.
7. **Completion & status** — Once the last ciphertext block is written, `done` is asserted, `STATUS` transitions to `DONE`, and the CPU polls `STATUS` to confirm completion.

## Encryption Pipeline Architecture

A 10-stage pipeline implementing the AES-128 algorithm, one complete round per stage (the final stage omits `MixColumns`):

- **Initial round (Stage 0)** — `AddRoundKey` with `round_key_0`: plaintext XORed with the first round key.
- **Main rounds (Stages 1–9)** — `SubBytes` (byte-wise S-box substitution), `ShiftRows` (row-wise cyclic shifts), `MixColumns` (column-wise linear transform over GF(2⁸)), `AddRoundKey` (XOR with the corresponding round key). The S-box is implemented as a lookup table for fast hardware execution.
- **Final round (Stage 10)** — `SubBytes`, `ShiftRows`, `AddRoundKey` with `round_key_10` (no `MixColumns`), producing the 128-bit ciphertext.

### Key Expansion & Precomputation

The `key_scheduler` precomputes all 11 round keys (`round_key_0`–`round_key_10`) from the master key using the AES key schedule, combinationally and in parallel — all round keys are available immediately, with no sequential wait. Round 0 uses `round_key_0` (the master key), rounds 1–9 use `round_key_1`–`round_key_9`, and round 10 uses `round_key_10`. Precomputation avoids latency stalls waiting for key generation, letting the pipeline process a new block every 10 clock cycles.

### Pipeline Latches & Address Tracking

All 10 latches propagate the encrypted data alongside the address of the plaintext block, since the write controller must know where to write each ciphertext result. Each latch tracks:

- 128-bit data (plaintext → intermediate states → ciphertext)
- 128-bit address (passed through unchanged)
- 1-bit valid signal (`valid_in` at stage 0, `valid_out` at stage 10, intermediate valid bits in between)

When the global stall signal is asserted, all latches — including valid signals — freeze simultaneously, ensuring data consistency and preventing loss or corruption.

## Memory Controllers & AXI Transactions

### Read Controller (Plaintext Fetcher)

Orchestrates AXI4-Lite read transactions to fetch plaintext and queue it into `read_mem`, using two independent state machines:

**AR (Address Read) state machine** — manages the address phase:
- Starts in `ar_idle`; on START, transitions to `ar_run`.
- In `ar_run`, issues `ARVALID` every clock (if `ARREADY` is high, `read_mem` isn't full, and not stalled).
- Increments `req_addr` by 4 bytes after each successful transaction.
- Returns to `ar_idle` when `req_addr >= end_address`.

**R (Data Read) state machine** — manages the data phase:
- Starts in `r_idle`; on START, transitions to `r_run`.
- In `r_run`, sets `RREADY` high (if `read_mem` isn't full and not stalled).
- On `RVALID` (with `RREADY` high), captures `RDATA` and writes to `read_mem`.
- Returns to `r_idle` when `resp_addr >= end_address`.

The two state machines run independently, so address requests can pipeline ahead of data arrival — a feature of AXI4-Lite that improves throughput. Only `OKAY` (`2'b00`) read responses are written to the FIFO; other responses are treated as errors.

### Write Controller (Ciphertext Writer)

Orchestrates AXI4-Lite write transactions to drain `write_mem` back to external memory, using a single unified state machine:

- Starts in `aw_idle`; on START, transitions to `aw_run`.
- In `aw_idle` — sets `rd_en` high to read an entry from `write_mem` (if not empty) and raises both `AWVALID` and `WVALID`.
- In `aw_run` — monitors both the AW and W channels; both must complete (`aw_done && w_done`) for a full transaction.
- On success — reads the next `write_mem` entry (if not empty) and continues.
- Asserts stall to the rest of the system if either channel isn't ready, preventing pipeline overflow.
- Returns to `aw_idle` once `write_mem` is empty and `done` is asserted.

If external memory is slow to accept writes, the write controller stalls the entire system, preventing `read_mem` from filling with unprocessable data. `BRESP` is monitored for errors — any non-`OKAY` response sets `STATUS` to `ERROR`.

## Performance & Throughput Analysis

- **Pipeline latency** — Exactly 10 clock cycles from `valid_in` at stage 0 to `valid_out` at stage 10.
- **Throughput** — Under ideal conditions, one 128-bit block every 10 cycles (0.1 blocks/cycle), roughly **12.8 Gbps** at a typical 400 MHz implementation frequency.
- **Stall impact** — Slow external memory (read/write latency > 10 cycles) eventually fills or empties the FIFOs, triggering system-wide stalls that throttle throughput to match memory bandwidth.
- **FIFO sizing** — 4-entry FIFOs balance area against tolerance for memory latency; larger FIFOs would improve latency tolerance at the cost of area and complexity.

## Design Decisions & Trade-offs

- **Precomputed round keys** — Computed combinationally at startup; trades silicon area (11 × 128-bit copies) for eliminated key-scheduling latency. On-the-fly computation would suit resource-constrained designs better.
- **10-stage unrolled pipeline** — All AES rounds unrolled into separate stages, trading high area (10× SubBytes/ShiftRows/MixColumns) for high throughput. A single repeated round stage would use ~1/10 the area at 1/10 the throughput.
- **Dual-port FIFOs** — Asymmetric granularity (32-bit write, 128-bit read on `read_mem`) enables fine-grained external memory control at the cost of more careful FIFO logic versus a simpler symmetric design.
- **Global stall signal** — One signal halts all domains — simple but coarse-grained versus per-module local back-pressure, which the design deems unnecessary for correctness.
- **Sequential memory addressing** — Contiguous word addressing from `start_address` to `end_address` is simple but inflexible compared to scatter/gather addressing.
- **Synchronous control** — All control signals sampled on clock edges for deterministic behavior, at some latency cost versus asynchronous signaling.

## Integration & Verification Approach

The accelerator integrates into a larger SoC with standard AXI4-Lite interfaces (slave for control, master for memory), compatible with common open-source and commercial interconnects.

**Testbench strategy** — Simulation uses a 10-entry NIST test vector suite with known plaintext-ciphertext pairs, exercising the full pipeline from CPU register writes through memory transactions. It verifies:
- Correct ciphertext output for known plaintext/key
- Proper status transitions (`IDLE → BUSY → DONE`)
- Correct handling of start/end addresses
- FIFO full/empty logic under various timing scenarios
- Error responses from memory (simulated via `BRESP` injection)

**Synthesis considerations** — The design synthesizes cleanly to standard-cell libraries. Precomputed round keys and S-box lookup tables are the main area contributors; clock frequency is typically limited by pipeline stage logic depth (SubBytes, ShiftRows, MixColumns, AddRoundKey). Timing analysis should focus on the datapath critical path and FIFO pointer comparison logic.

## Future Enhancements & Variants

- Support for AES-192 and AES-256 via extended key size and additional rounds
- Configurable block modes (GCM, CTR) instead of ECB
- Decryption path (`InvShiftRows`, `InvSubBytes`, `InvMixColumns`) for bidirectional operation
- Scatter/gather addressing for non-contiguous memory regions
- Burst support (AXI4 instead of AXI4-Lite) for higher memory bandwidth
- Interrupt generation on completion (instead of polling `STATUS`)
- Hardware reset and key revocation features for security
- TRNG integration for IV generation in modes like CBC or CTR

## Summary: Key Takeaways

1. **Clean separation of concerns** — Control, key management, data transformation, and memory management are logically separated into independent modules.
2. **Efficient pipelined execution** — An unrolled 10-stage pipeline delivers one block per 10 cycles, with precomputed round keys eliminating scheduling latency.
3. **Intelligent memory buffering** — Asymmetric dual-FIFO architecture balances area, latency, and flexibility, with global stall signals providing flow control without complex per-module handshakes.
4. **Standard interface compliance** — AXI4-Lite master and slave ports make the accelerator compatible with standard SoC integration flows.
5. **Practical trade-offs** — Every design choice (precomputation vs. on-the-fly, unrolled vs. iterated pipeline, FIFO sizing, stall granularity) reflects a deliberate, defensible trade-off between performance, area, and complexity for the target use case (edge encryption, embedded systems).

---
*For implementation details and register-level traces, refer to the individual module source files and testbench. This document provides the architectural blueprint; the code offers granular verification and simulation artifacts.*
