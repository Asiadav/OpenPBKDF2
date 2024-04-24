/**
* SHA256 Encryption wrapper
* input the password or the previously 
**/

module sha256_1024in (
     input logic clk_i
    ,input logic rst_i 
        
    ,input logic [1023:0] in 
    ,input logic [5:0] msg_len_i
    ,input logic in_valid
    ,output logic in_ready
    
    ,output logic [255:0] out
    ,input logic out_ready
    ,output logic out_valid
  );
  
    logic new_hash, in_v, in_r, out_v, out_r;
    logic [2:0] ps, ns;
    logic [511:0] in_l, pad;

    sha256 hasher (.clk_i, .rst_i, .new_hash, .in_valid(in_v), .in(in_l),
   		   .in_ready(in_r), .out_valid(out_v), .out, .out_ready(out_r));

    always @(*) begin
    ns = ps; in_ready = 0; out_valid = 0; in_v = 0; out_r = 0; new_hash = 0;
    case (ps)
	0: begin  // Read Input
	    if (in_valid) ns = 1; // new data recieved
	end
	1: begin  // Load First Chunk Into SHA256
	    if (in_r) ns = 2;
	    in_v = 1;
	    in_ready = 1;
	    new_hash = 1;
	end
	2: begin  // Wait for hash
	    if (out_v) ns = 3;
	end
	3: begin  // Load Second Chunk Into SHA256
	    if (in_ready) ns = 4;
	    out_r = 1;
	end
        4: begin  // Wait for hash (again)
	    if (out_v) ns = 5;
	end
	5: begin  // Output Result
	    if (out_ready) ns = 0;
	    out_valid = 1;
	    out_r = 1;
	end
	default:  begin end// unused
    endcase
    end

    assign pad = 

    always @(posedge clk_i) begin
        if (rst_i) begin
            ps <= 0;
            in <= 0;
        end else begin
            ps <= ns;
            if (ns == 1) in_l <= in[1023:512];
            if (ns == 3) in <= in[511:0] & {1'b1, msg_len_i};
        end
    end
endmodule

