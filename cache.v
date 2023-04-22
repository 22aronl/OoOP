module cache(input clk,
    input [15:1] raddr0_, output reg [15:0] rdata0_, output reg rvalid0_,
    input [15:1] raddr1_, output reg [15:0] rdata1_, output reg rvalid1_,
    output reg [15:1] store_addr, output reg [15:0] store_data, output store_en,
    input wen0, input [15:1] waddr0, input [15:0] wdata0);

    parameter DELAY = 1;
    parameter NUM_SETS = 64;
    parameter DATA_WIDTH = 16;
    parameter INDEX_WIDTH = 6;
    parameter TAG_WIDTH = 8;

    //TODO: May be taking in too much data -> update memory

    wire [DATA_WIDTH - 1: 0] addr0 = shift_reg[DELAY];
    wire wen = shift_write[DELAY][0];
    wire [DATA_WIDTH - 1: 0] wdata = shift_write[DELAY][31:16];
    wire [DATA_WIDTH - 1: 1] waddr = shift_write[DELAY][15:1];

    //Memory 16: [15:8] Tag [7:2] Index [1:0] Offset
    reg [DATA_WIDTH - 1 : 0] data[0 : NUM_SETS - 1];
    reg [TAG_WIDTH - 1 : 0] tag[0 : NUM_SETS - 1];
    reg [DATA_WIDTH - 1: 0] valid[0 : NUM_SETS - 1];

    wire [TAG_WIDTH - 1: 0] rtag0 = addr0[15:16-TAG_WIDTH+1];
    wire [INDEX_WIDTH - 1: 0] rindex0 = addr0[16-TAG_WIDTH:16-TAG_WIDTH-INDEX_WIDTH+1];

    wire hit0 = (tag[rindex0] === rtag0);

    reg [DATA_WIDTH - 1: 0] shift_reg [0:DELAY];
    reg [DATA_WIDTH + 15: 0] shift_write[0:DELAY];

    integer i;
    initial begin
        for(i = 0; i < NUM_SETS; i = i + 1) begin
            valid[i] <= 1'b0;
        end
    end

    wire store_en = wen0 & valid[waddr0[7:2]];

    always @(posedge clk) begin
        shift_reg[0] <= raddr0_;
        shift_write[0] <= {wdata0, waddr0, wen0};

        for(i = 0; i < DELAY; i = i + 1) begin
            shift_reg[i + 1] <= shift_reg[i];
            shift_write[i + 1] <= shift_write[i];
        end

        if(wen0) begin
            if(valid[waddr[7:2]] == 1'b1) begin
                store_data <= data[waddr[7:2]];
                store_addr <= {tag[waddr[7:2]], waddr[7:2], 2'b00};
            end
            data[waddr[7:2]] <= wdata;
            tag[waddr[7:2]] <= waddr[15:16-TAG_WIDTH+1];
            valid[waddr[7:2]] <= 1'b1;
        end

        if(hit0 & valid[rindex0]) begin
            rdata0_ <= data[rindex0];
            rvalid0_ <= 1'b1;
        end
        else begin
            rvalid0_ <= 1'b0;
        end
    end


endmodule