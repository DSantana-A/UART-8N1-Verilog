`timescale 1ns/1ps

module tbUartTX ();
    reg clk, reset, start;
    reg [7:0] data;
    wire tx, busy;

    always #10 clk = ~clk;

    TX dut(.data(data), .clk(clk), .reset(reset), .start(start), .tx(tx), .busy(busy));

    initial begin
        $dumpfile("UartTX.vcd");
        $dumpvars(0,tbUartTX);
        clk = 0; reset = 1; start = 0; data = 0;
        #100;
        reset = 0;

        @(posedge clk);
        data = 8'hA5;
        start = 1;

        @(posedge clk);
        start = 0;

        wait(busy == 0);
        #100
        $display("Transmision Completed. Data sent: %h", 8'hA5);
        $finish;

    end
endmodule