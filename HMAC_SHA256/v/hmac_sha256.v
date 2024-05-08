/**
* HMAC using SHA256 Encryption
* input the password and the salt to get the keyed has output 
**/

module hmac_sha256 (
     input logic clk_i
    ,input logic rst_i 
        
    ,input logic [511:0] key_i    // left aligned - the key has all 0's on the right to fill the input
    ,input logic [511:0] msg_i    // left aligned - the msg has all 0's on the right to fill the input
    ,input logic [5:0] msg_len_i // length of the hash in bits
    
    ,output logic [255:0] prf_o
    
    ,output logic v_o
    ,output logic r_o
    ,input logic r_i
    ,input logic v_i
  );
  
    logic new_hash, in_valid, in_ready, out_valid, out_ready, sel;
    logic [2:0] ps, ns;
    logic [255:0] out;
    logic [439:0] one;
    logic [511:0] pad, key_reg;
    logic [1023:0] in, in_1, in_2;

    sha256_1024in hasher (.clk_i, .rst_i, .in_valid, .in, .in_ready, .out_valid, .out, .out_ready);

    always @(*) begin
    ns = ps; r_o = 0; out_ready = 0; in_valid = 0; v_o = 0;
    case (ps)
	0: begin  // Read Input
	    if (v_i) ns = 1; // new data recieved
	end
	1: begin  // Load Into Reg
	    if (in_ready) ns = 2;
	    r_o = 1;
	    in_valid = 1;
	end
	2: begin  // Wait for hash
	    if (out_valid) begin ns = 3; out_ready = 1; end
	end
	3: begin  // Load into Reg
	    if (in_ready) ns = 4;
	    in_valid = 1;
	end
        4: begin  // Wait for hash (again)
	    if (out_valid) begin ns = 5; out_ready = 1; end
	end
	5: begin  // Output Result
	    if (r_i) ns = 0;
	    out_ready = 1;
	    v_o = 1;
	    $display("prf_o: %h", prf_o);
 	    $finish;
	end
	default:  begin end// unused
    endcase
    end

    oneSetter2 setter (.len(msg_len_i), .one);
    assign in_1 = {{64{8'h36}} ^ key_i, msg_i} | {1'b1, msg_len_i, 3'b000} | {one, 64'b0};
    assign in_2 = {{64{8'h5c}} ^ key_reg, out, 1'b1, 191'b0, 64'd768};

    always @(posedge clk_i) begin
        if (rst_i) begin
            ps <= 0;
            in <= 0;
            //prf_o <= 0;
        end else begin
            ps <= ns;
            if (ns == 3'b001) begin in <= in_1; key_reg <= key_i; end // update the sha256 input register
            if (ns == 3'b011) in <= in_2; // update the sha256 input register
            if (ns == 3'b101) prf_o <= out; // update the output register
        end
    end
endmodule


module oneSetter(
    input [5:0] len,
    output logic [439:0] one
);


// Define a lookup table with 64 entries (6-bit inputNumber)
reg [439:0] lut [63:0];

// Initialize the lookup table
initial begin
    for (int i = 8; i < 440; i+=8) begin
        lut[i] = 8'b10000000 << (440 - i);
	$display("%b", lut[i]);
    end
end

assign result = lut[len];

endmodule

module oneSetter2(    input [5:0] len,
    output logic [439:0] one
);
always @(*) begin
    case(len) 
	55: one = 8'b10000000 << 0*8;
	54: one = 8'b10000000 << 1*8;
	53: one = 8'b10000000 << 2*8;
	52: one = 8'b10000000 << 3*8;
	51: one = 8'b10000000 << 4*8;
	50: one = 8'b10000000 << 5*8;
	49: one = 8'b10000000 << 6*8;
	48: one = 8'b10000000 << 7*8;
	47: one = 8'b10000000 << 8*8;
	46: one = 8'b10000000 << 9*8;
	45: one = 8'b10000000 << 10*8;
	44: one = 8'b10000000 << 11*8;
	43: one = 8'b10000000 << 12*8;
	42: one = 8'b10000000 << 13*8;
	41: one = 8'b10000000 << 14*8;
	40: one = 8'b10000000 << 15*8;
	39: one = 8'b10000000 << 16*8;
	38: one = 8'b10000000 << 17*8;
	37: one = 8'b10000000 << 18*8;
	36: one = 8'b10000000 << 19*8;
	35: one = 8'b10000000 << 20*8;
	34: one = 8'b10000000 << 21*8;
	33: one = 8'b10000000 << 22*8;
	32: one = 8'b10000000 << 23*8;
	31: one = 8'b10000000 << 24*8;
	30: one = 8'b10000000 << 25*8;
	29: one = 8'b10000000 << 26*8;
	28: one = 8'b10000000 << 27*8;
	27: one = 8'b10000000 << 28*8;
	26: one = 8'b10000000 << 29*8;
	25: one = 8'b10000000 << 30*8;
	24: one = 8'b10000000 << 31*8;
	23: one = 8'b10000000 << 32*8;
	22: one = 8'b10000000 << 33*8;
	21: one = 8'b10000000 << 34*8;
	20: one = 8'b10000000 << 35*8;
	19: one = 8'b10000000 << 36*8;
	18: one = 8'b10000000 << 37*8;
	17: one = 8'b10000000 << 38*8;
	16: one = 8'b10000000 << 39*8;
	15: one = 8'b10000000 << 40*8;
	14: one = 8'b10000000 << 41*8;
	13: one = 8'b10000000 << 42*8;
	12: one = 8'b10000000 << 43*8;
	11: one = 8'b10000000 << 44*8;
	10: one = 8'b10000000 << 45*8;
	9: one = 8'b10000000 << 46*8;
	8: one = 8'b10000000 << 47*8;
	7: one = 8'b10000000 << 48*8;
	6: one = 8'b10000000 << 49*8;
	5: one = 8'b10000000 << 50*8;
	4: one = 8'b10000000 << 51*8;
	3: one = 8'b10000000 << 52*8;
	2: one = 8'b10000000 << 53*8;
	1: one = 8'b10000000 << 54*8;
	0: one = 8'b10000000 << 55*8;
	default: begin end//lmao
    endcase
end
endmodule
