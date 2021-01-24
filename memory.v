/* Memory

   When "en" is 1, gives current value to the bus
   When "load" is 1 and clock edge rises, RAM takes in new value from the bus
   Always gives current value to 'value'
*/

`include "rom.v"
`include "ram.v"

module Memory(clk, bus, load_bar, en_bar, address, value);
    input clk;
    inout [15:0] bus;
    input load_bar;
    input en_bar;
    input [15:0] address;
    output [15:0] value;

    wire [15:0] rom_value;
    wire [15:0] ram_value;

    ROM rom (address[7:0], rom_value);
    RAM ram (clk, bus, load_bar, address, ram_value);

    assign value = address < 256 ? rom_value : ram_value;
    assign bus = en_bar ? 16'bZ : value;
endmodule
