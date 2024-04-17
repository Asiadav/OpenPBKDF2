/**
* Conway's Game of Life Cell
*
* data_i[7:0] is status of 8 neighbor cells
* data_o is status this cell
* 1: alive, 0: death
*
* when en_i==1:
*   simulate the cell transition with 8 given neighors
* else when update_i==1:
*   update the cell status to update_val_i
* else:
*   cell status remains unchanged
**/

module bsg_cgol_cell (
    input clk_i

    ,input en_i          
    ,input [7:0] data_i

    ,input update_i     
    ,input update_val_i

    ,output logic data_o
  );
  
/*
    logic [3:0] num_ones;
    bsg_popcount #(.width_p(8)) count_ones (
        .i( data_i ),
        .o( num_ones )
    );
    */
	logic [3:0] num_ones;
	logic [1:0] psum_1, psum_2, psum_3, psum_4;
	logic [2:0] psum_5, psum_6;

	always @(*) begin
    	psum_1 = data_i[7] + data_i[6];
    	psum_2 = data_i[5] + data_i[4];
    	psum_3 = data_i[3] + data_i[2];
    	psum_4 = data_i[1] + data_i[0];
    	psum_5 = psum_1 + psum_2;
    	psum_6 = psum_3 + psum_4;
    	num_ones = psum_5 + psum_6;
	end

    always @(posedge clk_i) begin
        if(en_i) begin  // calc new value
	    data_o <= (data_o | num_ones[0]) & num_ones[1] & !num_ones[2]; // logical equivalent of 2 or 3
	    end else if(update_i) begin
            //cell_r <= update_val_i;
            data_o <= update_val_i;  // take given value
        end  else begin
            data_o <= data_o;  // remain unchanged
        end 
    end
endmodule

