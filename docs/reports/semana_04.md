# Semana 4 — Expansão de chave e datapath AES-128

## 1. Objetivo

O objetivo da Semana 4 foi implementar a expansão de chave do AES-128 e integrar o datapath completo para realizar cifragem e decriptação de blocos de 128 bits.

As principais atividades realizadas foram:

- implementação do `minisoc_aes_key_exp`;
- geração das 11 round keys do AES-128;
- validação das round keys com valores da FIPS-197;
- implementação do `minisoc_aes_dp`;
- integração das transformações diretas e inversas desenvolvidas anteriormente;
- implementação do controle iterativo das dez rodadas;
- validação completa da cifragem;
- validação completa da decriptação;
- criação do alvo `make week4` para regressão automatizada.

---

## 2. Expansão de chave AES-128

Foi implementado o módulo:

```text
rtl/minisoc_aes/minisoc_aes_key_exp.sv
```

O módulo recebe uma chave AES-128 de 128 bits e produz as 11 round keys utilizadas pelo algoritmo:

```text
round_key_0
round_key_1
...
round_key_10
```

A chave inicial corresponde à `round_key_0`.

A expansão é realizada utilizando as operações definidas pelo AES:

- `RotWord`;
- `SubWord`;
- `Rcon`;
- operações XOR entre as palavras de 32 bits.

A chave de 128 bits é inicialmente dividida em quatro palavras:

```text
w0
w1
w2
w3
```

e a expansão produz as palavras até `w43`.

Cada conjunto de quatro palavras forma uma round key de 128 bits.

### 2.1 Estratégia adotada

Foi escolhida a estratégia de **pré-computação das 11 round keys**.

Essa escolha simplifica principalmente a decriptação, pois as chaves precisam ser utilizadas em ordem inversa:

```text
Cifragem:
key_0 → key_1 → ... → key_10

Decriptação:
key_10 → key_9 → ... → key_0
```

A principal desvantagem é o aumento da lógica combinacional e da quantidade de sinais associados às chaves expandidas.

A avaliação definitiva de impacto em área ainda depende da etapa futura de síntese.

---

## 3. Validação do Key Expansion

Foi criado o testbench:

```text
tb/minisoc_aes_key_exp_tb.sv
```

Foi utilizada a chave do Apêndice A.1 da FIPS-197:

```text
2b7e151628aed2a6abf7158809cf4f3c
```

Todas as 11 round keys foram comparadas individualmente com os valores de referência.

O resultado obtido foi:

```text
PASS - Round Key 0
PASS - Round Key 1
PASS - Round Key 2
PASS - Round Key 3
PASS - Round Key 4
PASS - Round Key 5
PASS - Round Key 6
PASS - Round Key 7
PASS - Round Key 8
PASS - Round Key 9
PASS - Round Key 10

PASS: todas as 11 round keys estao corretas.
```

---

## 4. Datapath AES-128

Foi implementado o módulo:

```text
rtl/minisoc_aes/minisoc_aes_dp.sv
```

Foi utilizada uma arquitetura iterativa, na qual o mesmo hardware é reutilizado ao longo das dez rodadas do AES.

Os principais elementos internos são:

- registrador de estado de 128 bits;
- contador de rodadas;
- Key Expansion;
- caminho de cifragem;
- caminho de decriptação;
- bloco `AddRoundKey` compartilhado;
- máquina de estados para controle da operação.

A máquina de estados utiliza:

```text
IDLE
INIT
ROUND
FINAL
```

---

## 5. Cifragem

Na cifragem, a rodada inicial executa:

```text
plaintext
    ↓
AddRoundKey(key_0)
```

As rodadas 1 a 9 executam:

```text
SubBytes
    ↓
ShiftRows
    ↓
MixColumns
    ↓
AddRoundKey
```

A rodada 10 executa:

```text
SubBytes
    ↓
ShiftRows
    ↓
AddRoundKey
```

O `MixColumns` é desviado na rodada final, conforme definido pelo AES.

A seleção das chaves segue:

```text
round_count = 0  → key_0
round_count = 1  → key_1
...
round_count = 10 → key_10
```

---

## 6. Decriptação

Na decriptação, a operação inicial é:

```text
ciphertext
    ↓
AddRoundKey(key_10)
```

As rodadas intermediárias executam:

```text
InvShiftRows
    ↓
InvSubBytes
    ↓
AddRoundKey
    ↓
InvMixColumns
```

A rodada final executa:

```text
InvShiftRows
    ↓
InvSubBytes
    ↓
AddRoundKey(key_0)
```

A seleção das chaves ocorre em ordem inversa:

```text
round_count = 0  → key_10
round_count = 1  → key_9
...
round_count = 10 → key_0
```

O sinal `decrypt_i` seleciona o modo de operação e é armazenado internamente no início da operação.

---

## 7. Validação da cifragem

Foi criado o testbench:

```text
tb/minisoc_aes_dp_encrypt_tb.sv
```

Foram utilizados dois vetores da FIPS-197.

### 7.1 Apêndice C.1

```text
Key:
000102030405060708090a0b0c0d0e0f

Plaintext:
00112233445566778899aabbccddeeff

Ciphertext esperado:
69c4e0d86a7b0430d8cdb78070b4c55a
```

Resultado:

```text
Obtido:
69c4e0d86a7b0430d8cdb78070b4c55a

PASS - FIPS-197 Appendix C.1
```

### 7.2 Apêndice B

```text
Key:
2b7e151628aed2a6abf7158809cf4f3c

Plaintext:
3243f6a8885a308d313198a2e0370734

Ciphertext esperado:
3925841d02dc09fbdc118597196a0b32
```

Resultado:

```text
Obtido:
3925841d02dc09fbdc118597196a0b32

PASS - FIPS-197 Appendix B
```

---

## 8. Validação da decriptação

Foi criado o testbench:

```text
tb/minisoc_aes_dp_decrypt_tb.sv
```

Os mesmos vetores foram aplicados no sentido inverso.

### 8.1 Apêndice C.1

```text
Ciphertext:
69c4e0d86a7b0430d8cdb78070b4c55a

Plaintext esperado:
00112233445566778899aabbccddeeff
```

Resultado:

```text
Obtido:
00112233445566778899aabbccddeeff

PASS - FIPS-197 Appendix C.1
```

### 8.2 Apêndice B

```text
Ciphertext:
3925841d02dc09fbdc118597196a0b32

Plaintext esperado:
3243f6a8885a308d313198a2e0370734
```

Resultado:

```text
Obtido:
3243f6a8885a308d313198a2e0370734

PASS - FIPS-197 Appendix B
```

---

## 9. Regressão automatizada

O `Makefile` foi atualizado com o alvo:

```bash
make week4
```

A regressão executa:

1. lint do RTL utilizado pelo datapath;
2. teste das 11 round keys;
3. teste completo de cifragem;
4. teste completo de decriptação.

A execução final apresentou:

```text
PASS: decriptacao AES-128 validada.

PASS: regressao RTL da Semana 4 concluida.
```

---

## 10. Estado atual

Ao final da Semana 4 estão implementados e funcionalmente verificados:

- S-box e InvS-box;
- SubBytes e InvSubBytes;
- ShiftRows e InvShiftRows;
- MixColumns e InvMixColumns;
- AddRoundKey;
- expansão da chave AES-128;
- geração das 11 round keys;
- datapath iterativo AES-128;
- cifragem completa;
- decriptação completa;
- FSM de controle das rodadas;
- regressão automatizada da Semana 4.

A cifragem e a decriptação foram verificadas utilizando vetores oficiais da FIPS-197.


