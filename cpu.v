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

    wire mem_wen;
    wire [15:0] mem_waddr;
    wire [15:0] mem_wdata;
    wire [15:0] mem_raddr;
    wire [15:0] mem_rdata;

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
        .raddr0_(mem_raddr[15:1]),
        .raddr1_(),
        .rdata0_(mem_rdata),
        .rdata1_(),
        .wen0(mem_wen),
        .waddr0(mem_waddr[15:1]),
        .wdata0(mem_wdata)
    );

    wire [23:0] raddr;
    wire [183:0] rdata;

    //Negative, Zero, Positive
    // [9:7] flags, [6] busy, [5:0] ROB index
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

    wire [5:0] d1_tailA = ROBtail;
    wire [5:0] d1_tailB = (ROBtail + 1) % 64;
    wire [5:0] d1_tailC = (ROBtail + 2) % 64;
    wire [5:0] d1_tailD = (ROBtail + 3) % 64;

    wire [3:0] opcodeA = instructA[15:12];

    wire is_addrA = (opcodeA === 4'b0001) & (instructA[5:3] === 3'b000);
    wire is_addiA = (opcodeA === 4'b0001) & (instructA[5] === 1'b1);
    wire is_andrA = (opcodeA == 4'b0101) & (instructA[5:3] === 3'b000);
    wire is_andiA = (opcodeA === 4'b0101) & (instructA[5] === 1'b1);
    wire is_brA = (opcodeA === 4'b0000);
    wire is_jmpA = (opcodeA === 4'b1100) & (instructA[11:9] === 3'b000) & (instructA[5:0] === 6'b000000);
    wire is_jsrA = (opcodeA === 4'b0100) & (instructA[11] == 1'b1);
    wire is_jsrrA = (opcodeA === 4'b0100) & (instructA[11:9] === 3'b000) & (instructA[5:0] !== 6'b000000); 
    wire is_ldA = (opcodeA === 4'b0010);
    wire is_ldiA = (opcodeA === 4'b1010);
    wire is_ldrA = (opcodeA === 4'b0110);
    wire is_leaA = (opcodeA === 4'b1110);
    wire is_notA = (opcodeA === 4'b1001) & (instructA[5:0] === 6'b111111);
    wire is_retA = (instructA === 16'hC1C0);
    wire is_retiA = (instructA === 16'h8000);
    wire is_stA = (opcodeA === 4'b0011);
    wire is_stiA = (opcodeA === 4'b1011);
    wire is_strA = (opcodeA === 4'b0111);
    wire is_trapA = (opcodeA === 4'b1111);
    wire is_validA = is_addrA | is_addiA | is_andrA | is_andiA | is_brA | 
                        is_jmpA | is_jsrA | is_jsrrA | is_ldA | is_ldiA | 
                        is_ldrA | is_leaA | is_notA | is_retA | is_retiA | is_stA | is_stiA | is_strA | is_trapA;

    wire [19:0] d1_instructA = {is_validA, is_addrA, is_addiA, is_andrA, is_andiA, is_brA, 
                                    is_jmpA, is_jsrA, is_jsrrA, is_ldA, is_ldiA, 
                                    is_ldrA, is_leaA, is_notA, is_retA, is_retiA, 
                                    is_stA, is_stiA, is_strA, is_trapA};


    wire is_ldunitA = is_ldA | is_ldiA | is_ldrA | is_stA | is_stiA | is_strA;
    wire is_aluunitA = is_addrA | is_addiA | is_andiA | is_notA | is_leaA;

    wire [15:0] imm5A = {{12{instructA[4]}}, instructA[3:0]};
    wire [15:0] pc_offset9A = {{8{instructA[8]}}, instructA[7:0]};
    wire [15:0] offset6A = {{11{instructA[5]}}, instructA[4:0]};

    wire useA0 = is_addrA | is_addiA | is_andrA | is_andiA | is_jmpA | is_jsrrA | is_ldrA | is_notA;
    wire useA1 = is_addrA | is_andrA;
    wire [1:0] useA = {useA0, useA1};

    wire is_aluA = (opcodeA == 4'b0001) | (opcodeA == 4'b1010) | (opcodeA == 4'b1001);
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

    //Decode 2
    //TODO: Timing issues with tailA and useA

    reg [19:0] d2_instructA;
    reg d2_is_ldunitA;
    reg d2_is_aluunitA;
    reg d2_is_bunitA;
    reg [15:0] d2_imm5A;
    reg [15:0] d2_pc_offset9A;
    reg [15:0] d2_offset6A;

    reg [5:0] d2_tailA; //ROB
    reg [3:0] d2_opcodeA; //Operation
    reg d2_is_aluA;
    reg d2_writeToRegA;
    reg [2:0] d2_writeRegA;
    reg [2:0] d2_regA0;
    reg [2:0] d2_regA1;
    reg [1:0] d2_useA_;
    wire [22:0] d2_rdataA0 = rdata[183:161];
    wire [22:0] d2_rdataA1 = rdata[160:138];

    // [19] is_valid, [18]addr, [17] addi, [16] andr, [15] andi, [14] br, [13] jmp, [12] jsr, [11] jsrr, [10] ld, 
    // [9] ldi, [8] ldr, [7] lea, [6] not, [5] ret, [4] reti, [3] st, [2] sti, [1] str, [0] trap
    
    wire [5:0] d2_lookA0 = d2_rdataA0[5:0];
    wire [5:0] d2_lookA1 = d2_rdataA1[5:0];
    wire [15:0] d2_valueA0 = (d2_instructA[14] | d2_instructA[10] | d2_instructA[9] | d2_instructA[7] | d2_instructA[3] | d2_instructA[2]) ? d2_pc_offset9A :
                                d2_rdataA0[6] ? ROB[d2_rdataA0[5:0]] : 
                                d2_rdataA0[22:7];
    wire [15:0] d2_valueA1 = (d2_instructA[17] | d2_instructA[15]) ? d2_imm5A :
                                (d2_instructA[8]) ? d2_offset6A :
                                (d2_rdataA1[6]) ? ROB[d2_rdataA1[5:0]] : 
                                d2_rdataA1[22:7];
    
    wire [1:0] d2_useA = {d2_useA_[1] & ROB[d2_lookA0][32] == 1'b0, d2_useA_[0] & ROB[d2_lookA1][32] == 1'b0};
    //TODO: Update ROBcheck with the computed values ehre too

    wire [56:0] d2_outputA = {d2_opcodeA, d2_tailA, d2_lookA0, d2_lookA1, d2_valueA0, d2_valueA1, d2_useA, d2_instructA[19]};

    reg d2_is_aluunitB;
    reg d2_is_ldunitB;
    reg d2_is_bunitB;
    wire [56:0] d2_outputB;

    reg d2_is_aluunitC;
    reg d2_is_ldunitC;
    reg d2_is_bunitC;
    wire [56:0] d2_outputC;

    reg d2_is_aluunitD;
    reg d2_is_ldunitD;
    reg d2_is_bunitD;
    wire [56:0] d2_outputD;

    // [22:7]data, [6] busy, [5:0] rob_loc
    always @(posedge clk) begin
        d2_instructA <= d1_instructA;
        d2_is_ldunitA <= is_ldunitA;
        d2_is_aluunitA <= is_aluunitA;
        d2_imm5A <= imm5A;
        d2_pc_offset9A <= pc_offset9A;
        d2_offset6A <= offset6A;

        d2_tailA <= d1_tailA;
        d2_opcodeA <= opcodeA;
        d2_is_aluA <= is_aluA;
        d2_writeToRegA <= writeToRegA;
        d2_writeRegA <= writeRegA;
        d2_regA0 <= regA0;
        d2_regA1 <= regA1;
        d2_useA_ <= useA;
    end 

    //TODO: Store Instructions into buffer to be put into the reservation stations

    // // // // //
    //    ROB   //
    // // // // //


    //TODO: Add support for the condition registers
    //Ready Bit, Value, PC (for piping into cache & branch checking for now)
    reg [32:0] ROB[0:63];
    //Addition check for: [5] isOutput, [4] IsStore, [3] IsWriteToReg, [2:0] RegNum
    reg [5:0] ROBcheck[0:63];
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

    //TODO: Add support for ordering these instructions in
    queue alu_queue(
        .clk(clk),
        .flush(),
        .taken(alu_queue_used),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation0(d2_opcodeA), .inROB0(d2_tailA), .inLook0A(d2_lookA0), .inLook0B(d2_lookA1), .inValue0A(d2_valueA0), .inValue0B(d2_valueA1), .inUse0(d2_useA), .inReady0(d2_instructA[19]),
        .inOperation1(), .inROB1(), .inLook1A(), .inLook1B(), .inUse1(), .inReady1(1'b0),
        .inOperation2(), .inROB2(), .inLook2A(), .inLook2B(), .inUse2(), .inReady2(1'b0),
        .inOperation3(), .inROB3(), .inLook3A(), .inLook3B(), .inUse3(), .inReady3(1'b0),
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

    
    //////////////
    // BU QUEUE //
    //////////////
    wire [1:0] bu_buq_used = {1'b0, buq_used};
    wire buq_used;
    wire [56:0] buq_out;

    queue bu_queue(
        .clk(clk),
        .flush(),
        .taken(bu_buq_used),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation0(), .inROB0(), .inLook0A(), .inLook0B(), .inUse0(), .inReady0(),
        .inOperation1(), .inROB1(), .inLook1A(), .inLook1B(), .inUse1(), .inReady1(),
        .inOperation2(), .inROB2(), .inLook2A(), .inLook2B(), .inUse2(), .inReady2(),
        .inOperation3(), .inROB3(), .inLook3A(), .inLook3B(), .inUse3(), .inReady3(),
        .outOperation0(buq_out),
        .outOperation1()
    );


    wire [40:0] bu_rs_out;
    wire bu_rs_valid;
    reservation_station bu_rs(
        .clk(clk),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation(buq_out), .operationUsed(buq_used),
        .outOperation(bu_rs_out), .outOperationValid(bu_rs_valid)
    );

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
                            (alu_opcode0 == 4'b1001) ? ~alu_value0A :   0;                    // NOT
    
    // NZP
    assign forwardA = {alu_valid0, alu_rob0, alu_out0};

    always @(posedge clk) begin
        //TODO: link functional unit A to instruction queue
        alu_valid0 <= alu_rs_0_valid;
        alu_opcode0 <= alu_rs_0_out[40:37];
        alu_rob0 <= alu_rs_0_out[36:32];
        alu_value0A <= alu_rs_0_out[31:16];
        alu_value0B <= alu_rs_0_out[15:0];
        if ((alu_opcode0 == 4'b0001) | (alu_opcode0 == 4'b0101) | (alu_opcode0 == 4'b1001)
            & alu_rob0 > conditionCode[5:0]
            & alu_rob0 > alu_rob1
            & alu_valid0)
            //& alu_rob0 > load store unit rob
            //& alu_rob0 > branch unit rob
            begin
                //conditionCode <= {1'b1, {alu_out0[15], alu_out0 ==== 0, ~alu_out0[15]}, alu_rob0};
                conditionCode <= {1'b1, alu_out0[15], alu_out0 == 0, ~alu_out0[15], alu_rob0};
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
    assign forwardB = {alu_valid1, alu_rob1, alu_out1};

    always @(posedge clk) begin
        alu_valid1 <= alu_rs_1_valid;
        alu_opcode1 <= alu_rs_1_out[40:37];
        alu_rob1 <= alu_rs_1_out[36:32];
        alu_value1A <= alu_rs_1_out[31:16];
        alu_value1B <= alu_rs_1_out[15:0];

    end



    // Branch Unit: uses forwardC
    reg bu_valid;

    reg [3:0] bu_opcode;
    reg [5:0] bu_rob;
    reg [31:0] bu_value;
    reg [15:0] bu_pcoffset11;
    reg bu_rflag;
    reg [15:0] bu_pc;
    reg bu_valid0 = 1'b0;
    
    wire is_jmp = (bu_opcode == 4'b1100);
    wire is_jsr = (bu_opcode == 4'b0100);
    wire is_br = (bu_opcode == 4'b0000);
    wire [15:0] bu_pc_offest = {{5{bu_pcoffset11[10]}}, bu_pcoffset11[10:0]};
    wire [15:0]target = is_jmp ? bu_value :
                        is_jsr ?
                            (bu_rflag === 0) ? bu_value :
                            (bu_pc + 8) + {{5{bu_pcoffset11[10]}}, {bu_pcoffset11[10:0]}} :
                        is_br ? (bu_pc + 8) + {{5{bu_pcoffset11[10]}}, {bu_pcoffset11[10:0]}}: //I changed this, might not be correct
                        pc + 8;
                            
    wire [15:0]bu_r7 = bu_pc + 8;

    wire bu_jmp = is_jmp ||
                is_jsr ||
                1;//;(is_br && ((bu_n && bu_nzp[2]) || (bu_z && bu_nzp[1]) || (bu_p && bu_nzp[0])));
        //TODO: bu_n does not exist

    always @(posedge clk) begin
        bu_valid <= bu_rs_valid;
        bu_opcode <= bu_rs_out[40:37];
        bu_rob <= bu_rs_out[36:32];
        bu_value <= bu_rs_out[31:0];
    end

    // Load Store Unit: uses forwardD
    wire [56:0] lsu_out;
    queue lsu_queue(
        .clk(clk),
        .flush(),
        .taken({1'b0, !load_stall}),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation0(), .inROB0(), .inLook0A(), .inLook0B(), .inUse0(), .inReady0(),
        .inOperation1(), .inROB1(), .inLook1A(), .inLook1B(), .inUse1(), .inReady1(),
        .inOperation2(), .inROB2(), .inLook2A(), .inLook2B(), .inUse2(), .inReady2(),
        .inOperation3(), .inROB3(), .inLook3A(), .inLook3B(), .inUse3(), .inReady3(),
        .outOperation0(lsu_out),
        .outOperation1()
    );
    wire load_stall;
    wire [15:0] lsu_data;
    wire [5:0] lsu_rob;
    wire lsu_out_valid;

    load_store_unit lsu(
        .clk(clk),
        .flush(),
        .stores_to_commit(),
        .is_ld(), .data(), .location(), .ROBloc(), .input_valid(),
        .commit_data(mem_wdata), .commit_location(mem_waddr), .commit_valid(mem_wen),
        .mem_location(mem_raddr), .mem_valid(),
        .mem_data(mem_rdata),
        .out_data(lsu_data), .out_ROB(lsu_rob), .out_valid(lsu_out_valid),
        .load_stall(load_stall)
    );

    assign forwardD = {lsu_out_valid, lsu_rob, lsu_data};

    always @(posedge clk) begin
        if(pc > 100)
            halt <= 1;
        pc <= pc + 8;
        //pc <= target;
    end
endmodule
