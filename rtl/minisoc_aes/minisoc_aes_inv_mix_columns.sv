`timescale 1ns/1ps

module minisoc_aes_inv_mix_columns (
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

    function automatic logic [7:0] mul4 (
        input logic [7:0] x
    );
        begin
            mul4 = mul2(mul2(x));
        end
    endfunction

    function automatic logic [7:0] mul8 (
        input logic [7:0] x
    );
        begin
            mul8 = mul2(mul4(x));
        end
    endfunction

    function automatic logic [7:0] mul9 (
        input logic [7:0] x
    );
        begin
            mul9 = mul8(x) ^ x;
        end
    endfunction

    function automatic logic [7:0] mul11 (
        input logic [7:0] x
    );
        begin
            mul11 = mul8(x) ^ mul2(x) ^ x;
        end
    endfunction

    function automatic logic [7:0] mul13 (
        input logic [7:0] x
    );
        begin
            mul13 = mul8(x) ^ mul4(x) ^ x;
        end
    endfunction

    function automatic logic [7:0] mul14 (
        input logic [7:0] x
    );
        begin
            mul14 = mul8(x) ^ mul4(x) ^ mul2(x);
        end
    endfunction

    genvar c;

    generate
        for (c = 0; c < 4; c = c + 1) begin : gen_inv_mix_column

            wire [7:0] s0;
            wire [7:0] s1;
            wire [7:0] s2;
            wire [7:0] s3;

            assign s0 = state_in[127 - (32*c) -: 8];
            assign s1 = state_in[119 - (32*c) -: 8];
            assign s2 = state_in[111 - (32*c) -: 8];
            assign s3 = state_in[103 - (32*c) -: 8];

            assign state_out[127 - (32*c) -: 8] =
                mul14(s0) ^ mul11(s1) ^ mul13(s2) ^ mul9(s3);

            assign state_out[119 - (32*c) -: 8] =
                mul9(s0) ^ mul14(s1) ^ mul11(s2) ^ mul13(s3);

            assign state_out[111 - (32*c) -: 8] =
                mul13(s0) ^ mul9(s1) ^ mul14(s2) ^ mul11(s3);

            assign state_out[103 - (32*c) -: 8] =
                mul11(s0) ^ mul13(s1) ^ mul9(s2) ^ mul14(s3);

        end
    endgenerate

endmodule
