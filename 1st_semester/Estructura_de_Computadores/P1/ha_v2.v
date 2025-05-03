//Semisumador de dos entradas de 1 bit realizado a partir sentencias assign

module ha_v2(output wire sum, output wire carry, input wire a, input wire b);

// semisumador con asignaciones continuas (assign)

assign sum = a ^ b;	//operador xor (bit a bit)
assign carry = a & b;	//operador and (bit a bit)

endmodule
// Esta version hace la misma mierda
// Solo dice que la salida de sum y de carry es lo que tiene cada uno correspondientemente
// Se calcula el lado derecho y se asigna al lado izq (obvio)


