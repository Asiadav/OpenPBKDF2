module bsg_cgol #(
   parameter `BSG_INV_PARAM(board_width_p)
  ,parameter `BSG_INV_PARAM(max_game_length_p)
  ,localparam num_total_cells_lp = board_width_p*board_width_p
  ,localparam game_length_width_lp=`BSG_SAFE_CLOG2(max_game_length_p+1)
                 )
  (input  logic clk_i
  ,input  logic reset_i
  ,input  logic en_i

  ,input  logic [63:0] data_i
  ,input  logic v_i
  ,output logic ready_o

  ,output logic [63:0] data_o
  ,output logic v_o
  ,input  logic yumi_i
);

  logic [num_total_cells_lp-1:0] cells_init_val, cells_last_val;
  logic [game_length_width_lp-1:0] frames_lo;

  logic input_channel_v;
  logic ctrl_rd, ctrl_v;
  logic update_lo, en_lo;
  logic output_channel_yumi;

  bsg_cgol_ctrl #(
    .max_game_length_p(max_game_length_p)
  ) ctrl (
     .clk_i    (clk_i)
    ,.reset_i  (reset_i)
    ,.en_i     (en_i)
    ,.frames_i (frames_lo)
    ,.v_i      (input_channel_v)
    ,.ready_o  (ctrl_rd)
    ,.v_o      (ctrl_v)
    ,.yumi_i   (output_channel_yumi)
    ,.update_o (update_lo)
    ,.en_o     (en_lo)
  );

  bsg_cgol_input_data_channel #(
     .board_width_p(board_width_p)
    ,.max_game_length_p(max_game_length_p)
  ) input_channel (
     .clk_i    (clk_i)
    ,.reset_i  (reset_i)
    ,.data_i   (data_i)
    ,.v_i      (v_i)
    ,.ready_o  (ready_o)
    ,.data_o   (cells_init_val)
    ,.frames_o (frames_lo)
    ,.v_o      (input_channel_v)
    ,.ready_i  (ctrl_rd)
  );

  bsg_cgol_cell_array #(
    .board_width_p(board_width_p)
  ) cell_array (
     .clk_i    (clk_i)
    ,.data_i   (cells_init_val)
    ,.en_i     (en_lo)
    ,.update_i (update_lo)
    ,.data_o   (cells_last_val)
  );
  
  bsg_cgol_output_data_channel #(
     .board_width_p(board_width_p)
  ) output_channel (
     .clk_i   (clk_i)
    ,.reset_i (reset_i)
    ,.data_i  (cells_last_val)
    ,.v_i     (ctrl_v)
    ,.yumi_o  (output_channel_yumi)
    ,.data_o  (data_o)
    ,.v_o     (v_o)
    ,.yumi_i  (yumi_i)
  );

  
endmodule
