module sum4_ul4(output reg[3:0] Out, output reg c_out, input wire[3:0] OP1, input wire[3:0] OP2, input wire c_in, input wire [1:0] S, input wire l);

  always @(OP1, OP2, c_in, S, l) begin         // Mux
    if (l) begin                        // Si l = 1 hará lo que hace el ul4                 
      case(S)                           //  Comienza el ul4
        2'b00   : Out = OP1 & OP2;
        2'b01   : Out = OP1 | OP2;
        2'b10   : Out = OP1 ^ OP2;
        2'b11   : Out = ~OP1;
        default : Out = 4'b0000;
      endcase
      c_out = 0;
    end

    else begin                       // Si l = 0 hará la función de la suma
      {c_out, Out} = OP1 + OP2 + c_in;
    end 
  end

endmodule