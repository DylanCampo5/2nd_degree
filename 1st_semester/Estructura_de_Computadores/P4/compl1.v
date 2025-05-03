module compl1(output wire [3:0] Out, input wire [3:0] Inp, input wire cpl);         // x = codicion ? y : z;
  assign Out = cp1 ? ~Inp : Inp;
endmodule;
// Cambia los bits 0 por 1




/* 
op2 op1 op0             add1 - op1_A - op2_B - cpl
a+cin ---   000    |     0       0       0      0                                                  
-a+cin ---  001    |     1       0       0      1                             C1a+1+cin, que debo intentar: [C1a][1]
a+b+cin --- 010    |     X       1       1      0                                 
a+1+cin --- 011    |     1       0       0      0                                 
aANDb ---   100    |     X       1       1      0                                          
aORb ---    101    |     X       1       1      0                                             
aXORb ---   110    |     X       1       1      0                             Si op1_A 1, siempre será A 
NOTa ---    111    |     X       1       1      0                                               
*/

/*
Hay que sacar los miniterminos de cada uno o reducir por K (online)
Los copio por columnas, obviamente
EJEMPLO:    y = A'B' + C     y = (add1)
En vez de dibujar como un gil,              signed add1 = (~op2 and ~op1) or op0
*/

/* 
add1 entonces pasa 1
AMod --- sale 0 1 a
BMod --- a b C1a C1b
*/