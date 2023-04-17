module store_buffer(
    input clk, input flush,
    input [15:0] data, input [15:0] location, input input_valid,//a store instruction
    input [15:0] search_location, //location to search for in the queue
    input [2:0] stores_to_commit, //how mnay in the q to commit to memory
    output [15:0] search_data, output [15:0] search_valid, //output for inputed search location
    output [15:0] commit_data, output [15:0] commit_location, output commit_valid,//storing commited data TODO: timing issues if storing is instantaneous
    output store_full
    );

    assign store_full = (count == QUEUE_SIZE - 1) || (valid_count == QUEUE_SIZE - 1);

    parameter QUEUE_SIZE = 16;
    reg [3:0] head = 4'h0;
    reg [3:0] tail = 4'h0;
    reg [3:0] count = 4'h0;

    // [32] Valid, [31:16] Location, [15:0] Data
    reg [32:0] queue[0:QUEUE_SIZE-1];
    integer i;

    reg [15:0] rsearch_data = 16'h0000;
    reg rsearch_valid = 1'b0;

    assign search_data = rsearch_data;
    assign search_valid = rsearch_valid;

    always @(posedge clk) begin
        for(i = 0; i < QUEUE_SIZE; i = i + 1) begin
            if(valid_queue[i][32] == 1'b1) begin
                if(search_location == queue[i][31:16]) begin
                    rsearch_data = queue[i][15:0];
                    rsearch_valid = 1'b1;
                end
            end
        end

        for(i = 0; i < QUEUE_SIZE; i = i + 1) begin
            if(queue[i][32] == 1'b1) begin
                if(search_location == queue[i][31:16]) begin
                    rsearch_data = queue[i][15:0];
                    rsearch_valid = 1'b1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if(input_valid) begin
            queue[tail] <= {1'b1, location, data};
            tail <= tail + 1;
        end

        if(stores_to_commit != 3'b000) begin
            valid_queue[valid_tail] <= queue[0];

            if(stores_to_commit > 3'b001) begin
                valid_queue[valid_tail + 1] <= queue[1];
            end

            if(stores_to_commit > 3'b010) begin
                valid_queue[valid_tail + 2] <= queue[2];
            end

            if(stores_to_commit > 3'b011) begin
                valid_queue[valid_tail + 3] <= queue[3];
            end

            valid_tail <= valid_tail + stores_to_commit;

            for(i = 0; i < QUEUE_SIZE - stores_to_commit; i = i + 1) begin
                queue[i] <= queue[i + stores_to_commit];
            end
        end
    end

    reg [3:0] valid_count;
    reg [32:0] valid_queue[0:QUEUE_SIZE-1];
    reg [3:0] valid_tail = 4'h0;

endmodule