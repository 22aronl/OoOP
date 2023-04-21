
module load_store_unit(
    input clk, input flush, input [1:0] stores_to_commit,
    input is_ld, input [15:0] data, input [15:0] location, input [5:0] ROBloc, input input_valid,
    output [15:0] commit_data, output [15:0] commit_location, output commit_valid,
    output [15:0] mem_location, output mem_valid,
    input [15:0] mem_data,
    output [15:0] out_data, output [5:0] out_ROB, output out_valid,
    output load_stall //stall receiving more load units
);
    assign load_stall = store_buffer_stall;
    assign out_ROB = load_store[head][5:0];
    assign out_data = load_store_data[head][16] ? load_store_data[head][15:0] : mem_data;
    assign out_valid = load_store[head][6];

    //Timing of Load_WAIt might be wrong
    parameter LOAD_WAIT = 3;
    parameter LOAD_SIZE = 8;
    wire store_buffer_stall;
    
    // [6] valid [5:0] ROB_location
    reg [6:0] load_store[0:LOAD_SIZE-1];
    reg [16:0] load_store_data[0:LOAD_SIZE-1];
    reg [3:0] head = 4'b0000;
    reg [3:0] tail = LOAD_WAIT;
    integer i;
    always @(posedge clk) begin
        if(flush) begin
            head <= 4'b0000;
            tail <= LOAD_WAIT;
            for(i = 0; i < LOAD_SIZE; i = i + 1) begin
                load_store[i][6] <= 1'b0;
                load_store_data[i][16] <= 1'b0;
            end
        end else begin
            load_store[tail] <= {input_valid && is_ld, ROBloc};
            tail <= (tail + 1) % LOAD_SIZE;
            head <= (head + 1) % LOAD_SIZE;

            if(search_valid) begin
                load_store[(tail + LOAD_SIZE - 1) % LOAD_SIZE][6] <= 1'b0;
                load_store_data[(tail + LOAD_SIZE - 1) % LOAD_SIZE] <= {search_valid, search_data};
            end
        end
    end

    wire [15:0] search_data;
    wire search_valid;

    store_buffer store_buffer(
        .clk(clk),
        .flush(flush),
        .data(data), .location(location), .input_valid(input_valid && !is_ld),
        .search_location(location),
        .stores_to_commit(stores_to_commit),
        .commit_data(commit_data), .commit_location(commit_location), .commit_valid(commit_valid),
        .search_data(search_data), .search_valid(search_valid),
        .store_stall(store_buffer_stall)
    );



endmodule