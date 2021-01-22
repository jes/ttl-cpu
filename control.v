/* Control logic: turn a 16-bit microinstruction into control signals

    Bit | Meaning
    ----+--------
     15 | EO
     14 | EO ? EX : bus_out[2]
     13 | EO ? NX : bus_out[1]
     12 | EO ? EY : bus_out[0]
     11 | EO ? NY : RT
     10 | EO ? F  : P+
      9 | EO ? NO : (unused)
      8 | bus_in[2]
      7 | bus_in[1]
      6 | bus_in[0]
      5 | JC
      4 | JZ
      3 | JGT
      2 | JLT
      1 | (unused)
      0 | (unused)

 */

module Control(uinstr,
        PO, IOH, IOL, RO, XO, YO, DO, RT, PA, MI, RI, II, XI, YI, DI, JC, JZ, JGT, JLT, ALU_flags);

    input [15:0] uinstr,
    output PO, IOH, IOL, RO, XO, YO, DO, RT, PA, MI, RI, II, XI, YI, DI, JC, JZ, JGT, JLT;
    output [5:0] ALU_flags;

    wire [3:0] bus_out;
    wire [3:0] bus_in;

    assign EO = uinstr[15];

    // ALU has no side effects if !EO, so we can safely tie
    // the bus_out signals to ALU_flags without checking EO
    assign ALU_flags = uinstr[14:9];
    assign bus_out = uinstr[14:12];
    assign bus_in = uinstr[8:6];

    // bus_out decoding:
    assign PO = (!EO && bus_out == 0);  // PC out
    assign IOH = (!EO && bus_out == 1); // IR out (high end)
    assign IOL = (!EO && bus_out == 2); // IR out (low end)
    assign RO = (!EO && bus_out == 3);  // RAM out
    assign XO = (!EO && bus_out == 4);  // X out
    assign YO = (!EO && bus_out == 5);  // Y out
    assign DO = (!EO && bus_out == 6);  // device out
    // spare: assign .. = (!EO && bus_out == 7)

    // decode RT/P+
    assign RT = !EO && uinstr[11];
    assign PA = !EO && uinstr[10];

    // bus_in decoding:
    // bus_in == 0 means nobody inputs from bus
    assign MI = (bus_in == 1); // MAR in
    assign RI = (bus_in == 2); // RAM in
    assign II = (bus_in == 3); // IR in
    assign XI = (bus_in == 4); // X in
    assign YI = (bus_in == 5); // Y in
    assign DI = (bus_in == 6); // device in
    // spare: assign .. = (bus_in == 7)

    assign JC = uinstr[5];
    assign JZ = uinstr[4];
    assign JGT = uinstr[3];
    assign JLT = uinstr[2];
endmodule
