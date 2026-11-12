# Semana 3 — Microarquitetura e Transformações de Rodada

## 1.Objetivos

- Implementar as transformações restantes das rodadas de cifragem e decriptação.
- Desenvolver os blocos `MixColumns`, `AddRoundKey`, `InvSubBytes`, `InvShiftRows` e `InvMixColumns`.
- Criar testbenches unitários baseados nos valores intermediários da FIPS-197.
- Definir a microarquitetura interna do núcleo AES.
- Definir uma arquitetura iterativa, reutilizando os mesmos blocos combinacionais ao longo das rodadas e utilizando uma máquina de estados para controlar a execução.

## 2.Implementação das transformações

Nesta semana foram adicionados os seguintes módulos RTL:

- `minisoc_aes_mix_columns.sv`
- `minisoc_aes_add_round_key.sv`
- `minisoc_aes_inv_sbox.sv`
- `minisoc_aes_inv_sub_bytes.sv`
- `minisoc_aes_inv_shift_rows.sv`
- `minisoc_aes_inv_mix_columns.sv`

### MixColumns

O bloco `MixColumns` foi implementado de forma combinacional, operando separadamente sobre cada uma das quatro colunas do estado AES.

As multiplicações no campo finito GF(2⁸) foram implementadas por funções auxiliares, utilizando as multiplicações por 2 e 3 previstas no AES.

### AddRoundKey

O bloco `AddRoundKey` realiza a operação XOR entre o estado atual e a chave da rodada:

```text
state_out = state_in XOR round_key
```

- O módulo é combinacional e será compartilhado pelas etapas de cifragem e decriptação.
- A geração das chaves de rodada não faz parte desta etapa e será tratada posteriormente no **Key Schedule**.

### Transformações inversas

Para possibilitar a decriptação foram implementadas:

- `InvSubBytes`
- `InvShiftRows`
- `InvMixColumns`

A `InvSBox` foi obtida a partir da correspondência inversa da S-box direta, evitando a transcrição manual das 256 entradas.

O `InvMixColumns` utiliza as multiplicações por 9, 11, 13 e 14 no campo GF(2⁸), conforme definido pelo AES.

## 3.Microarquitetura proposta

Foi adotada uma arquitetura iterativa, na qual um único conjunto de blocos é reutilizado durante as rodadas.

O estado atual é armazenado em um registrador de 128 bits denominado `State Register`.

### Caminho de cifragem

As rodadas intermediárias executam:

```text
State Register
    ↓
SubBytes
    ↓
ShiftRows
    ↓
MixColumns
    ↓
AddRoundKey
    ↓
State Register
```

Na rodada final, `MixColumns` deve ser ignorado. Para isso foi introduzido um multiplexador controlado pelo sinal `final_round`:

```text
final_round = 0 → utiliza MixColumns
final_round = 1 → utiliza diretamente ShiftRows
```

A etapa inicial também possui tratamento específico, pois o AES começa com uma operação `AddRoundKey` antes da primeira rodada.

O sinal `init_round`, gerado quando `round_count == 0`, faz com que o `input_block` seja enviado diretamente ao `AddRoundKey`.

## 4.Caminho de decriptação

O datapath foi estendido conceitualmente para permitir cifragem e decriptação utilizando os mesmos registradores, contador e bloco `AddRoundKey`.

O sinal `decrypt` seleciona qual caminho será utilizado:

```text
decrypt = 0 → cifragem
decrypt = 1 → decriptação
```

Nas rodadas intermediárias de decriptação, a sequência definida é:

```text
State Register
    ↓
InvShiftRows
    ↓
InvSubBytes
    ↓
AddRoundKey
    ↓
InvMixColumns
    ↓
State Register
```

Na rodada final da decriptação, `InvMixColumns` também é ignorado. Para isso foi proposta a lógica:

```text
inv_mix_en = decrypt & ~init_round & ~final_round
```

Assim, `InvMixColumns` é utilizado apenas nas rodadas intermediárias da decriptação. O bloco `AddRoundKey` permanece compartilhado entre os dois modos.

### Seleção das chaves de rodada

A seleção das chaves foi definida arquiteturalmente como:

```text
Cifragem:     key_index = round_count
Decriptação:  key_index = 10 - round_count
```

> **Observação:** essa estratégia ainda depende da implementação do Key Schedule, prevista para a próxima etapa do projeto.

## 5.Controle das rodadas

Foi definido um contador de 4 bits, `round_count[3:0]`, que representa as rodadas de 0 a 10.

Os principais sinais de controle são:

- `round_reset`
- `round_inc`
- `state_we`
- `init_round`
- `final_round`
- `done`
- `decrypt`

O sinal `round_reset` limpa o contador de rodadas, enquanto `round_inc` determina quando ele deve ser incrementado.

O sinal `state_we` habilita a escrita do novo valor no `State Register`.

Os sinais derivados do contador são:

```text
round_count == 0  → init_round
round_count == 10 → final_round
```

## 6.Máquina de estados

Foi definida uma FSM com quatro estados principais: `IDLE`, `INIT`, `ROUND` e `FINAL`.

### IDLE

Estado de espera por uma nova operação.

```text
round_reset = 1
round_inc   = 0
state_we    = 0
done        = 0
```

### INIT

Executa o `AddRoundKey` inicial e prepara o contador para a primeira rodada.

```text
round_reset = 0
round_inc   = 1
state_we    = 1
done        = 0
```

Ao final deste estado, `round_count` passa de 0 para 1.

### ROUND

Executa as rodadas intermediárias do AES.

```text
round_reset = 0
round_inc   = 1
state_we    = 1
done        = 0
```

- Enquanto `round_count < 9`, a FSM permanece em `ROUND`.
- Quando `round_count == 9`, a próxima rodada será a rodada final.

### FINAL

Executa a última rodada e grava o resultado final.

```text
round_reset = 0
round_inc   = 0
state_we    = 1
done        = 1
```

Após essa etapa, a FSM retorna ao estado `IDLE`.

O `output_block[127:0]` corresponde ao valor armazenado no `State Register`, sendo considerado resultado final válido quando `done = 1`.

## 6.Verificação funcional

Foram criados testbenches unitários para os módulos desenvolvidos nesta semana:

- `minisoc_aes_mix_columns_tb.sv`
- `minisoc_aes_add_round_key_tb.sv`
- `minisoc_aes_inv_shift_rows_tb.sv`
- `minisoc_aes_inv_sub_bytes_tb.sv`
- `minisoc_aes_inv_mix_columns_tb.sv`

Os testbenches utilizam valores intermediários fornecidos pela FIPS-197.

### MixColumns

```text
Entrada:         d4bf5d30e0b452aeb84111f11e2798e5
Saída esperada:  046681e5e0cb199a48f8d37a2806264c
```

Resultado: `PASS - MixColumns Round 1`

### AddRoundKey

```text
state_in:        5f72641557f5bc92f7be3b291db9f91a
round_key:       d6aa74fdd2af72fadaa678f1d6ab76fe
Saída esperada:  89d810e8855ace682d1843d8cb128fe4
```

Resultado: `PASS - AddRoundKey Round 1`

### InvShiftRows

```text
Entrada:         7ad5fda789ef4e272bca100b3d9ff59f
Saída esperada:  7a9f102789d5f50b2beffd9f3dca4ea7
```

Resultado: `PASS - InvShiftRows Round 1`

### InvSubBytes

```text
Entrada:         7a9f102789d5f50b2beffd9f3dca4ea7
Saída esperada:  bd6e7c3df2b5779e0b61216e8b10b689
```

Resultado: `PASS - InvSubBytes Round 1`

### InvMixColumns

```text
Entrada:         bd6e7c3df2b5779e0b61216e8b10b689
Saída esperada:  4773b91ff72f354361cb018ea1e6cf2c
```

Resultado: `PASS - InvMixColumns Round 1`

## 7.Regressão da Semana 3

O `Makefile` foi atualizado para incluir os módulos e testes da Semana 3.

O comando:

```bash
make week3
```

executa:

- lint dos módulos RTL;
- testes da S-box;
- testes de SubBytes;
- testes de ShiftRows;
- teste de MixColumns;
- teste de AddRoundKey;
- teste de InvSubBytes;
- teste de InvShiftRows;
- teste de InvMixColumns.

A regressão completa terminou com:

```text
====================================
PASS: regressao RTL da Semana 3 concluida com sucesso.
====================================
```

Os módulos desenvolvidos nesta semana também foram compilados sem erros de lint com:

```bash
vcs -full64 -sverilog +lint=all
```
