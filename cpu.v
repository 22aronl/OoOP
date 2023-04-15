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
    //TODO: Also implement instruction buffer
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

    wire [23:0] raddr;
    wire [183:0] rdata;

    //Negative, Zero, Positive
    // [7] valid [6] condition code, [5:0] ROB index
    reg [7:0] conditionCodes[0:2];

    regs regs(
        .clk(clk),
        .raddr0_(raddr[23:21]),
        .raddr1_(raddr[20:18]),
        .raddr2_(raddr[17:15]),
        .raddr3_(raddr[14:12]),
        .raddr4_(raddr[11:9]),
        .raddr5_(raddr[8:6]),
        .raddr6_(raddr[5:3]),
        .raddr7_(raddr[2:0]),
        .rdata0(rdata[183:161]),
        .rdata1(rdata[160:138]),
        .rdata2(rdata[137:115]),
        .rdata3(rdata[114:92]),
        .rdata4(rdata[91:69]),
        .rdata5(rdata[68:46]),
        .rdata6(rdata[45:23]),
        .rdata7(rdata[22:0]),
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

    //TODO: Deal with Condition Codes pls

    wire [15:0] d1_tailA = ROBtail;
    wire [15:0] d1_tailB = (ROBtail + 1) % 64;
    wire [15:0] d1_tailC = (ROBtail + 2) % 64;
    wire [15:0] d1_tailD = (ROBtail + 3) % 64;

    wire [3:0] opcodeA = instructA[15:12];
    wire writeToRegA = (opcodeA == 4'b0001) | (opcodeA == 4'b0101) | (opcodeA == 4'b0010) | (opcodeA == 4'b1010) |
                            (opcodeA == 4'b0110) | (opcodeA == 4'b1110) | (opcodeA == 4'1001);
    wire [2:0] writeRegA = [11:9];
    wire [2:0] regA0 = instructA[8:6];
    wire [2:0] regA1 = instructA[2:0];

    wire [3:0] opcodeB = instructB[15:12];
    wire writeToRegB = (opcodeB == 4'b0001) | (opcodeB == 4'b0101) | (opcodeB == 4'b0010) | (opcodeB == 4'b1010) |
                            (opcodeB == 4'b0110) | (opcodeB == 4'b1110) | (opcodeB == 4'1001);
    wire [2:0] writeRegB = [11:9];
    wire [2:0] regB0 = instructB[8:6];
    wire [2:0] regB1 = instructB[2:0];

    wire [3:0] opcodeC = instructC[15:12];
    wire writeToRegC = (opcodeC == 4'b0001) | (opcodeC == 4'b0101) | (opcodeC == 4'b0010) | (opcodeC == 4'b1010) |
                            (opcodeC == 4'b0110) | (opcodeC == 4'b1110) | (opcodeC == 4'1001);
    wire [2:0] writeRegC = [11:9];
    wire [2:0] regC0 = instructC[8:6];
    wire [2:0] regC1 = instructC[2:0];

    wire [3:0] opcodeD = instructD[15:12];
    wire writeToRegD = (opcodeD == 4'b0001) | (opcodeD == 4'b0101) | (opcodeD == 4'b0010) | (opcodeD == 4'b1010) |
                            (opcodeD == 4'b0110) | (opcodeD == 4'b1110) | (opcodeD == 4'1001);
    wire [2:0] writeRegD = [11:9];
    wire [2:0] regD0 = instructD[8:6];
    wire [2:0] regD1 = instructD[2:0];

    assign raddr = {regA0, regA1, regB0, regB1, regC0, regC1, regD0, regD1};

    always @(posedge clk) begin
        d1_pcA <= pcA;
        d1_pcB <= pcB;
        d1_pcC <= pcC;
        d1_pcD <= pcD;
    end


    // // // // //
    //    ROB  //
    // // // // //

    //Ready Bit, Value, PC (for piping into cache & branch checking for now)
    reg [32:0]ROB[0:63];
    reg [5:0] ROBhead = 5'h00;
    reg [5:0] ROBtail = 5'h00;
    reg [5:0] ROBsize = 5'h00;

    always @(posedge clk) begin
        ROB[d1_tailA][15:0] <= pcA;
        ROB[d1_tailB][15:0] <= pcB;
        ROB[d1_tailC][15:0] <= pcC;
        ROB[d1_tailD][15:0] <= pcD;
    end

    // // //
    // Forwarding BUS
    // // //

    // [22] Valid Bit [21:16] Rob instruction [15:0] Rob Value
    wire [22:0] forwardA;
    wire [22:0] forwardB;
    wire [22:0] forwardC;
    wire [22:0] forwardD;


    // // // // // // // //
    // Instruction Queues //
    // // // // // // // //


    // // //
    // ALU Queue //
    // // //




    always @(posedge clk) begin
        if(pc > 100)
            halt <= 1;
        pc <= pc + 8;
    end
endmodule