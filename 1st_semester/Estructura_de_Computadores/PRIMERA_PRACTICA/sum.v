module sum4(output wire[3:0] S, output wire c_out, input wire[3:0] A, input wire[3:0] B, input wire c_in);

    wire C1, C2, C3;

    fa fa1 (C1, S[0] ,A [0], B[0], c_in);
    fa fa2 (C2, S[1] ,A[1], B[1], C1);
    fa fa3 (C3, S[2], A[2], B[2], C2);
    fa fa4 (c_out, S[3], A[3], B[3], C3);

endmodule;
