`timescale 1ps/1ps

module regs(input clk,
    input [2:0]raddr0_, output [22:0]rdata0, 
    input [2:0]raddr1_, output [22:0]rdata1,
    input [2:0]raddr2_, output [22:0]rdata2,
    input [2:0]raddr3_, output [22:0]rdata3,
    input [2:0]raddr4_, output [22:0]rdata4,
    input [2:0]raddr5_, output [22:0]rdata5,
    input [2:0]raddr6_, output [22:0]rdata6,
    input [2:0]raddr7_, output [22:0]rdata7,
    input wen0, input [2:0]waddr0, input [15:0]wdata0,
    input wen1, input [2:0]waddr1, input [15:0]wdata1);

    reg [15:0]data[0:7];
    reg busy[0:7];
    reg [5:0] rob_loc[0:7];

    reg [2:0]raddr0;
    reg [2:0]raddr1;
    reg [2:0]raddr2;
    reg [2:0]raddr3;
    reg [2:0]raddr4;
    reg [2:0]raddr5;
    reg [2:0]raddr6;
    reg [2:0]raddr7;

    assign rdata0 = {data[raddr0], busy[raddr0], rob_loc[raddr0]};
    assign rdata1 = {data[raddr1], busy[raddr1], rob_loc[raddr1]};
    assign rdata2 = {data[raddr2], busy[raddr2], rob_loc[raddr2]};
    assign rdata3 = {data[raddr3], busy[raddr3], rob_loc[raddr3]};
    assign rdata4 = {data[raddr4], busy[raddr4], rob_loc[raddr4]};
    assign rdata5 = {data[raddr5], busy[raddr5], rob_loc[raddr5]};
    assign rdata6 = {data[raddr6], busy[raddr6], rob_loc[raddr6]};
    assign rdata7 = {data[raddr7], busy[raddr7], rob_loc[raddr7]};

    integer i;
    initial begin
        for(i = 0; i < 8; i = i + 1) begin
            busy[i] = 1'b0;
        end
    end

    always @(posedge clk) begin
        raddr0 <= raddr0_;
        raddr1 <= raddr1_;
        raddr2 <= raddr2_;
        raddr3 <= raddr3_;
        raddr4 <= raddr4_;
        raddr5 <= raddr5_;
        raddr6 <= raddr6_;
        raddr7 <= raddr7_;

        if (wen0) begin
            data[waddr0] <= wdata0;
        end

        if(wen1) begin
            data[waddr1] <= wdata1;
        end
    end

endmodule
