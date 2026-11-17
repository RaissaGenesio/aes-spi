`timescale 1ns/1ps

module minisoc_aes_key_exp (
    input  logic [127:0] key_i,
    output logic [127:0] round_keys_o [0:10]
);

    // A chave original é a round key 0.
    assign round_keys_o[0] = key_i;

    genvar r;

    generate
        for (r = 0; r < 10; r = r + 1) begin : gen_key_round

            // Quatro palavras de 32 bits da chave anterior.
            wire [31:0] w0;
            wire [31:0] w1;
            wire [31:0] w2;
            wire [31:0] w3;

            // Saídas da S-box usadas pelo SubWord.
            wire [7:0] sb0;
            wire [7:0] sb1;
            wire [7:0] sb2;
            wire [7:0] sb3;

            wire [31:0] g_word;

            wire [31:0] next_w0;
            wire [31:0] next_w1;
            wire [31:0] next_w2;
            wire [31:0] next_w3;

            // Constante de rodada AES-128.
            localparam logic [7:0] RCON =
                (r == 0) ? 8'h01 :
                (r == 1) ? 8'h02 :
                (r == 2) ? 8'h04 :
                (r == 3) ? 8'h08 :
                (r == 4) ? 8'h10 :
                (r == 5) ? 8'h20 :
                (r == 6) ? 8'h40 :
                (r == 7) ? 8'h80 :
                (r == 8) ? 8'h1b :
                           8'h36;

            // Divide a round key anterior em quatro palavras.
            assign w0 = round_keys_o[r][127:96];
            assign w1 = round_keys_o[r][95:64];
            assign w2 = round_keys_o[r][63:32];
            assign w3 = round_keys_o[r][31:0];

            // RotWord(w3):
            //
            // {a0, a1, a2, a3}
            //       ↓
            // {a1, a2, a3, a0}
            //
            // Em seguida cada byte passa pela S-box (SubWord).

            minisoc_aes_sbox u_sbox_0 (
                .in_byte  (w3[23:16]),
                .out_byte (sb0)
            );

            minisoc_aes_sbox u_sbox_1 (
                .in_byte  (w3[15:8]),
                .out_byte (sb1)
            );

            minisoc_aes_sbox u_sbox_2 (
                .in_byte  (w3[7:0]),
                .out_byte (sb2)
            );

            minisoc_aes_sbox u_sbox_3 (
                .in_byte  (w3[31:24]),
                .out_byte (sb3)
            );

            // g() = SubWord(RotWord(w3)) XOR Rcon
            assign g_word = {
                sb0 ^ RCON,
                sb1,
                sb2,
                sb3
            };

            // Geração das quatro palavras da próxima round key.
            assign next_w0 = w0 ^ g_word;
            assign next_w1 = w1 ^ next_w0;
            assign next_w2 = w2 ^ next_w1;
            assign next_w3 = w3 ^ next_w2;

            assign round_keys_o[r + 1] = {
                next_w0,
                next_w1,
                next_w2,
                next_w3
            };

        end
    endgenerate

endmodule
