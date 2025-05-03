//Semisumador de dos entradas de 1 bit realizado con sentencia always

module ha_v4(output reg sum, output reg carry, input wire a, input wire b);
// Pone reg ya que cada que cambia a o b lo hace de nuevo, y pone reg pq cada que cambia, necesita recordar lo anterior
// Si estoy en una asignacion continua, el lado izq SIEMPRE es wire, y si no es continua, pos sera reg

// construcci�n always (procedural), las asignaciones deben ser a variables con
// estado ('sum' y �carry� ahora son de tipo reg)

always @(a, b) 
// Alternativamente, always @(a or b) o always @* (autom�tico, considera todas las var. que intervienen)

begin  //always
  sum = a ^ b;
  carry = a & b;
end    //always
// BUSCAR: Que chigaos son los bloques... :1        Pueden ser de tipo always o initial 
// Cada que se modifica una var_, se modifica el bloque y sirve pa bucles, condicionales, mezclas y mucha mierda


endmodule
// DISEÑO DE COMPORTAMIENTO CON LOS BLOQUES

