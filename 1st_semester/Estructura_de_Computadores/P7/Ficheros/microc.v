module microc(output wire [5:0] Opcode, output wire z, input wire clk, reset, s_inc, s_inm, we3, wez, input wire [2:0] Op);
//Microcontrolador sin memoria de datos de un solo ciclo


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
*/