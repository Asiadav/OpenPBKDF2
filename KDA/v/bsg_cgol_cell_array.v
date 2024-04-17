module bsg_cgol_cell_array #(
   parameter `BSG_INV_PARAM(board_width_p)
  ,localparam num_total_cells_lp = board_width_p*board_width_p
)
  (input clk_i

  ,input [num_total_cells_lp-1:0] data_i
  ,input en_i
  ,input update_i

  ,output logic [num_total_cells_lp-1:0] data_o
  );

  logic [0:board_width_p+1][0:board_width_p+1] cells_n; // One per cell, plus a boundary on all edges

  // Top boundary
  assign cells_n[0] = '0;

  // Cell Array
  for (genvar row_idx=0; row_idx<board_width_p; row_idx++) begin : gen_rows
    // Left boundary
    assign cells_n[row_idx+1][0] = 1'b0;

    for (genvar col_idx=0; col_idx<board_width_p; col_idx++) begin : gen_cols
      logic [7:0] nghs;
      assign nghs[0] = cells_n[row_idx+1-1][col_idx+1  ]; // Above
      assign nghs[1] = cells_n[row_idx+1-1][col_idx+1-1]; // Above Left
      assign nghs[2] = cells_n[row_idx+1-1][col_idx+1+1]; // Above Right
      assign nghs[3] = cells_n[row_idx+1  ][col_idx+1-1]; // Left
      assign nghs[4] = cells_n[row_idx+1  ][col_idx+1+1]; // Right
      assign nghs[5] = cells_n[row_idx+1+1][col_idx+1-1]; // Below Left
      assign nghs[6] = cells_n[row_idx+1+1][col_idx+1  ]; // Below
      assign nghs[7] = cells_n[row_idx+1+1][col_idx+1+1]; // Below Right

      bsg_cgol_cell life_cell(
         .clk_i(clk_i)
        ,.data_i(nghs)
        ,.en_i(en_i)
        ,.update_i(update_i)
        ,.update_val_i(data_i[num_total_cells_lp-1-row_idx*board_width_p-col_idx])
        ,.data_o(cells_n[row_idx+1][col_idx+1])
      );

      assign data_o[num_total_cells_lp-1-row_idx*board_width_p-col_idx] = cells_n[row_idx+1][col_idx+1];
    end

    // right boundary
    assign cells_n[row_idx+1][board_width_p+1] = 1'b0;
  end

  // Bottom boundary
  assign cells_n[board_width_p+1] = '0;
  
endmodule
