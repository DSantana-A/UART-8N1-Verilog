`timescale 1ns/1ps

module TX (
    input  logic [7:0] data,
    input  logic       clk, reset, start,
    output logic       tx, busy
);
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } state_t;

    localparam int CLKS = 5208;

    state_t      state;
    logic [12:0] baud_count;
    logic [2:0]  bit_count;
    logic [7:0]  shift_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            tx <= 1;
            busy <= 0;
            state <= IDLE;
            baud_count <=0;
            bit_count <=0;
            shift_reg <=0;
        end else begin
            case (state)
                IDLE: begin
                    if (start==1) begin
                        shift_reg <= data;
                        busy <= 1;
                        baud_count <= 0;
                        bit_count <= 0;
                        state <= START;
                    end
                end
                START: begin
                    tx <= 0;
                    if (baud_count < (CLKS -1)) begin
                        baud_count <= baud_count+1;
                    end else begin
                        baud_count <= 0;
                        state <= DATA;
                    end
                end
                DATA: begin
                    tx <= shift_reg[0];
                    if (baud_count < (CLKS -1)) begin
                        baud_count <= baud_count+1;
                    end else begin
                        baud_count <= 0;
                        shift_reg <= shift_reg>>1;
                        if (bit_count == 7) begin
                            bit_count <= 0;
                            state <= STOP;
                        end else begin
                            bit_count <= bit_count +1;

                        end
                    end
                end
                STOP: begin
                    tx <= 1;
                    if (baud_count < (CLKS -1)) begin
                        baud_count <= baud_count+1;
                    end else begin
                        baud_count <= 0;
                        busy <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
