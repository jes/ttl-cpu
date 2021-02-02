/* RAM

   When "en" is 1, gives current value to the bus
   When "load" is 1 and clock edge rises, takes in new value from the bus
   Always gives current value to 'value'
 */

module RAM(clk, in, load_bar, address, value);
    input clk;
    input [15:0] in;
    input load_bar;
    input [15:0] address;
    output [15:0] value;

    reg [15:0] ram [0:255];

    reg [15:0] out;
    assign value = out;

    always @ (posedge clk) begin
        if (!load_bar) ram[address[7:0]] <= in;
        out <= ram[address[7:0]];
    end
endmodule
