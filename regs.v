`timescale 1ps/1ps

module regs(input clk,
    input [3:0]raddr0_, output [15:0]rdata0,
    input [3:0]raddr1_, output [15:0]rdata1,
    input [3:0]raddr2_, output [15:0]rdata2,
    input [3:0]raddr3_, output [15:0]rdata3,
    input [3:0]raddr4_, output [15:0]rdata4,
    input [3:0]raddr5_, output [15:0]rdata5,
    input wen0, input [3:0]waddr0, input [15:0]wdata0,
    input wen1, input [3:0]waddr1, input [15:0]wdata1,
    input wen2, input [3:0]waddr2, input [15:0]wdata2);

    reg [15:0]data[0:15];

    reg [3:0]raddr0;
    reg [3:0]raddr1;
    reg [3:0]raddr2;
    reg [3:0]raddr3;
    reg [3:0]raddr4;
    reg [3:0]raddr5;

    assign rdata0 = data[raddr0];
    assign rdata1 = data[raddr1];
    assign rdata2 = data[raddr2];
    assign rdata3 = data[raddr3];
    assign rdata4 = data[raddr4];
    assign rdata5 = data[raddr5];

    always @(posedge clk) begin
        raddr0 <= raddr0_;
        raddr1 <= raddr1_;
        raddr2 <= raddr2_;
        raddr3 <= raddr3_;
        raddr4 <= raddr4_;
        raddr5 <= raddr5_;

        if (wen0) begin
            data[waddr0] <= wdata0;
        end

        if(wen1) begin
            data[waddr1] <= wdata1;
        end
    end

endmodule
