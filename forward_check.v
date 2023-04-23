module forward_check(
    input [22:0] forwardA, input [22:0] forwardB, input [22:0] forwardC, input [22:0] forwardD,
    input [55:0] inOperation, output [55:0] outOperation);
    //[22] valid [21:16] rob [15:0] value

    //[55:52] operation [51:46] ROB [45:40]lookA [39:34] lookB [33:18] valueA [17:2] valueB [1:0] user
    wire [1:0] user = inOperation[1:0];
    wire [15:0] valueA_ = inOperation[33:18];
    wire [15:0] valueB_ = inOperation[17:2];

    wire [15:0] valueA = inOperation[1] ? 
                            (forwardA[22] && inOperation[45:40] === forwardA[21:16]) ? forwardA[15:0] :
                            (forwardB[22] && inOperation[45:40] === forwardB[21:16]) ? forwardB[15:0] :
                            (forwardC[22] && inOperation[45:40] === forwardC[21:16]) ? forwardC[15:0] :
                            (forwardD[22] && inOperation[45:40] === forwardD[21:16]) ? forwardD[15:0] :
                            inOperation[33:18] : inOperation[33:18];

    wire userA = inOperation[1] && 
                            !((forwardA[22] && inOperation[45:40] === forwardA[21:16]) || 
                            (forwardB[22] && inOperation[45:40] === forwardB[21:16]) ||
                            (forwardC[22] && inOperation[45:40] === forwardC[21:16]) ||
                            (forwardD[22] && inOperation[45:40] === forwardD[21:16]));
    
    wire [15:0] valueB = inOperation[0] ? 
                            (forwardA[22] && inOperation[39:34] === forwardA[21:16]) ? forwardA[15:0] :
                            (forwardB[22] && inOperation[39:34] === forwardB[21:16]) ? forwardB[15:0] :
                            (forwardC[22] && inOperation[39:34] === forwardC[21:16]) ? forwardC[15:0] :
                            (forwardD[22] && inOperation[39:34] === forwardD[21:16]) ? forwardD[15:0] :
                            inOperation[17:2] : inOperation[17:2];

    wire userB = inOperation[0] && 
                            !((forwardA[22] && inOperation[39:34] === forwardA[21:16]) ||
                            (forwardB[22] && inOperation[39:34] === forwardB[21:16]) ||
                            (forwardC[22] && inOperation[39:34] === forwardC[21:16]) ||
                            (forwardD[22] && inOperation[39:34] === forwardD[21:16]));

    assign outOperation = {inOperation[55:34], valueA, valueB, userA, userB};

endmodule