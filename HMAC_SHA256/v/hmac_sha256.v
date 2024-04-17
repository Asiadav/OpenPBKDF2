/**
* HMAC using SHA256 Encryption
**/

module hmac_sha256 (
     input clk_i
    ,input rst_i 
        
    ,input [255:0] prf_i
    ,input [255:0] salt_i
    
    ,output logic [255:0] prf_o
    
    ,output prf_v_o
    ,input prf_r_i
  );
  
    logic in_valid, inready, out_valid, out_ready;
    logic [255:0] out;
    logic [511:0] in;
    sha256 hasher (.clk_i, .rst_i, .in_valid, .in, .in_ready, .out_valid, .out, .out_ready);

    
    always @(posedge clk_i) begin
      
    end
endmodule

