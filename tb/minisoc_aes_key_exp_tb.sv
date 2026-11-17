`timescale 1ns/1ps

module minisoc_aes_key_exp_tb;

    logic [127:0] key_i;
    logic [127:0] round_keys_o [0:10];

    minisoc_aes_key_exp dut (
        .key_i        (key_i),
        .round_keys_o (round_keys_o)
    );

    task automatic check_key (
        input integer index,
        input logic [127:0] expected
    );
        begin
            if (round_keys_o[index] !== expected) begin
                $display("FAIL - Round Key %0d", index);
                $display("Esperado: %h", expected);
                $display("Obtido:   %h", round_keys_o[index]);
                $fatal(1);
            end
            else begin
                $display(
                    "PASS - Round Key %0d = %h",
                    index,
                    round_keys_o[index]
                );
            end
        end
    endtask

    initial begin

        // FIPS-197 - Appendix A.1
        key_i = 128'h2b7e151628aed2a6abf7158809cf4f3c;

        #1;

        check_key(
            0,
            128'h2b7e151628aed2a6abf7158809cf4f3c
        );

        check_key(
            1,
            128'ha0fafe1788542cb123a339392a6c7605
        );

        check_key(
            2,
            128'hf2c295f27a96b9435935807a7359f67f
        );

        check_key(
            3,
            128'h3d80477d4716fe3e1e237e446d7a883b
        );

        check_key(
            4,
            128'hef44a541a8525b7fb671253bdb0bad00
        );

        check_key(
            5,
            128'hd4d1c6f87c839d87caf2b8bc11f915bc
        );

        check_key(
            6,
            128'h6d88a37a110b3efddbf98641ca0093fd
        );

        check_key(
            7,
            128'h4e54f70e5f5fc9f384a64fb24ea6dc4f
        );

        check_key(
            8,
            128'head27321b58dbad2312bf5607f8d292f
        );

        check_key(
            9,
            128'hac7766f319fadc2128d12941575c006e
        );

        check_key(
            10,
            128'hd014f9a8c9ee2589e13f0cc8b6630ca6
        );

        $display("==========================================");
        $display("PASS: todas as 11 round keys estao corretas.");
        $display("==========================================");

        $finish;

    end

endmodule
