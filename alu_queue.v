
module alu_queue(
    input clk,
    input [22:0] forwardA, input [22:0] forwardB, input [22:0] forwardC, input [22:0] forwardD,
    input [4:0] inOperation0, input [5:0] inROB0, input [5:0] inLook0A, input [5:0] inLook0B, input [15:0] inValue0A, input [15:0] inValue0B, input [1:0] inUse0, input inReady0,
    input [4:0] inOperation1, input [5:0] inROB1, input [5:0] inLook1A, input [5:0] inLook1B, input [15:0] inValue1A, input [15:0] inValue1B, input [1:0] inUse1, input inReady1,
    input [4:0] inOperation2, input [5:0] inROB2, input [5:0] inLook2A, input [5:0] inLook2B, input [15:0] inValue2A, input [15:0] inValue2B, input [1:0] inUse2, input inReady2,
    input [4:0] inOperation3, input [5:0] inROB3, input [5:0] inLook3A, input [5:0] inLook3B, input [15:0] inValue3A, input [15:0] inValue3B, input [1:0] inUse3, input inReady3,
    output [4:0] outOperation0, output [5:0] outROB0, output [15:0] outValue0A, output [15:0] outValue0B, output outReady0
    );

    parameter QUEUE_SIZE = 64;

    reg valid [0:QUEUE_SIZE-1];
    reg [4:0] operation [0:QUEUE_SIZE-1];
    reg [5:0] rob_num [0:QUEUE_SIZE-1];
    reg [5:0] lookA [0:QUEUE_SIZE-1];
    reg [5:0] lookB [0:QUEUE_SIZE-1];
    reg [15:0] valueA [0:QUEUE_SIZE-1];
    reg [15:0] valueB [0:QUEUE_SIZE-1];
    reg [1:0] user [0:QUEUE_SIZE-1];
    reg ready [0:QUEUE_SIZE-1];

    integer i;

    reg [5:0] readyCounter = 5'h00;
    reg inserted;

    initial begin
        for(i = 0; i < QUEUE_SIZE; i = i + 1)
            valid[i] <= 1'b0;
    end

    // always @(posedge clk) begin
    //     for(i = 0; i < QUEUE_SIZE; i = i + 1) begin
    //         if(valid[i] == 1 && ready[i] == 1) begin
    //             outOperation0 <= operation[i];
    //             outROB0 <= rob_num[i];
    //             outValue0A <= valueA[i];
    //             outValue0B <= valueB[i];
    //             outReady0 <= 1'b1;
    //             valid[i] <= 1'b0;
    //         end
    //     end
    // end

endmodule