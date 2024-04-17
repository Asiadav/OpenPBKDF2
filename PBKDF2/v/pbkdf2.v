/**
* PBKDF2 key generatoring algorithm 
**/

module pbkdf2_chunk(
     input clk_i
    ,input rst_i
    ,input [31:0] iters_i
    ,input [255:0] pass_i
    ,input [255:0] salt_i

    ,input ready_i     
    ,output logic valid_o

    ,output logic [255:0] hash_o
  );
    
    logic prf_v_o, prf_r_i;
    logic [31:0] count;
    logic [255:0] prf_i, prf_o;
  
    prf_i = count == 0 ? pass_i : prf_reg // on the first iterations, input password


    // instantiate HMAC
    //HMAC_SHA256 prf (.clk_i, .rst_i, .prf_i, .salt_i, prf_o, .prf_v_o, .prf_r_i);.

    
    always @(posedge clk_i) begin
	if (rst_i) begin
	    count <= 0;
            prf_reg <= 0;
	end else
	    if (prf_v_o) begin // store output data, increment count and compute U_x
		prf_r_i <= 1;	
		prf_reg <= prf_o
		hash_o <= hash_o ^ prf_o;
		count <= count + 1;
	    end else 
		prf_r_i <= 0;
	end
    end

endmodule

