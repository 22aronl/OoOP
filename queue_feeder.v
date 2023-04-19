
module queue_feeder(
    input [56:0] inOperationA, input validA,
    input [56:0] inOperationB, input validB,
    input [56:0] inOperationC, input validC,
    input [56:0] inOperationD, input validD,
    output [56:0] outOperationA, output outValidA,
    output [56:0] outOperationB, output outValidB,
    output [56:0] outOperationC, output outValidC,
    output [56:0] outOperationD, output outValidD
    );

    assign outValidA = validA | validB | validC | validD;
    assign outValidB = (validA) ? (validB | validC | validD) :
                            (validB) ? (validC | validD) :
                            (validC) ? validD :
                            1'b0;
    assign outValidC = (validA & validB) ? (validC | validD) :
                        (validA & validC) ? validD :
                        (validB & validC) ? validD :
                        1'b0;
    assign outValidD = validA & validB & validC & validD;

    assign outOperationA = validA ? inOperationA :
                            validB ? inOperationB :
                            validC ? inOperationC :
                            inOperationD;
    
    assign outOperationB = (validA) ? validB ? inOperationB :
                                    validC ? inOperationC :
                                    inOperationD :
                            (validB) ? validC ? inOperationC :
                                    inOperationD :
                            inOperationD;
                        
    assign outOperationC = (validA & validB) ? validC ? inOperationC :
                                    inOperationD :
                            (validA & validC) ? inOperationD :
                            inOperationD;

    assign outOperationD = inOperationD;

endmodule