
module alu_queue(
    input clk,
    input [22:0] forwardA, input [22:0] forwardB, input [22:0] forwardC, input [22:0] forwardD,
    input [3:0] inOperation0, input [5:0] inROB0, input [5:0] inLook0A, input [5:0] inLook0B, input [15:0] inValue0A, input [15:0] inValue0B, input [1:0] inUse0, input inReady0,
    input [3:0] inOperation1, input [5:0] inROB1, input [5:0] inLook1A, input [5:0] inLook1B, input [15:0] inValue1A, input [15:0] inValue1B, input [1:0] inUse1, input inReady1,
    input [3:0] inOperation2, input [5:0] inROB2, input [5:0] inLook2A, input [5:0] inLook2B, input [15:0] inValue2A, input [15:0] inValue2B, input [1:0] inUse2, input inReady2,
    input [3:0] inOperation3, input [5:0] inROB3, input [5:0] inLook3A, input [5:0] inLook3B, input [15:0] inValue3A, input [15:0] inValue3B, input [1:0] inUse3, input inReady3,
    output [3:0] outOperation0, output [5:0] outROB0, output [15:0] outValue0A, output [15:0] outValue0B, output outReady0,
    output [3:0] outOperation1, output [5:0] outROB1, output [15:0] outValue1A, output [15:0] outValue1B, output outReady1
    );

    parameter QUEUE_SIZE = 64;

    reg valid [0:QUEUE_SIZE-1];
    reg [3:0] operation [0:QUEUE_SIZE-1];
    reg [5:0] rob_num [0:QUEUE_SIZE-1];
    reg [5:0] lookA [0:QUEUE_SIZE-1];
    reg [5:0] lookB [0:QUEUE_SIZE-1];
    reg [15:0] valueA [0:QUEUE_SIZE-1];
    reg [15:0] valueB [0:QUEUE_SIZE-1];
    reg [1:0] user [0:QUEUE_SIZE-1];

    integer i;

    reg [5:0] readyCounter = 5'h00;
    reg inserted;

    initial begin
        for(i = 0; i < QUEUE_SIZE; i = i + 1)
            valid[i] <= 1'b0;
    end

    reg [3:0] routOperation0;
    reg [5:0] routROB0;
    reg [15:0] routValue0A;
    reg [15:0] routValue0B;
    reg routReady0 = 1'b0;

    reg [3:0] routOperation1;
    reg [5:0] routROB1;
    reg [15:0] routValue1A;
    reg [15:0] routValue1B;
    reg routReady1 = 1'b0;

    assign outOperation0 = routOperation0;
    assign outROB0 = routROB0;
    assign outValue0A = routValue0A;
    assign outValue0B = routValue0B;
    assign outReady0 = routReady0;

    assign outOperation1 = routOperation1;
    assign outROB1 = routROB1;
    assign outValue1A = routValue1A;
    assign outValue1B = routValue1B;
    assign outReady1 = routReady1;

    reg insert;
    //TODO: Uses Blocking code, try a way that doesn't need to do this
    always @(posedge clk) begin
        insert = 1'b0;
        for(i = 0; i < QUEUE_SIZE; i = i + 1) begin
            if(insert == 0 && valid[i] == 1'b1) begin
                if(user[i][1] == 1'b0 && user[i][0] == 1'b0) begin
                    routOperation0 = operation[i];
                    routROB0 = rob_num[i];
                    routValue0A = valueA[i];
                    routValue0B = valueB[i];
                    routReady0 = 1'b1;
                    valid[i] = 1'b0;
                    insert = 1;
                end
            end
        end
        insert = 1'b0;
        for(i = 0; i < QUEUE_SIZE; i = i + 1) begin
            if(insert == 1'b0 && valid[i] == 1'b1) begin
                if(user[i][1] == 1'b0 && user[i][0] == 1'b0) begin
                    routOperation1 = operation[i];
                    routROB1 = rob_num[i];
                    routValue1A = valueA[i];
                    routValue1B = valueB[i];
                    routReady1 = 1'b1;
                    valid[i] = 1'b0;
                    insert = 1;
                end
            end
        end
        insert = 1'b0;
        if(inReady0 == 1'b1) begin
            for(i = 0; i < QUEUE_SIZE; i = i + 1) begin
                if(insert == 1'b0 && valid[i] == 1'b0) begin
                    valid[i] = 1'b1;
                    operation[i] = inOperation0;
                    rob_num[i] = inROB0;
                    lookA[i] = inLook0A;
                    lookB[i] = inLook0B;
                    valueA[i] = inValue0A;
                    valueB[i] = inValue0B;
                    user[i] = inUse0;
                    insert = 1'b1;
                end
            end
        end
        insert = 1'b0;
        if(inReady1 == 1'b1) begin
            for(i = 0; i < QUEUE_SIZE; i = i + 1) begin
                if(insert == 1'b0 && valid[i] == 1'b0) begin
                    valid[i] = 1'b1;
                    operation[i] = inOperation1;
                    rob_num[i] = inROB1;
                    lookA[i] = inLook1A;
                    lookB[i] = inLook1B;
                    valueA[i] = inValue1A;
                    valueB[i] = inValue1B;
                    user[i] = inUse1;
                    insert = 1'b1;
                end
            end
        end
        insert = 1'b0;
        if(inReady2 == 1'b1) begin
            for(i = 0; i < QUEUE_SIZE; i = i + 1) begin
                if(insert == 1'b0 && valid[i] == 1'b0) begin
                    valid[i] = 1'b1;
                    operation[i] = inOperation2;
                    rob_num[i] = inROB2;
                    lookA[i] = inLook2A;
                    lookB[i] = inLook2B;
                    valueA[i] = inValue2A;
                    valueB[i] = inValue2B;
                    user[i] = inUse2;
                    insert = 1'b1;
                end
            end
        end
        insert = 1'b0;
        if(inReady3 == 1'b1) begin
            for(i = 0; i < QUEUE_SIZE; i = i + 1) begin
                if(insert == 1'b0 && valid[i] == 1'b0) begin
                    valid[i] = 1'b1;
                    operation[i] = inOperation3;
                    rob_num[i] = inROB3;
                    lookA[i] = inLook3A;
                    lookB[i] = inLook3B;
                    valueA[i] = inValue3A;
                    valueB[i] = inValue3B;
                    user[i] = inUse3;
                    insert = 1'b1;
                end
            end
        end
    end

    always @(posedge clk) begin
        for(i = 0; i < QUEUE_SIZE; i = i + 1) begin
            if(valid[i] == 1'b1) begin
                if(forwardA[22] == 1'b1) begin
                    if(user[i][1] == 1'b1 && lookA[i] == forwardA[21:16]) begin
                        user[i][1] <= 1'b0;
                        valueA[i] <= forwardA[15:0];
                    end

                    if(user[i][0] == 1'b1 && lookB[i] == forwardA[21:16]) begin
                        user[i][0] <= 1'b0;
                        valueB[i] <= forwardA[15:0];
                    end
                end

                if(forwardB[22] == 1'b1) begin
                    if(user[i][1] == 1'b1 && lookA[i] == forwardB[21:16]) begin
                        user[i][1] <= 1'b0;
                        valueA[i] <= forwardB[15:0];
                    end

                    if(user[i][0] == 1'b1 && lookB[i] == forwardB[21:16]) begin
                        user[i][0] <= 1'b0;
                        valueB[i] <= forwardB[15:0];
                    end
                end

                if(forwardC[22] == 1'b1) begin
                    if(user[i][1] == 1'b1 && lookA[i] == forwardC[21:16]) begin
                        user[i][1] <= 1'b0;
                        valueA[i] <= forwardC[15:0];
                    end

                    if(user[i][0] == 1'b1 && lookB[i] == forwardC[21:16]) begin
                        user[i][0] <= 1'b0;
                        valueB[i] <= forwardC[15:0];
                    end
                end

                if(forwardD[22] == 1'b1) begin
                    if(user[i][1] == 1'b1 && lookA[i] == forwardD[21:16]) begin
                        user[i][1] <= 1'b0;
                        valueA[i] <= forwardD[15:0];
                    end

                    if(user[i][0] == 1'b1 && lookB[i] == forwardD[21:16]) begin
                        user[i][0] <= 1'b0;
                        valueB[i] <= forwardD[15:0];
                    end
                end
            end
        end
    end

endmodule