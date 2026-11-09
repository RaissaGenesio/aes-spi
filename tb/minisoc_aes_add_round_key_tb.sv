`timescale 1ns/1ps

module minisoc_aes_add_round_key_tb;

    logic [127:0] state_in;
    logic [127:0] round_key;
    logic [127:0] state_out;
    logic [127:0] expected_state;

    minisoc_aes_add_round_key dut (
        .state_in  (state_in),
        .round_key (round_key),
        .state_out (state_out)
    );

    initial begin

        // FIPS-197 - AES-128 - Round 1
        state_in =
            128'h5f72641557f5bc92f7be3b291db9f91a;

        round_key =
            128'hd6aa74fdd2af72fadaa678f1d6ab76fe;

        expected_state =
            128'h89d810e8855ace682d1843d8cb128fe4;

        #1;

        if (state_out !== expected_state) begin
            $display("FAIL - AddRoundKey Round 1");
            $display("Esperado: %h", expected_state);
            $display("Obtido:   %h", state_out);
            $fatal(1);
        end
        else begin
            $display("PASS - AddRoundKey Round 1");
        end

        $display("PASS: todos os testes AddRoundKey passaram.");
        $finish;

    end

endmodule
