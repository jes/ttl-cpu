/* General-purpose 16-bit register for TTL CPU

   Likely to be used for:
    X register, Y register

   When "en" is 1, gives current value to the bus
   When "load" is 1 and clock edge rises, takes in new value from the bus
   Always gives current value to 'value'
*/

`include "ttl/74377.v"

module Register(clk, bus, load_bar, value);
    input clk;
    input [15:0] bus;
    input load_bar;
    output [15:0] value;

    ttl_74377 reglow (load_bar, bus[7:0], clk, value[7:0]);
    ttl_74377 reghigh (load_bar, bus[15:8], clk, value[15:8]);
endmodule
