module bsg_cgol_ctrl #(
   parameter `BSG_INV_PARAM(max_game_length_p)
  ,localparam game_len_width_lp=`BSG_SAFE_CLOG2(max_game_length_p+1)
) (
   input clk_i
  ,input reset_i

  ,input en_i

  // Input Data Channel
  ,input  [game_len_width_lp-1:0] frames_i
  ,input  v_i
  ,output ready_o

  // Output Data Channel
  ,input yumi_i
  ,output v_o

  // Cell Array
  ,output update_o
  ,output en_o
);

  wire unused = en_i; // for clock gating, unused
  logic [game_len_width_lp-1:0] frames_r, frames_n;
  
  // TODO: Design your control logic
  typedef enum logic [1:0] {eWAIT, eRUN, eDONE} state_e;
  state_e state_n, state_r;
  
  assign ready_o = state_r == eWAIT;
  assign v_o = state_r == eDONE;
  assign update_o = v_i;
  assign en_o = state_r == eRUN;

  always_ff @(posedge clk_i)
    begin
      if (reset_i) begin
        state_r <= eWAIT;
        frames_r <= 0;
      end else begin
        state_r <= state_n;
        frames_r <= frames_n;
      end
    end

  always_comb 
    begin
      state_n = state_r;
      if (ready_o & v_i) begin
        state_n = eRUN;
      end else if ((state_r == eRUN) & (!frames_n)) begin
        state_n = eDONE;
      end else if (v_o & yumi_i) begin
        state_n = eWAIT;
      end
    end

    always_comb
      begin
        frames_n = frames_r;
        if (state_r == eWAIT) begin
          frames_n = frames_i;
        end else if ((state_r == eRUN) & (frames_r > 0)) begin
          frames_n = frames_r - 1;
        end
      end

endmodule
