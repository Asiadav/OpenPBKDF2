/**
* HMAC using SHA256 Encryption
* input the password or the previously 
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
    logic [511:0] pad;
    logic [1023:0] in, in_1, in_2;

    assign pad = ps == 1 ? {64{8'h5c}} : {64{8'h36}}; // select the padding

    sha256_1024in hasher (.clk_i, .rst_i, .in_valid, .in, .in_ready, .out_valid, .out, .out_ready);

    always @(*) begin
    ns = ps; r_o = 0; out_ready = 0; in_valid = 0; v_o = 0;
    case (ps)
	0: begin  // Read Input
	    if (v_i) ns = 1; // new data recieved
	end
	1: begin  // Load Into Reg
	    $display("loading first hash");
	    $display("%d", msg_len_i);
	    $display("%h", in);
	    if (in_ready) ns = 2;
	    r_o = 1;
	    in_valid = 1;
	end
	2: begin  // Wait for hash
	    if (out_valid) ns = 3;
	end
	3: begin  // Load into Reg
	    $display("loading second hash");
	    $display("%h", in);
	    if (in_ready) ns = 4;
	    in_valid = 1;
	end
        4: begin  // Wait for hash (again)
	    if (out_valid) ns = 5;
	    $display("waiting for second hash");
	end
	5: begin  // Output Result
	    $display("outputing hmac");
	    if (r_i) ns = 0;
	    out_ready = 1;
	    v_o = 1;
	end
	default:  begin end// unused
    endcase
    end

    //assign one = {8'b10000000, 64'b0} << 8(55 - msg_len_i);  // horrible large synthesis
    //assign one[512 - msg_len_i] = 1;  // unknown synthesis
    oneSetter setter (.len(msg_len_i), .one);
    //assign one = 8'b10000000 << 8 * 19;
    assign in_1 = {pad ^ key_i, msg_i} | {1'b1, msg_len_i, 3'b000} | {one, 64'b0};
    assign in_2 = {pad ^ key_i, out, 1'b1, 191'b0, 64'd768};

    always @(posedge clk_i) begin
        if (rst_i) begin
            ps <= 0;
            in <= 0;
            //prf_o <= 0;
        end else begin
            ps <= ns;
            if (ns == 1) in <= in_1 ; // update the sha256 input register
            if (ns == 3) in <= in_2; // update the sha256 input register
            if (ns == 5) prf_o <= out; // update the output register
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

