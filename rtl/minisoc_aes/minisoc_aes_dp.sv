`timescale 1ns/1ps

module minisoc_aes_dp (
    input  logic         clk_i,
    input  logic         rst_n_i,
    input  logic         start_i,
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

    // 0 = AddRoundKey inicial
    // 1..9 = rodadas normais
    // 10 = rodada final
    logic [3:0] round_count_q;

    // Round keys do AES-128.
    logic [127:0] round_keys [0:10];

    // Sinais intermediarios do datapath.
    logic [127:0] sub_bytes_out;
    logic [127:0] shift_rows_out;
    logic [127:0] mix_columns_out;

    logic [127:0] round_data;
    logic [127:0] ark_state_in;
    logic [127:0] current_round_key;
    logic [127:0] add_round_key_out;

    // ============================================================
    // Key Expansion
    // ============================================================

    minisoc_aes_key_exp u_key_exp (
        .key_i        (key_i),
        .round_keys_o (round_keys)
    );

    // ============================================================
    // Transformacoes da rodada
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

    // Na rodada final o MixColumns e ignorado.
    always_comb begin
        if (fsm_q == FINAL)
            round_data = shift_rows_out;
        else
            round_data = mix_columns_out;
    end

    // INIT recebe diretamente o bloco de entrada.
    // ROUND e FINAL recebem a saida das transformacoes.
    always_comb begin
        if (fsm_q == INIT)
            ark_state_in = block_i;
        else
            ark_state_in = round_data;
    end

    // Chave correspondente a rodada atual.
    always_comb begin
        current_round_key = round_keys[round_count_q];
    end

    // AddRoundKey compartilhado.
    minisoc_aes_add_round_key u_add_round_key (
        .state_in  (ark_state_in),
        .round_key (current_round_key),
        .state_out (add_round_key_out)
    );

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

        end
        else begin

            fsm_q <= fsm_d;

            case (fsm_q)

                IDLE: begin
                    round_count_q <= 4'd0;
                end

                INIT: begin

                    // AddRoundKey inicial:
                    // block_i XOR round_key_0
                    state_q       <= add_round_key_out;
                    round_count_q <= 4'd1;

                end

                ROUND: begin

                    // Rodadas 1 ate 9.
                    state_q       <= add_round_key_out;
                    round_count_q <= round_count_q + 4'd1;

                end

                FINAL: begin

                    // Rodada 10.
                    // MixColumns ja foi desviado pelo MUX.
                    state_q       <= add_round_key_out;
                    round_count_q <= 4'd0;

                end

                default: begin
                    round_count_q <= 4'd0;
                end

            endcase
        end
    end

    // Durante FINAL, add_round_key_out ja contem o ciphertext.
    // Depois da rodada final, state_q mantem o mesmo resultado.
    always_comb begin
        if (fsm_q == FINAL)
            block_o = add_round_key_out;
        else
            block_o = state_q;
    end

endmodule
