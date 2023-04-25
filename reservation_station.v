module reservation_station(input clk, input flush,
    input [22:0] forwardA, input [22:0] forwardB, input [22:0] forwardC, input [22:0] forwardD,
    input [56:0] inOperation, output operationUsed, output [41:0] outOperation, output outOperationValid
    );

    //Size of the reservation station: 5
    reg [56:0] operation [0:4];
    reg [0:4]commited;
    //[56] valid, [55:52]operation, [51:46]rob, [45:40]lookA, [39:34] lookB [33:18] valueA, [17:2] value b, [1:0] user

    wire [1:0] inOperationUse = inOperation[1:0];
    wire [5:0] inOperationLookA = inOperation[45:40];
    wire [5:0] inOperationLookB = inOperation[39:34];
    wire [5:0] inOperationRob = inOperation[51:46];
    
    wire [1:0] commit0 = operation[0][1:0];
    wire [1:0] commit1 = operation[1][1:0];
    wire [1:0] commit2 = operation[2][1:0];
    wire [1:0] commit3 = operation[3][1:0];
    wire [1:0] commit4 = operation[4][1:0];

    wire committed0 = commited[0];
    wire committed1 = commited[1];
    wire committed2 = commited[2];
    wire committed3 = commited[3];
    wire committed4 = commited[4];

    assign operationUsed = (!commited[0] | !commited[1] | !commited[2] | !commited[3] | !commited[4]);
    integer i;

    assign outOperationValid = (commited[0] & operation[0][1:0] === 2'b00) | (commited[1] & operation[1][1:0] === 2'b00) | (commited[2] & operation[2][1:0] === 2'b00) | (commited[3] & operation[3][1:0] === 2'b00) | (commited[4] & operation[4][1:0] === 2'b00);

    wire [2:0] operationIndex = commited[0] & operation[0][1:0] == 2'b00 ? 3'b000 :
                                commited[1] & operation[1][1:0] == 2'b00 ? 3'b001 :
                                commited[2] & operation[2][1:0] == 2'b00 ? 3'b010 :
                                commited[3] & operation[3][1:0] == 2'b00 ? 3'b011 :
                                commited[4] & operation[4][1:0] == 2'b00 ? 3'b100 : 3'b111;
                                
    assign outOperation = {operation[operationIndex][55:52], operation[operationIndex][51:46], operation[operationIndex][33:18], operation[operationIndex][17:2]};

    initial begin
        for(i = 0; i < 5; i = i + 1) begin
            commited[i] <= 1'b0;
            operation[i][56] <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(flush) begin
            for(i = 0; i < 5; i = i + 1)
                commited[i] <= 1'b0;
        end
        else begin
            if(operationUsed && inOperation[56]) begin
                if(!commited[0]) begin
                    operation[0] <= inOperation;
                    commited[0] <= 1'b1;
                end
                else if(!commited[1]) begin
                    operation[1] <= inOperation;
                    commited[1] <= 1'b1;
                end
                else if(!commited[2]) begin
                    operation[2] <= inOperation;
                    commited[2] <= 1'b1;
                end
                else if(!commited[3]) begin
                    operation[3] <= inOperation;
                    commited[3] <= 1'b1;
                end
                else if(!commited[4]) begin
                    operation[4] <= inOperation;
                    commited[4] <= 1'b1;
                end
            end

            if(outOperationValid) begin
                commited[operationIndex] <= 1'b0;
            end

            for(i = 0; i < 5; i = i + 1) begin
                if(commited[i] == 1'b1) begin
                    if(forwardA[22] == 1'b1) begin
                        if(operation[i][1] == 1'b1 && operation[i][45:40] == forwardA[21:16]) begin
                            operation[i][1] <= 1'b0;
                            operation[i][33:18] <= forwardA[15:0];
                        end

                        if(operation[i][0] == 1'b1 && operation[i][39:34] == forwardA[21:16]) begin
                            operation[i][0] <= 1'b0;
                            operation[i][17:2] <= forwardA[15:0];
                        end
                    end

                    if(forwardB[22] == 1'b1) begin
                        if(operation[i][1] == 1'b1 && operation[i][45:40] == forwardB[21:16]) begin
                            operation[i][1] <= 1'b0;
                            operation[i][33:18] <= forwardB[15:0];
                        end

                        if(operation[i][0] == 1'b1 && operation[i][39:34] == forwardB[21:16]) begin
                            operation[i][0] <= 1'b0;
                            operation[i][17:2] <= forwardB[15:0];
                        end
                    end

                    if(forwardC[22] == 1'b1) begin
                        if(operation[i][1] == 1'b1 && operation[i][45:40] == forwardC[21:16]) begin
                            operation[i][1] <= 1'b0;
                            operation[i][33:18] <= forwardC[15:0];
                        end

                        if(operation[i][0] == 1'b1 && operation[i][39:34] == forwardC[21:16]) begin
                            operation[i][0] <= 1'b0;
                            operation[i][17:2] <= forwardC[15:0];
                        end
                    end

                    if(forwardD[22] == 1'b1) begin
                        if(operation[i][1] == 1'b1 && operation[i][45:40] == forwardD[21:16]) begin
                            operation[i][1] <= 1'b0;
                            operation[i][33:18] <= forwardD[15:0];
                        end

                        if(operation[i][0] == 1'b1 && operation[i][39:34] == forwardD[21:16]) begin
                            operation[i][0] <= 1'b0;
                            operation[i][17:2] <= forwardD[15:0];
                        end
                    end
                end
            end
        end
    end

endmodule