`timescale 1ns/1ps
module minisoc_spi (
    input  logic         clk_i,
    input  logic         rst_n_i,

    input  logic         spi_sclk_i,
    input  logic         spi_cs_n_i,
    input  logic         spi_mosi_i,
    output logic         spi_miso_o,

    output logic [127:0] cfg_key_o,
    output logic [127:0] cfg_iv_o,
    output logic [63:0]  cfg_counter_o,
    output logic [8:0]   cfg_num_blocks_o,
    output logic [2:0]   cfg_mode_o,
    output logic         cfg_decrypt_o,
    output logic         aes_start_o,

    input  logic         aes_busy_i,
    input  logic         aes_done_i,
    input  logic         aes_error_i,
    input  logic [8:0]   aes_blocks_done_i,

    output logic         mem_sel_aes_o,
    output logic         pll_enable_o,
    output logic [1:0]   pll_div_sel_o,

    input  logic         pll_locked_i
);

    // ============================================================
    // Enderecos
    // ============================================================

    localparam logic [5:0] ADDR_KEY0           = 6'h00;
    localparam logic [5:0] ADDR_KEY1           = 6'h01;
    localparam logic [5:0] ADDR_KEY2           = 6'h02;
    localparam logic [5:0] ADDR_KEY3           = 6'h03;

    localparam logic [5:0] ADDR_IV0            = 6'h04;
    localparam logic [5:0] ADDR_IV1            = 6'h05;
    localparam logic [5:0] ADDR_IV2            = 6'h06;
    localparam logic [5:0] ADDR_IV3            = 6'h07;

    localparam logic [5:0] ADDR_COUNTER_HI     = 6'h08;
    localparam logic [5:0] ADDR_COUNTER_LO     = 6'h09;
    localparam logic [5:0] ADDR_NUM_BLOCKS     = 6'h0A;
    localparam logic [5:0] ADDR_AES_CONTROL    = 6'h0B;
    localparam logic [5:0] ADDR_AES_STATUS     = 6'h0C;
    localparam logic [5:0] ADDR_VERSION        = 6'h0D;
    localparam logic [5:0] ADDR_SYSTEM_CONTROL = 6'h0E;
    localparam logic [5:0] ADDR_SYSTEM_STATUS  = 6'h0F;
    localparam logic [5:0] ADDR_NOP            = 6'h3F;


    // ============================================================
    // Recepcao SPI
    // ============================================================

    logic [39:0] spi_rx_shift_q;
    logic [39:0] frame_hold_q;
    logic [5:0]  bit_count_q;
    logic        frame_toggle_q;


    // ============================================================
    // CDC SPI -> clk_i
    // ============================================================

    logic frame_toggle_meta_q;
    logic frame_toggle_sync_q;
    logic frame_toggle_sync_d_q;

    logic frame_valid_clk;
    logic frame_ready_q;

    logic [39:0] frame_clk_q;


    // ============================================================
    // Decodificacao
    // ============================================================

    logic        frame_rwb;
    logic [5:0]  frame_addr;
    logic        frame_rsv;
    logic [31:0] frame_data;

    assign frame_rwb  = frame_clk_q[39];
    assign frame_addr = frame_clk_q[38:33];
    assign frame_rsv  = frame_clk_q[32];
    assign frame_data = frame_clk_q[31:0];


    // ============================================================
    // Multiplexador de leitura
    // ============================================================

    logic [31:0] read_data;

    always_comb begin

        read_data = 32'b0;

        case (frame_addr)

            ADDR_KEY0:
                read_data = cfg_key_o[127:96];

            ADDR_KEY1:
                read_data = cfg_key_o[95:64];

            ADDR_KEY2:
                read_data = cfg_key_o[63:32];

            ADDR_KEY3:
                read_data = cfg_key_o[31:0];

            ADDR_IV0:
                read_data = cfg_iv_o[127:96];

            ADDR_IV1:
                read_data = cfg_iv_o[95:64];

            ADDR_IV2:
                read_data = cfg_iv_o[63:32];

            ADDR_IV3:
                read_data = cfg_iv_o[31:0];

            ADDR_COUNTER_HI:
                read_data = cfg_counter_o[63:32];

            ADDR_COUNTER_LO:
                read_data = cfg_counter_o[31:0];

            ADDR_NUM_BLOCKS:
                read_data = {
                    23'b0,
                    cfg_num_blocks_o
                };

            ADDR_AES_CONTROL:
                read_data = {
                    27'b0,
                    cfg_mode_o,
                    cfg_decrypt_o,
                    1'b0
                };

            ADDR_AES_STATUS:
                read_data = {
                    20'b0,
                    aes_blocks_done_i,
                    aes_error_i,
                    aes_done_i,
                    aes_busy_i
                };

            // Placeholder enquanto VERSION nao possui
            // valor numerico definido na especificacao.
            ADDR_VERSION:
                read_data = 32'b0;

            ADDR_SYSTEM_CONTROL:
                read_data = {
                    28'b0,
                    pll_div_sel_o,
                    pll_enable_o,
                    mem_sel_aes_o
                };

            ADDR_SYSTEM_STATUS:
                read_data = {
                    31'b0,
                    pll_locked_i
                };

            default:
                read_data = 32'b0;

        endcase
    end


    // ============================================================
    // Captura serial MOSI
    // ============================================================

    always_ff @(posedge spi_sclk_i or
                posedge spi_cs_n_i or
                negedge rst_n_i) begin

        if (!rst_n_i) begin
            spi_rx_shift_q <= 40'b0;
            bit_count_q    <= 6'd0;
        end
        else if (spi_cs_n_i) begin
            spi_rx_shift_q <= 40'b0;
            bit_count_q    <= 6'd0;
        end
        else begin

            spi_rx_shift_q <= {
                spi_rx_shift_q[38:0],
                spi_mosi_i
            };

            if (bit_count_q == 6'd39) begin
                bit_count_q <= 6'd0;
            end
            else begin
                bit_count_q <= bit_count_q + 6'd1;
            end
        end
    end


    // ============================================================
    // Frame completo
    // ============================================================

    always_ff @(posedge spi_sclk_i or negedge rst_n_i) begin

        if (!rst_n_i) begin
            frame_hold_q   <= 40'b0;
            frame_toggle_q <= 1'b0;
        end
        else if (!spi_cs_n_i && (bit_count_q == 6'd39)) begin

            frame_hold_q <= {
                spi_rx_shift_q[38:0],
                spi_mosi_i
            };

            frame_toggle_q <= ~frame_toggle_q;
        end
    end


    // ============================================================
    // Sincronizador SPI -> clk_i
    // ============================================================

    always_ff @(posedge clk_i or negedge rst_n_i) begin

        if (!rst_n_i) begin
            frame_toggle_meta_q   <= 1'b0;
            frame_toggle_sync_q   <= 1'b0;
            frame_toggle_sync_d_q <= 1'b0;
        end
        else begin
            frame_toggle_meta_q   <= frame_toggle_q;
            frame_toggle_sync_q   <= frame_toggle_meta_q;
            frame_toggle_sync_d_q <= frame_toggle_sync_q;
        end
    end

    assign frame_valid_clk =
        frame_toggle_sync_q ^ frame_toggle_sync_d_q;


    // ============================================================
    // Captura do frame em clk_i
    // ============================================================

    always_ff @(posedge clk_i or negedge rst_n_i) begin

        if (!rst_n_i) begin
            frame_clk_q   <= 40'b0;
            frame_ready_q <= 1'b0;
        end
        else begin

            frame_ready_q <= frame_valid_clk;

            if (frame_valid_clk) begin
                frame_clk_q <= frame_hold_q;
            end
        end
    end


    // ============================================================
    // Banco de registradores
    // ============================================================

    always_ff @(posedge clk_i or negedge rst_n_i) begin

        if (!rst_n_i) begin

            cfg_key_o        <= 128'b0;
            cfg_iv_o         <= 128'b0;
            cfg_counter_o    <= 64'b0;
            cfg_num_blocks_o <= 9'b0;

            cfg_mode_o       <= 3'b000;
            cfg_decrypt_o    <= 1'b0;
            aes_start_o      <= 1'b0;

            mem_sel_aes_o    <= 1'b0;
            pll_enable_o     <= 1'b0;
            pll_div_sel_o    <= 2'b00;
        end
        else begin

            // START = write-one-pulse.
            aes_start_o <= 1'b0;

            if (frame_ready_q &&
                !frame_rwb &&
                !frame_rsv) begin

                case (frame_addr)

                    ADDR_KEY0:
                        cfg_key_o[127:96] <= frame_data;

                    ADDR_KEY1:
                        cfg_key_o[95:64] <= frame_data;

                    ADDR_KEY2:
                        cfg_key_o[63:32] <= frame_data;

                    ADDR_KEY3:
                        cfg_key_o[31:0] <= frame_data;


                    ADDR_IV0:
                        cfg_iv_o[127:96] <= frame_data;

                    ADDR_IV1:
                        cfg_iv_o[95:64] <= frame_data;

                    ADDR_IV2:
                        cfg_iv_o[63:32] <= frame_data;

                    ADDR_IV3:
                        cfg_iv_o[31:0] <= frame_data;


                    ADDR_COUNTER_HI:
                        cfg_counter_o[63:32] <= frame_data;

                    ADDR_COUNTER_LO:
                        cfg_counter_o[31:0] <= frame_data;


                    ADDR_NUM_BLOCKS:
                        cfg_num_blocks_o <= frame_data[8:0];


                    ADDR_AES_CONTROL: begin

                        cfg_mode_o    <= frame_data[4:2];
                        cfg_decrypt_o <= frame_data[1];

                        if (frame_data[0]) begin
                            aes_start_o <= 1'b1;
                        end
                    end


                    ADDR_SYSTEM_CONTROL: begin

                        mem_sel_aes_o <= frame_data[0];
                        pll_enable_o  <= frame_data[1];
                        pll_div_sel_o <= frame_data[3:2];
                    end


                    ADDR_AES_STATUS,
                    ADDR_VERSION,
                    ADDR_SYSTEM_STATUS,
                    ADDR_NOP: begin
                        // Registradores somente leitura / NOP.
                    end


                    default: begin
                    end

                endcase
            end
        end
    end


    // ============================================================
    // Preparacao da resposta de leitura - dominio clk_i
    // ============================================================

    logic [31:0] read_response_q;
    logic        read_response_toggle_q;

    always_ff @(posedge clk_i or negedge rst_n_i) begin

        if (!rst_n_i) begin
            read_response_q        <= 32'b0;
            read_response_toggle_q <= 1'b0;
        end
        else if (frame_ready_q &&
                 frame_rwb &&
                 !frame_rsv) begin

            // Guarda o valor solicitado.
            read_response_q <= read_data;

            // Avisa o dominio SPI que existe nova resposta.
            read_response_toggle_q <=
                ~read_response_toggle_q;
        end
    end


    // ============================================================
    // CDC da resposta: clk_i -> spi_sclk_i
    // ============================================================

    logic read_response_toggle_meta_q;
    logic read_response_toggle_sync_q;
    logic read_response_toggle_sync_d_q;

    logic [31:0] read_response_spi_q;
    logic        read_response_pending_q;


    always_ff @(posedge spi_sclk_i or negedge rst_n_i) begin

        if (!rst_n_i) begin

            read_response_toggle_meta_q   <= 1'b0;
            read_response_toggle_sync_q   <= 1'b0;
            read_response_toggle_sync_d_q <= 1'b0;

            read_response_spi_q     <= 32'b0;
            read_response_pending_q <= 1'b0;
        end
        else begin

            read_response_toggle_meta_q <=
                read_response_toggle_q;

            read_response_toggle_sync_q <=
                read_response_toggle_meta_q;

            read_response_toggle_sync_d_q <=
                read_response_toggle_sync_q;


            // Nova resposta atravessou o CDC.
            if (read_response_toggle_sync_q ^
                read_response_toggle_sync_d_q) begin

                read_response_spi_q <= read_response_q;
                read_response_pending_q <= 1'b1;
            end

            // Final da transacao NOP utilizada para retorno.
            else if (!spi_cs_n_i &&
                     (bit_count_q == 6'd39) &&
                     (spi_rx_shift_q[37:32] == ADDR_NOP) &&
                     (spi_rx_shift_q[31] == 1'b0)) begin

                read_response_pending_q <= 1'b0;
            end
        end
    end


    // ============================================================
    // Transmissao MISO
    // ============================================================

    logic nop_return_q;

    // SPI Mode 0:
    // MISO e atualizado na borda de descida.
    always_ff @(negedge spi_sclk_i or
                posedge spi_cs_n_i or
                negedge rst_n_i) begin

        if (!rst_n_i) begin
            spi_miso_o  <= 1'b0;
            nop_return_q <= 1'b0;
        end
        else if (spi_cs_n_i) begin
            spi_miso_o   <= 1'b0;
            nop_return_q <= 1'b0;
        end
        else begin

            // Os primeiros 8 bits correspondem ao cabecalho
            // da transacao NOP.
            //
            // Depois do 8o bit recebido, ja sabemos se o
            // endereco da segunda transacao e 0x3F.
            if (bit_count_q == 6'd8) begin

                if ((spi_rx_shift_q[6:1] == ADDR_NOP) &&
                    (spi_rx_shift_q[0] == 1'b0) &&
                    read_response_pending_q) begin

                    nop_return_q <= 1'b1;

                    // Primeiro bit do payload.
                    spi_miso_o <= read_response_spi_q[31];
                end
                else begin
                    nop_return_q <= 1'b0;
                    spi_miso_o   <= 1'b0;
                end
            end

            // DATA[31:0] ocupa os ultimos 32 bits do frame.
            else if (nop_return_q &&
                     (bit_count_q >= 6'd9) &&
                     (bit_count_q <= 6'd39)) begin

                spi_miso_o <=
                    read_response_spi_q[39 - bit_count_q];
            end

            else begin
                spi_miso_o <= 1'b0;
            end
        end
    end

endmodule
