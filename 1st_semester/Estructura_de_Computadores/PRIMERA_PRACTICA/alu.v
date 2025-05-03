// `timescale 1ns / 10ps;

module alu(output wire [3:0] R, output wire zero, carry, sign, input wire [3:0] A, B, input wire c_in, input wire [2:0] Op);

    wire [3:0] cable_Op1, cable_Op2, cable_sum, cable_ul4;

    preprocess preprocesador(cable_Op1, cable_Op2, A, B, Op);
    sum4_ul4 Bloque_derecho(R, carry, cable_Op1, cable_Op2, c_in, Op[1:0], Op[2]);      // Modi
    
    /*
    sum4 sumador(cable_sum, carry, cable_Op1, cable_Op2, c_in);
    ul4 u_logica(cable_ul4, cable_Op1, cable_Op2, Op[1:0]);
    mux2_4 mux(R, cable_sum, cable_ul4, Op[2]);
    */

    assign zero = R ? 1'b0 : 1'b1;         // Si R es 1, da 0 --- Si R es 0, da 1
    assign sign = R[3];             // Le metemos a sign el valor más significativo de R 

endmodule;

// iverilog alu.v prep.v compl1.v sum.v fa.v u14.v cl.v mux4_1.v mux2_4.v 2>> error.txt
// iverilog alu_tb.v alu.v prep.v compl1.v sum.v fa.v u14.v cl.v mux4_1.v mux2_4.v 2>> error.txt
// gtkwave alu.vcd