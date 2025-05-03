module mux2_4(output reg [3:0] Out, input wire [3:0] A, input wire [3:0] B, input wire s);

    always @(A, B, s) begin               // Out debe ser reg, ni wire, cuidao
      if (s)
        Out = B;
      else
        Out = A;
    end                  // Ya tenemos un mux 2a1, que bestias

endmodule;