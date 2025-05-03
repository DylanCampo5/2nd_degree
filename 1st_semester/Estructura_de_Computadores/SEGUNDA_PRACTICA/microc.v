module microc(output wire [5:0] Opcode, output wire z, input wire clk, reset, s_inc, s_inm, we3, wez, input wire [2:0] Op);
//Microcontrolador sin memoria de datos de un solo ciclo

//Componentes internos del micro
wire [7:0] rd1, rd2, wd3, alu_out, inm;    
wire [15:0] instruccion;
wire [9:0] pc_out, pc_in, dir_salto;
wire z_alu;

// memoria de programa:
memprog memp(instruccion, clk, pc_out);

// PC:
registro #(10) PC(instruccion, clk, reset, pc_out);    // MIRAR ESTE BIEN TMB

// El sumador:
sum sumador(pc_in, pc_out,  10'b1);

// El mux de la izq:
mux2 #(10) mux1(pc_in, dir_salto, pc_in, s_inc);   // CREO QUE ESTA BIEN

// Banco de registro:
regfile banco_reg(rd1, rd2, clk, we3, instruccion[11:8], instruccion[7:4], instruccion[3:0], wd3);

// Para que el imn tenga el cacho que quiero del "instruccion"
assign inm = instruccion[11:4];

// El mux2 de la derecha:
mux2 #(10) mux2(wd3, alu_out, inm, s_inm);

// El ALU:
alu #(10) alu(alu_out, z_alu, rd1, rd2, Op);

// Flip flop tipo D de arribita:
ffd ffd(clk, reset, z_alu, wez, z);

// Para que la salida del OPCODE sea el cacho seleccionado de  "instruccion"
assign OPCODE = instruccion[15:10];

endmodule

/* 

CODIFICACION:
j START:        0100 0000 0000 0101     j
li #0 R2:       0001 0000 0000 0010     R2 = 0
li #2 R1:       0001 0000 0010 0001     R1 = 2
li #4 R3:       0001 0000 0100 0011     R3 = 4
li #1 R4:       0001 0000 0001 0100     R4 = 1
add R2 R3 R2:   1010 0010 0011 0010     R2 = 0 + 4 = 4
sub R1 R4 R1:   1011 0001 0100 0001     R1 = 2 - 1 = 1
jnz Iter:       0100 1000 0000 1001     j
add R2 R3 R2:   1010 0010 0011 0010     R2 = 4 + 4 = 8
sub R1 R4 R1:   1011 0001 0100 0001     R1 = 1 - 1 = 0
jFIN:           0100 0000 0000 1100     j 

Acá na más hay 11
*/



/*

MUX - componentes
SUM - componentes
Memoria Programa - memprog
Banco de Registro - componentes
Biestable D - componentes
ALU - alu

*/