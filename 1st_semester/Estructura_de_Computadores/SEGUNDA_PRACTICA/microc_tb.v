`timescale 1 ns / 10 ps
module microc_tb;

// declaración de variables
reg clk, reset, s_inc, s_inm, we3, wez;
reg [2:0] Op;
wire z;
wire [5:0] Opcode;

// instanciación del camino de datos
microc micro(Opcode, z, clk, reset, s_inc, s_inm, we3, wez, Op);

// generación de reloj clk
always
begin
  clk=1
  #10
  clk=0
  #10
end

// Reseteo y configuración de salidas del testbench
initial
begin
  $dumpfile("microc_tb.vcd"): ;
  $dumpvars;

  // ... señal de reset
  

end

// Bloque simulación señales control por ciclo
initial
begin
  // (ciclo 1): j Start
  #10
  s_inc = 1'b0;
  Op = 3'b000;
  s_inm = 1'b0;       //
  we3 = 0;            // De escritura, solo si hay un li, un add, o lo que sea

  // (ciclo 2): li #0 R2
  #20
  s_inc = 1'b1;
  Op = 3'b000;
  s_inm = 1'b0;


  // (ciclo 3): li #2 R1


  // (ciclo 4): li #4 R3


  // (ciclo 5): li #1 R4


  // (ciclo 6): add R2 R3 R2


  // (ciclo 7): sub R1 R4 R1


  // (ciclo 8): jnz Iter
  s_inc = z_alu;

  // (ciclo 9): add R2 R3 R2


  // (ciclo 10): sub R1 R4 R1


  // (ciclo 11): j Fin


  $finish;
end

endmodule


// iverilog *.v
// vvp *.vcd
// gtkway 