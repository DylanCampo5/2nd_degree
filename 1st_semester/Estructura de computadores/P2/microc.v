module microc(output wire [5:0] Opcode, output wire z, input wire clk, reset, s_inc, s_inm, we3, s_skip, input wire [2:0] Op);
//Microcontrolador sin memoria de datos de un solo ciclo
wire [7:0] rd1, rd2, wd3, alu_out, inm;    
wire [15:0] instruccion;
wire [9:0] pc_out, pc_in, dir_salto, mux_out, sum_out;

assign dir_salto = instruccion[9:0];

memprog memoria(instruccion, clk, pc_out);

registro #(10) PC(pc_out, clk, reset, pc_in);

regfile Banco_reg(rd1, rd2, clk, we3, instruccion[3:0], instruccion[7:4], instruccion[11:8], wd3);

alu ALU(alu_out, z, rd1, rd2, Op);

// Mux de la izq del todo
mux2 #(10) mux1(pc_in, dir_salto, sum_out, s_inc);

// Mux del centro
assign n1 = 10'b0000000001;
assign n2 = 10'b0000000010;
mux2 #(10) mux2(mux_out, n1, n2, s_skip);

// Mux de la derecha
assign inm = instruccion[11:4];
mux2 #(10) mux3(wd3, alu_out, inm, s_inm);

sum sumador(sum_out, mux_out, pc_out);

assign OPCODE = instruccion[15:10];

endmodule
