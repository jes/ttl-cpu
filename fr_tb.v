/* Flags register testbench */
`include "fr.v"

module test;
    reg clk;

    reg [2:0] in;
    wire [2:0] out;
    reg load;

    assign load_bar = !load;

    FR fr (clk, in, load_bar, out);

    initial begin
        clk = 0;
        #1
        in = 3'b111;
        #1 if (out === 3'b111) $display("Bad: loaded value without load or posedge");
        load = 1;
        #1 if (out === 3'b111) $display("Bad: loaded value without posedge");
        clk = 1;
        #1 if (out !== 3'b111) $display("Bad: didn't load value at posedge,",out);
        clk = 0;
        in = 0; load = 0;
        #1 if (out !== 3'b111) $display("Bad: lost value without load or posedge,",out);
        clk = 1;
        #1 if (out != 3'b111) $display("Bad: lost value without load,",out);
        clk = 0;
        #1 if (out != 3'b111) $display("Bad: lost value at negedge,",out);
        load = 1;
        #1
        clk = 1;
        #1 if (out != 0) $display("Bad: didn't load value at posedge (2nd time),",out);
    end
endmodule