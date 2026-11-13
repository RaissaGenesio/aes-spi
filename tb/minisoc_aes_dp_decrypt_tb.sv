`timescale 1ns/1ps

module minisoc_aes_dp_decrypt_tb;

    logic         clk_i;
    logic         rst_n_i;
    logic         start_i;
    logic         decrypt_i;
    logic [127:0] block_i;
    logic [127:0] key_i;

    logic [127:0] block_o;
    logic         busy_o;
    logic         done_o;

    integer cycles;

    // Clock de 100 MHz.
    initial begin
        clk_i = 1'b0;
        forever #5 clk_i = ~clk_i;
    end

    minisoc_aes_dp dut (
        .clk_i     (clk_i),
        .rst_n_i   (rst_n_i),
        .start_i   (start_i),
        .decrypt_i (decrypt_i),
        .block_i   (block_i),
        .key_i     (key_i),
        .block_o   (block_o),
        .busy_o    (busy_o),
        .done_o    (done_o)
    );

    task automatic run_decrypt_test (
        input string        test_name,
        input logic [127:0] key,
        input logic [127:0] ciphertext,
        input logic [127:0] expected_plaintext
    );

        begin

            @(negedge clk_i);

            key_i     = key;
            block_i   = ciphertext;
            decrypt_i = 1'b1;
            start_i   = 1'b1;

            // START por apenas um ciclo.
            @(negedge clk_i);
            start_i = 1'b0;

            cycles = 0;

            while ((done_o !== 1'b1) && (cycles < 20)) begin
                @(posedge clk_i);
                #1;
                cycles = cycles + 1;
            end

            if (done_o !== 1'b1) begin
                $display("FAIL - %s", test_name);
                $display("Timeout esperando done_o.");
                $fatal(1);
            end

            $display("------------------------------------------");
            $display("Teste:      %s", test_name);
            $display("Key:        %h", key);
            $display("Ciphertext: %h", ciphertext);
            $display("Esperado:   %h", expected_plaintext);
            $display("Obtido:     %h", block_o);

            if (block_o !== expected_plaintext) begin
                $display("FAIL - plaintext incorreto.");
                $fatal(1);
            end

            $display("PASS - %s", test_name);
            $display("Ciclos aguardados: %0d", cycles);

            @(negedge clk_i);

        end

    endtask


    initial begin

        rst_n_i   = 1'b0;
        start_i   = 1'b0;
        decrypt_i = 1'b1;
        block_i   = 128'b0;
        key_i     = 128'b0;

        repeat (2)
            @(posedge clk_i);

        @(negedge clk_i);
        rst_n_i = 1'b1;

        // ========================================================
        // FIPS-197 Appendix C.1
        // ========================================================

        run_decrypt_test(
            "FIPS-197 Appendix C.1",
            128'h000102030405060708090a0b0c0d0e0f,
            128'h69c4e0d86a7b0430d8cdb78070b4c55a,
            128'h00112233445566778899aabbccddeeff
        );

        // ========================================================
        // FIPS-197 Appendix B
        // ========================================================

        run_decrypt_test(
            "FIPS-197 Appendix B",
            128'h2b7e151628aed2a6abf7158809cf4f3c,
            128'h3925841d02dc09fbdc118597196a0b32,
            128'h3243f6a8885a308d313198a2e0370734
        );

        $display("==========================================");
        $display("PASS: decriptacao AES-128 validada.");
        $display("==========================================");

        $finish;

    end

endmodule
