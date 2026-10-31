`timescale 1ns/1ps

module minisoc_aes_shift_rows_tb;

    logic [127:0] state_in;
    logic [127:0] state_out;

    integer errors;

    minisoc_aes_shift_rows dut (
        .state_in  (state_in),
        .state_out (state_out)
    );

    task automatic check_shiftrows (
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
                $display("PASS - ShiftRows Round %0d", round_num);
            end
        end
    endtask

    initial begin

        errors = 0;

        $display("-----------------------------------");
        $display("Teste AES ShiftRows");
        $display("-----------------------------------");

        // FIPS-197 - Appendix B - Round 1
        check_shiftrows(
            128'hd42711aee0bf98f1b8b45de51e415230,
            128'hd4bf5d30e0b452aeb84111f11e2798e5,
            1
        );

        // FIPS-197 - Appendix B - Round 10
        check_shiftrows(
            128'he9098972cb31075f3d327d94af2e2cb5,
            128'he9317db5cb322c723d2e895faf090794,
            10
        );

        if (errors == 0) begin
            $display("-----------------------------------");
            $display("PASS: todos os testes ShiftRows passaram.");
            $display("-----------------------------------");
        end
        else begin
            $display("-----------------------------------");
            $display("FAIL: %0d erro(s) em ShiftRows.", errors);
            $display("-----------------------------------");
        end

        $finish;
    end

endmodule
