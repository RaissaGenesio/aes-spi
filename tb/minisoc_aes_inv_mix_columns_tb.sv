`timescale 1ns/1ps

module minisoc_aes_inv_mix_columns_tb;

    logic [127:0] state_in;
    logic [127:0] state_out;
    logic [127:0] expected_state;

    minisoc_aes_inv_mix_columns dut (
        .state_in  (state_in),
        .state_out (state_out)
    );

    initial begin

        // FIPS-197 - Appendix C.1
        // Equivalent Inverse Cipher - Round 1
        state_in =
            128'hbd6e7c3df2b5779e0b61216e8b10b689;

        expected_state =
            128'h4773b91ff72f354361cb018ea1e6cf2c;

        #1;

        if (state_out !== expected_state) begin
            $display("FAIL - InvMixColumns Round 1");
            $display("Esperado: %h", expected_state);
            $display("Obtido:   %h", state_out);
            $fatal(1);
        end
        else begin
            $display("PASS - InvMixColumns Round 1");
        end

        $display("PASS: todos os testes InvMixColumns passaram.");
        $finish;

    end

endmodule
