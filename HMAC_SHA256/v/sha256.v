/**
*SHA256 encryption module
**/

module sha256 (
     input clk_i
    ,input rst_i  
  
    ,input in_valid
    ,input [511:0] in   
    ,output in_ready

    ,output out_valid
    ,output logic [255:0] out
    ,input out_ready
  

    out = in[255:0];

    always @(posedge clk_i) begin
    end
endmodule

