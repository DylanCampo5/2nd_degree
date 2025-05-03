module cl(output wire out, input wire a, b, input wire [1:0] S);

    wire sA, sO, sX, sN;
    
    and     pa(sA, a, b);
    or      po(sO, a, b);
    xor     pe(sX, a, b);
    not     px(sN, a);

    mux4_1  mux(out, sA, sO, sX, sN, S);

endmodule;