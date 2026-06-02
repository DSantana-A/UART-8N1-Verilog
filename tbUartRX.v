`timescale 1ns/1ps

module tbUartRX();
    reg clk, reset, rx;
    wire [7:0] data;
    wire ready;

    always #10 clk = ~clk;

    RX dut(.clk(clk), .reset(reset), .rx(rx), .data(data), .ready(ready));
    
    initial begin
        $dumpfile("UartRX.vcd");
        $dumpvars(0,tbUartRX);
        clk = 0; reset = 1; rx=1;
        #100;
        reset = 0;

        //Each cicle 20ns, 5208(cicles) * 20ns = 104,160ns

        //Start Bit
        rx=0; #104160;
        //LSB
        rx=1; #104160;
        rx=0; #104160;
        rx=1; #104160;
        rx=0; #104160;
        rx=0; #104160;
        rx=1; #104160;
        rx=0; #104160;
        rx=1; #104160;
        //Stop Bit
        rx=1; 
        
        @(posedge ready);
        #100;
        $display("Data Received: %h", data);
        $finish;
        
    end
endmodule