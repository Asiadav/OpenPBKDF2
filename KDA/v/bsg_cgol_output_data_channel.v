module bsg_cgol_output_data_channel #(
   parameter `BSG_INV_PARAM(board_width_p)
  ,localparam num_total_cells_lp = board_width_p*board_width_p
) (
     input clk_i
    ,input reset_i

    ,input [num_total_cells_lp-1:0]    data_i 
    ,input                             v_i
    ,output                            yumi_o

    ,output [63:0]                     data_o
    ,output                            v_o
    ,input                             yumi_i
  );

  if (num_total_cells_lp >= 64) begin
    localparam piso_els_lp = `BSG_CDIV(num_total_cells_lp, 64);

    logic [piso_els_lp*64-1:0] data_piso;
    logic ready_lo;

    assign data_piso = {{(piso_els_lp*64-num_total_cells_lp){1'b0}}, data_i};
    
    bsg_parallel_in_serial_out #(
       .width_p(64)
      ,.els_p (piso_els_lp)
    ) piso (
       .clk_i       (clk_i)
      ,.reset_i     (reset_i)

      ,.valid_i     (v_i)
      ,.data_i      (data_piso)
      ,.ready_and_o (ready_lo)

      ,.valid_o     (v_o)
      ,.data_o      (data_o)
      ,.yumi_i      (yumi_i)
    );

    assign yumi_o = v_i & ready_lo;
  end
  else begin
    assign data_o = {{(64-num_total_cells_lp){1'b0}}, data_i};
    assign v_o = v_i;
    assign yumi_o = yumi_i;
  end

endmodule

