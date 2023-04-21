`timescale 1ps/1ps

module mem(input clk,
    input [15:1]rinstruct0_, output [15:0]routput0_,
    input [15:1]rinstruct1_, output [15:0]routput1_,
    input [15:1]rinstruct2_, output [15:0]routput2_,
    input [15:1]rinstruct3_, output [15:0]routput3_, 
    input [15:1]raddr0_, output [15:0]rdata0_,
    input [15:1]raddr1_, output [15:0]rdata1_,
    input wen0, input [15:1]waddr0, input [15:0]wdata0);

    reg [15:0]data[0:16'h7fff];

    /* Simulation -- read initial content from file */
    initial begin
        $readmemh("mem.hex",data);
    end

    reg [15:1]rinstruct0;
    reg [15:1]rinstruct1;
    reg [15:1]rinstruct2;
    reg [15:1]rinstruct3;

    assign routput0_ = data[rinstruct0];
    assign routput1_ = data[rinstruct1];
    assign routput2_ = data[rinstruct2];
    assign routput3_ = data[rinstruct3];

    reg [15:1]raddr0;
    reg [15:0]rdata0;

    reg [15:1]raddr1;
    reg [15:0]rdata1;

    assign rdata0_ = rdata0;
    assign rdata1_ = rdata1;

    always @(posedge clk) begin
        rinstruct0 <= rinstruct0_;
        rinstruct1 <= rinstruct1_;
        rinstruct2 <= rinstruct2_;
        rinstruct3 <= rinstruct3_;

        raddr0 <= raddr0_;
        raddr1 <= raddr1_;
        rdata0 <= data[raddr0];
        rdata1 <= data[raddr1];
        
        if (wen0) begin
            data[waddr0] <= wdata0;
        end
    end

endmodule
