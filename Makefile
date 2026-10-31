VCS = vcs -full64 -sverilog

SBOX       = rtl/minisoc_aes/minisoc_aes_sbox.sv
SUBBYTES   = rtl/minisoc_aes/minisoc_aes_sub_bytes.sv
SHIFTROWS  = rtl/minisoc_aes/minisoc_aes_shift_rows.sv

SBOX_TB      = tb/minisoc_aes_sbox_tb.sv
SUBBYTES_TB  = tb/minisoc_aes_sub_bytes_tb.sv
SHIFTROWS_TB = tb/minisoc_aes_shift_rows_tb.sv

.PHONY: all week2 lint sbox_test subbytes_test shiftrows_test week1 clean

all: week2

week2: lint sbox_test subbytes_test shiftrows_test
	@echo "===================================="
	@echo "PASS: Semana 2 concluida com sucesso."
	@echo "===================================="

lint:
	$(VCS) +lint=all $(SBOX) $(SUBBYTES) $(SHIFTROWS) -o simv_week2_lint

sbox_test:
	$(VCS) $(SBOX) $(SBOX_TB) -o simv_sbox_tb
	./simv_sbox_tb

subbytes_test:
	$(VCS) $(SBOX) $(SUBBYTES) $(SUBBYTES_TB) -o simv_subbytes_tb
	./simv_subbytes_tb

shiftrows_test:
	$(VCS) $(SHIFTROWS) $(SHIFTROWS_TB) -o simv_shiftrows_tb
	./simv_shiftrows_tb

week1:
	$(VCS) rtl/porta_and.sv tb/porta_and_tb.sv -o simv
	./simv

clean:
	rm -rf simv simv.daidir \
	simv_sbox_tb simv_sbox_tb.daidir \
	simv_subbytes_tb simv_subbytes_tb.daidir \
	simv_shiftrows_tb simv_shiftrows_tb.daidir \
	simv_week2_lint simv_week2_lint.daidir \
	csrc ucli.key spyglass.out *.log
