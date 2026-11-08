`timescale 1ns/1ps

module minisoc_aes_mix_columns (
    input  logic [127:0] state_in,
    output logic [127:0] state_out
);

    // Multiplicacao por 2 em GF(2^8)
    function automatic logic [7:0] mul2 (
        input logic [7:0] x
    );
        begin
            if (x[7])
                mul2 = (x << 1) ^ 8'h1b;
            else
                mul2 = (x << 1);
        end
    endfunction

    // Multiplicacao por 3 em GF(2^8)
    function automatic logic [7:0] mul3 (
        input logic [7:0] x
    );
        begin
            mul3 = mul2(x) ^ x;
        end
    endfunction

    genvar c;

    generate
        for (c = 0; c < 4; c = c + 1) begin : gen_mix_column

            wire [7:0] s0;
            wire [7:0] s1;
            wire [7:0] s2;
            wire [7:0] s3;

            assign s0 = state_in[127 - (32*c) -: 8];
            assign s1 = state_in[119 - (32*c) -: 8];
            assign s2 = state_in[111 - (32*c) -: 8];
            assign s3 = state_in[103 - (32*c) -: 8];

            assign state_out[127 - (32*c) -: 8] =
                mul2(s0) ^ mul3(s1) ^ s2 ^ s3;

            assign state_out[119 - (32*c) -: 8] =
                s0 ^ mul2(s1) ^ mul3(s2) ^ s3;

            assign state_out[111 - (32*c) -: 8] =
                s0 ^ s1 ^ mul2(s2) ^ mul3(s3);

            assign state_out[103 - (32*c) -: 8] =
                mul3(s0) ^ s1 ^ s2 ^ mul2(s3);

        end
    endgenerate

endmodule
