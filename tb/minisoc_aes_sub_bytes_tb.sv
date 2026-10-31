`timescale 1ns/1ps

module minisoc_aes_sub_bytes_tb;

    logic [127:0] state_in;
    logic [127:0] state_out;

    integer errors;

    minisoc_aes_sub_bytes dut (
        .state_in  (state_in),
        .state_out (state_out)
    );

    task automatic check_subbytes (
        input logic [127:0] input_state,
        input logic [127:0] expected_state,
        input integer round_num
    );
        begin
            state_in = input_state;
            #1;

            if (state_out !== expected_state) begin
                $display("FAIL - Round %0d", round_num);
                $display("Entrada : %032h", state_in);
                $display("Esperado: %032h", expected_state);
                $display("Obtido  : %032h", state_out);
                errors = errors + 1;
            end
            else begin
                $display("PASS - SubBytes Round %0d", round_num);
            end
        end
    endtask

    initial begin

        errors = 0;

        $display("-----------------------------------");
        $display("Teste AES SubBytes");
        $display("-----------------------------------");

        // FIPS-197 - Appendix B - Round 1
        check_subbytes(
            128'h193de3bea0f4e22b9ac68d2ae9f84808,
            128'hd42711aee0bf98f1b8b45de51e415230,
            1
        );

        // FIPS-197 - Appendix B - Round 10
        check_subbytes(
            128'heb40f21e592e38848ba113e71bc342d2,
            128'he9098972cb31075f3d327d94af2e2cb5,
            10
        );

        if (errors == 0) begin
            $display("-----------------------------------");
            $display("PASS: todos os testes SubBytes passaram.");
            $display("-----------------------------------");
        end
        else begin
            $display("-----------------------------------");
            $display("FAIL: %0d erro(s) em SubBytes.", errors);
            $display("-----------------------------------");
        end

        $finish;
    end

endmodule
