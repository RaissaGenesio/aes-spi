`timescale 1ns/1ps

module minisoc_spi_tb;

    logic         clk_i;
    logic         rst_n_i;

    logic         spi_sclk_i;
    logic         spi_cs_n_i;
    logic         spi_mosi_i;
    logic         spi_miso_o;

    logic [127:0] cfg_key_o;
    logic [127:0] cfg_iv_o;
    logic [63:0]  cfg_counter_o;
    logic [8:0]   cfg_num_blocks_o;
    logic [2:0]   cfg_mode_o;
    logic         cfg_decrypt_o;
    logic         aes_start_o;

    logic         aes_busy_i;
    logic         aes_done_i;
    logic         aes_error_i;
    logic [8:0]   aes_blocks_done_i;

    logic         mem_sel_aes_o;
    logic         pll_enable_o;
    logic [1:0]   pll_div_sel_o;

    logic         pll_locked_i;

    logic         start_seen;

    localparam logic [5:0] ADDR_KEY0           = 6'h00;
    localparam logic [5:0] ADDR_NUM_BLOCKS     = 6'h0A;
    localparam logic [5:0] ADDR_AES_CONTROL    = 6'h0B;
    localparam logic [5:0] ADDR_AES_STATUS     = 6'h0C;
    localparam logic [5:0] ADDR_SYSTEM_CONTROL = 6'h0E;
    localparam logic [5:0] ADDR_SYSTEM_STATUS  = 6'h0F;
    localparam logic [5:0] ADDR_NOP            = 6'h3F;


    // ============================================================
    // DUT
    // ============================================================

    minisoc_spi dut (
        .clk_i               (clk_i),
        .rst_n_i             (rst_n_i),

        .spi_sclk_i          (spi_sclk_i),
        .spi_cs_n_i          (spi_cs_n_i),
        .spi_mosi_i          (spi_mosi_i),
        .spi_miso_o          (spi_miso_o),

        .cfg_key_o           (cfg_key_o),
        .cfg_iv_o            (cfg_iv_o),
        .cfg_counter_o       (cfg_counter_o),
        .cfg_num_blocks_o    (cfg_num_blocks_o),
        .cfg_mode_o          (cfg_mode_o),
        .cfg_decrypt_o       (cfg_decrypt_o),
        .aes_start_o         (aes_start_o),

        .aes_busy_i          (aes_busy_i),
        .aes_done_i          (aes_done_i),
        .aes_error_i         (aes_error_i),
        .aes_blocks_done_i   (aes_blocks_done_i),

        .mem_sel_aes_o       (mem_sel_aes_o),
        .pll_enable_o        (pll_enable_o),
        .pll_div_sel_o       (pll_div_sel_o),

        .pll_locked_i        (pll_locked_i)
    );


    // ============================================================
    // Clock always-on: 2 GHz
    // Periodo = 0.5 ns
    // ============================================================

    initial begin
        clk_i = 1'b0;

        forever begin
            #0.25 clk_i = ~clk_i;
        end
    end


    // ============================================================
    // Monitor do START
    // ============================================================

    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i)
            start_seen <= 1'b0;
        else if (aes_start_o)
            start_seen <= 1'b1;
    end


    // ============================================================
    // Transacao SPI de 40 bits
    // SPI Mode 0 / MSB-first / 25 MHz
    // ============================================================

    task automatic spi_transfer_40 (
        input  logic [39:0] tx_frame,
        output logic [39:0] rx_frame
    );

        integer i;

        begin

            rx_frame = 40'b0;

            spi_sclk_i = 1'b0;
            spi_cs_n_i = 1'b0;

            #20;

            for (i = 39; i >= 0; i = i - 1) begin

                // MOSI fica valido antes da borda de subida.
                spi_mosi_i = tx_frame[i];

                #10;

                // Borda de subida:
                // DUT amostra MOSI e mestre amostra MISO.
                spi_sclk_i = 1'b1;

                #1;
                rx_frame[i] = spi_miso_o;

                #9;

                // Borda de descida:
                // DUT atualiza MISO.
                spi_sclk_i = 1'b0;

                #20;
            end

            spi_cs_n_i = 1'b1;
            spi_mosi_i = 1'b0;

            #100;
        end
    endtask


    // ============================================================
    // Escrita SPI
    // ============================================================

    task automatic spi_write (
        input logic [5:0]  addr,
        input logic [31:0] data
    );

        logic [39:0] tx;
        logic [39:0] rx;

        begin

            tx = {
                1'b0,      // WRITE
                addr,
                1'b0,      // RSV
                data
            };

            spi_transfer_40(tx, rx);

        end
    endtask


    // ============================================================
    // Leitura SPI
    //
    // 1a transacao: READ request
    // 2a transacao: NOP 0x3F
    // ============================================================

    task automatic spi_read (
        input  logic [5:0]  addr,
        output logic [31:0] data
    );

        logic [39:0] tx;
        logic [39:0] rx;

        begin

            // --------------------------------------------
            // Primeira transacao: solicita leitura
            // --------------------------------------------

            tx = {
                1'b1,          // READ
                addr,
                1'b0,          // RSV
                32'b0
            };

            spi_transfer_40(tx, rx);


            // --------------------------------------------
            // Segunda transacao: NOP para retorno
            // --------------------------------------------

            tx = {
                1'b0,
                ADDR_NOP,
                1'b0,
                32'b0
            };

            spi_transfer_40(tx, rx);

            data = rx[31:0];

        end
    endtask


    // ============================================================
    // Testes
    // ============================================================

    logic [31:0] read_value;

    initial begin

        // Valores iniciais
        rst_n_i            = 1'b0;

        spi_sclk_i         = 1'b0;
        spi_cs_n_i         = 1'b1;
        spi_mosi_i         = 1'b0;

        aes_busy_i         = 1'b0;
        aes_done_i         = 1'b0;
        aes_error_i        = 1'b0;
        aes_blocks_done_i  = 9'd0;

        pll_locked_i       = 1'b0;

        #10;

        rst_n_i = 1'b1;

        #20;


        // ========================================================
        // TESTE 1 - Escrita KEY0
        // ========================================================

        $display("");
        $display("TESTE 1 - Escrita KEY0");

        spi_write(
            ADDR_KEY0,
            32'h11223344
        );

        if (cfg_key_o[127:96] !== 32'h11223344) begin
            $fatal(
                1,
                "FAIL KEY0: esperado=11223344 obtido=%08h",
                cfg_key_o[127:96]
            );
        end

        $display(
            "PASS KEY0 = %08h",
            cfg_key_o[127:96]
        );


        // ========================================================
        // TESTE 2 - NUM_BLOCKS = 256
        // ========================================================

        $display("");
        $display("TESTE 2 - NUM_BLOCKS");

        spi_write(
            ADDR_NUM_BLOCKS,
            32'd256
        );

        if (cfg_num_blocks_o !== 9'd256) begin
            $fatal(
                1,
                "FAIL NUM_BLOCKS: esperado=256 obtido=%0d",
                cfg_num_blocks_o
            );
        end

        $display(
            "PASS NUM_BLOCKS = %0d",
            cfg_num_blocks_o
        );


        // ========================================================
        // TESTE 3 - AES_CONTROL
        //
        // MODE    = 3'b001
        // DECRYPT = 1
        // START   = 1
        // ========================================================

        $display("");
        $display("TESTE 3 - AES_CONTROL");


        spi_write(
            ADDR_AES_CONTROL,
            32'h00000007
        );

        if (cfg_mode_o !== 3'b001) begin
            $fatal(
                1,
                "FAIL MODE: esperado=001 obtido=%03b",
                cfg_mode_o
            );
        end

        if (cfg_decrypt_o !== 1'b1) begin
            $fatal(
                1,
                "FAIL DECRYPT"
            );
        end

        if (!start_seen) begin
            $fatal(
                1,
                "FAIL START: pulso nao detectado"
            );
        end

        $display(
            "PASS AES_CONTROL MODE=%03b DECRYPT=%b START detectado",
            cfg_mode_o,
            cfg_decrypt_o
        );


        // ========================================================
        // TESTE 4 - SYSTEM_CONTROL
        //
        // MEM_SEL_AES = 1
        // PLL_ENABLE  = 1
        // PLL_DIV_SEL = 2'b10
        // ========================================================

        $display("");
        $display("TESTE 4 - SYSTEM_CONTROL");

        spi_write(
            ADDR_SYSTEM_CONTROL,
            32'h0000000B
        );

        if (mem_sel_aes_o !== 1'b1 ||
            pll_enable_o  !== 1'b1 ||
            pll_div_sel_o !== 2'b10) begin

            $fatal(
                1,
                "FAIL SYSTEM_CONTROL"
            );
        end

        $display(
            "PASS SYSTEM_CONTROL MEM=%b PLL_EN=%b DIV=%02b",
            mem_sel_aes_o,
            pll_enable_o,
            pll_div_sel_o
        );


        // ========================================================
        // TESTE 5 - Leitura KEY0
        // ========================================================

        $display("");
        $display("TESTE 5 - Leitura KEY0");

        spi_read(
            ADDR_KEY0,
            read_value
        );

        if (read_value !== 32'h11223344) begin
            $fatal(
                1,
                "FAIL READ KEY0: esperado=11223344 obtido=%08h",
                read_value
            );
        end

        $display(
            "PASS READ KEY0 = %08h",
            read_value
        );


        // ========================================================
        // TESTE 6 - AES_STATUS
        // ========================================================

        $display("");
        $display("TESTE 6 - AES_STATUS");

        aes_busy_i        = 1'b1;
        aes_done_i        = 1'b1;
        aes_error_i       = 1'b0;
        aes_blocks_done_i = 9'd5;

        spi_read(
            ADDR_AES_STATUS,
            read_value
        );

        if (read_value[0] !== 1'b1 ||
            read_value[1] !== 1'b1 ||
            read_value[2] !== 1'b0 ||
            read_value[11:3] !== 9'd5) begin

            $fatal(
                1,
                "FAIL AES_STATUS: obtido=%08h",
                read_value
            );
        end

        $display(
            "PASS AES_STATUS = %08h",
            read_value
        );


        // ========================================================
        // TESTE 7 - SYSTEM_STATUS / PLL_LOCKED
        // ========================================================

        $display("");
        $display("TESTE 7 - SYSTEM_STATUS");

        pll_locked_i = 1'b1;

        spi_read(
            ADDR_SYSTEM_STATUS,
            read_value
        );

        if (read_value[0] !== 1'b1) begin
            $fatal(
                1,
                "FAIL PLL_LOCKED"
            );
        end

        $display(
            "PASS SYSTEM_STATUS = %08h",
            read_value
        );


        // ========================================================
        // RESULTADO
        // ========================================================

        $display("");
        $display("========================================");
        $display("PASS: front-end SPI validado.");
        $display("========================================");
        $display("");

        $finish;
    end

endmodule
