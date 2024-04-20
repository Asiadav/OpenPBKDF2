/**
*SHA256 encryption module
**/

function [31:0] S0(input [31:0] x);
	begin
		S0 = {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};
	end
endfunction

function [31:0] S1(input [31:0] x);
	begin
		S1 = {x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]};
	end
endfunction

function [31:0] s0(input [31:0] x);
	begin
		s0 = {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ {3'b0, x[31:3]};
	end
endfunction

function [31:0] s1(input [31:0] x);
	begin
		s1 = {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ {10'b0, x[31:10]};
	end
endfunction

function [31:0] message(input [31:0] sixteen, input [31:0] fifteen, input [31:0] seven, input [31:0] two);
	begin
		message = sixteen + s0(fifteen) + seven + s1(two);
	end
endfunction


module sha256 (
     input logic clk_i
    ,input logic rst_i  
  
    ,input logic in_valid
    ,input [511:0] in
    ,input logic new_hash
    ,output logic in_ready

    ,output logic out_valid
    ,output logic [255:0] out
    ,input logic out_ready);
  

    localparam H0_INITIAL = 32'h6a09e667;
	localparam H1_INITIAL = 32'hbb67ae85;
	localparam H2_INITIAL = 32'h3c6ef372;
	localparam H3_INITIAL = 32'ha54ff53a;
	localparam H4_INITIAL = 32'h510e527f;
	localparam H5_INITIAL = 32'h9b05688c;
	localparam H6_INITIAL = 32'h1f83d9ab;
	localparam H7_INITIAL = 32'h5be0cd19;
	logic [31:0] K [0:63] = '{
		32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
		32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
		32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
		32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
		32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
		32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
		32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7,
		32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
		32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13,
		32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
		32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3,
		32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
		32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5,
		32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
		32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208,
		32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2};

    enum {WAITING, RUNNING, FINISHED} state;

	logic [0:31] H [0: 7], H_next [0: 7]; // 8 H values
	logic [0:31] W_history [0:15], W, W_next; // 64 W values
    logic [6:0] cycle; // 0 - 64; 0-63 are message scheduling, 1-64 are compression

    logic [511: 0] saved_in;
    logic saved_new;

	always_ff @(posedge clk_i) begin
		if (rst_i) begin
            in_ready <= 0;
            out_valid <= 0;
            state <= WAITING;

			H[0] <= H0_INITIAL;
			H[1] <= H1_INITIAL;
			H[2] <= H2_INITIAL;
			H[3] <= H3_INITIAL;
			H[4] <= H4_INITIAL;
			H[5] <= H5_INITIAL;
			H[6] <= H6_INITIAL;
			H[7] <= H7_INITIAL;
		end else begin
            // $display("state: %d", state);
			if (state == WAITING) begin
                in_ready <= 1;
                if (in_valid) begin
                    saved_in <= in;
                    saved_new <= new_hash;

                    if (new_hash) begin
                        H[0] <= H0_INITIAL;
                        H[1] <= H1_INITIAL;
                        H[2] <= H2_INITIAL;
                        H[3] <= H3_INITIAL;
                        H[4] <= H4_INITIAL;
                        H[5] <= H5_INITIAL;
                        H[6] <= H6_INITIAL;
                        H[7] <= H7_INITIAL;
                    end

                    state <= RUNNING;
                end
            end else if (state == RUNNING) begin
                in_ready <= 0;
                if (cycle == 64) begin
                    out <= {H_next[0], H_next[1], H_next[2], H_next[3], H_next[4], H_next[5], H_next[6], H_next[7]};
                    
                    H <= H_next;
                    out_valid <= 1;
                    state <= FINISHED;
                end else begin
                    out <= out;
                    out_valid <= 0;
                end

                W_history[1:15] <= W_history[0:14];
                W_history[0] <= W_next;
                W <= W_next;

            end else if (state == FINISHED) begin
                $display("Out: %64h", out);
                if (out_ready == 1) begin
                    out_valid <= 0;
                    state <= WAITING;
                end
            end
		end
	end
	
	always_ff @(posedge clk_i) begin
		if (rst_i || state != RUNNING) cycle <= 0;
		else cycle <= cycle + 6'b1;
	end


	logic [0:31] a, a_next, b, b_next, c, c_next, d, d_next,
				 e, e_next, f, f_next, g, g_next, h, h_next;

	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			a <= H0_INITIAL;
			b <= H1_INITIAL;
			c <= H2_INITIAL;
			d <= H3_INITIAL;
			e <= H4_INITIAL;
			f <= H5_INITIAL;
			g <= H6_INITIAL;
			h <= H7_INITIAL;
		end else begin
			if (state == RUNNING) begin
				if (cycle == 0) begin
					a <= saved_new ? H0_INITIAL : H[0];
					b <= saved_new ? H1_INITIAL : H[1];
					c <= saved_new ? H2_INITIAL : H[2];
					d <= saved_new ? H3_INITIAL : H[3];
					e <= saved_new ? H4_INITIAL : H[4];
					f <= saved_new ? H5_INITIAL : H[5];
					g <= saved_new ? H6_INITIAL : H[6];
					h <= saved_new ? H7_INITIAL : H[7];
				end else begin
					a <= a_next;
					b <= b_next;
					c <= c_next;
					d <= d_next;
					e <= e_next;
					f <= f_next;
					g <= g_next;
					h <= h_next;
				end
				// if (cycle >= 1) begin
					// $display("Cycle %d", cycle);
					// $display("a  %32b", a);
					// $display("b  %32b", b);
					// $display("c  %32b", c);
					// $display("d  %32b", d);
					// $display("e  %32b", e);
					// $display("f  %32b", f);
					// $display("g  %32b", g);
					// $display("h  %32b", h);
                    // $display();
				// end
			end
		end
	end

	logic [0:31] ch, temp1, maj, temp2;
	assign ch = ((e & f) ^ ((~e) & g));
	assign temp1 = (h + S1(e)) + ch + (K[cycle[5:0] - 5'b1] + W);
	assign maj = ((a & b) ^ (a & c) ^ (b & c));
	assign temp2 = S0(a) + maj;

	always_comb begin
		if (cycle < 16) begin
			case(cycle)
				 0: W_next  = {saved_in[8 * 4 * 16 - 1 + 24: 8 * 4 * 15 + 24], saved_in[8 * 4 * 16 - 1 + 16: 8 * 4 * 15 + 16], saved_in[8 * 4 * 16 - 1 + 8: 8 * 4 * 15 + 8], saved_in[8 * 4 * 16 - 1: 8 * 4 * 15]};
				 1: W_next  = {saved_in[8 * 4 * 15 - 1 + 24: 8 * 4 * 14 + 24], saved_in[8 * 4 * 15 - 1 + 16: 8 * 4 * 14 + 16], saved_in[8 * 4 * 15 - 1 + 8: 8 * 4 * 14 + 8], saved_in[8 * 4 * 15 - 1: 8 * 4 * 14]};
				 2: W_next  = {saved_in[8 * 4 * 14 - 1 + 24: 8 * 4 * 13 + 24], saved_in[8 * 4 * 14 - 1 + 16: 8 * 4 * 13 + 16], saved_in[8 * 4 * 14 - 1 + 8: 8 * 4 * 13 + 8], saved_in[8 * 4 * 14 - 1: 8 * 4 * 13]};
				 3: W_next  = {saved_in[8 * 4 * 13 - 1 + 24: 8 * 4 * 12 + 24], saved_in[8 * 4 * 13 - 1 + 16: 8 * 4 * 12 + 16], saved_in[8 * 4 * 13 - 1 + 8: 8 * 4 * 12 + 8], saved_in[8 * 4 * 13 - 1: 8 * 4 * 12]};
				 4: W_next  = {saved_in[8 * 4 * 12 - 1 + 24: 8 * 4 * 11 + 24], saved_in[8 * 4 * 12 - 1 + 16: 8 * 4 * 11 + 16], saved_in[8 * 4 * 12 - 1 + 8: 8 * 4 * 11 + 8], saved_in[8 * 4 * 12 - 1: 8 * 4 * 11]};
				 5: W_next  = {saved_in[8 * 4 * 11 - 1 + 24: 8 * 4 * 10 + 24], saved_in[8 * 4 * 11 - 1 + 16: 8 * 4 * 10 + 16], saved_in[8 * 4 * 11 - 1 + 8: 8 * 4 * 10 + 8], saved_in[8 * 4 * 11 - 1: 8 * 4 * 10]};
				 6: W_next  = {saved_in[8 * 4 * 10 - 1 + 24: 8 * 4 *  9 + 24], saved_in[8 * 4 * 10 - 1 + 16: 8 * 4 *  9 + 16], saved_in[8 * 4 * 10 - 1 + 8: 8 * 4 *  9 + 8], saved_in[8 * 4 * 10 - 1: 8 * 4 *  9]};
				 7: W_next  = {saved_in[8 * 4 *  9 - 1 + 24: 8 * 4 *  8 + 24], saved_in[8 * 4 *  9 - 1 + 16: 8 * 4 *  8 + 16], saved_in[8 * 4 *  9 - 1 + 8: 8 * 4 *  8 + 8], saved_in[8 * 4 *  9 - 1: 8 * 4 *  8]};
				 8: W_next  = {saved_in[8 * 4 *  8 - 1 + 24: 8 * 4 *  7 + 24], saved_in[8 * 4 *  8 - 1 + 16: 8 * 4 *  7 + 16], saved_in[8 * 4 *  8 - 1 + 8: 8 * 4 *  7 + 8], saved_in[8 * 4 *  8 - 1: 8 * 4 *  7]};
				 9: W_next  = {saved_in[8 * 4 *  7 - 1 + 24: 8 * 4 *  6 + 24], saved_in[8 * 4 *  7 - 1 + 16: 8 * 4 *  6 + 16], saved_in[8 * 4 *  7 - 1 + 8: 8 * 4 *  6 + 8], saved_in[8 * 4 *  7 - 1: 8 * 4 *  6]};
				10: W_next  = {saved_in[8 * 4 *  6 - 1 + 24: 8 * 4 *  5 + 24], saved_in[8 * 4 *  6 - 1 + 16: 8 * 4 *  5 + 16], saved_in[8 * 4 *  6 - 1 + 8: 8 * 4 *  5 + 8], saved_in[8 * 4 *  6 - 1: 8 * 4 *  5]};
				11: W_next  = {saved_in[8 * 4 *  5 - 1 + 24: 8 * 4 *  4 + 24], saved_in[8 * 4 *  5 - 1 + 16: 8 * 4 *  4 + 16], saved_in[8 * 4 *  5 - 1 + 8: 8 * 4 *  4 + 8], saved_in[8 * 4 *  5 - 1: 8 * 4 *  4]};
				12: W_next  = {saved_in[8 * 4 *  4 - 1 + 24: 8 * 4 *  3 + 24], saved_in[8 * 4 *  4 - 1 + 16: 8 * 4 *  3 + 16], saved_in[8 * 4 *  4 - 1 + 8: 8 * 4 *  3 + 8], saved_in[8 * 4 *  4 - 1: 8 * 4 *  3]};
				13: W_next  = {saved_in[8 * 4 *  3 - 1 + 24: 8 * 4 *  2 + 24], saved_in[8 * 4 *  3 - 1 + 16: 8 * 4 *  2 + 16], saved_in[8 * 4 *  3 - 1 + 8: 8 * 4 *  2 + 8], saved_in[8 * 4 *  3 - 1: 8 * 4 *  2]};
				14: W_next  = {saved_in[8 * 4 *  2 - 1 + 24: 8 * 4 *  1 + 24], saved_in[8 * 4 *  2 - 1 + 16: 8 * 4 *  1 + 16], saved_in[8 * 4 *  2 - 1 + 8: 8 * 4 *  1 + 8], saved_in[8 * 4 *  2 - 1: 8 * 4 *  1]};
				15: W_next  = {saved_in[8 * 4 *  1 - 1 + 24: 8 * 4 *  0 + 24], saved_in[8 * 4 *  1 - 1 + 16: 8 * 4 *  0 + 16], saved_in[8 * 4 *  1 - 1 + 8: 8 * 4 *  0 + 8], saved_in[8 * 4 *  1 - 1: 8 * 4 *  0]};
			endcase
		end else begin
			W_next =  (W_history[4'd15]   +
					s0(W_history[4'd14])) +
					  (W_history[4'd06]   +
					s1(W_history[4'd01]));
		end
		
        h_next = g;
		g_next = f;
		f_next = e;
		e_next = d + temp1;
		d_next = c;
		c_next = b;
		b_next = a;
		a_next = temp1 + temp2;
		H_next[0] = H[0] + a_next;
		H_next[1] = H[1] + b_next;
		H_next[2] = H[2] + c_next;
		H_next[3] = H[3] + d_next;
		H_next[4] = H[4] + e_next;
		H_next[5] = H[5] + f_next;
		H_next[6] = H[6] + g_next;
		H_next[7] = H[7] + h_next;
	end
endmodule

