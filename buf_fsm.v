`timescale 1ns / 1ns

// Moore finite-state machine for circular buffer
module buf_fsm(
    input clk,
    input rst,
    input t1,
    input t2,
    input t3, // write or read t3
    input t4, // writing or reading done at opposite bank
    input loop_work, // stay in WORK
    input go_work,
    output reg [1:0] state
);

parameter IDLE = 2'd0, READY = 2'd1, WORK = 2'd2, WAIT = 2'd3;
reg [1:0] nxt_state;

always @(posedge clk or posedge rst) begin // sequential
    if (rst) state <= IDLE;
    else state <= nxt_state;
end

always @* begin // combinational
    case (state)
        IDLE:
            if (t1) nxt_state = go_work ? WORK : READY;
        READY: // start point
            if (t2) nxt_state = WORK;
        WORK:
            if (t3) nxt_state = t4 ? (loop_work ? WORK : IDLE) : WAIT;
        WAIT:
            if (t4) nxt_state = IDLE;
        default:
            nxt_state = IDLE;
    endcase
end

endmodule
