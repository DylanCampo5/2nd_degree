module alu(output wire [3:0] R, output wire zero, carry, sign, input wire [3:0] A, B, input wire c_in, input wire [2:0] Op);

    wire [3:0] cable_Op1, cable_Op2, cable_sum, cable_ul4;

    prep preprocess(cable_Op1, cable_Op2, A, B, Op);
    u14 ul4(cable_ul4, cable_Op1, cable_Op2, Op[1:0]);
    sum4 sumador(cable_sum, cable_Op1, cable_Op2, c_in);
    mux2_4 mux(R, cable_ul4, cable_sum, Op[2]);

    assign zero = R? 0 : 1;         // Si R es 1, da 0 --- Si R es 0, da 1
    assign sign = R[3];             // Le metemos a sign el valor más significativo de R 

endmodule;