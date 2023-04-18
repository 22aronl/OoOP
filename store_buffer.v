module store_buffer(
    input clk, input flush,
    input [15:0] data, input [15:0] location, input input_valid,//a store instruction
    input [15:0] search_location, //location to search for in the queue
    input [1:0] stores_to_commit, //how mnay in the q to commit to memory
    output [15:0] search_data, output search_valid, //output for inputed search location
    output [15:0] commit_data, output [15:0] commit_location, output commit_valid,//storing commited data TODO: timing issues if storing is instantaneous
    output store_stall //stall if store buffer is full
    );

    //[33] write to mem [32] valid [31:16] location [15:0] data
    reg [33:0] store_buffer [0:7];
    reg [3:0] head = 4'b0000;
    reg [3:0] tail = 4'b0000;
    reg [3:0] count = 4'b0000;
    
    assign commit_valid = rcommit_valid & rcommit_write;
    assign commit_location = rcommit_location;
    assign commit_data = rcommit_data;

    reg [15:0] rcommit_data;
    reg [15:0] rcommit_location;
    reg rcommit_valid = 1'b0;
    reg rcommit_write = 1'b0;

    assign store_stall = count == 4'b0111;

    assign search_data = (store_buffer[7][32] == 1'b1 && store_buffer[7][31:16] == search_location) ? store_buffer[7][15:0] :
                            (store_buffer[6][32] == 1'b1 && store_buffer[6][31:16] == search_location) ? store_buffer[6][15:0] :
                            (store_buffer[5][32] == 1'b1 && store_buffer[5][31:16] == search_location) ? store_buffer[5][15:0] :
                            (store_buffer[4][32] == 1'b1 && store_buffer[4][31:16] == search_location) ? store_buffer[4][15:0] :
                            (store_buffer[3][32] == 1'b1 && store_buffer[3][31:16] == search_location) ? store_buffer[3][15:0] :
                            (store_buffer[2][32] == 1'b1 && store_buffer[2][31:16] == search_location) ? store_buffer[2][15:0] :
                            (store_buffer[1][32] == 1'b1 && store_buffer[1][31:16] == search_location) ? store_buffer[1][15:0] :
                            (store_buffer[0][32] == 1'b1 && store_buffer[0][31:16] == search_location) ? store_buffer[0][15:0] :
                            rcommit_valid == 1'b1 && rcommit_location == search_location ? rcommit_data : 16'b0000000000000000;
    
    assign search_valid = (store_buffer[7][32] == 1'b1 && store_buffer[7][31:16] == search_location) |
                            (store_buffer[6][32] == 1'b1 && store_buffer[6][31:16] == search_location) |
                            (store_buffer[5][32] == 1'b1 && store_buffer[5][31:16] == search_location) |
                            (store_buffer[4][32] == 1'b1 && store_buffer[4][31:16] == search_location) |
                            (store_buffer[3][32] == 1'b1 && store_buffer[3][31:16] == search_location) |
                            (store_buffer[2][32] == 1'b1 && store_buffer[2][31:16] == search_location) |
                            (store_buffer[1][32] == 1'b1 && store_buffer[1][31:16] == search_location) |
                            (store_buffer[0][32] == 1'b1 && store_buffer[0][31:16] == search_location) |
                            (rcommit_valid == 1'b1 && rcommit_location == search_location);

    integer i;
    always @(posedge clk) begin
        rcommit_write <= store_buffer[0][33];
        rcommit_valid <= store_buffer[0][32];
        rcommit_location <= store_buffer[0][31:16];
        rcommit_data <= store_buffer[0][15:0];

        if(store_buffer[0][33:32] == 2'b11) begin
            for(i = 0; i < 7; i = i + 1) begin
                store_buffer[i] <= store_buffer[i+1];
            end
            store_buffer[7][33:32] <= 2'b00;
            count <= count - 1;
            tail <= tail - 1;
            head <= head - 1;
        end
    end

    //I give up
    always @(negedge clk) begin
        if(flush) begin
            tail <= 4'b0000;
            head <= 4'b0000;
            count <= 4'b0000;
            for(i = 0; i < 8; i = i + 1) begin
                store_buffer[i][33:32] <= 2'b00;
            end
        end else begin
            if(input_valid) begin
                store_buffer[tail] <= {2'b01, location, data};
                tail <= tail + 1;
                count <= count + 1;
            end

            if(stores_to_commit > 0) begin
                for(i = 0; i < stores_to_commit; i = i + 1) begin
                    store_buffer[i + head][33] <= 1'b1;
                end
                head <= head + stores_to_commit;
            end
        end
    end


endmodule