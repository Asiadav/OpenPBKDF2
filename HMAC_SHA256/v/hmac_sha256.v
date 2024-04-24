/**
* HMAC using SHA256 Encryption
**/

module hmac_sha256 (
     input logic clk_i
    ,input logic rst_i 
        
    ,input logic [255:0] prf_i
    ,input logic [255:0] salt_i
    
    ,output logic [255:0] prf_o
    
    ,output logic v_o
    ,output logic r_o
    ,input logic r_i
    ,input logic v_i
  );
  
    logic new_hash, in_valid, in_ready, out_valid, out_ready, sel;
    logic [2:0] ps, ns;
    logic [255:0] pad, out;
    logic [511:0] in;

    assign pad = ps == 1 ? {16{16'h5c}} : {16{16'h36}}; // select the padding

    assign new_hash = 1;
    sha256 hasher (.clk_i, .rst_i, .in_valid, .new_hash, .in, .in_ready, .out_valid, .out, .out_ready);

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
	    if (out_valid) ns = 3;
	end
	3: begin  // Load into Reg
	    if (in_ready) ns = 4;
	    in_valid = 1;
	end
        4: begin  // Wait for hash (again)
	    if (out_valid) ns = 5;
	end
	5: begin  // Output Result
	    if (r_i) ns = 0;
	    out_ready = 1;
	    v_o = 1;
	end
	default:  begin end// unused
    endcase
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            ps <= 0;
            in <= 0;
            prf_o <= 0;
        end else begin
            ps <= ns;
            if (ps == 1) in <= {pad ^ salt_i, prf_i}; // update the sha256 input register
            if (ps == 3) in <= {pad ^ salt_i, out, 8'b10000000, 56'b0, 64'd96}; // update the sha256 input register
            if (ps == 5) prf_o <= out; // update the output register
        end
    end
endmodule

