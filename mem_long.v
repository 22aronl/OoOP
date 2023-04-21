module mem_long(input clk,
    input [15:1] rinstruct0_, output [15:0] routput0_,
    input [15:1] rinstruct1_, output [15:0] routput1_,
    input [15:1] rinstruct2_, output [15:0] routput2_,
    input [15:1] rinstruct3_, output [15:0] routput3_,
    input [15:1] raddr0_, output reg [15:0] rdata0_,
    input [15:1] raddr1_, output [15:0] rdata1_,
    input wen0, input [15:1] waddr0, input [15:0] wdata0);

    parameter DELAY = 2;
    parameter WIDTH = $clog2(DELAY + 1);

    reg [15:0]data[0:16'h7fff];

    reg [15:1]rinstruct0;
    reg [15:1]rinstruct1;
    reg [15:1]rinstruct2;
    reg [15:1]rinstruct3;

    assign routput0_ = data[rinstruct0];
    assign routput1_ = data[rinstruct1];
    assign routput2_ = data[rinstruct2];
    assign routput3_ = data[rinstruct3];

    // [15:1] addr
    reg [15:1] shift_reg [0:DELAY];
    // [31:16] data, [15:1] addr, [0] wen
    reg [31:0] shift_write[0:DELAY];

    initial begin
        $readmemh("mem.hex",data);
    end

    integer i;

    always @(posedge clk) begin 
        rinstruct0 <= rinstruct0_;
        rinstruct1 <= rinstruct1_;
        rinstruct2 <= rinstruct2_;
        rinstruct3 <= rinstruct3_;

        shift_reg[0] <= raddr0_;
        rdata0_ <= data[shift_reg[DELAY]];

        if(shift_write[DELAY][0] === 1'b1) begin
            data[shift_write[DELAY][15:1]] <= shift_write[DELAY][31:16];
        end

        for(i = 0; i < DELAY; i = i + 1) begin
            shift_reg[i + 1] <= shift_reg[i];
            shift_write[i + 1] <= shift_write[i];
        end
    end

endmodule