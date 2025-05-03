//Sumador completo (full-adder) de tres entradas de 1 bit realizado a partir de puertas l�gicas 
module fa_v1(output wire sum, output wire c_out, input wire a, input wire b, input wire c_in);

    // Para declarar las var_
    wire sum1, carry1, carry2;

    //Se pone primero las salidas y luego se ponen las entradas
    ha_v1 ha1(sum1, carry1, a, b);
    ha_v1 ha2(sum, carry2, c_in, sum1);
    or    or1(c_out, carry1, carry2);

endmodule
