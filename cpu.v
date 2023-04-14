`timescale 1ps/1ps

module main();

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end

    wire clk;
    clock c0(
        .clk(clk)
    );

    reg halt = 0;
    counter ctr(
        .clk(clk),
        .isHalt(halt)
    );

    reg [15:0] pc = 16'h0000;

    wire [15:0] pcA = pc;
    wire [15:0] pcB = pc + 2;
    wire [15:0] pcC = pc + 4;
    wire [15:0] pcD = pc + 6;

    wire [15:0] instructA;
    wire [15:0] instructB;
    wire [15:0] instructC;
    wire [15:0] instructD;

    //TODO: Update to accomodate for branch prediction
    //TODO: Actually bother implementing instruction cache
    //TODO: Those tasks may be interrelated

    mem mem(
        .clk(clk),
        .rinstruct0_(pcA[15:1]),
        .rinstruct1_(pcB[15:1]),
        .rinstruct2_(pcC[15:1]),
        .rinstruct3_(pcD[15:1]),
        .routput0_(instructA),
        .routput1_(instructB),
        .routput2_(instructC),
        .routput3_(instructD),
        .raddr0_(),
        .raddr1_(),
        .rdata0_(),
        .rdata1_(),
        .wen0(),
        .waddr0(),
        .wdata0()
    );

    regs regs(
        .clk(clk),
        .raddr0_(),
        .raddr1_(),
        .raddr2_(),
        .raddr3_(),
        .raddr4_(),
        .raddr5_(),
        .rdata0(),
        .rdata1(),
        .rdata2(),
        .rdata3(),
        .rdata4(),
        .rdata5(),
        .wen0(),
        .waddr0(),
        .wdata0(),
        .wen1(),
        .waddr1(),
        .wdata1()
    );

    //decode 1
    reg d1_pcA;
    reg d1_pcB;
    reg d1_pcC;
    reg d1_pcD;

    

    always @(posedge clk) begin
        d1_pcA <= pcA;
        d1_pcB <= pcB;
        d1_pcC <= pcC;
        d1_pcD <= pcD;
    end


    always @(posedge clk) begin
        if(pc > 100)
            halt <= 1;
        pc <= pc + 8;
    end
endmodule