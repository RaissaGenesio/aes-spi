`timescale 1ns/1ps

module minisoc_aes_inv_sub_bytes_tb;

    logic [127:0] state_in;
    logic [127:0] state_out;
    logic [127:0] expected_state;

    minisoc_aes_inv_sub_bytes dut (
        .state_in  (state_in),
        .state_out (state_out)
    );

    initial begin

        // FIPS-197 - Appendix C.1 - Inverse Cipher - Round 1
        state_in =
            128'h7a9f102789d5f50b2beffd9f3dca4ea7;

        expected_state =
            128'hbd6e7c3df2b5779e0b61216e8b10b689;

        #1;

        if (state_out !== expected_state) begin
            $display("FAIL - InvSubBytes Round 1");
            $display("Esperado: %h", expected_state);
            $display("Obtido:   %h", state_out);
            $fatal(1);
        end
        else begin
            $display("PASS - InvSubBytes Round 1");
        end

        $display("PASS: todos os testes InvSubBytes passaram.");
        $finish;

    end

endmodule
