VCS = vcs -full64 -sverilog

# ==============================
# RTL - Semana 2
# ==============================

SBOX       = rtl/minisoc_aes/minisoc_aes_sbox.sv
SUBBYTES   = rtl/minisoc_aes/minisoc_aes_sub_bytes.sv
SHIFTROWS  = rtl/minisoc_aes/minisoc_aes_shift_rows.sv

# ==============================
# RTL - Semana 3
# ==============================

MIXCOLUMNS     = rtl/minisoc_aes/minisoc_aes_mix_columns.sv
ADDROUNDKEY    = rtl/minisoc_aes/minisoc_aes_add_round_key.sv
INV_SBOX       = rtl/minisoc_aes/minisoc_aes_inv_sbox.sv
INVSUBBYTES    = rtl/minisoc_aes/minisoc_aes_inv_sub_bytes.sv
INVSHIFTROWS   = rtl/minisoc_aes/minisoc_aes_inv_shift_rows.sv
INVMIXCOLUMNS  = rtl/minisoc_aes/minisoc_aes_inv_mix_columns.sv

# ==============================
# RTL - Semana 4
# ==============================

KEYEXP = rtl/minisoc_aes/minisoc_aes_key_exp.sv
AES_DP = rtl/minisoc_aes/minisoc_aes_dp.sv

# ==============================
# Testbenches - Semana 2
# ==============================

SBOX_TB      = tb/minisoc_aes_sbox_tb.sv
SUBBYTES_TB  = tb/minisoc_aes_sub_bytes_tb.sv
SHIFTROWS_TB = tb/minisoc_aes_shift_rows_tb.sv

# ==============================
# Testbenches - Semana 3
# ==============================

MIXCOLUMNS_TB    = tb/minisoc_aes_mix_columns_tb.sv
ADDROUNDKEY_TB   = tb/minisoc_aes_add_round_key_tb.sv
INVSUBBYTES_TB   = tb/minisoc_aes_inv_sub_bytes_tb.sv
INVSHIFTROWS_TB  = tb/minisoc_aes_inv_shift_rows_tb.sv
INVMIXCOLUMNS_TB = tb/minisoc_aes_inv_mix_columns_tb.sv

# ==============================
# Testbenches - Semana 4
# ==============================

KEYEXP_TB      = tb/minisoc_aes_key_exp_tb.sv
AES_ENCRYPT_TB = tb/minisoc_aes_dp_encrypt_tb.sv
AES_DECRYPT_TB = tb/minisoc_aes_dp_decrypt_tb.sv


.PHONY: all week1 week2 week3 week4 \
        lint_week2 lint_week3 lint_week4 \
        sbox_test subbytes_test shiftrows_test \
        mixcolumns_test addroundkey_test \
        invsubbytes_test invshiftrows_test invmixcolumns_test \
        keyexp_test aes_encrypt_test aes_decrypt_test \
        clean


all: week4


# ==============================
# Semana 2
# ==============================

week2: lint_week2 sbox_test subbytes_test shiftrows_test
	@echo "===================================="
	@echo "PASS: Semana 2 concluida com sucesso."
	@echo "===================================="


lint_week2:
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


# ==============================
# Semana 3
# ==============================

week3: lint_week3 \
       sbox_test subbytes_test shiftrows_test \
       mixcolumns_test addroundkey_test \
       invsubbytes_test invshiftrows_test invmixcolumns_test
	@echo "===================================="
	@echo "PASS: regressao RTL da Semana 3 concluida com sucesso."
	@echo "===================================="


lint_week3:
	$(VCS) +lint=all \
	$(SBOX) \
	$(SUBBYTES) \
	$(SHIFTROWS) \
	$(MIXCOLUMNS) \
	$(ADDROUNDKEY) \
	$(INV_SBOX) \
	$(INVSUBBYTES) \
	$(INVSHIFTROWS) \
	$(INVMIXCOLUMNS) \
	-o simv_week3_lint


mixcolumns_test:
	$(VCS) $(MIXCOLUMNS) $(MIXCOLUMNS_TB) -o simv_mixcolumns_tb
	./simv_mixcolumns_tb


addroundkey_test:
	$(VCS) $(ADDROUNDKEY) $(ADDROUNDKEY_TB) -o simv_addroundkey_tb
	./simv_addroundkey_tb


invsubbytes_test:
	$(VCS) $(INV_SBOX) $(INVSUBBYTES) $(INVSUBBYTES_TB) -o simv_invsubbytes_tb
	./simv_invsubbytes_tb


invshiftrows_test:
	$(VCS) $(INVSHIFTROWS) $(INVSHIFTROWS_TB) -o simv_invshiftrows_tb
	./simv_invshiftrows_tb


invmixcolumns_test:
	$(VCS) $(INVMIXCOLUMNS) $(INVMIXCOLUMNS_TB) -o simv_invmixcolumns_tb
	./simv_invmixcolumns_tb


# ==============================
# Semana 4
# ==============================

week4: lint_week4 \
       keyexp_test \
       aes_encrypt_test \
       aes_decrypt_test
	@echo "=============================================="
	@echo "PASS: regressao RTL da Semana 4 concluida."
	@echo "=============================================="


lint_week4:
	$(VCS) +lint=all \
	$(SBOX) \
	$(INV_SBOX) \
	$(SUBBYTES) \
	$(SHIFTROWS) \
	$(MIXCOLUMNS) \
	$(INVSUBBYTES) \
	$(INVSHIFTROWS) \
	$(INVMIXCOLUMNS) \
	$(ADDROUNDKEY) \
	$(KEYEXP) \
	$(AES_DP) \
	-o simv_week4_lint


keyexp_test:
	$(VCS) \
	$(SBOX) \
	$(KEYEXP) \
	$(KEYEXP_TB) \
	-o simv_keyexp_tb
	./simv_keyexp_tb


aes_encrypt_test:
	$(VCS) \
	$(SBOX) \
	$(INV_SBOX) \
	$(SUBBYTES) \
	$(SHIFTROWS) \
	$(MIXCOLUMNS) \
	$(INVSUBBYTES) \
	$(INVSHIFTROWS) \
	$(INVMIXCOLUMNS) \
	$(ADDROUNDKEY) \
	$(KEYEXP) \
	$(AES_DP) \
	$(AES_ENCRYPT_TB) \
	-o simv_dp_encrypt
	./simv_dp_encrypt


aes_decrypt_test:
	$(VCS) \
	$(SBOX) \
	$(INV_SBOX) \
	$(SUBBYTES) \
	$(SHIFTROWS) \
	$(MIXCOLUMNS) \
	$(INVSUBBYTES) \
	$(INVSHIFTROWS) \
	$(INVMIXCOLUMNS) \
	$(ADDROUNDKEY) \
	$(KEYEXP) \
	$(AES_DP) \
	$(AES_DECRYPT_TB) \
	-o simv_dp_decrypt
	./simv_dp_decrypt


# ==============================
# Semana 1
# ==============================

week1:
	$(VCS) rtl/porta_and.sv tb/porta_and_tb.sv -o simv
	./simv


# ==============================
# Limpeza
# ==============================

clean:
	rm -rf simv simv.daidir \
	       simv_sbox_tb simv_sbox_tb.daidir \
	       simv_subbytes_tb simv_subbytes_tb.daidir \
	       simv_shiftrows_tb simv_shiftrows_tb.daidir \
	       simv_mixcolumns_tb simv_mixcolumns_tb.daidir \
	       simv_addroundkey_tb simv_addroundkey_tb.daidir \
	       simv_invsubbytes_tb simv_invsubbytes_tb.daidir \
	       simv_invshiftrows_tb simv_invshiftrows_tb.daidir \
	       simv_invmixcolumns_tb simv_invmixcolumns_tb.daidir \
	       simv_keyexp_tb simv_keyexp_tb.daidir \
	       simv_dp_encrypt simv_dp_encrypt.daidir \
	       simv_dp_decrypt simv_dp_decrypt.daidir \
	       simv_week2_lint simv_week2_lint.daidir \
	       simv_week3_lint simv_week3_lint.daidir \
	       simv_week4_lint simv_week4_lint.daidir \
	       simv_dp_lint simv_dp_lint.daidir \
	       simv_keyexp_lint simv_keyexp_lint.daidir \
	       csrc ucli.key spyglass.out *.log
