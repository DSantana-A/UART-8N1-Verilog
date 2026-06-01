module RX (
    input clk, reset, rx,
    output reg [7:0] data,
    output  reg ready
);
    
    parameter IDLE = 2'b00;
    parameter START = 2'b01;
    parameter DATA = 2'b10;
    parameter STOP = 2'b11;
    parameter CLKS = 5208;

    reg [1:0] state;
    reg [12:0] baud_count;
    reg [2:0] bit_count;

    always @(posedge clk ) begin
        if (reset) begin
            data <= 0;
            ready <= 0;
            state <= IDLE;
            baud_count <=0;
            bit_count <=0;
        end else begin
            case (state)
             IDLE  : begin
                ready <= 0;
                if (rx==0) begin
                    baud_count <= 0;
                    state <= START;
                end
             end
             START : begin
                if (baud_count < CLKS/2 - 1) begin
                    baud_count <= baud_count + 1;
                end else begin
                    baud_count <= 0;
                    if (rx == 0)
                    state <= DATA;
                    else
                    state <= IDLE;
                end
             end
             DATA : begin
                if (baud_count < CLKS - 1) begin
                    baud_count  <= baud_count + 1;
                end else begin
                   baud_count <= 0;
                   data[bit_count] <= rx;
                   if (bit_count == 7) begin
                    bit_count <= 0;
                    state <= STOP;
                   end else begin
                        bit_count <= bit_count + 1;
                   end
                end
             end
             STOP : begin
                if (baud_count < CLKS -1) begin
                    baud_count <= baud_count + 1;
                end else begin
                    baud_count <= 0;
                    ready <= 1;
                    state <= IDLE;
                end
             end 
            endcase
        end
        
    end

endmodule