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

    wire wen0 = cu_wen0;
    wire wen1 = cu_wen1;
    wire wen2 = cu_wen2;
    wire [2:0]waddr0 = cu_waddr0;
    wire [2:0]waddr1 = cu_waddr1;
    wire [2:0]waddr2 = cu_waddr2;
    wire [15:0]wdata0 = cu_wdata0;
    wire [15:0]wdata1 = cu_wdata1;
    wire [15:0]wdata2 = cu_wdata2;
    wire [5:0] wrob0 = cu_wrob0;
    wire [5:0] wrob1 = cu_wrob1;
    wire [5:0] wrob2 = cu_wrob2;

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
        .rob_locA(d2_tailA), .rob_waddrA(d2_writeRegA), .rob_wenA(d2_rob_wenA),
        .rob_locB(d2_tailB), .rob_waddrB(d2_writeRegB), .rob_wenB(d2_rob_wenB),
        .rob_locC(d2_tailC), .rob_waddrC(d2_writeRegC), .rob_wenC(d2_rob_wenC),
        .rob_locD(d2_tailD), .rob_waddrD(d2_writeRegD), .rob_wenD(d2_rob_wenD),
        .wen0(wen0),
        .waddr0(waddr0),
        .wdata0(wdata0),
        .wrob0(wrob0),
        .wen1(wen1),
        .waddr1(waddr1),
        .wdata1(wdata1),
        .wrob1(wrob1),
        .wen2(wen2),
        .waddr2(waddr2),
        .wdata2(wdata2),
        .wrob2(wrob2)
    );


    //decode 1
    reg [15:0]d1_pcA;
    reg [15:0]d1_pcB;
    reg [15:0]d1_pcC;
    reg [15:0]d1_pcD;

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
    wire is_validA = !flush && (is_addrA | is_addiA | is_andrA | is_andiA | is_brA | 
                        is_jmpA | is_jsrA | is_jsrrA | is_ldA | is_ldiA | 
                        is_ldrA | is_leaA | is_notA | is_retA | is_retiA | is_stA | is_stiA | is_strA | is_trapA);

    wire [19:0] d1_instructA = {is_validA, is_addrA, is_addiA, is_andrA, is_andiA, is_brA, 
                                    is_jmpA, is_jsrA, is_jsrrA, is_ldA, is_ldiA, 
                                    is_ldrA, is_leaA, is_notA, is_retA, is_retiA, 
                                    is_stA, is_stiA, is_strA, is_trapA};


    wire is_ldunitA = is_ldA | is_ldiA | is_ldrA | is_stA | is_stiA | is_strA;
    wire is_aluunitA = is_addrA | is_addiA | is_andrA | is_andiA | is_notA | is_leaA | is_trapA; // added is_trapA to alu
    wire is_bunitA = is_brA | is_jmpA | is_jsrA | is_jsrrA;

    wire [15:0] imm5A = {{12{instructA[4]}}, instructA[3:0]};
    wire [15:0] pc_offset11A = {{4{instructA[11]}}, instructA[11:0]};
    wire [15:0] offset6A = {{11{instructA[5]}}, instructA[4:0]};

    wire useA0 = is_addrA | is_addiA | is_andrA | is_andiA | is_jmpA | is_jsrrA | is_ldrA | is_notA | is_stA | is_stiA | is_strA | is_trapA;
    wire useA1 = is_addrA | is_andrA | is_strA;
    wire [1:0] useA = {useA0, useA1};

    wire writeToRegA = is_addrA | is_addiA | is_andrA | is_andiA | is_ldA | is_ldiA | is_ldrA | is_leaA | is_notA;
    wire [2:0] writeRegA = instructA[11:9];
    wire is_storeA = is_stA | is_stiA | is_strA;

    wire is_aluA = (opcodeA == 4'b0001) | (opcodeA == 4'b1010) | (opcodeA == 4'b1001);
    wire [2:0] regA0 = (is_storeA) ? writeRegA :
                        is_trapA ? 0: instructA[8:6];
    wire [2:0] regA1 = is_strA ? instructA[8:6] : instructA[2:0];



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
    wire is_validB = !flush && (is_addrB | is_addiB | is_andrB | is_andiB | is_brB | 
                        is_jmpB | is_jsrB | is_jsrrB | is_ldB | is_ldiB | 
                        is_ldrB | is_leaB | is_notB | is_retB | is_retiB | is_stB | is_stiB | is_strB | is_trapB);

    wire [19:0] d1_instructB = {is_validB, is_addrB, is_addiB, is_andrB, is_andiB, is_brB, 
                                    is_jmpB, is_jsrB, is_jsrrB, is_ldB, is_ldiB, 
                                    is_ldrB, is_leaB, is_notB, is_retB, is_retiB, 
                                    is_stB, is_stiB, is_strB, is_trapB};

    
    wire is_bunitB = is_jsrB | is_jsrrA | is_jmpB | is_brB | is_retB;
    wire is_ldunitB = is_ldB | is_ldiB | is_ldrB | is_stB | is_stiB | is_strB;
    wire is_aluunitB = is_addrB | is_addiB | is_andrB | is_andiB | is_notB | is_leaB | is_trapB;

    wire [15:0] imm5B = {{12{instructB[4]}}, instructB[3:0]};
    wire [15:0] pc_offset11B = {{4{instructB[11]}}, instructB[11:0]};
    wire [15:0] offset6B = {{11{instructB[5]}}, instructB[4:0]};

    wire useB0 = is_addrB | is_addiB | is_andrB | is_andiB | is_jmpB | is_jsrrB | is_ldrB | is_notB | is_stB | is_stiB | is_strB | is_trapB;
    wire useB1 = is_addrB | is_andrB | is_strB;
    wire [1:0] useB = {useB0, useB1};

    wire writeToRegB = is_addrB | is_addiB | is_andrB | is_andiB | is_ldB | is_ldiB | is_ldrB | is_leaB | is_notB;
    wire [2:0] writeRegB = instructB[11:9];
    wire is_storeB = is_stB | is_stiB | is_strB;

    wire is_aluB = (opcodeB == 4'b0001) | (opcodeB == 4'b1010) | (opcodeB == 4'b1001); // ?????????? where is this used
    wire [2:0] regB0 = (is_storeB) ? writeRegB : 
                        is_trapB ? 0: instructB[8:6];
    wire [2:0] regB1 = is_strA ? instructB[8:6] : instructB[2:0];


    // TODO rename 
    wire [3:0] opcodeC = instructC[15:12];

    wire is_addrC = (opcodeC === 4'b0001) & (instructC[5:3] === 3'b000);
    wire is_addiC = (opcodeC === 4'b0001) & (instructC[5] === 1'b1);
    wire is_andrC = (opcodeC == 4'b0101) & (instructC[5:3] === 3'b000);
    wire is_andiC = (opcodeC === 4'b0101) & (instructC[5] === 1'b1);
    wire is_brC = (opcodeC === 4'b0000);
    wire is_jmpC = (opcodeC === 4'b1100) & (instructC[11:9] === 3'b000) & (instructC[5:0] === 6'b000000);
    wire is_jsrC = (opcodeC === 4'b0100) & (instructC[11] == 1'b1);
    wire is_jsrrC = (opcodeC === 4'b0100) & (instructC[11:9] === 3'b000) & (instructC[5:0] !== 6'b000000); 
    wire is_ldC = (opcodeC === 4'b0010);
    wire is_ldiC = (opcodeC === 4'b1010);
    wire is_ldrC = (opcodeC === 4'b0110);
    wire is_leaC = (opcodeC === 4'b1110);
    wire is_notC = (opcodeC === 4'b1001) & (instructC[5:0] === 6'b111111);
    wire is_retC = (instructC === 16'hC1C0);
    wire is_retiC = (instructC === 16'h8000);
    wire is_stC = (opcodeC === 4'b0011);
    wire is_stiC = (opcodeC === 4'b1011);
    wire is_strC = (opcodeC === 4'b0111);
    wire is_trapC = (opcodeC === 4'b1111);
    wire is_validC = !flush && (is_addrC | is_addiC | is_andrC | is_andiC | is_brC | 
                        is_jmpC | is_jsrC | is_jsrrC | is_ldC | is_ldiC | 
                        is_ldrC | is_leaC | is_notC | is_retC | is_retiC | is_stC | is_stiC | is_strC | is_trapC);

    wire [19:0] d1_instructC = {is_validC, is_addrC, is_addiC, is_andrC, is_andiC, is_brC, 
                                    is_jmpC, is_jsrC, is_jsrrC, is_ldC, is_ldiC, 
                                    is_ldrC, is_leaC, is_notC, is_retC, is_retiC, 
                                    is_stC, is_stiC, is_strC, is_trapC};


    wire is_ldunitC = is_ldC | is_ldiC | is_ldrC | is_stC | is_stiC | is_strC;
    wire is_aluunitC = is_addrC | is_addiC | is_andrC | is_andiC | is_notC | is_leaC | is_trapC;
    wire is_bunitC = is_brC | is_jmpC | is_jsrC | is_jsrrC;


    wire [15:0] imm5C = {{12{instructC[4]}}, instructC[3:0]};
    wire [15:0] pc_offset11C = {{4{instructC[11]}}, instructC[11:0]};
    wire [15:0] offset6C = {{11{instructC[5]}}, instructC[4:0]};

    wire useC0 = is_addrC | is_addiC | is_andrC | is_andiC | is_jmpC | is_jsrrC | is_ldrC | is_notC | is_stC | is_stiC | is_strC | is_trapC;
    wire useC1 = is_addrC | is_andrC | is_strC | is_brC;
    wire [1:0] useC = {useC0, useC1};

    wire writeToRegC = is_addrC | is_addiC | is_andrC | is_andiC | is_ldC | is_ldiC | is_ldrC | is_leaC | is_notC | is_trapC;
    wire [2:0] writeRegC = instructC[11:9];
    wire is_storeC = is_stC | is_stiC | is_strC;

    wire is_aluC = (opcodeC == 4'b0001) | (opcodeC == 4'b1010) | (opcodeC == 4'b1001);
    wire [2:0] regC0 = is_storeC ? writeRegC : is_trapC ? 0 : instructC[8:6];
    wire [2:0] regC1 = is_strC ? instructC[8:6] : instructC[2:0];



    // TODO rename 
    wire [3:0] opcodeD = instructD[15:12];

    wire is_addrD = (opcodeD === 4'b0001) & (instructD[5:3] === 3'b000);
    wire is_addiD = (opcodeD === 4'b0001) & (instructD[5] === 1'b1);
    wire is_andrD = (opcodeD == 4'b0101) & (instructD[5:3] === 3'b000);
    wire is_andiD = (opcodeD === 4'b0101) & (instructD[5] === 1'b1);
    wire is_brD = (opcodeD === 4'b0000);
    wire is_jmpD = (opcodeD === 4'b1100) & (instructD[11:9] === 3'b000) & (instructD[5:0] === 6'b000000);
    wire is_jsrD = (opcodeD === 4'b0100) & (instructD[11] == 1'b1);
    wire is_jsrrD = (opcodeD === 4'b0100) & (instructD[11:9] === 3'b000) & (instructD[5:0] !== 6'b000000); 
    wire is_ldD = (opcodeD === 4'b0010);
    wire is_ldiD = (opcodeD === 4'b1010);
    wire is_ldrD = (opcodeD === 4'b0110);
    wire is_leaD = (opcodeD === 4'b1110);
    wire is_notD = (opcodeD === 4'b1001) & (instructD[5:0] === 6'b111111);
    wire is_retD = (instructD === 16'hC1C0);
    wire is_retiD = (instructD === 16'h8000);
    wire is_stD = (opcodeD === 4'b0011);
    wire is_stiD = (opcodeD === 4'b1011);
    wire is_strD = (opcodeD === 4'b0111);
    wire is_trapD = (opcodeD === 4'b1111);
    wire is_validD = !flush && (is_addrD | is_addiD | is_andrD | is_andiD | is_brD | 
                        is_jmpD | is_jsrD | is_jsrrD | is_ldD | is_ldiD | 
                        is_ldrD | is_leaD | is_notD | is_retD | is_retiD | is_stD | is_stiD | is_strD | is_trapD);

    wire [19:0] d1_instructD = {is_validD, is_addrD, is_addiD, is_andrD, is_andiD, is_brD, 
                                    is_jmpD, is_jsrD, is_jsrrD, is_ldD, is_ldiD, 
                                    is_ldrD, is_leaD, is_notD, is_retD, is_retiD, 
                                    is_stD, is_stiD, is_strD, is_trapD};


    wire is_ldunitD = is_ldD | is_ldiD | is_ldrD | is_stD | is_stiD | is_strD;
    wire is_aluunitD = is_addrD | is_addiD | is_andrD | is_andiD | is_notD | is_leaD | is_trapD;
    wire is_bunitD = is_brD | is_jmpD | is_jsrD | is_jsrrD;


    wire [15:0] imm5D = {{12{instructD[4]}}, instructD[3:0]};
    wire [15:0] pc_offset11D = {{4{instructD[11]}}, instructD[11:0]};
    wire [15:0] offset6D = {{11{instructD[5]}}, instructD[4:0]};

    wire useD0 = is_addrD | is_addiD | is_andrD | is_andiD | is_jmpD | is_jsrrD | is_ldrD | is_notD | is_stD | is_stiD | is_strD | is_trapD;
    wire useD1 = is_addrD | is_andrD | is_strD;
    wire [1:0] useD = {useD0, useD1};

    wire writeToRegD = is_addrD | is_addiD | is_andrD | is_andiD | is_ldD | is_ldiD | is_ldrD | is_leaD | is_notD;
    wire [2:0] writeRegD = instructD[11:9];
    wire is_storeD = is_stD | is_stiD | is_strD;

    wire is_aluD = (opcodeD == 4'b0001) | (opcodeD == 4'b1010) | (opcodeD == 4'b1001);
    wire [2:0] regD0 = is_storeD ? writeRegD : is_trapD ? 0 :instructD[8:6];
    wire [2:0] regD1 = is_strD ? instructD[8:6] : instructD[2:0];


    assign raddr = {regA0, regA1, regB0, regB1, regC0, regC1, regD0, regD1};



    wire rob_wenD = writeToRegD;
    wire rob_wenC = writeToRegD && (writeRegD == writeRegC) ? 0 : writeToRegC;
    wire rob_wenB = (writeToRegD && (writeRegD == writeRegB)) || 
                    (writeToRegC && (writeRegC == writeRegB)) ? 0 : writeToRegB;
    wire rob_wenA = (writeToRegD && (writeRegD == writeRegA)) ||
                    (writeToRegC && (writeRegC == writeRegA)) ||  
                    (writeToRegB && (writeRegB == writeRegA)) ? 0 : writeToRegA;

    reg d2_rob_wenD;
    reg d2_rob_wenC;
    reg d2_rob_wenB;
    reg d2_rob_wenA;

    always @(posedge clk) begin
        d2_rob_wenD <= rob_wenD;
        d2_rob_wenC <= rob_wenC;
        d2_rob_wenB <= rob_wenB;
        d2_rob_wenA <= rob_wenA;
    end

    //TODO: Fix the register dependency checking (simulatenous dependency issues)

    reg [15:0] d2_pcA;
    reg [15:0] d2_pcB;
    reg [15:0] d2_pcC;
    reg [15:0] d2_pcD;

    always @(posedge clk) begin
        d1_pcA <= pcA;
        d1_pcB <= pcB;
        d1_pcC <= pcC;
        d1_pcD <= pcD;

        d2_pcA <= d1_pcA;
        d2_pcB <= d1_pcB;
        d2_pcC <= d1_pcC;
        d2_pcD <= d1_pcD;
    end

    //Decode 2
    //TODO: Timing issues with tailA and useA

    reg [19:0] d2_instructA;
    reg d2_is_ldunitA = 1'b0;
    reg d2_is_aluunitA = 1'b0;
    reg d2_is_bunitA = 1'b0;
    reg d2_is_brA;
    reg [15:0] d2_imm5A;
    reg [15:0] d2_pc_offset11A;
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
    wire [5:0] d2_lookA1 = d2_is_brA ? (d2_tailA +63) % 64:
                            d2_rdataA1[5:0];
    wire [15:0] d2_valueA0 = (d2_instructA[12] | d2_instructA[14] | d2_instructA[10] | d2_instructA[9] | d2_instructA[7]) ? d2_pcA :
                                d2_instructA[13] ? {16{1'b0}} : // ret
                                d2_rdataA0[6] ? ROB[d2_rdataA0[5:0]] : 
                                d2_rdataA0[22:7];
    wire [15:0] d2_valueA1 = (d2_instructA[12] | d2_instructA[14] | d2_instructA[10] | d2_instructA[9] | d2_instructA[7] | d2_instructB[3] | d2_instructB[2] | d2_instructA[0]) ? d2_pc_offset11A : 
                                d2_instructA[11] ? {16{1'b0}} : // jsrr
                                (d2_instructA[17] | d2_instructA[15]) ? d2_imm5A :
                                (d2_instructA[8]) ? d2_offset6A :
                                (d2_rdataA1[6]) ? ROB[d2_rdataA1[5:0]] : 
                                d2_rdataA1[22:7];

    wire robLookA0 = ROB[d2_lookA0][32];
    
    wire [1:0] d2_useA = {d2_useA_[1] & (ROB[d2_lookA0][32] == 1'b0 & d2_rdataA0[6] == 1'b1), (d2_useA_[0] & ROB[d2_lookA1][32] == 1'b0 & d2_rdataA1[6] == 1'b1)};
    //TODO: Update ROBcheck with the computed values ehre too

    wire [56:0] d2_outputA = {d2_opcodeA, d2_tailA, d2_lookA0, d2_lookA1, d2_valueA0, d2_valueA1, d2_useA, d2_instructA[19]};



    //TODO: Store needs additional memory storage
    // [22:7]data, [6] busy, [5:0] rob_loc
    always @(posedge clk) begin
        d2_instructA <= d1_instructA;
        d2_is_ldunitA <= is_ldunitA;
        d2_is_aluunitA <= is_aluunitA;
        d2_is_bunitA <= is_bunitA;
        d2_imm5A <= imm5A;
        d2_pc_offset11A <= pc_offset11A;
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

    reg [19:0] d2_instructB;

    reg [15:0] d2_imm5B;
    reg [15:0] d2_pc_offset11B;
    reg [15:0] d2_offset6B;
    reg d2_writeToRegB;
    reg [2:0] d2_writeRegB;

    reg [3:0] d2_opcodeB; //Operation
    reg d2_is_aluB;
    reg [2:0] d2_regB0;
    reg [2:0] d2_regB1;
    reg [1:0] d2_useB_;
    
    reg d2_is_brB;

    reg d2_is_aluunitB = 1'b0;
    reg d2_is_ldunitB = 1'b0;
    reg d2_is_bunitB = 1'b0;
    reg [5:0] d2_tailB; //ROB

    //TODO: update rdara indexs
    wire [22:0] d2_rdataB0 = rdata[137:115];
    wire [22:0] d2_rdataB1 = rdata[114:92];
    wire d2_lookB0_ = d2_writeToRegA && (d2_writeRegA == d2_regB0);
    wire d2_lookB1_ = d2_writeToRegA && (d2_writeRegA == d2_regB1);
    wire [5:0]d2_lookB0 = d2_lookB0_ ? d2_tailA : d2_rdataB0[5:0];
    wire [5:0]d2_lookB1 = d2_is_brB ? (d2_tailB +63) % 64:
                            d2_lookB1_ ? d2_tailA : d2_rdataB1[5:0];

    wire [15:0] d2_valueB0 = (d2_instructB[12] | d2_instructB[14] | d2_instructB[10] | d2_instructB[9] | d2_instructB[7]) ? d2_pcB :
                                d2_instructB[13] ? {16{1'b0}} : // ret
                                d2_rdataB0[6] ? ROB[d2_rdataB0[5:0]] : 
                                d2_rdataB0[22:7];
    wire [15:0] d2_valueB1 = (d2_instructB[12] | d2_instructB[14] | d2_instructB[10] | d2_instructB[9] | d2_instructB[7] | d2_instructB[3] | d2_instructB[2] | d2_instructB[0]) ? d2_pc_offset11B : 
                                d2_instructB[11] ? {16{1'b0}} : // jsrr
                                (d2_instructB[17] | d2_instructB[15]) ? d2_imm5B :
                                (d2_instructB[8]) ? d2_offset6B :
                                (d2_rdataB1[6]) ? ROB[d2_rdataB1[5:0]] : 
                                d2_rdataB1[22:7];
    
    wire [1:0] d2_useB = {d2_useB_[1] & ((ROB[d2_lookB0][32] == 1'b0 & d2_rdataB0[6] == 1'b1)|d2_lookB0_), d2_useB_[0] & ((ROB[d2_lookB1][32] == 1'b0 & d2_rdataB1[6] == 1'b1)|d2_lookB1_)};
    //TODO: Update ROBcheck with the computed values ehre too

    wire [56:0] d2_outputB = {d2_opcodeB, d2_tailB, d2_lookB0, d2_lookB1, d2_valueB0, d2_valueB1, d2_useB, d2_instructB[19]};


        // [22:7]data, [6] busy, [5:0] rob_loc
    always @(posedge clk) begin
        d2_instructB <= d1_instructB;
        d2_is_ldunitB <= is_ldunitB;
        d2_is_aluunitB <= is_aluunitB;
        d2_is_bunitB <= is_bunitB;
        d2_imm5B <= imm5B;
        d2_pc_offset11B <= pc_offset11B;
        d2_offset6B <= offset6B;
        d2_writeToRegB <= writeToRegB;
        d2_writeRegB <= writeRegB;
        d2_is_aluB <= is_aluB;
        d2_regB0 <= regB0;
        d2_regB1 <= regB1;
        d2_tailB <= d1_tailB;
        d2_opcodeB <= opcodeB;
        d2_useB_ <= useB;
    end 

    reg [19:0] d2_instructC;

    reg [15:0] d2_imm5C;
    reg [15:0] d2_pc_offset11C;
    reg [15:0] d2_offset6C;
    reg d2_writeToRegC;
    reg [2:0] d2_writeRegC;
    reg d2_is_aluC;
    reg [2:0] d2_regC0;
    reg [2:0] d2_regC1;
    reg [5:0] d2_tailC; //ROB
    reg [3:0] d2_opcodeC; //Operation

    reg d2_is_brC;

    reg [1:0] d2_useC_;
    wire [22:0] d2_rdataC0 = rdata[91:69];
    wire [22:0] d2_rdataC1 = rdata[68:46];

    reg d2_is_aluunitC = 1'b0;
    reg d2_is_ldunitC = 1'b0;
    reg d2_is_bunitC = 1'b0;

    wire d2_lookC0_ = (d2_writeToRegB && (d2_writeRegB == d2_regC0)) ||
                        (d2_writeToRegA && (d2_writeRegA == d2_regC0));
    wire d2_lookC1_ = (d2_writeToRegB && (d2_writeRegB == d2_regC1)) ||
                        (d2_writeToRegA && (d2_writeRegA == d2_regC1));

    wire [5:0]d2_lookC0 = d2_writeToRegB && 
                (d2_writeRegB == d2_regC0) ? d2_tailB :                   // check in priority order
                d2_writeToRegA && (d2_writeRegA == d2_regC0) ? d2_tailA : d2_rdataC0[5:0];
    wire [5:0]d2_lookC1 = d2_is_brC ? (d2_tailC +63) % 64: // this is the ROB idx of the previous instruction
                d2_writeToRegB && (d2_writeRegB == d2_regC1) ? d2_tailB : 
                d2_writeToRegA && (d2_writeRegA == d2_regC1) ? d2_tailA : d2_rdataC1[5:0];

                //TODO: WHY??


    wire [15:0] d2_valueC0 = (d2_instructC[12] | d2_instructC[14] | d2_instructC[10] | d2_instructC[9] | d2_instructC[7]) ? d2_pcC :
                                d2_instructC[13] ? {16{1'b0}} : // ret
                                d2_rdataC0[6] ? ROB[d2_rdataC0[5:0]] : 
                                d2_rdataC0[22:7];
    wire [15:0] d2_valueC1 = (d2_instructC[12] | d2_instructC[14] | d2_instructC[10] | d2_instructC[9] | d2_instructC[7] | d2_instructC[3] | d2_instructC[2] | d2_instructC[0]) ? d2_pc_offset11C : 
                                d2_instructC[11] ? {16{1'b0}} : // jsrr
                                (d2_instructC[17] | d2_instructC[15]) ? d2_imm5C :
                                (d2_instructC[8]) ? d2_offset6C :
                                (d2_rdataC1[6]) ? ROB[d2_rdataC1[5:0]] : 
                                d2_rdataC1[22:7];
    
    wire [1:0] d2_useC = {d2_useC_[1] &((ROB[d2_lookC0][32] == 1'b0 & d2_rdataC0[6] == 1'b1)|d2_lookC0_), 
                        d2_useC_[0] & ((ROB[d2_lookC1][32] == 1'b0 & d2_rdataC1[6] == 1'b1)|d2_lookC1_)};
    //TODO: Update ROBcheck with the computed values ehre too

    wire [56:0] d2_outputC = {d2_opcodeC, d2_tailC, d2_lookC0, d2_lookC1, d2_valueC0, d2_valueC1, d2_useC, d2_instructC[19]};


        // [22:7]data, [6] busy, [5:0] rob_loc
    always @(posedge clk) begin
        d2_instructC <= d1_instructC;
        d2_is_ldunitC <= is_ldunitC;
        d2_is_aluunitC <= is_aluunitC;
        d2_is_bunitC <= is_bunitC;

        d2_imm5C <= imm5C;
        d2_pc_offset11C <= pc_offset11C;
        d2_offset6C <= offset6C;
        d2_writeToRegC <= writeToRegC;
        d2_writeRegC <= writeRegC;
        d2_is_brA <= is_brA;
        d2_is_brB <= is_brB;
        d2_is_brC <= is_brC;
        d2_is_brD <= is_brD;

        d2_is_aluC <= is_aluC;
        d2_regC0 <= regC0;
        d2_regC1 <= regC1;
        d2_tailC <= d1_tailC;
        d2_opcodeC <= opcodeC;
        d2_useC_ <= useC;
    end 

    reg [19:0] d2_instructD;

    reg [15:0] d2_imm5D;
    reg [15:0] d2_pc_offset11D;
    reg [15:0] d2_offset6D;
    reg d2_writeToRegD;
    reg [2:0] d2_writeRegD;

    reg [5:0] d2_tailD; //ROB
    reg [3:0] d2_opcodeD; //Operation
    reg d2_is_aluD;
    reg [2:0] d2_regD0;
    reg [2:0] d2_regD1;
    reg [1:0] d2_useD_;
    wire [22:0] d2_rdataD0 = rdata[45:23];
    wire [22:0] d2_rdataD1 = rdata[22:0];

    reg d2_is_brD;

    reg d2_is_aluunitD = 1'b0;
    reg d2_is_ldunitD = 1'b0;
    reg d2_is_bunitD = 1'b0;

    wire d2_lookD0_ = d2_writeToRegC && (d2_writeRegC == d2_regD0)||
                        d2_writeToRegB && (d2_writeRegB == d2_regD0)||
                        d2_writeToRegA && (d2_writeRegA == d2_regD0);
    wire d2_lookD1_ = (d2_writeToRegC && (d2_writeRegC == d2_regD1))||
                        (d2_writeToRegB && (d2_writeRegB == d2_regD1))||
                        (d2_writeToRegA && (d2_writeRegA == d2_regD1));

    wire [5:0]d2_lookD0 = d2_writeToRegC && (d2_writeRegC == d2_regD0) ? d2_tailC :
                d2_writeToRegB && (d2_writeRegB == d2_regD0) ? d2_tailB :
                d2_writeToRegA && (d2_writeRegA == d2_regD0) ? d2_tailA : d2_rdataD0[5:0];

    wire [5:0]d2_lookD1 = d2_is_brD ? (d2_tailD +63) % 64:
                d2_writeToRegC && (d2_writeRegC == d2_regD1) ? d2_tailC :
                d2_writeToRegB && (d2_writeRegB == d2_regD1) ? d2_tailB :
                d2_writeToRegA && (d2_writeRegA == d2_regD1) ? d2_tailA : d2_rdataD1[5:0];

    wire [15:0] d2_valueD0 = (d2_instructD[12] | d2_instructD[14] | d2_instructD[10] | d2_instructD[9] | d2_instructD[7]) ? d2_pcD :
                                d2_instructD[13] ? {16{1'b0}} : // ret
                                d2_rdataD0[6] ? ROB[d2_rdataD0[5:0]] : 
                                d2_rdataD0[22:7];
    wire [15:0] d2_valueD1 = (d2_instructD[12] | d2_instructD[14] | d2_instructD[10] | d2_instructD[9] | d2_instructD[7] | d2_instructD[3] | d2_instructD[2] | d2_instructD[0]) ? d2_pc_offset11D : 
                                d2_instructD[11] ? {16{1'b0}} : // jsrr
                                (d2_instructD[17] | d2_instructD[15]) ? d2_imm5D :
                                (d2_instructD[8]) ? d2_offset6D :
                                (d2_rdataD1[6]) ? ROB[d2_rdataD1[5:0]] : 
                                d2_rdataD1[22:7];
    wire [1:0] d2_useD = {d2_useD_[1] & (ROB[d2_lookD0][32] == 1'b0 & d2_rdataD0[6] == 1'b1 | d2_lookD0_), 
                            d2_useD_[0] & (ROB[d2_lookD1][32] == 1'b0 & d2_rdataD1[6] == 1'b1 | d2_lookD1_)};
    //TODO: Update ROBcheck with the computed values ehre too
    //[56:53] opcode, [52:47] tail, [46:41] look0,
    wire [56:0] d2_outputD = {d2_opcodeD, d2_tailD, d2_lookD0, d2_lookD1, d2_valueD0, d2_valueD1, d2_useD, d2_instructD[19]};


    // [22:7]data, [6] busy, [5:0] rob_loc
    always @(posedge clk) begin
        d2_instructD <= d1_instructD;
        d2_is_ldunitD <= is_ldunitD;
        d2_is_aluunitD <= is_aluunitD;
        d2_is_bunitD <= is_bunitD;
        d2_imm5D <= imm5D;
        d2_pc_offset11D <= pc_offset11D;
        d2_offset6D <= offset6D;
        d2_writeToRegD <= writeToRegD;
        d2_writeRegD <= writeRegD;

        d2_is_aluD <= is_aluD;
        d2_regD0 <= regD0;
        d2_regD1 <= regD1;
        d2_tailD <= d1_tailD;
        d2_opcodeD<= opcodeD;
        d2_useD_ <= useD;
    end 


    //TODO: Store Instructions into buffer to be put into the reservation stations

    // // // // //
    //    ROB   //
    // // // // //


    //TODO: Add support for the condition registers
    //Ready Bit, Value, PC (for piping into cache & branch checking for now)
    reg [32:0] ROB[0:63];
    //Addition check for:   [13] set=x21 not set=x25 [12] take jump, [11:6] offset6 [5] isTrap, [4] IsStore, [3] IsWriteToReg, [2:0] RegNum
    reg [13:0] ROBcheck[0:63];
    reg [2:0] ROB_condition_codes[0:63]; // N, Z, P
    reg [5:0] ROBhead = 5'h00;
    reg [5:0] ROBtail = 5'h00;
    reg [5:0] ROBsize = 5'h00;

    always @(posedge clk) begin
        ROB[d1_tailA][15:0] <= pcA;
        ROB[d1_tailA][32] <= 1'b0;

        //TODO Update
        ROB[d1_tailB][15:0] <= pcB;
        ROB[d1_tailB][32] <= 1'b0;
        ROB[d1_tailC][15:0] <= pcC;
        ROB[d1_tailC][32] <= 1'b0;
        ROB[d1_tailD][15:0] <= pcD;
        ROB[d1_tailD][32] <= 1'b0;
        if(is_validA)
            ROBtail <= (ROBtail + 4) % 64;

        ROBcheck[d1_tailA][11:0] <= {offset6A, is_trapA, is_storeA, writeToRegA, writeRegA};
        ROBcheck[d1_tailB][11:0] <= {offset6B, is_trapB, is_storeB, writeToRegB, writeRegB};
        ROBcheck[d1_tailC][11:0] <= {offset6C, is_trapC, is_storeC, writeToRegC, writeRegC};
        ROBcheck[d1_tailD][11:0] <= {offset6D, is_trapD, is_storeD, writeToRegD, writeRegD};
    end


    always @(posedge clk) begin
        if(forwardA[22] == 1'b1) begin
            ROB[forwardA[21:16]][31:16] <= forwardA[15:0];
            ROB_condition_codes[forwardA[21:16]] <= condition_code_A;
            ROB[forwardA[21:16]][32] <= 1'b1;
            ROBcheck[forwardA[21:16]][13] <= alu_value0B == 8'b00100101 ? 1'b0 : 1'b1;
        end

        if(forwardB[22] == 1'b1) begin
            ROB[forwardB[21:16]][31:16] <= forwardB[15:0];
            ROB_condition_codes[forwardB[21:16]] <= condition_code_B;
            ROB[forwardB[21:16]][32] <= 1'b1;
            ROBcheck[forwardB[21:16]][13] <= alu_value1B == 8'b00100101 ? 1'b0 : 1'b1;
        end

        if(forwardC[22] == 1'b1) begin
            ROB[forwardC[21:16]][31:16] <= forwardC[15:0];
            ROB[forwardC[21:16]][32] <= 1'b1;
            ROBcheck[forwardC[21:16]][12] <= bu_jmp;
        end

        if(forwardD[22] == 1'b1) begin
            ROB[forwardD[21:16]][31:16] <= forwardD[15:0];
            ROB_condition_codes[forwardD[21:16]] <= condition_code_D;
            ROB[forwardD[21:16]][32] <= 1'b1;
            // add the thing for trap
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
    wire [1:0] alu_queue_used = {alu_queue_used_0 & alu_queue_used_1 & alu_queue_valid0 & alu_queue_valid1, (alu_queue_used_0 & alu_queue_valid0) ^ (alu_queue_used_1 & alu_queue_valid1)};
    wire [56:0] alu_queue_out0_;
    wire [56:0] alu_queue_out1_;
    wire alu_queue_valid0 = alu_queue_out0_[56] === 1'b1;
    wire alu_queue_valid1 = alu_queue_out1_[56] === 1'b1;

    wire [56:0] alu_queue_out0 = alu_queue_out0_;
    wire [56:0] alu_queue_out1 = alu_queue_used == 2'b01 ? alu_queue_out0_ : alu_queue_out1_;

    wire [5:0] alu_queue_ROBC = alu_queue_out0[51:46];
    wire [5:0] alu_queue_lookC0 = alu_queue_out0[45:40];
    wire [5:0] alu_queue_lookC1 = alu_queue_out0[39:34];
    wire [1:0] alu_queue_useC = alu_queue_out0[1:0];

    wire [5:0] alu_queue_ROBD = alu_queue_out1[51:46];
    wire [5:0] alu_queue_lookD0 = alu_queue_out1[45:40];
    wire [5:0] alu_queue_lookD1 = alu_queue_out1[39:34];
    wire [1:0] alu_queue_useD = alu_queue_out1[1:0];

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
        .outOperation0(alu_queue_out0_),
        .outOperation1(alu_queue_out1_)
    );

    wire [41:0] alu_rs_0_out;
    wire alu_rs_0_valid;
    reservation_station alu_rs0(
        .clk(clk),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation(alu_queue_out0), .operationUsed(alu_queue_used_0), .flush(flush),
        .outOperation(alu_rs_0_out), .outOperationValid(alu_rs_0_valid)
    );

    wire [41:0] alu_rs_1_out;
    wire alu_rs_1_valid;
    reservation_station alu_rs1(
        .clk(clk),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation(alu_queue_out1), .operationUsed(alu_queue_used_1), .flush(flush),
        .outOperation(alu_rs_1_out), .outOperationValid(alu_rs_1_valid)
    );

    
    //////////////
    // BU QUEUE //
    //////////////

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

    // TODO: get condition flags from result of pc - 2
    wire [1:0] bu_buq_used = {1'b0, buq_used & bu_queue_valid}; //?? why would you put 1'b1 here
    wire buq_used;
    wire [56:0] buq_out;
    wire bu_queue_valid = buq_out[56] === 1'b1;

    queue bu_queue(
        .clk(clk),
        .flush(),
        .taken(bu_buq_used),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation0(bu_feederA[56:53]), .inROB0(bu_feederA[52:47]), .inLook0A(bu_feederA[46:41]), .inLook0B(bu_feederA[40:35]), .inValue0A(bu_feederA[34:19]), .inValue0B(bu_feederA[18:3]), .inUse0(bu_feederA[2:1]), .inReady0(bu_feederA[0] & bu_feedervalidA),
        .inOperation1(bu_feederB[56:53]), .inROB1(bu_feederB[52:47]), .inLook1A(bu_feederB[46:41]), .inLook1B(bu_feederB[40:35]), .inValue1A(bu_feederB[34:19]), .inValue1B(bu_feederA[18:3]), .inUse1(bu_feederB[2:1]), .inReady1(bu_feederB[0] & bu_feedervalidB),
        .inOperation2(bu_feederC[56:53]), .inROB2(bu_feederC[52:47]), .inLook2A(bu_feederC[46:41]), .inLook2B(bu_feederC[40:35]), .inValue2A(bu_feederC[34:19]), .inValue2B(bu_feederA[18:3]), .inUse2(bu_feederC[2:1]), .inReady2(bu_feederC[0] & bu_feedervalidC),
        .inOperation3(bu_feederD[56:53]), .inROB3(bu_feederD[52:47]), .inLook3A(bu_feederD[46:41]), .inLook3B(bu_feederD[40:35]), .inValue3A(bu_feederD[34:19]), .inValue3B(bu_feederA[18:3]), .inUse3(bu_feederD[2:1]), .inReady3(bu_feederD[0] & bu_feedervalidD),
        .outOperation0(buq_out),
        .outOperation1()
    );


    wire [41:0] bu_rs_out;
    wire bu_rs_valid;
    reservation_station bu_rs(
        .clk(clk),
        .forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), .forwardD(forwardD),
        .inOperation(buq_out), .operationUsed(buq_used), .flush(flush),
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

    wire alu_unknown0 = ~((alu_opcode0 == 4'b0001) || (alu_opcode0 == 4'b0101) || (alu_opcode0 == 4'b1001));

    wire [15:0] alu_out0 = (alu_opcode0 == 4'b0001 | alu_opcode0 == 4'b1110) ? alu_value0A + alu_value0B :           // ADD
                            (alu_opcode0 == 4'b0101) ? alu_value0A & alu_value0B :    // AND (based on bit 5)
                            (alu_opcode0 == 4'b1001) ? ~alu_value0A :                       // NOT
                            (alu_opcode0 == 4'b1111) ?  alu_value0A :                   // TRAP
                               0;
    
    wire [5:0] forwardAROB = alu_rob0;
    wire [15:0] forwardAValue = alu_out0;
    assign forwardA = {alu_valid0, alu_rob0, alu_out0};
    wire [2:0] condition_code_A = (alu_opcode0 == 4'b0001) | (alu_opcode0 == 4'b0101) | (alu_opcode0 == 4'b1001) | (alu_opcode0 == 4'b1110) ?
                                    {1'b1, alu_out0[15], alu_out0 == 0, ~alu_out0[15], alu_rob0} : 0;

    always @(posedge clk) begin
        //TODO: link functional unit A to instruction queue
        alu_valid0 <= alu_rs_0_valid;
        alu_opcode0 <= alu_rs_0_out[41:38];
        alu_rob0 <= alu_rs_0_out[37:32];
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

    wire [15:0] alu_out1 = (alu_opcode1 == 4'b0001 | alu_opcode1 == 4'b1110) ? alu_value1A + alu_value1B :            // ADD
                            (alu_opcode1 == 4'b0101) ? alu_value1A & alu_value1B :    // AND (based on bit 5)
                            (alu_opcode1 == 4'b1001) ? ~alu_value1A :                       // NOT
                            (alu_opcode1 == 4'b1111) ?  alu_value1A :                    // TRAP
                            0;

    wire [5:0] forwardBROB = alu_rob1;
    wire [15:0] forwardBValue = alu_out1;
    assign forwardB = {alu_valid1, alu_rob1, alu_out1};
    wire [2:0] condition_code_B = (alu_opcode1 == 4'b0001) | (alu_opcode1 == 4'b0101) | (alu_opcode1 == 4'b1001) | (alu_opcode1 == 4'b1110) ?
                                    {1'b1, alu_out1[15], alu_out1 == 0, ~alu_out1[15], alu_rob1} : 0;

    always @(posedge clk) begin
        alu_valid1 <= alu_rs_1_valid;
        alu_opcode1 <= alu_rs_1_out[41:38];
        alu_rob1 <= alu_rs_1_out[37:32];
        alu_value1A <= alu_rs_1_out[31:16];
        alu_value1B <= alu_rs_1_out[15:0];

    end


    // Branch Unit: uses forwardC
    reg bu_valid;

    reg [3:0] bu_opcode;
    reg [5:0] bu_rob;
    reg [15:0] bu_pcval;
    reg [11:0] bu_pcoffset11;
    reg bu_rflag;

    wire [3:0] bu_nzp = ROB_condition_codes[(bu_rob +63)%64 ];

    reg [15:0] bu_value;
    
    wire bu_is_jmp = (bu_opcode == 4'b1100);
    wire bu_is_jsr = (bu_opcode == 4'b0100);
    wire bu_is_br = (bu_opcode == 4'b0000);
    wire [15:0]target = bu_is_jmp ? bu_pcval :
                        bu_is_jsr ?
                            (bu_rflag === 0) ? bu_pcval :
                            (bu_pcval + 2) + {{5{bu_pcoffset11[10]}}, {bu_pcoffset11[10:0]}} :
                        bu_is_br ? (bu_pcval + 2) + {{5{bu_pcoffset11[10]}}, {bu_pcoffset11[10:0]}}: //I changed this, might not be correct
                        bu_pcval + 2;
                            
    wire [15:0]bu_r7 = bu_pcval + 2;

    // wire bu_br_cond = (is_br && ((bu_n && bu_nzp[2]) || (bu_z && bu_nzp[1]) || (bu_p && bu_nzp[0])));
    wire bu_br_cond = 1'b0;

    wire bu_jmp = bu_valid && (bu_is_jmp ||
                bu_is_jsr ||
                (bu_is_br && (bu_br_cond)));

    wire [5:0] forwardCROB = bu_rob;
    wire [15:0] forwardCValue = target;
    assign forwardC = {bu_jmp && bu_valid, bu_rob[5:0], target[15:0]};

    always @(posedge clk) begin
        bu_valid <= bu_rs_valid;
        bu_opcode <= bu_rs_out[41:38];
        bu_rob <= bu_rs_out[37:32];
        bu_pcval <= bu_rs_out[31:16];
        bu_pcoffset11 <= bu_rs_out[10:0];
        bu_rflag <= bu_rs_out[15];
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
    assign lsu_used = lsu_out[56] === 1'b1 && lsu_out[1:0] === 2'b00;
    wire load_flush = 1'b0;
    wire [1:0] store_buffer_commit = 2'b00;
    wire [4:0] load_opcode = lsu_out[55:52];
    wire load_is_ld = (lsu_out[55:52]===4'b0010) | (lsu_out[55:52]===4'b1010) | (lsu_out[55:52]===4'b0110);

    wire [15:0] lsu_in_loc0 = (load_opcode === 4'b0011 | load_opcode === 4'b1011) ? ROB[lsu_rob][15:0] : 
                                (load_opcode === 4'b0111) ? lsu_out[17:2] :
                                lsu_out[33:18];
    wire [15:0] lsu_tste = lsu_out[33:18];
    wire [5:0] lsu_offset6 = ROBcheck[lsu_out[51:46]][11:6];
    wire [15:0] lsu_in_loc1 = (load_opcode === 4'b0110 | load_opcode === 4'b0111) ? {{9{lsu_offset6[5]}}, lsu_offset6} : 
                                lsu_out[17:2];

    wire [15:0] lsu_in_loc = lsu_in_loc0 + lsu_in_loc1;

    //TODO: STORE ISSUE
    //TODO: Load location line up issues
    load_store_unit lsu(
        .clk(clk),
        .flush(load_flush),
        .stores_to_commit(store_buffer_commit),
        .is_ld(load_is_ld), .data(lsu_out[33:18]), .location(lsu_in_loc), .ROBloc(lsu_out[51:46]), .input_valid(lsu_used),
        .commit_data(mem_wdata), .commit_location(mem_waddr), .commit_valid(mem_wen),
        .mem_location(mem_raddr), .mem_valid(),
        .mem_data(mem_rdata),
        .out_data(lsu_data), .out_ROB(lsu_rob), .out_valid(lsu_out_valid),
        .load_stall(load_stall)
    );

    assign forwardD = {lsu_out_valid, lsu_rob, lsu_data};
    wire [2:0] condition_code_D = {1'b1, lsu_data[15], lsu_data == 0, ~lsu_data[15], lsu_rob};

    always @(posedge clk) begin
        if(pc > 500)
            halt <= 1;
        pc <= pc + 8;
        //pc <= cu_target;
        //pc <= target;
    end

    wire [5:0] headOfROB = ROBcheck[ROBhead];
    wire [32:0] ROBa = ROB[ROBhead];
    wire flush = cu_flush;

    reg cu_flush = 1'b0;

    wire cu_wen0 = ROB[ROBhead][32] && ROBcheck[ROBhead][3]; // if [4] then should be mem write enabled
    wire cu_wen1 = ROB[ROBhead][32] && (ROB[(ROBhead+1) % 64][32] === 1'b1) && !ROBcheck[ROBhead][12];
    wire cu_wen2 = ROB[ROBhead][32] && (ROB[(ROBhead+1) % 64][32] === 1'b1) && !ROBcheck[ROBhead][12] && (ROB[(ROBhead+2) % 64][32] === 1'b1) && !ROBcheck[ROBhead][6] && !ROBcheck[(ROBhead + 1) % 64][12];

    wire [2:0] cu_waddr0 = ROBcheck[ROBhead][2:0];
    wire [2:0] cu_waddr1 = ROBcheck[(ROBhead+1) % 64][2:0];
    wire [2:0] cu_waddr2 = ROBcheck[(ROBhead+2) % 64][2:0];

    wire [15:0]cu_target = ((bu_jmp) & (ROBhead === forwardC[21:16])) ? forwardC[15:0] : // forward from bu
                            (ROBcheck[ROBhead][12] === 1) ? ROB[ROBhead][31:16] :                       // commit instr #1
                            
                            (bu_jmp & (((ROBhead + 1)%64) === forwardC[21:16])) ? forwardC[15:0] :
                            (ROBcheck[(ROBhead + 1) % 64][12] === 1) ? ROB[(ROBhead + 1) % 64][31:16] : // commit instr #2

                            (bu_jmp & (((ROBhead + 2)%64) === forwardC[21:16])) ? forwardC[15:0] :
                            (ROBcheck[(ROBhead + 2) % 64][12] === 1) ? ROB[(ROBhead + 2) % 64][31:16] : // commit instr #3
                            
                             pc + 8;

    wire [15:0]cu_wdata0 = ROBhead === forwardA[21:16] ? forwardA[15:0] :
                            ROBhead === forwardB[21:16] ? forwardB[15:0] :
                            ROBhead === forwardC[21:16] ? forwardC[15:0] :
                            ROBhead === forwardD[21:16] ? forwardD[15:0] :
                            ROB[(ROBhead)][31:16];
    // forward the val to be committed
    wire [15:0]cu_wdata1 = (ROBhead+1) % 64 === forwardA[21:16] ? forwardA[15:0] :
                            (ROBhead+1) % 64 === forwardB[21:16] ? forwardB[15:0] :
                            (ROBhead+1) % 64 === forwardC[21:16] ? forwardC[15:0] :
                            (ROBhead+1) % 64 === forwardD[21:16] ? forwardD[15:0] :
                            ROB[(ROBhead+1) % 64][31:16];

    wire [15:0]cu_wdata2 = (ROBhead+2) % 64 === forwardA[21:16] ? forwardA[15:0] :
                            (ROBhead+2) % 64 === forwardB[21:16] ? forwardB[15:0] :
                            (ROBhead+2) % 64 === forwardC[21:16] ? forwardC[15:0] :
                            (ROBhead+2) % 64 === forwardD[21:16] ? forwardD[15:0] :
                            ROB[(ROBhead+2) % 64][31:16];

    wire [5:0] cu_wrob0 = ROBhead;
    wire [5:0] cu_wrob1 = (ROBhead+1) % 64;
    wire [5:0] cu_wrob2 = (ROBhead+2) % 64;

    //ROB Commit Unit
    always @(posedge clk) begin
        // TODO move all pc target logic here
        // propogate bu_jmp flush signal here
        // check to see if committed instruction is behind a jmp instruction -> do not exec

        // Commit 0
        if(ROB[ROBhead][32] === 1'b1) begin
            if(ROBcheck[ROBhead][5] == 1'b1) begin //IsTrapVector
                if(ROBcheck[ROBhead][13] == 1'b1) begin  // x21
                    $write("%0c", cu_wdata0[7:0]);
                end
                else begin  //x 25
                    $finish();
                end 
            end
            ROBhead <= (ROBhead + 1) % 64;
            // Commit 1

            if((ROB[(ROBhead+1) % 64][32] === 1'b1) && !ROBcheck[ROBhead][12]) begin
                
                if(ROBcheck[(ROBhead+1) % 64][5] == 1'b1) begin //IsTrapVector
                    if(ROBcheck[(ROBhead+1) % 64][13] == 1'b1) begin  // x21
                        $write("%0c", cu_wdata1[7:0]);
                    end
                    else begin  //x 25
                        $finish();
                    end
                end
                ROBhead <= (ROBhead + 2) % 64;
                // Commit 2
                if((ROB[(ROBhead+2) % 64][32] === 1'b1) && !ROBcheck[ROBhead][12] && !ROBcheck[(ROBhead + 1) % 64][12]) begin
                    
                    if(ROBcheck[(ROBhead+2)%64][5] == 1'b1) begin //IsTrapVector
                        if(ROBcheck[(ROBhead+2) % 64][13] == 1'b1) begin  // x21
                            $write("%0c", cu_wdata2);
                        end
                        else begin  //x 25
                            $finish();
                        end 
                    end
                    ROBhead <= (ROBhead + 3) % 64;
                end
            end
        end
    end
endmodule