`timescale 1ns/1ps

module minisoc_aes_inv_shift_rows_tb;

    logic [127:0] state_in;
    logic [127:0] state_out;
    logic [127:0] expected_state;

    minisoc_aes_inv_shift_rows dut (
        .state_in  (state_in),
        .state_out (state_out)
    );

    initial begin

        // FIPS-197 - Appendix C.1 - Inverse Cipher - Round 1
        state_in =
            128'h7ad5fda789ef4e272bca100b3d9ff59f;

        expected_state =
            128'h7a9f102789d5f50b2beffd9f3dca4ea7;

        #1;

        if (state_out !== expected_state) begin
            $display("FAIL - InvShiftRows Round 1");
            $display("Esperado: %h", expected_state);
            $display("Obtido:   %h", state_out);
            $fatal(1);
        end
        else begin
            $display("PASS - InvShiftRows Round 1");
        end

        $display("PASS: todos os testes InvShiftRows passaram.");
        $finish;

    end

endmodule
