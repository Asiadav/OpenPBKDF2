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

typedef struct {
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] c;
    logic [31:0] d;
    logic [31:0] e;
    logic [31:0] f;
    logic [31:0] g;
    logic [31:0] h;
} stage;

module sha256_stage(
    input stage in_stage,
    output stage out_stage,
    input [31:0] w,
    input [31:0] k
);

    logic [0:31] ch, temp1, maj, temp2;
	assign ch = ((in_stage.e & in_stage.f) ^ ((~in_stage.e) & in_stage.g));
	assign temp1 = (in_stage.h + S1(in_stage.e)) + ch + (k + w);
	assign maj = ((in_stage.a & in_stage.b) ^ (in_stage.a & in_stage.c) ^ (in_stage.b & in_stage.c));
	assign temp2 = S0(in_stage.a) + maj;

    assign out_stage.h = in_stage.g;
    assign out_stage.g = in_stage.f;
    assign out_stage.f = in_stage.e;
    assign out_stage.e = in_stage.d + temp1;
    assign out_stage.d = in_stage.c;
    assign out_stage.c = in_stage.b;
    assign out_stage.b = in_stage.a;
    assign out_stage.a = temp1 + temp2;
endmodule

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

    enum {WAITING, RUNNING, FINISHED} state;

	logic [31:0] H [0: 7], H_next [0: 7]; // 8 H values
    logic [31:0] w [0:63];

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
                out <= {H_next[0], H_next[1], H_next[2], H_next[3], H_next[4], H_next[5], H_next[6], H_next[7]};
                
                H <= H_next;
                out_valid <= 1;
                state <= FINISHED;
                // $display("a  %32b", stages[63].a);
                // $display("b  %32b", stages[63].b);
                // $display("c  %32b", stages[63].c);
                // $display("d  %32b", stages[63].d);
                // $display("e  %32b", stages[63].e);
                // $display("f  %32b", stages[63].f);
                // $display("g  %32b", stages[63].g);
                // $display("h  %32b", stages[63].h);
                // for (int i = 0; i < 64; i = i + 1) begin
                //     $display("w%d  %32b", i, w[i]);
                // end
            end else if (state == FINISHED) begin
                //$display("Out: %64h", out);
                if (out_ready == 1) begin
                    out_valid <= 0;
                    state <= WAITING;
                end
            end
		end
	end

    stage entrance_stage;

	always_comb begin
		if (rst_i) begin
			entrance_stage.a = H0_INITIAL;
			entrance_stage.b = H1_INITIAL;
			entrance_stage.c = H2_INITIAL;
			entrance_stage.d = H3_INITIAL;
			entrance_stage.e = H4_INITIAL;
			entrance_stage.f = H5_INITIAL;
			entrance_stage.g = H6_INITIAL;
			entrance_stage.h = H7_INITIAL;
		end else begin
            entrance_stage.a = saved_new ? H0_INITIAL : H[0];
            entrance_stage.b = saved_new ? H1_INITIAL : H[1];
            entrance_stage.c = saved_new ? H2_INITIAL : H[2];
            entrance_stage.d = saved_new ? H3_INITIAL : H[3];
            entrance_stage.e = saved_new ? H4_INITIAL : H[4];
            entrance_stage.f = saved_new ? H5_INITIAL : H[5];
            entrance_stage.g = saved_new ? H6_INITIAL : H[6];
            entrance_stage.h = saved_new ? H7_INITIAL : H[7];
		end
	end

    localparam [0:63] [31:0] K = {
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


    stage stages [0:63];

    genvar i;
    generate
        for(i = 0; i < 64; i = i + 1) begin : stage_gen
            sha256_stage sha_stage
            (
                .in_stage(i == 0 ? entrance_stage : stages[i - 1]),
                .out_stage(stages[i]),
                .w(w[i]),
                .k(K[i])
            );

            case(i)
                0:  assign w[i] = saved_in[8 * 4 * 15 + 8 * 0 +:32];
                1:  assign w[i] = saved_in[8 * 4 * 14 + 8 * 0 +:32];
                2:  assign w[i] = saved_in[8 * 4 * 13 + 8 * 0 +:32];
                3:  assign w[i] = saved_in[8 * 4 * 12 + 8 * 0 +:32];
                4:  assign w[i] = saved_in[8 * 4 * 11 + 8 * 0 +:32];
                5:  assign w[i] = saved_in[8 * 4 * 10 + 8 * 0 +:32];
                6:  assign w[i] = saved_in[8 * 4 *  9 + 8 * 0 +:32];
                7:  assign w[i] = saved_in[8 * 4 *  8 + 8 * 0 +:32];
                8:  assign w[i] = saved_in[8 * 4 *  7 + 8 * 0 +:32];
                9:  assign w[i] = saved_in[8 * 4 *  6 + 8 * 0 +:32];
                10: assign w[i] = saved_in[8 * 4 *  5 + 8 * 0 +:32];
                11: assign w[i] = saved_in[8 * 4 *  4 + 8 * 0 +:32];
                12: assign w[i] = saved_in[8 * 4 *  3 + 8 * 0 +:32];
                13: assign w[i] = saved_in[8 * 4 *  2 + 8 * 0 +:32];
                14: assign w[i] = saved_in[8 * 4 *  1 + 8 * 0 +:32];
                15: assign w[i] = saved_in[8 * 4 *  0 + 8 * 0 +:32];
                default: assign w[i] = (w[i - 6'd16] + s0(w[i - 6'd15])) + (w[i - 6'd07] + s1(w[i - 6'd02]));
            endcase 
        end
    endgenerate

    assign H_next[0] = H[0] + stages[63].a;
    assign H_next[1] = H[1] + stages[63].b;
    assign H_next[2] = H[2] + stages[63].c;
    assign H_next[3] = H[3] + stages[63].d;
    assign H_next[4] = H[4] + stages[63].e;
    assign H_next[5] = H[5] + stages[63].f;
    assign H_next[6] = H[6] + stages[63].g;
    assign H_next[7] = H[7] + stages[63].h;
endmodule