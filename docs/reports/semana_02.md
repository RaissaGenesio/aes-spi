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

```text
PASS: todas as 256 entradas da S-box estao corretas.
