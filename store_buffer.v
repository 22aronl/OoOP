module store_buffer(
    input clk, input flush,
    input [15:0] data, input [15:0] location, input input_valid,//a store instruction
    input [15:0] search_location, //location to search for in the queue
    input [2:0] stores_to_commit, //how mnay in the q to commit to memory
    output [15:0] search_data, output [15:0] search_valid, //output for inputed search location
    output [15:0] commit_data, output [15:0] commit_location, output commit_valid,//storing commited data TODO: timing issues if storing is instantaneous
    output store_stall //stall if store buffer is full
    );

    //[32] valid [31:16] location [15:0] data
    reg [32:0] store_buffer [0:7];
    reg [32:0] retired_buffer [0:3];
    integer i;
    always @(posedge clk) begin
        if(input_valid == 1'b1) begin
            if(stores_to_commit == 3'b000) begin
                for(i = 0; i < 7; i = i + 1) begin
                    store_buffer[i] <= store_buffer[i + 1];
                end
            end
            store_buffer[7] <= {1'b1, location, data};
        end
    end


endmodule