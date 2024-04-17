// instantiates the bsg_nonsynth_manycore_io_complex
// connected to the fsb via a bsg_manycore_links_to_fsb
//

`include "bsg_manycore_packet.vh"

module bsg_manycore_master_node

    import bsg_fsb_pkg::*;
    import bsg_manycore_1x1_pkg::*;

 #(parameter ring_width_p = "inv"
  ,parameter master_id_p  = "inv"
  ,parameter client_id_p  = "inv"
  )

  (input  clk_i
  ,input  reset_i
  ,input  en_i
  
  ,input                     v_i
  ,input  [ring_width_p-1:0] data_i
  ,output                    ready_o
  
  ,output                    v_o
  ,output [ring_width_p-1:0] data_o
  ,input                     yumi_i
  );

    localparam bank_size_lp       = bsg_manycore_1x1_pkg::bank_size_gp;
    localparam bank_num_lp        = bsg_manycore_1x1_pkg::bank_num_gp;
    localparam addr_width_lp      = bsg_manycore_1x1_pkg::addr_width_gp;
    localparam data_width_lp      = bsg_manycore_1x1_pkg::data_width_gp;
    localparam hetero_type_vec_lp = bsg_manycore_1x1_pkg::hetero_type_vec_gp;
    localparam remote_credits_lp  = bsg_manycore_1x1_pkg::fsb_remote_credits_gp;

    localparam num_tiles_y_lp     = bsg_manycore_1x1_pkg::num_tiles_y_gp;
    localparam num_tiles_x_lp     = bsg_manycore_1x1_pkg::num_tiles_x_gp;

    localparam tile_id_ptr_lp     = bsg_manycore_1x1_pkg::tile_id_ptr_gp;
    localparam max_cycles_lp      = bsg_manycore_1x1_pkg::max_cycles_gp;
    localparam mem_size_lp        = bsg_manycore_1x1_pkg::mem_size_gp;

    localparam dest_id_lp         = master_id_p;
    localparam x_cord_width_lp    = `BSG_SAFE_CLOG2(num_tiles_x_lp);
    localparam y_cord_width_lp    = `BSG_SAFE_CLOG2(num_tiles_y_lp+1); // extra row for i/o

    `declare_bsg_manycore_link_sif_s(addr_width_lp,data_width_lp,x_cord_width_lp,y_cord_width_lp);

    bsg_manycore_link_sif_s [num_tiles_x_lp-1:0] ver_link_sif_li;
    bsg_manycore_link_sif_s [num_tiles_x_lp-1:0] ver_link_sif_lo;
    logic finish_lo, success_lo, timeout_lo;
    
    localparam trace_width_lp = ring_width_p - 4;
    localparam rom_addr_width_lp = 32;
    localparam rom_data_width_lp = 4 + trace_width_lp;

    logic [rom_addr_width_lp-1:0] rom_addr_li;
    logic [rom_data_width_lp-1:0] rom_data_lo;


    logic [trace_width_lp-1:0] tr_data_lo;
    logic                      tr_v_lo;

    logic [ring_width_p-1:0] mc_data_lo;
    logic                     mc_v_lo;

    logic tr_booted_lo;

    assign v_o = tr_booted_lo ? mc_v_lo : tr_v_lo;
    assign data_o = tr_booted_lo ? mc_data_lo : {(4)'(master_id_p), tr_data_lo};

    bsg_manycore_boot_node_rom #(.width_p(rom_data_width_lp)
                                ,.addr_width_p(rom_addr_width_lp))
      boot_node_rom
        (.addr_i(rom_addr_li)
        ,.data_o(rom_data_lo));
    
    bsg_fsb_node_trace_replay #( .ring_width_p(trace_width_lp), .rom_addr_width_p(rom_addr_width_lp) )
      trace_replay
        (.clk_i      (clk_i)
        ,.reset_i    (reset_i)
        ,.en_i       (en_i)
 
        ,.rom_addr_o (rom_addr_li)
        ,.rom_data_i (rom_data_lo)
 
        ,.v_i        ()
        ,.data_i     ()
        ,.ready_o    ()
 
        ,.v_o        (tr_v_lo)
        ,.data_o     (tr_data_lo)
        ,.yumi_i     (yumi_i)
 
        ,.done_o     (tr_booted_lo)
        ,.error_o    ()
        );


    bsg_nonsynth_manycore_io_complex #( .mem_size_p    (mem_size_lp   )
                                      , .max_cycles_p  (max_cycles_lp )
                                      , .addr_width_p  (addr_width_lp )
                                      , .data_width_p  (data_width_lp )
                                      , .num_tiles_x_p (num_tiles_x_lp)
                                      , .num_tiles_y_p (num_tiles_y_lp)
                                      , .tile_id_ptr_p (tile_id_ptr_lp) )
      io_complex
        ( .clk_i   (clk_i)
        , .reset_i (reset_i | ~tr_booted_lo)

        , .ver_link_sif_i (ver_link_sif_li)
        , .ver_link_sif_o (ver_link_sif_lo)

        , .finish_lo  (finish_lo)
        , .success_lo (success_lo)
        , .timeout_lo (timeout_lo) );



    bsg_manycore_links_to_fsb #( .ring_width_p     (ring_width_p     )
                               , .dest_id_p        (dest_id_lp       )
                               , .num_links_p      (num_tiles_x_lp   )
                               , .addr_width_p     (addr_width_lp    )
                               , .data_width_p     (data_width_lp    )
                               , .x_cord_width_p   (x_cord_width_lp  )
                               , .y_cord_width_p   (y_cord_width_lp  )
                               , .remote_credits_p (remote_credits_lp) )
      l2f
        ( .clk_i   (clk_i)
        , .reset_i (reset_i | ~tr_booted_lo)

        , .links_sif_i (ver_link_sif_lo)
        , .links_sif_o (ver_link_sif_li)

        , .v_i     (v_i)
        , .data_i  (data_i)
        , .ready_o (ready_o)

        , .v_o    (mc_v_lo)
        , .data_o (mc_data_lo)
        , .yumi_i (yumi_i) );

endmodule

