module memory_controller(input clk, 
    input [15:1] rinstruct0_, output [15:0] routput0_,
    input [15:1] rinstruct1_, output [15:0] routput1_,
    input [15:1] rinstruct2_, output [15:0] routput2_,
    input [15:1] rinstruct3_, output [15:0] routput3_,
    input [15:1] raddr0_, output reg [15:0] rdata0_,
    input [15:1] raddr1_, output [15:0] rdata1_,
    input wen0, input [15:1] waddr0, input [15:0] wdata0);

    cache #(10) cache(
        .clk(clk),
        .raddr0_(raddr0_), .rdata0_(), .rvalid0_(),
        .raddr1_(raddr1_), .rdata1_(), .rvalid1_(),
        .store_addr(), .store_data(), .store_en(),
        .wen0(), .waddr0(), .wdata0()
    ); 

    //todo: i have read issues where writes can be overwrriten by a memory fetch

    mem_long #(85) mem(
        .clk(clk),
        .rinstruct0_(rinstruct0_), .routput0_(routput0_),
        .rinstruct1_(rinstruct1_), .routput1_(routput1_),
        .rinstruct2_(rinstruct2_), .routput2_(routput2_),
        .rinstruct3_(rinstruct3_), .routput3_(routput3_),
        .raddr0_(), .rdata0_(),
        .raddr1_(), .rdata1_(),
        .wen0(), .waddr0(), .wdata0()
    );

endmodule