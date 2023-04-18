
module queue(
    input clk, input flush, input [1:0] taken,
    input [22:0] forwardA, input [22:0] forwardB, input [22:0] forwardC, input [22:0] forwardD,
    input [3:0] inOperation0, input [5:0] inROB0, input [5:0] inLook0A, input [5:0] inLook0B, input [15:0] inValue0A, input [15:0] inValue0B, input [1:0] inUse0, input inReady0,
    input [3:0] inOperation1, input [5:0] inROB1, input [5:0] inLook1A, input [5:0] inLook1B, input [15:0] inValue1A, input [15:0] inValue1B, input [1:0] inUse1, input inReady1,
    input [3:0] inOperation2, input [5:0] inROB2, input [5:0] inLook2A, input [5:0] inLook2B, input [15:0] inValue2A, input [15:0] inValue2B, input [1:0] inUse2, input inReady2,
    input [3:0] inOperation3, input [5:0] inROB3, input [5:0] inLook3A, input [5:0] inLook3B, input [15:0] inValue3A, input [15:0] inValue3B, input [1:0] inUse3, input inReady3,
    output [56:0] outOperation0, output [56:0] outOperation1);
    //TODO: Check out size
    //Inoperation0 must be filled before inOperation 1 is used, etc.

    parameter QUEUE_SIZE = 64;

    reg valid [0:QUEUE_SIZE-1];
    reg [3:0] operation [0:QUEUE_SIZE-1];
    reg [5:0] rob_num [0:QUEUE_SIZE-1];
    reg [5:0] lookA [0:QUEUE_SIZE-1];
    reg [5:0] lookB [0:QUEUE_SIZE-1];
    reg [15:0] valueA [0:QUEUE_SIZE-1];
    reg [15:0] valueB [0:QUEUE_SIZE-1];
    reg [1:0] user [0:QUEUE_SIZE-1];

    reg [5:0] head = 6'h00;
    reg [5:0] tail = 6'h00;

    assign outOperation0 = {valid[head], operation[head], rob_num[head], lookA[head], lookB[head], valueA[head], valueB[head], user[head]};
    assign outOperation1 = {valid[(head + 1)%QUEUE_SIZE], operation[(head + 1)%QUEUE_SIZE], rob_num[(head + 1)%QUEUE_SIZE], lookA[(head + 1)%QUEUE_SIZE], lookB[(head + 1)%QUEUE_SIZE], valueA[(head + 1)%QUEUE_SIZE], valueB[(head + 1)%QUEUE_SIZE], user[(head + 1)%QUEUE_SIZE]};

    always @(posedge clk) begin
        head <= (head + taken) % QUEUE_SIZE;

        if(inReady0) begin
            valid[tail] <= 1'b1;
            operation[tail] <= inOperation0;
            rob_num[tail] <= inROB0;
            lookA[tail] <= inLook0A;
            lookB[tail] <= inLook0B;
            valueA[tail] <= inValue0A;
            valueB[tail] <= inValue0B;
            user[tail] <= inUse0;
        end

        if(inReady1) begin
            valid[(tail + 1)%QUEUE_SIZE] <= 1'b1;
            operation[(tail + 1)%QUEUE_SIZE] <= inOperation1;
            rob_num[(tail + 1)%QUEUE_SIZE] <= inROB1;
            lookA[(tail + 1)%QUEUE_SIZE] <= inLook1A;
            lookB[(tail + 1)%QUEUE_SIZE] <= inLook1B;
            valueA[(tail + 1)%QUEUE_SIZE] <= inValue1A;
            valueB[(tail + 1)%QUEUE_SIZE] <= inValue1B;
            user[(tail + 1)%QUEUE_SIZE] <= inUse1;
        end

        if(inReady2) begin
            valid[(tail + 2)%QUEUE_SIZE] <= 1'b1;
            operation[(tail + 2)%QUEUE_SIZE] <= inOperation2;
            rob_num[(tail + 2)%QUEUE_SIZE] <= inROB2;
            lookA[(tail + 2)%QUEUE_SIZE] <= inLook2A;
            lookB[(tail + 2)%QUEUE_SIZE] <= inLook2B;
            valueA[(tail + 2)%QUEUE_SIZE] <= inValue2A;
            valueB[(tail + 2)%QUEUE_SIZE] <= inValue2B;
            user[(tail + 2)%QUEUE_SIZE] <= inUse2;
        end

        if(inReady3) begin
            valid[(tail + 3)%QUEUE_SIZE] <= 1'b1;
            operation[(tail + 3)%QUEUE_SIZE] <= inOperation3;
            rob_num[(tail + 3)%QUEUE_SIZE] <= inROB3;
            lookA[(tail + 3)%QUEUE_SIZE] <= inLook3A;
            lookB[(tail + 3)%QUEUE_SIZE] <= inLook3B;
            valueA[(tail + 3)%QUEUE_SIZE] <= inValue3A;
            valueB[(tail + 3)%QUEUE_SIZE] <= inValue3B;
            user[(tail + 3)%QUEUE_SIZE] <= inUse3;
        end

        tail <= (tail + inReady0 + inReady1 + inReady2 + inReady3) % QUEUE_SIZE;
    end

    integer i;
    //TODO: timing errors between forward cycle and the cycle the instructions get added the queue
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