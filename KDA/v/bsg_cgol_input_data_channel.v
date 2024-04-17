module bsg_cgol_input_data_channel #(
   parameter `BSG_INV_PARAM(board_width_p)
  ,parameter `BSG_INV_PARAM(max_game_length_p)
  ,localparam num_total_cells_lp = board_width_p*board_width_p
  ,localparam game_length_width_lp=`BSG_SAFE_CLOG2(max_game_length_p+1)
) (
     input clk_i
    ,input reset_i

    ,input [63:0]                      data_i 
    ,input                             v_i
    ,output                            ready_o

    ,output [num_total_cells_lp-1:0]   data_o
    ,output [game_length_width_lp-1:0] frames_o
    ,output                            v_o
    ,input                             ready_i
  );

  if ((num_total_cells_lp+game_length_width_lp) >= 64) begin
    localparam sipo_els_lp = `BSG_CDIV(num_total_cells_lp+game_length_width_lp, 64);

    logic [sipo_els_lp-1:0] valid_lo;
    logic [sipo_els_lp*64-1:0] data_sipo;
    logic [$clog2(sipo_els_lp+1)-1:0] yumi_cnt;
    
    bsg_serial_in_parallel_out #(
       .width_p(64)
      ,.els_p (sipo_els_lp)
    ) sipo (
       .clk_i      (clk_i)
      ,.reset_i    (reset_i)
      ,.valid_i    (v_i)
      ,.data_i     (data_i)
      ,.ready_o    (ready_o)

      ,.valid_o    (valid_lo)
      ,.data_o     (data_sipo)

      ,.yumi_cnt_i (yumi_cnt)
    );

    assign frames_o = data_sipo[game_length_width_lp-1:0];
    assign data_o   = data_sipo[game_length_width_lp+:num_total_cells_lp];

    // Wait until we get all the data
    logic sipo_yumi;
    assign v_o = &valid_lo;
    assign sipo_yumi = ready_i & v_o;
    assign yumi_cnt = sipo_yumi? sipo_els_lp : '0;

  end
  else begin
    assign v_o = v_i;
    assign ready_o = ready_i;
    assign data_o = data_i[game_length_width_lp+:num_total_cells_lp];
    assign frames_o = data_i[game_length_width_lp-1:0];
  end

endmodule
