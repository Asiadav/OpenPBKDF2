// hmac_sha256_tb.v
//
// This file contains the toplevel testbench for testing
// this design. 
//

module hmac_sha256_tb;

  /* Dump Test Waveform To VPD File */
  initial begin
    $fsdbDumpfile("waveform.fsdb");
    $fsdbDumpvars();
  end

  /* Non-synth clock generator */
  logic clk;
  bsg_nonsynth_clock_gen #(10000) clk_gen_1 (clk);

  /* Non-synth reset generator */
  logic reset;
  bsg_nonsynth_reset_gen #(.num_clocks_p(1),.reset_cycles_lo_p(5),. reset_cycles_hi_p(5))
    reset_gen
      (.clk_i        ( clk )
      ,.async_reset_o( reset )
      );


  logic tr_v_lo;
  logic [9:0] tr_data_lo;
  logic tr_ready_lo;
  logic tr_yumi_li;
  logic tr_yumi_lo;

  logic [31:0] rom_addr_li;
  logic [13:0] rom_data_lo;

  logic dut_v_r;
  logic dut_data_lo;
  logic [7:0] data_li;
  logic en_li, update_li, update_val_li;

  bsg_fsb_node_trace_replay #(.ring_width_p(10)
                             ,.rom_addr_width_p(32) )
    trace_replay
      ( .clk_i ( ~clk )
      , .reset_i( reset )
      , .en_i( 1'b1 )

      , .v_i    ( dut_v_r )
      , .data_i ( {9'b0, dut_data_lo} )
      , .ready_o( tr_ready_lo )

      , .v_o   ( tr_v_lo )
      , .data_o( tr_data_lo )
      , .yumi_i( tr_yumi_li )

      , .rom_addr_o( rom_addr_li )
      , .rom_data_i( rom_data_lo )

      , .done_o()
      , .error_o()
      );

  trace_rom #(.width_p(14),.addr_width_p(32))
    ROM
      (.addr_i( rom_addr_li )
      ,.data_o( rom_data_lo )
      );

//   bsg_cgol_cell DUT
//     (.clk_i        (           clk )

//     ,.data_i       (       data_li )
//     ,.en_i         (         en_li )
//     ,.update_i     (     update_li )
//     ,.update_val_i ( update_val_li )

//     ,.data_o       (   dut_data_lo )
//     );

  // input handshake for DUT, it can consume new data in each cycle
  assign en_li = tr_v_lo & tr_data_lo[9];
  assign update_li = tr_v_lo & (~tr_data_lo[9]);
  assign update_val_li = tr_data_lo[8];
  assign data_li = tr_data_lo[7:0];
  assign tr_yumi_li = tr_v_lo; 

  // output handshake for DUT, valid then yumi
  always_ff @(posedge clk) begin
    if (reset) begin
      dut_v_r <= 0;
    end
    else begin
      if (tr_v_lo)
        dut_v_r <= 1;
      else if (tr_yumi_lo)
        dut_v_r <= 0;
    end
  end
  
  // trace_replay yumi
  always_ff @(negedge clk) begin
    tr_yumi_lo <= tr_ready_lo & dut_v_r;
  end

endmodule
