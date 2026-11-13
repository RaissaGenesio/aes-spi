`timescale 1ns/1ps

module minisoc_aes_dp (
    input  logic         clk_i,
    input  logic         rst_n_i,
    input  logic         start_i,
    input  logic         decrypt_i,
    input  logic [127:0] block_i,
    input  logic [127:0] key_i,

    output logic [127:0] block_o,
    output logic         busy_o,
    output logic         done_o
);

    typedef enum logic [1:0] {
        IDLE,
        INIT,
        ROUND,
        FINAL
    } fsm_state_t;

    fsm_state_t fsm_q;
    fsm_state_t fsm_d;

    // Estado atual do AES.
    logic [127:0] state_q;

    // Modo capturado no inicio da operacao.
    logic decrypt_q;

    // 0 = AddRoundKey inicial
    // 1..9 = rodadas intermediarias
    // 10 = rodada final
    logic [3:0] round_count_q;

    // Round keys AES-128.
    logic [127:0] round_keys [0:10];

    // ============================================================
    // Caminho de cifragem
    // ============================================================

    logic [127:0] sub_bytes_out;
    logic [127:0] shift_rows_out;
    logic [127:0] mix_columns_out;
    logic [127:0] enc_round_data;

    // ============================================================
    // Caminho de decriptacao
    // ============================================================

    logic [127:0] inv_shift_rows_out;
    logic [127:0] inv_sub_bytes_out;
    logic [127:0] inv_mix_columns_out;

    // ============================================================
    // Sinais compartilhados
    // ============================================================

    logic [127:0] ark_state_in;
    logic [127:0] current_round_key;
    logic [127:0] add_round_key_out;
    logic [127:0] next_state_data;

    // ============================================================
    // Key Expansion
    // ============================================================

    minisoc_aes_key_exp u_key_exp (
        .key_i        (key_i),
        .round_keys_o (round_keys)
    );

    // ============================================================
    // Cifragem
    // ============================================================

    minisoc_aes_sub_bytes u_sub_bytes (
        .state_in  (state_q),
        .state_out (sub_bytes_out)
    );

    minisoc_aes_shift_rows u_shift_rows (
        .state_in  (sub_bytes_out),
        .state_out (shift_rows_out)
    );

    minisoc_aes_mix_columns u_mix_columns (
        .state_in  (shift_rows_out),
        .state_out (mix_columns_out)
    );

    // Rodada final da cifragem nao utiliza MixColumns.
    always_comb begin
        if (fsm_q == FINAL)
            enc_round_data = shift_rows_out;
        else
            enc_round_data = mix_columns_out;
    end

    // ============================================================
    // Decriptacao
    // ============================================================

    minisoc_aes_inv_shift_rows u_inv_shift_rows (
        .state_in  (state_q),
        .state_out (inv_shift_rows_out)
    );

    minisoc_aes_inv_sub_bytes u_inv_sub_bytes (
        .state_in  (inv_shift_rows_out),
        .state_out (inv_sub_bytes_out)
    );

    // No inverse cipher, InvMixColumns ocorre depois do AddRoundKey.
    minisoc_aes_inv_mix_columns u_inv_mix_columns (
        .state_in  (add_round_key_out),
        .state_out (inv_mix_columns_out)
    );

    // ============================================================
    // Entrada compartilhada do AddRoundKey
    // ============================================================

    always_comb begin

        if (fsm_q == INIT)
            ark_state_in = block_i;

        else if (decrypt_q)
            ark_state_in = inv_sub_bytes_out;

        else
            ark_state_in = enc_round_data;

    end

    // ============================================================
    // Selecao da round key
    // ============================================================

    always_comb begin

        if (decrypt_q)
            current_round_key = round_keys[4'd10 - round_count_q];
        else
            current_round_key = round_keys[round_count_q];

    end

    // ============================================================
    // AddRoundKey compartilhado
    // ============================================================

    minisoc_aes_add_round_key u_add_round_key (
        .state_in  (ark_state_in),
        .round_key (current_round_key),
        .state_out (add_round_key_out)
    );

    // Na decriptacao, as rodadas intermediarias utilizam
    // InvMixColumns apos AddRoundKey.
    //
    // INIT e FINAL nao utilizam InvMixColumns.
    always_comb begin

        if (decrypt_q && (fsm_q == ROUND))
            next_state_data = inv_mix_columns_out;
        else
            next_state_data = add_round_key_out;

    end

    // ============================================================
    // FSM combinacional
    // ============================================================

    always_comb begin

        fsm_d  = fsm_q;
        busy_o = 1'b0;
        done_o = 1'b0;

        case (fsm_q)

            IDLE: begin
                if (start_i)
                    fsm_d = INIT;
            end

            INIT: begin
                busy_o = 1'b1;
                fsm_d  = ROUND;
            end

            ROUND: begin

                busy_o = 1'b1;

                if (round_count_q == 4'd9)
                    fsm_d = FINAL;

            end

            FINAL: begin

                busy_o = 1'b1;
                done_o = 1'b1;
                fsm_d  = IDLE;

            end

            default: begin
                fsm_d = IDLE;
            end

        endcase
    end

    // ============================================================
    // Registradores
    // ============================================================

    always_ff @(posedge clk_i or negedge rst_n_i) begin

        if (!rst_n_i) begin

            fsm_q         <= IDLE;
            state_q       <= 128'b0;
            round_count_q <= 4'd0;
            decrypt_q     <= 1'b0;

        end
        else begin

            fsm_q <= fsm_d;

            case (fsm_q)

                IDLE: begin

                    round_count_q <= 4'd0;

                    // Captura o modo apenas no inicio da operacao.
                    if (start_i)
                        decrypt_q <= decrypt_i;

                end

                INIT: begin

                    // Encrypt:
                    // plaintext XOR key_0
                    //
                    // Decrypt:
                    // ciphertext XOR key_10
                    state_q       <= add_round_key_out;
                    round_count_q <= 4'd1;

                end

                ROUND: begin

                    // Encrypt:
                    // SubBytes -> ShiftRows -> MixColumns
                    // -> AddRoundKey
                    //
                    // Decrypt:
                    // InvShiftRows -> InvSubBytes -> AddRoundKey
                    // -> InvMixColumns
                    state_q       <= next_state_data;
                    round_count_q <= round_count_q + 4'd1;

                end

                FINAL: begin

                    // Encrypt:
                    // SubBytes -> ShiftRows -> AddRoundKey
                    //
                    // Decrypt:
                    // InvShiftRows -> InvSubBytes -> AddRoundKey
                    state_q       <= next_state_data;
                    round_count_q <= 4'd0;

                end

                default: begin
                    round_count_q <= 4'd0;
                end

            endcase
        end
    end

    // Durante FINAL o resultado combinacional ja esta valido.
    // Depois, state_q mantem o resultado.
    always_comb begin

        if (fsm_q == FINAL)
            block_o = next_state_data;
        else
            block_o = state_q;

    end

endmodule
