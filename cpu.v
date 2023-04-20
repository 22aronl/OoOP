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

    wire wen0;
    wire wen1;
    wire [2:0]waddr0;
    wire [2:0]waddr1;
    wire [15:0]wdata0;
    wire [15:0]wdata1;

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
        .rob_locA(writeToA), .rob_waddrA(),
        .rob_locB(), .rob_waddrB(),
        .rob_locC(), .rob_waddrC(),
        .rob_locD(), .rob_waddrD(),
        .wen0(wen0),
        .waddr0(waddr0),
        .wdata0(wdata0),
        .wen1(wen1),
        .waddr1(waddr1),
        .wdata1(wdata1)
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

    wire writeToRegA = is_addrA | is_addiA | is_andrA | is_andiA | is_ldA | is_ldiA | is_ldrA | is_leaA | is_notA;
    wire [2:0] writeRegA = instructA[11:9];
    wire is_storeA = is_stA | is_stiA | is_strA;

    wire is_aluA = (opcodeA == 4'b0001) | (opcodeA == 4'b1010) | (opcodeA == 4'b1001);
    wire [2:0] regA0 = instructA[8:6];
    wire [2:0] regA1 = instructA[2:0];



    wire [3:0] opcodeB = instructB[15:12];

    wire is_addrB = (opcodeB === 4'b0001) & (instructB[5:3] === 3'b000);
    wire is_addiB = (opcodeB === 4'b0001) & (instructB[5] === 1'b1);
    wire is_andrB = (opcodeB == 4'b0101) & (instructB[5:3] === 3'b000);
    wire is_andiB = (opcodeB === 4'b0101) & (instructB[5] === 1'b1);
    wire is_brB = (opcodeB === 4'b0000);
    wire is_jmpB = (opcodeB === 4'b1100) & (instructB[11:9] === 3'b000) & (instructB[5:0] === 6'b000000);
    wire is_jsrB = (opcodeB === 4'b0100) & (instructB[11] == 1'b1);
    wire is_jsrrB = (opcodeB === 4'b0100) & (instructB[11:9] === 3'b000) & (instructB[5:0] !== 6'b000000); 
    wire is_ldB = (opcodeB === 4'b0010);
    wire is_ldiB = (opcodeB === 4'b1010);
    wire is_ldrB = (opcodeB === 4'b0110);
    wire is_leaB = (opcodeB === 4'b1110);
    wire is_notB = (opcodeB === 4'b1001) & (instructB[5:0] === 6'b111111);
    wire is_retB = (instructB === 16'hC1C0);
    wire is_retiB = (instructB === 16'h8000);
    wire is_stB = (opcodeB === 4'b0011);
    wire is_stiB = (opcodeB === 4'b1011);
    wire is_strB = (opcodeB === 4'b0111);
    wire is_trapB = (opcodeB === 4'b1111);
    wire is_validB = is_addrB | is_addiB | is_andrB | is_andiB | is_brB | 
                        is_jmpB | is_jsrB | is_jsrrB | is_ldB | is_ldiB | 
                        is_ldrB | is_leaB | is_notB | is_retB | is_retiB | is_stB | is_stiB | is_strB | is_trapB;

    wire [19:0] d1_instructB = {is_validB, is_addrB, is_addiB, is_andrB, is_andiB, is_brB, 
                                    is_jmpB, is_jsrB, is_jsrrB, is_ldB, is_ldiB, 
                                    is_ldrB, is_leaB, is_notB, is_retB, is_retiB, 
                                    is_stB, is_stiB, is_strB, is_trapB};


    wire is_ldunitB = is_ldB | is_ldiB | is_ldrB | is_stB | is_stiB | is_strB;
    wire is_aluunitB = is_addrB | is_addiB | is_andiB | is_notB | is_leaB;

    wire [15:0] imm5B = {{12{instructB[4]}}, instructB[3:0]};
    wire [15:0] pc_offset9B = {{8{instructB[8]}}, instructB[7:0]};
    wire [15:0] offset6B = {{11{instructB[5]}}, instructB[4:0]};

    wire useB0 = is_addrB | is_addiB | is_andrB | is_andiB | is_jmpB | is_jsrrB | is_ldrB | is_notB;
    wire useB1 = is_addrB | is_andrB;
    wire [1:0] useB = {useB0, useB1};

    wire writeToRegB = is_addrB | is_addiB | is_andrB | is_andiB | is_ldB | is_ldiB | is_ldrB | is_leaB | is_notB;
    wire [2:0] writeRegB = instructB[11:9];
    wire is_storeB = is_stB | is_stiB | is_strB;

    wire is_aluB = (opcodeB == 4'b0001) | (opcodeB == 4'b1010) | (opcodeB == 4'b1001);
    wire [2:0] regB0 = instructB[8:6];
    wire [2:0] regB1 = instructB[2:0];


    // TODO rename 
    wire [3:0] opcodeC = instructC[15:12];

    wire is_addrC = (opcodeB === 4'b0001) & (instructB[5:3] === 3'b000);
    wire is_addiC = (opcodeB === 4'b0001) & (instructB[5] === 1'b1);
    wire is_andrC = (opcodeB == 4'b0101) & (instructB[5:3] === 3'b000);
    wire is_andiC = (opcodeB === 4'b0101) & (instructB[5] === 1'b1);
    wire is_brC = (opcodeB === 4'b0000);
    wire is_jmpC = (opcodeB === 4'b1100) & (instructB[11:9] === 3'b000) & (instructB[5:0] === 6'b000000);
    wire is_jsrC = (opcodeB === 4'b0100) & (instructB[11] == 1'b1);
    wire is_jsrrC = (opcodeB === 4'b0100) & (instructB[11:9] === 3'b000) & (instructB[5:0] !== 6'b000000); 
    wire is_ldC = (opcodeB === 4'b0010);
    wire is_ldiC = (opcodeB === 4'b1010);
    wire is_ldrC = (opcodeB === 4'b0110);
    wire is_leaC = (opcodeB === 4'b1110);
    wire is_notC = (opcodeB === 4'b1001) & (instructB[5:0] === 6'b111111);
    wire is_retC = (instructB === 16'hC1C0);
    wire is_retiC = (instructB === 16'h8000);
    wire is_stC = (opcodeB === 4'b0011);
    wire is_stiC = (opcodeB === 4'b1011);
    wire is_strC = (opcodeB === 4'b0111);
    wire is_trapC = (opcodeB === 4'b1111);
    wire is_validC = is_addrC | is_addiC | is_andrC | is_andiC | is_brC | 
                        is_jmpC | is_jsrC | is_jsrrC | is_ldC | is_ldiC | 
                        is_ldrC | is_leaC | is_notC | is_retC | is_retiC | is_stC | is_stiC | is_strC | is_trapC;

    wire [19:0] d1_instructC = {is_validC, is_addrC, is_addiC, is_andrC, is_andiC, is_brC, 
                                    is_jmpC, is_jsrC, is_jsrrC, is_ldC, is_ldiC, 
                                    is_ldrC, is_leaC, is_notC, is_retC, is_retiC, 
                                    is_stC, is_stiC, is_strC, is_trapC};


    wire is_ldunitC = is_ldC | is_ldiC | is_ldrC | is_stC | is_stiC | is_strC;
    wire is_aluunitC = is_addrC | is_addiC | is_andiC | is_notC | is_leaC;

    wire [15:0] imm5C = {{12{instructC[4]}}, instructC[3:0]};
    wire [15:0] pc_offset9C = {{8{instructC[8]}}, instructC[7:0]};
    wire [15:0] offset6C = {{11{instructC[5]}}, instructC[4:0]};

    wire useC0 = is_addrC | is_addiC | is_andrC | is_andiC | is_jmpC | is_jsrrC | is_ldrC | is_notC;
    wire useC1 = is_addrC | is_andrC;
    wire [1:0] useC = {useC0, useC1};

    wire writeToRegC = is_addrC | is_addiC | is_andrC | is_andiC | is_ldC | is_ldiC | is_ldrC | is_leaC | is_notC;
    wire [2:0] writeRegC = instructC[11:9];
    wire is_storeC = is_stC | is_stiC | is_strC;

    wire is_aluC = (opcodeC == 4'b0001) | (opcodeC == 4'b1010) | (opcodeC == 4'b1001);
    wire [2:0] regC0 = instructC[8:6];
    wire [2:0] regC1 = instructC[2:0];



    // TODO rename 
    wire [3:0] opcodeD = instructD[15:12];

    wire is_addrD = (opcodeB === 4'b0001) & (instructB[5:3] === 3'b000);
    wire is_addiD = (opcodeB === 4'b0001) & (instructB[5] === 1'b1);
    wire is_andrD = (opcodeB == 4'b0101) & (instructB[5:3] === 3'b000);
    wire is_andiD = (opcodeB === 4'b0101) & (instructB[5] === 1'b1);
    wire is_brD = (opcodeB === 4'b0000);
    wire is_jmpD = (opcodeB === 4'b1100) & (instructB[11:9] === 3'b000) & (instructB[5:0] === 6'b000000);
    wire is_jsrD = (opcodeB === 4'b0100) & (instructB[11] == 1'b1);
    wire is_jsrrD = (opcodeB === 4'b0100) & (instructB[11:9] === 3'b000) & (instructB[5:0] !== 6'b000000); 
    wire is_ldD = (opcodeB === 4'b0010);
    wire is_ldiD = (opcodeB === 4'b1010);
    wire is_ldrD = (opcodeB === 4'b0110);
    wire is_leaD = (opcodeB === 4'b1110);
    wire is_notD = (opcodeB === 4'b1001) & (instructB[5:0] === 6'b111111);
    wire is_retD = (instructB === 16'hC1C0);
    wire is_retiD = (instructB === 16'h8000);
    wire is_stD = (opcodeB === 4'b0011);
    wire is_stiD = (opcodeB === 4'b1011);
    wire is_strD = (opcodeB === 4'b0111);
    wire is_trapD = (opcodeB === 4'b1111);
    wire is_validD = is_addrD | is_addiD | is_andrD | is_andiD | is_brD | 
                        is_jmpD | is_jsrD | is_jsrrD | is_ldD | is_ldiD | 
                        is_ldrD | is_leaD | is_notD | is_retD | is_retiD | is_stD | is_stiD | is_strD | is_trapD;

    wire [19:0] d1_instructD = {is_validD, is_addrD, is_addiD, is_andrD, is_andiD, is_brD, 
                                    is_jmpD, is_jsrD, is_jsrrD, is_ldD, is_ldiD, 
                                    is_ldrD, is_leaD, is_notD, is_retD, is_retiD, 
                                    is_stD, is_stiD, is_strD, is_trapD};


    wire is_ldunitD = is_ldD | is_ldiD | is_ldrD | is_stD | is_stiD | is_strD;
    wire is_aluunitD = is_addrD | is_addiD | is_andiD | is_notD | is_leaD;

    wire [15:0] imm5D = {{12{instructD[4]}}, instructD[3:0]};
    wire [15:0] pc_offset9D = {{8{instructD[8]}}, instructD[7:0]};
    wire [15:0] offset6D = {{11{instructD[5]}}, instructD[4:0]};

    wire useD0 = is_addrD | is_addiD | is_andrD | is_andiD | is_jmpD | is_jsrrD | is_ldrD | is_notD;
    wire useD1 = is_addrD | is_andrD;
    wire [1:0] useD = {useD0, useD1};

    wire writeToRegD = is_addrD | is_addiD | is_andrD | is_andiD | is_ldD | is_ldiD | is_ldrD | is_leaD | is_notD;
    wire [2:0] writeRegD = instructD[11:9];
    wire is_storeD = is_stD | is_stiD | is_strD;

    wire is_aluD = (opcodeD == 4'b0001) | (opcodeD == 4'b1010) | (opcodeD == 4'b1001);
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
    reg d2_writeToRegA;
    reg [2:0] d2_writeRegA;

    reg [5:0] d2_tailA; //ROB
    reg [3:0] d2_opcodeA; //Operation
    reg d2_is_aluA;
    reg [2:0] d2_regA0;
    reg [2:0] d2_regA1;
    reg [1:0] d2_useA_;
    wire [22:0] d2_rdataA0 = rdata[183:161];
    wire [22:0] d2_rdataA1 = rdata[160:138];

    // [19] is_valid, [18]addr, [17] addi, [16] andr, [15] andi, [14] br, [13] jmp, [12] jsr, [11] jsrr, [10] ld, 
    // [9] ldi, [8] ldr, [7] lea, [6] not, [5] ret, [4] reti, [3] st, [2] sti, [1] str, [0] trap
    
    //TODO: Storage issues for store commands
    wire [5:0] d2_lookA0 = d2_rdataA0[5:0];
    wire [5:0] d2_lookA1 = d2_rdataA1[5:0];
    wire [15:0] d2_valueA0 = (d2_instructA[12] | d2_instructA[14] | d2_instructA[10] | d2_instructA[9] | d2_instructA[7] | d2_instructA[3] | d2_instructA[2]) ? d1_pcA :
                                d2_instructA[13] ? {16{1'b0}} : // ret
                                d2_rdataA0[6] ? ROB[d2_rdataA0[5:0]] : 
                                d2_rdataA0[22:7];
    wire [15:0] d2_valueA1 = (d2_instructA[12] | d2_instructA[14] | d2_instructA[10] | d2_instructA[9] | d2_instructA[7] | d2_instructA[3] | d2_instructA[2]) ? d2_pc_offset9A : 
                                d2_instructA[11] ? {16{1'b0}} : // jsrr
                                (d2_instructA[17] | d2_instructA[15]) ? d2_imm5A :
                                (d2_instructA[8]) ? d2_offset6A :
                                (d2_rdataA1[6]) ? ROB[d2_rdataA1[5:0]] : 
                                d2_rdataA1[22:7];
    
    wire [1:0] d2_useA = {d2_useA_[1] & ROB[d2_lookA0][32] == 1'b0, d2_useA_[0] & ROB[d2_lookA1][32] == 1'b0};
    //TODO: Update ROBcheck with the computed values ehre too

    wire [56:0] d2_outputA = {d2_opcodeA, d2_tailA, d2_lookA0, d2_lookA1, d2_valueA0, d2_valueA1, d2_useA, d2_instructA[19]};

    reg d2_is_aluunitB = 1'b0;
    reg d2_is_ldunitB = 1'b0;
    reg d2_is_bunitB = 1'b0;
    wire [56:0] d2_outputB;

    reg d2_is_aluunitC = 1'b0;
    reg d2_is_ldunitC = 1'b0;
    reg d2_is_bunitC = 1'b0;
    wire [56:0] d2_outputC;

    reg d2_is_aluunitD = 1'b0;
    reg d2_is_ldunitD = 1'b0;
    reg d2_is_bunitD = 1'b0;
    wire [56:0] d2_outputD;
    //TODO: Store needs additional memory storage
    // [22:7]data, [6] busy, [5:0] rob_loc
    always @(posedge clk) begin
        d2_instructA <= d1_instructA;
        d2_is_ldunitA <= is_ldunitA;
        d2_is_aluunitA <= is_aluunitA;
        d2_imm5A <= imm5A;
        d2_pc_offset9A <= pc_offset9A;
        d2_offset6A <= offset6A;
        d2_writeToRegA <= writeToRegA;
        d2_writeRegA <= writeRegA;

        d2_tailA <= d1_tailA;
        d2_opcodeA <= opcodeA;
        d2_is_aluA <= is_aluA;
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
    //Addition check for: [5] isTrap, [4] IsStore, [3] IsWriteToReg, [2:0] RegNum
    reg [5:0] ROBcheck[0:63];
    reg [2:0] ROB_condition_codes[0:63]; // N, Z, P
    reg [5:0] ROBhead = 5'h00;
    reg [5:0] ROBtail = 5'h00;
    reg [5:0] ROBsize = 5'h00;

    always @(posedge clk) begin
        ROB[d1_tailA][15:0] <= pcA;
        ROB[d1_tailA][32] <= 1'b0;

        //TODO Update
        ROB[d1_tailB][15:0] <= pcB;
        ROB[d1_tailC][15:0] <= pcC;
        ROB[d1_tailD][15:0] <= pcD;
        if(is_validA)
            ROBtail <= (ROBtail + 4) % 64;

        ROBcheck[d1_tailA] <= {is_trapA, is_storeA, writeToRegA, writeRegA};
    end

    always @(posedge clk) begin
        if(forwardA[22] == 1'b1) begin
            ROB[forwardA[21:16]][31:16] <= forwardA[15:0];
            ROB_condition_codes[forwardA[21:16]] <= condition_code_A;
            ROB[forwardA[21:16]][32] <= 1'b1;
        end

        if(forwardB[22] == 1'b1) begin
            ROB[forwardB[21:16]][31:16] <= forwardB[15:0];
            ROB_condition_codes[forwardC[21:16]] <= condition_code_B;
            ROB[forwardB[21:16]][32] <= 1'b1;
        end

        if(forwardC[22] == 1'b1) begin
            ROB[forwardC[21:16]][31:16] <= forwardC[15:0];
            ROB[forwardC[21:16]][32] <= 1'b1;
        end

        if(forwardD[22] == 1'b1) begin
            ROB[forwardD[21:16]][31:16] <= forwardD[15:0];
            ROB_condition_codes[forwardD[21:16]] <= condition_code_D;
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
    wire [56:0] alu_feederA;
    wire [56:0] alu_feederB;
    wire [56:0] alu_feederC;
    wire [56:0] alu_feederD;
    wire alu_feedervalidA;
    wire alu_feedervalidB;
    wire alu_feedervalidC;
    wire alu_feedervalidD;
    queue_feeder alu_feeder(
        .inOperationA(d2_outputA), .validA(d2_is_aluunitA),
        .inOperationB(d2_outputB), .validB(d2_is_aluunitB),
        .inOperationC(d2_outputC), .validC(d2_is_aluunitC),
        .inOperationD(d2_outputD), .validD(d2_is_aluunitD),
        .outOperationA(alu_feederA), .outValidA(alu_feedervalidA),
        .outOperationB(alu_feederB), .outValidB(alu_feedervalidB),
        .outOperationC(alu_feederC), .outValidC(alu_feedervalidC),
        .outOperationD(alu_feederD), .outValidD(alu_feedervalidD)
    );

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
        .inOperation0(alu_feederA[56:53]), .inROB0(alu_feederA[52:47]), .inLook0A(alu_feederA[46:41]), .inLook0B(alu_feederA[40:35]), .inValue0A(alu_feederA[34:19]), .inValue0B(alu_feederA[18:3]), .inUse0(alu_feederA[2:1]), .inReady0(alu_feederA[0] & alu_feedervalidA),
        .inOperation1(alu_feederB[56:53]), .inROB1(alu_feederB[52:47]), .inLook1A(alu_feederB[46:41]), .inLook1B(alu_feederB[40:35]), .inValue1A(alu_feederB[34:19]), .inValue1B(alu_feederB[18:3]), .inUse1(alu_feederB[2:1]), .inReady1(alu_feederB[0] & alu_feedervalidB),
        .inOperation2(alu_feederC[56:53]), .inROB2(alu_feederC[52:47]), .inLook2A(alu_feederC[46:41]), .inLook2B(alu_feederC[40:35]), .inValue2A(alu_feederC[34:19]), .inValue2B(alu_feederC[18:3]), .inUse2(alu_feederC[2:1]), .inReady2(alu_feederC[0] & alu_feedervalidC),
        .inOperation3(alu_feederD[56:53]), .inROB3(alu_feederD[52:47]), .inLook3A(alu_feederD[46:41]), .inLook3B(alu_feederD[40:35]), .inValue3A(alu_feederD[34:19]), .inValue3B(alu_feederD[18:3]), .inUse3(alu_feederD[2:1]), .inReady3(alu_feederD[0] & alu_feedervalidD),
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
    
    assign forwardA = {alu_valid0, alu_rob0, alu_out0};
    wire [2:0] condition_code_A = (alu_opcode0 == 4'b0001) | (alu_opcode0 == 4'b0101) | (alu_opcode0 == 4'b1001) ?
                                    {1'b1, alu_out0[15], alu_out0 == 0, ~alu_out0[15], alu_rob0} : 0;

    always @(posedge clk) begin
        //TODO: link functional unit A to instruction queue
        alu_valid0 <= alu_rs_0_valid;
        alu_opcode0 <= alu_rs_0_out[40:37];
        alu_rob0 <= alu_rs_0_out[36:32];
        alu_value0A <= alu_rs_0_out[31:16];
        alu_value0B <= alu_rs_0_out[15:0];
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
    assign forwardB = {alu_valid1, alu_rob1, alu_out1};
    wire [2:0] condition_code_B = (alu_opcode1 == 4'b0001) | (alu_opcode1 == 4'b0101) | (alu_opcode1 == 4'b1001) ?
                                    {1'b1, alu_out1[15], alu_out1 == 0, ~alu_out1[15], alu_rob1} : 0;

    always @(posedge clk) begin
        alu_valid1 <= alu_rs_1_valid;
        alu_opcode1 <= alu_rs_1_out[40:37];
        alu_rob1 <= alu_rs_1_out[36:32];
        alu_value1A <= alu_rs_1_out[31:16];
        alu_value1B <= alu_rs_1_out[15:0];

    end


    wire [56:0] bu_feederA;
    wire [56:0] bu_feederB;
    wire [56:0] bu_feederC;
    wire [56:0] bu_feederD;
    wire bu_feedervalidA;
    wire bu_feedervalidB;
    wire bu_feedervalidC;
    wire bu_feedervalidD;
    queue_feeder bu_feeder(
        .inOperationA(d2_outputA), .validA(d2_is_bunitA),
        .inOperationB(d2_outputB), .validB(d2_is_bunitB),
        .inOperationC(d2_outputC), .validC(d2_is_bunitC),
        .inOperationD(d2_outputD), .validD(d2_is_bunitD),
        .outOperationA(bu_feederA), .outValidA(bu_feedervalidA),
        .outOperationB(bu_feederB), .outValidB(bu_feedervalidB),
        .outOperationC(bu_feederC), .outValidC(bu_feedervalidC),
        .outOperationD(bu_feederD), .outValidD(bu_feedervalidD)
    );

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
                            (bu_pc + 2) + {{5{bu_pcoffset11[10]}}, {bu_pcoffset11[10:0]}} :
                        is_br ? (bu_pc + 2) + {{5{bu_pcoffset11[10]}}, {bu_pcoffset11[10:0]}}: //I changed this, might not be correct
                        pc + 2;
                            
    wire [15:0]bu_r7 = bu_pc + 2;

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



    // // // // // // // //
    // Load Store Unit // //
    // // // // // // // // 


    // Load Store Unit: uses forwardD

    wire [56:0] ld_feederA;
    wire [56:0] ld_feederB;
    wire [56:0] ld_feederC;
    wire [56:0] ld_feederD;
    wire ld_feedervalidA;
    wire ld_feedervalidB;
    wire ld_feedervalidC;
    wire ld_feedervalidD;
    queue_feeder lsu_feeder(
        .inOperationA(d2_outputA), .validA(d2_is_ldunitA),
        .inOperationB(d2_outputB), .validB(d2_is_ldunitB),
        .inOperationC(d2_outputC), .validC(d2_is_ldunitC),
        .inOperationD(d2_outputD), .validD(d2_is_ldunitD),
        .outOperationA(ld_feederA), .outValidA(ld_feedervalidA),
        .outOperationB(ld_feederB), .outValidB(ld_feedervalidB),
        .outOperationC(ld_feederC), .outValidC(ld_feedervalidC),
        .outOperationD(ld_feederD), .outValidD(ld_feedervalidD)
    );

    wire [56:0] lsu_out;
    wire lsu_used;
    queue lsu_queue(
        .clk(clk),
        .flush(),
        .taken({1'b0, !load_stall & lsu_used}),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation0(ld_feederA[56:53]), .inROB0(ld_feederA[52:47]), .inLook0A(ld_feederA[46:41]), .inLook0B(ld_feederA[40:35]), .inValue0A(ld_feederA[34:19]), .inValue0B(ld_feederA[18:3]), .inUse0(ld_feederA[2:1]), .inReady0(ld_feederA[0] & ld_feedervalidA),
        .inOperation1(ld_feederB[56:53]), .inROB1(ld_feederB[52:47]), .inLook1A(ld_feederB[46:41]), .inLook1B(ld_feederB[40:35]), .inValue1A(ld_feederB[34:19]), .inValue1B(ld_feederB[18:3]), .inUse1(ld_feederB[2:1]), .inReady1(ld_feederB[0] & ld_feedervalidB),
        .inOperation2(ld_feederC[56:53]), .inROB2(ld_feederC[52:47]), .inLook2A(ld_feederC[46:41]), .inLook2B(ld_feederC[40:35]), .inValue2A(ld_feederC[34:19]), .inValue2B(ld_feederC[18:3]), .inUse2(ld_feederC[2:1]), .inReady2(ld_feederC[0] & ld_feedervalidC),
        .inOperation3(ld_feederD[56:53]), .inROB3(ld_feederD[52:47]), .inLook3A(ld_feederD[46:41]), .inLook3B(ld_feederD[40:35]), .inValue3A(ld_feederD[34:19]), .inValue3B(ld_feederD[18:3]), .inUse3(ld_feederD[2:1]), .inReady3(ld_feederD[0] & ld_feedervalidD),
        .outOperation0(lsu_out),
        .outOperation1()
    );

    wire load_stall;
    wire [15:0] lsu_data;
    wire [5:0] lsu_rob;
    wire lsu_out_valid;
    assign lsu_used = lsu_out[2:1] === 2'b00;
    wire load_flush = 1'b0;
    wire [1:0] store_buffer_commit = 2'b00;
    wire load_is_ld = (lsu_out[55:52]===4'b0010) | (lsu_out[56:52]===4'b1010) | (lsu_out[56:52]===4'b0110);
    //TODO: STORE ISSUE
    //TODO: Load location line up issues
    load_store_unit lsu(
        .clk(clk),
        .flush(load_flush),
        .stores_to_commit(store_buffer_commit),
        .is_ld(load_is_ld), .data(lsu_out[33:18]), .location(lsu_out[17:2]), .ROBloc(lsu_out[51:46]), .input_valid(lsu_used),
        .commit_data(mem_wdata), .commit_location(mem_waddr), .commit_valid(mem_wen),
        .mem_location(mem_raddr), .mem_valid(),
        .mem_data(mem_rdata),
        .out_data(lsu_data), .out_ROB(lsu_rob), .out_valid(lsu_out_valid),
        .load_stall(load_stall)
    );

    assign forwardD = {lsu_out_valid, lsu_rob, lsu_data};
    wire [2:0] condition_code_D = {1'b1, lsu_data[15], lsu_data == 0, ~lsu_data[15], lsu_rob};

    always @(posedge clk) begin
        if(pc > 100)
            halt <= 1;
        pc <= pc + 8;
        //pc <= target;
    end

    wire [5:0] headOfROB = ROBcheck[ROBhead];
    wire [15:0] ROBa = ROB[ROBhead];

    //ROB Commit Unit
    always @(posedge clk) begin
        if(ROB[ROBhead][32] === 1'b1) begin
            
            if(ROBcheck[ROBhead][5] == 1'b1) begin
                //IsTrapVector
                $write("TRAPP");
            end
            else if(ROBcheck[ROBhead][4] == 1'b1) begin
                //Is Store
            end
            else if(ROBcheck[ROBhead][3] == 1'b1) begin
                //Is Write to Reg
                $write("WRITE");
            end

            ROBhead <= (ROBhead + 1) % 64;
        end
    end

endmodule
