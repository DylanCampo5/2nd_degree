`timescale 1 ns / 10 ps
module microc_tb;

// Declaración de variables
reg clk, reset, s_inc, s_inm, we3, s_skip;
reg [2:0] Op;
wire z;
wire [5:0] Opcode;

// Instanciación del camino de datos
microc micro(Opcode, z, clk, reset, s_inc, s_inm, we3, s_skip, Op);

// Generación de reloj clk
always
begin
  clk=1;
  #10;
  clk=0;
  #10;
end

// Reseteo y configuración de salidas del testbench
initial
begin
  $dumpfile("microc_tb.vcd");
  $dumpvars;
  
  //integer idx;
  //$dumpvars(0,  .br.R[1])

  reset = 1;  
  #5  
  reset = 0;

end

// Bloque simulación señales control por ciclo
initial
begin
  // Ciclo 1 (li 0, R1)
  #10   
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b000;
  s_inm = 1;

  // Ciclo 2 (li 1, R2)
  #20 
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b000;
  s_inm = 1; 

  // Ciclo 3 (li 4, R3)
  #20 
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b000;
  s_inm = 1;

  // Ciclo 4 (li 0, R4)
  #20 
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b000;
  s_inm = 1;

  // Ciclo 5 (and R3, R2, R5)(Bucle: )
  #20
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b100;
  s_inm = 0; 

  // Ciclo 6 (skipne R5, R4)
  #20
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b011;
  s_inm = 0;

  // Ciclo 7 (add R1, R2, R1)
  #20
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b010;
  s_inm = 0; 

  // Ciclo 8 (sub R3, R2, R3)
  #20
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b011;
  s_inm = 0; 

  // Ciclo 9 (skipeq R3, R2)
  #20
  s_inc = 1;
  s_skip = 0;
  we3 = 0;
  Op = 3'b011;
  s_inm = 0;

  // Ciclo 10 (j Bucle)
  #20
  s_inc = 0;
  s_skip = 0;
  we3 = 0;
  Op = 3'b000;
  s_inm = 0; 

  // Ciclo 11 (and R3, R2, R5)(Bucle: )
  #20
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b100;
  s_inm = 0; 

  // Ciclo 12 (skpine R5, R4)
  #20 
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b011;
  s_inm = 0;

  // Ciclo 13 (add R1, R2, R1)
  #20 
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b010;
  s_inm = 0;

  // Ciclo 14 (sub R3, R2, R3)
  #20 
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b011;
  s_inm = 0;

  // Ciclo 15 (skipeq R3, R2)
  #20 
  s_inc = 1;
  s_skip = 0;
  we3 = 0;
  Op = 3'b011;
  s_inm = 0;

  // Ciclo 16 (j Bucle)
  #20 
  s_inc = 0;
  s_skip = 0;
  we3 = 0;
  Op = 3'b000;
  s_inm = 0;

  // Ciclo 17 (and R3, R2, R5)(Bucle: )
  #20 
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b100;
  s_inm = 0;

  // Ciclo 18 (skipne R5, R4)
  #20  
  s_inc = 1;
  s_skip = 0;
  we3 = 0;
  Op = 3'b011;
  s_inm = 0;

  // Ciclo 19 (add R1, R2, R1)
  #20 
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b010;
  s_inm = 0;

  // Ciclo 20 (sub R3, R2, R3)
  #20 
  s_inc = 1;
  s_skip = 0;
  we3 = 1;
  Op = 3'b011;
  s_inm = 0;

  // Ciclo 21 (skipeq R3, R2)
  #20 
  s_inc = 1;
  s_skip = 1;
  we3 = 0;
  Op = 3'b011;
  s_inm = 0;

  // Ciclo 22 (j Fin)
  #20 
  s_inc = 0;
  s_skip = 0;
  we3 = 0;
  Op = 3'b000;
  s_inm = 0;

  // Ciclo 23 (j Fin)
  #20 
  s_inc = 0;
  s_skip = 0;
  we3 = 0;
  Op = 3'b000;
  s_inm = 0;;

  $finish;
end

endmodule
