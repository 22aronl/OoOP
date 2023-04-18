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
    // [9] valid [8:6] condition code, [5:0] ROB index
    reg [9:0] conditionCode;
    // reg [7:0] conditionCodes[0:2];

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
                            (opcodeA == 4'b0110) | (opcodeA == 4'b1110) | (opcodeA == 4'b1001);
    wire [2:0] writeRegA = instructA[11:9];
    wire [2:0] regA0 = instructA[8:6];
    wire [2:0] regA1 = instructA[2:0];

    wire [3:0] opcodeB = instructB[15:12];
    wire writeToRegB = (opcodeB == 4'b0001) | (opcodeB == 4'b0101) | (opcodeB == 4'b0010) | (opcodeB == 4'b1010) |
                            (opcodeB == 4'b0110) | (opcodeB == 4'b1110) | (opcodeB == 4'b1001);
    wire [2:0] writeRegB = instructB[11:9];
    wire [2:0] regB0 = instructB[8:6];
    wire [2:0] regB1 = instructB[2:0];

    wire [3:0] opcodeC = instructC[15:12];
    wire writeToRegC = (opcodeC == 4'b0001) | (opcodeC == 4'b0101) | (opcodeC == 4'b0010) | (opcodeC == 4'b1010) |
                            (opcodeC == 4'b0110) | (opcodeC == 4'b1110) | (opcodeC == 4'b1001);
    wire [2:0] writeRegC = instructC[11:9];
    wire [2:0] regC0 = instructC[8:6];
    wire [2:0] regC1 = instructC[2:0];

    wire [3:0] opcodeD = instructD[15:12];
    wire writeToRegD = (opcodeD == 4'b0001) | (opcodeD == 4'b0101) | (opcodeD == 4'b0010) | (opcodeD == 4'b1010) |
                            (opcodeD == 4'b0110) | (opcodeD == 4'b1110) | (opcodeD == 4'b1001);
    wire [2:0] writeRegD = instructD[11:9];
    wire [2:0] regD0 = instructD[8:6];
    wire [2:0] regD1 = instructD[2:0];

    assign raddr = {regA0, regA1, regB0, regB1, regC0, regC1, regD0, regD1};

    //TODO: Fix the register dependency checking (simulatenous dependency issues)

    always @(posedge clk) begin
        d1_pcA <= pcA;
        d1_pcB <= pcB;
        d1_pcC <= pcC;
        d1_pcD <= pcD;
    end

    //TODO: Store Instructions into buffer to be put into the reservation stations

    // // // // //
    //    ROB   //
    // // // // //


    //TODO: Add support for the condition registers
    //Ready Bit, Value, PC (for piping into cache & branch checking for now)
    reg [32:0] ROB[0:63];
    reg [5:0] ROBhead = 5'h00;
    reg [5:0] ROBtail = 5'h00;
    reg [5:0] ROBsize = 5'h00;

    always @(posedge clk) begin
        ROB[d1_tailA][15:0] <= pcA;
        ROB[d1_tailB][15:0] <= pcB;
        ROB[d1_tailC][15:0] <= pcC;
        ROB[d1_tailD][15:0] <= pcD;
        ROBtail <= (ROBtail + 4) % 64;
    end

    always @(posedge clk) begin
        if(forwardA[22] == 1'b1) begin
            ROB[forwardA[21:16]][31:16] <= forwardA[15:0];
            ROB[forwardA[21:16]][32] <= 1'b1;
        end

        if(forwardB[22] == 1'b1) begin
            ROB[forwardB[21:16]][31:16] <= forwardB[15:0];
            ROB[forwardB[21:16]][32] <= 1'b1;
        end

        if(forwardC[22] == 1'b1) begin
            ROB[forwardC[21:16]][31:16] <= forwardC[15:0];
            ROB[forwardC[21:16]][32] <= 1'b1;
        end

        if(forwardD[22] == 1'b1) begin
            ROB[forwardD[21:16]][31:16] <= forwardD[15:0];
            ROB[forwardD[21:16]][32] <= 1'b1;
        end
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

    //TODO: Fix Wiring

    wire alu_queue_used_0;
    wire alu_queue_used_1;
    wire [1:0] alu_queue_used = {alu_queue_used_0 & alu_queue_used_1, alu_queue_used_0 ^ alu_queue_used_1};
    wire [56:0] alu_queue_out0;
    wire [56:0] alu_queue_out1;

    queue alu_queue(
        .clk(clk),
        .flush(),
        .taken(alu_queue_used),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation0(), .inROB0(), .inLook0A(), .inLook0B(), .inUse0(), .inReady0(),
        .inOperation1(), .inROB1(), .inLook1A(), .inLook1B(), .inUse1(), .inReady1(),
        .inOperation2(), .inROB2(), .inLook2A(), .inLook2B(), .inUse2(), .inReady2(),
        .inOperation3(), .inROB3(), .inLook3A(), .inLook3B(), .inUse3(), .inReady3(),
        .outOperation0(alu_queue_out0),
        .outOperation1(alu_queue_out1)
    );

    wire [40:0] alu_rs_0_out;
    wire alu_rs_0_valid;
    reservation_station alu_rs0(
        .clk(clk),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation(alu_queue_out0), .operationUsed(alu_queue_used_0),
        .outOperation(alu_rs_0_out), .outOperationValid(alu_rs_0_valid)
    );

    wire [40:0] alu_rs_1_out;
    wire alu_rs_1_valid;
    reservation_station alu_rs1(
        .clk(clk),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation(alu_queue_out1), .operationUsed(alu_queue_used_1),
        .outOperation(alu_rs_1_out), .outOperationValid(alu_rs_1_valid)
    );

    

    // TODO : Insruction Queues


    // // // // // // // //
    //  Functional Units //
    // // // // // // // //

    // ALU 1 : uses forwardA
    // 0 is add, 1 is and, 2 is Not
    reg [3:0] alu_opcode0;
    reg [5:0] alu_rob0;
    reg [15:0] alu_value0A;
    reg [15:0] alu_value0B;
    reg alu_valid0 = 1'b0;

    wire alu_unknown0 = ~((alu_opcode0 == 4'b0000) || (alu_opcode0 == 4'b0101) || (alu_opcode0 == 4'b1001));

    wire [15:0] alu_out0 = (alu_opcode0 == 4'b0000) ? alu_value0A + alu_value0B :           // ADD
                            (alu_opcode0 == 4'b0101) ? alu_value0A[4] & alu_value0B[4] :    // AND (based on bit 5)
                            (alu_opcode0 == 4'b1001) ? ~alu_value0A :                       // NOT
    
    // NZP
    wire [2:0] alu_condition_code0 = (alu_opcode0 == 4'b0001) | (alu_opcode0 == 4'b0101) | (alu_opcode0 == 4'b1001) ? {alu_out0[15], alu_out0===0, ~alu_out0[15]}
    
    assign forwardA = {alu_valid0, alu_rob0, alu_out0};

    always @(posedge clk) begin
        //TODO: link functional unit A to instruction queue
        alu_valid0 <= alu_rs_0_valid;
        alu_opcode0 <= alu_rs_0_out[40:37];
        alu_rob0 <= alu_rs_0_out[36:32];
        alu_value0A <= alu_rs_0_out[31:16];
        alu_value0B <= alu_rs_0_out[15:0];
        if ((alu_opcode0 == 4'b0001) | (alu_opcode0 == 4'b0101) | (alu_opcode0 == 4'b1001))
            & alu_rob0 > conditionCode[5:0]
            & alu_rob0 > alu_rob1
            & alu_valid0
            //& alu_rob0 > load store unit rob
            //& alu_rob0 > branch unit rob
            begin
                conditionCode <= {1, {alu_out0[15], alu_out0===0, ~alu_out0[15]}, alu_rob0};
            end
    end

    // ALU 2: uses forwardB
    reg [3:0] alu_opcode1;
    reg [5:0] alu_rob1;
    reg [15:0] alu_value1A;
    reg [15:0] alu_value1B;
    reg alu_valid1 = 1'b0;

    wire alu_unknown1 = ~((alu_opcode0 == 4'b0000) || (alu_opcode0 == 4'b0101) || (alu_opcode0 == 4'b1001));

    wire [15:0] alu_out1 = (alu_opcode1 == 4'b0000) ? alu_value1A + alu_value1B :            // ADD
                            (alu_opcode1 == 4'b0101) ? alu_value1A[4] & alu_value1B[4] :    // AND (based on bit 5)
                            (alu_opcode1 == 4'b1001) ? ~alu_value1A :                       // NOT
                            0;
    // NZP
    wire [2:0] alu_condition_code1 = (alu_opcode1 == 4'b0001) | (alu_opcode1 == 4'b0101) | (alu_opcode1 == 4'b1001) ? {alu_out1[15], alu_out1===0, ~alu_out1[15]}
    assign forwardB = {alu_valid1, alu_rob1, alu_out1};

    always @(posedge clk) begin
        alu_valid1 <= alu_rs_1_valid;
        alu_opcode1 <= alu_rs_1_out[40:37];
        alu_rob1 <= alu_rs_1_out[36:32];
        alu_value1A <= alu_rs_1_out[31:16];
        alu_value1B <= alu_rs_1_out[15:0];
        if ((alu_opcode1 == 4'b0001) | (alu_opcode1 == 4'b0101) | (alu_opcode1 == 4'b1001))
            & alu_rob1 > conditionCode[5:0]
            & alu_rob1 > alu_rob1
            & alu_valid1
            //& alu_rob0 > load store unit rob
            //& alu_rob0 > branch unit rob
            begin
                conditionCode <= {1, {alu_out1[15], alu_out1===0, ~alu_out1[15]}, alu_rob1};
            end

    end



    // Branch Unit: uses forwardC
    reg [3:0] bu_opcode;
    reg [5:0] bu_rob0;
    reg [15:0] bu_value0B;
    reg [15:0] bu_pc;
    reg alu_valid0 = 1'b0;
    
    

    wire [15:0]target = (bu_opcode == 4'b1100) ? bu_baser :
                        (bu_opcode == 4'b0100) ?
                            (ins[11] == 0) ? bu_baser :
                            (pc + 8) + {5{ins[10]}, {ins[10:0]}} :
                        0;
                            
    wire [15:0]bu_r7 = pc + 8;


    // Load Store Unit: uses forwardD
    //TODO: Add Load Store Unit

    always @(posedge clk) begin
        if(pc > 100)
            halt <= 1;
        pc <= pc + 8;
    end
endmodule