//Semisumador de dos entradas de 1 bit realizado a partir de puertas

module ha_v1(output wire sum, output wire carry, input wire a, input wire b);   // Las cosas entre parentesis son los puertos que es lo que entra y sale
// El orden se puede cambiar, pero mejor poner las salidas primero
// Wire: Es un cable para conectar weas

//Declaraci�n de conexiones internas: no hay ninguna

//Estructura interna: Instancias de puertas y sus conexiones

xor xor1(sum, a, b);
and and1(carry, a, b);  

endmodule
// iverilog para compilar weas

