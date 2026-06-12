`timescale 1ns/1ps

module tbModUart();
    reg clk, reset, start;
    reg [7:0] dataIn;
    wire [7:0] dataOut;
    wire txLine, busy, ready;

    always #10 clk = ~clk;

    RX dutRX(.clk(clk), .reset(reset), .rx(txLine), .data(dataOut), .ready(ready));
    TX dutTX(.data(dataIn), .clk(clk), .reset(reset), .start(start), .tx(txLine), .busy(busy));

    initial begin
        $dumpfile("Uart.vcd");
        $dumpvars(0, tbModUart);
        clk = 0; reset = 1; start = 0; dataIn = 0;
        #100;
        reset = 0;

        @(posedge clk);
        dataIn = 8'HA5;
        start = 1;

        @(posedge clk);
        start = 0;

        @(posedge ready);
        #100;
        $display("TX envio: %h | RX recibio: %h", 8'hA5, dataOut);
        $finish;

    end

endmodule