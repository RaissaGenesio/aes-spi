`timescale 1ns/1ps

module minisoc_aes_mix_columns_tb;

    logic [127:0] state_in;
    logic [127:0] state_out;
    logic [127:0] expected_state;

    minisoc_aes_mix_columns dut (
        .state_in  (state_in),
        .state_out (state_out)
    );

    initial begin

        // FIPS-197 - Appendix B - Round 1
        state_in = 128'hd4bf5d30e0b452aeb84111f11e2798e5;

        expected_state =
            128'h046681e5e0cb199a48f8d37a2806264c;

        #1;

        if (state_out !== expected_state) begin
            $display("FAIL - MixColumns Round 1");
            $display("Esperado: %h", expected_state);
            $display("Obtido:   %h", state_out);
            $fatal(1);
        end
        else begin
            $display("PASS - MixColumns Round 1");
        end

        $display("PASS: todos os testes MixColumns passaram.");
        $finish;

    end

endmodule
