module preprocess(output wire [3:0] AMod, output wire [3:0] BMod, input wire [3:0] A, input wire [3:0]B, input wire [2:0] Op);
  
  wire add1, op1_A, op2_B, cpl;
  wire [3:0] cable1, cable2;
  
  assign add1 = Op[0];
  assign op1_A = Op[2] | (Op[1] & ~Op[0]);
  assign op2_B = Op[2] | (Op[1] & ~Op[0]);
  assign cpl = (~Op[2] & ~Op[1]) & Op[0];

  mux2_4 mux1(cable1, 4'b0, 4'b1, add1);                             // add1
  mux2_4 mux2(AMod, cable1, A, op1_A);                               // op1_A
  mux2_4 mux3(cable2, A, B, op2_B);                                  // op2_B
  compl1 C1(BMod, cable2, cpl);                                      // C1

endmodule;

//assign AMod = op1_A ? A : add1;                   // Verifica si op1_A es 1, si sí, saca A, si es 0, saca add1

/*
add1   --->   y = C          ---> signed add1   = op0
op1_A  --->   y = A + BC'    ---> signed op1_A  = op2 or (op1 and ~op0)
op2_B  --->   y = A + BC'    ---> signed op2_A  = op2 or (op1 and ~op0)
cp1    --->   y = A'B'C      ---> signed cp1    = ~op2 an d ~op1 and op0 
*/
