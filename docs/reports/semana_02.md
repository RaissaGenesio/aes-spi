# Relatório — Semana 2

## Objetivo

Implementar e validar os blocos combinacionais `minisoc_aes_sbox`, `minisoc_aes_sub_bytes` e `minisoc_aes_shift_rows`, seguindo as convenções definidas pelo Block Guide do MiniSoC AES v1.0.0.

## Implementação

Foram desenvolvidos três blocos do datapath AES:

- `minisoc_aes_sbox`: implementação combinacional da S-box AES com as 256 entradas definidas pela FIPS-197;
- `minisoc_aes_sub_bytes`: aplicação da S-box aos 16 bytes do estado AES de 128 bits;
- `minisoc_aes_shift_rows`: reordenação combinacional dos bytes conforme a transformação ShiftRows.

Foi adotada a convenção definida pelo Block Guide, em que o byte 0 do estado ocupa os bits `[127:120]` e o byte 15 ocupa `[7:0]`.

## Verificação

Foram criados testbenches autoverificáveis para os três módulos.

### S-box

A S-box foi testada para todas as 256 possíveis entradas de 8 bits.

Resultado:

PASS: todas as 256 entradas da S-box estao corretas.

### SubBytes

O módulo SubBytes foi validado utilizando os estados intermediários da FIPS-197 para as rodadas 1 e 10.

Resultados:

PASS - SubBytes Round 1
PASS - SubBytes Round 10
PASS: todos os testes SubBytes passaram.


### ShiftRows
O módulo ShiftRows também foi validado utilizando os estados intermediários das rodadas 1 e 10 da FIPS-197.

Resultados:

PASS - ShiftRows Round 1
PASS - ShiftRows Round 10
PASS: todos os testes ShiftRows passaram.

### Lint e fluxo de execução
O lint foi executado com o VCS utilizando +lint=all, sem erros.

O Makefile foi atualizado para permitir a execução completa dos testes da Semana 2 através de um único comando:
`make week2`

Esse comando executa:

1. lint dos três módulos;
2. teste das 256 entradas da S-box;
3. teste do SubBytes;
4. teste do ShiftRows.
Ao final da execução foi obtido:
PASS: Semana 2 concluida com sucesso.
