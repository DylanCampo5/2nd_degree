`timescale 1 ns / 10 ps
module microc_tb;

// declaración de variables
//...

// instanciación del camino de datos
//...

// generación de reloj clk
//...

// Reseteo y configuración de salidas del testbench
initial
begin
  $dumpfile("microc_tb.vcd");
  $dumpvars;
  // ... señal de reset
end

// Bloque simulación señales control por ciclo
initial
begin
  // retardos y señales para ejecutar primera instrucción (ciclo 1)
  // retardos y señales para ejecutar segunda instrucción (ciclo 2)
  // ...
  $finish;
end

endmodule
