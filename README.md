# Acelerador AES com Interface SPI e Baixo Consumo

Projeto desenvolvido na trilha **RTL Design** da Residência em Microeletrônica — Polo UFCG.

## Objetivo

Desenvolver um IP digital sintetizável baseado no **MiniSoC AES**, integrando:

- engine AES-128;
- interface SPI para configuração, controle e monitoramento;
- memória compartilhada para entrada e saída dos dados;
- geração e controle de clock;
- reset;
- suporte a técnicas de baixo consumo.

A especificação funcional do projeto segue o **Block Guide MiniSoC AES v1.0.0**.

## Arquitetura geral

O sistema é organizado em quatro blocos funcionais principais:

- **SPI Front-End** — configuração, comando e leitura de status;
- **AES Engine** — processamento de cifragem e decriptação AES-128;
- **Memória compartilhada** — armazenamento dos blocos de entrada e dos resultados;
- **PLL Mock** — modelo utilizado para geração e controle do clock do sistema.

A interface `MEMORY DATA` permite o acesso externo à memória quando ela não está sob controle do AES.

## Estrutura do repositório

```text
.
├── docs/
│   ├── architecture/
│   │   ├── aes_datapath.pdf
│   │   ├── aes_datapath.png
│   │   ├── aes_fsm.png
│   │   └── aes_microarchitecture.md
│   ├── reports/
│   │   ├── semana_01.md
│   │   ├── semana_02.md
│   │   ├── semana_03.md
│   │   └── semana_04.md
│   └── spec/
├── formal/
├── models/
├── rtl/
│   ├── minisoc_aes/
│   │   ├── minisoc_aes_sbox.sv
│   │   ├── minisoc_aes_sub_bytes.sv
│   │   ├── minisoc_aes_shift_rows.sv
│   │   ├── minisoc_aes_mix_columns.sv
│   │   ├── minisoc_aes_add_round_key.sv
│   │   ├── minisoc_aes_inv_sbox.sv
│   │   ├── minisoc_aes_inv_sub_bytes.sv
│   │   ├── minisoc_aes_inv_shift_rows.sv
│   │   ├── minisoc_aes_inv_mix_columns.sv
│   │   ├── minisoc_aes_key_exp.sv
│   │   └── minisoc_aes_dp.sv
│   ├── minisoc_mem/
│   ├── minisoc_pll/
│   ├── minisoc_spi/
│   └── minisoc_top.sv
├── scripts/
├── syn/
├── tb/
├── upf/
├── Makefile
└── README.md
```

## Organização

- `docs/spec/` — especificações do projeto e Block Guide;
- `docs/architecture/` — documentação da arquitetura, datapath e máquina de estados;
- `docs/reports/` — relatórios semanais;
- `rtl/minisoc_aes/` — módulos relacionados ao núcleo AES;
- `rtl/minisoc_mem/` — diretório destinado ao subsistema de memória;
- `rtl/minisoc_pll/` — diretório destinado à lógica relacionada ao PLL;
- `rtl/minisoc_spi/` — diretório destinado ao front-end SPI;
- `rtl/minisoc_top.sv` — integração dos blocos do sistema;
- `tb/` — testbenches utilizados na verificação;
- `formal/` — scripts e relatórios de verificação formal;
- `syn/` — scripts, constraints e relatórios de síntese;
- `upf/` — arquivos relacionados à intenção de potência e baixo consumo;
- `scripts/` — scripts auxiliares e automação;
- `models/` — modelos comportamentais auxiliares;
- `Makefile` — automação de lint, compilação e simulação.

# Estado atual

## Semana 1 — Ambiente e estudos

Foram realizados:

- configuração inicial do repositório;
- preparação do ambiente com VCS;
- estudo do AES e do protocolo SPI;
- criação de um fluxo mínimo de compilação, lint e simulação.

## Semana 2 — SubBytes e ShiftRows

Foram implementados:

- `minisoc_aes_sbox`;
- `minisoc_aes_sub_bytes`;
- `minisoc_aes_shift_rows`.

A S-box foi verificada para todas as **256 entradas possíveis**.

Os módulos `SubBytes` e `ShiftRows` foram verificados utilizando estados intermediários de referência da FIPS-197.

## Semana 3 — Microarquitetura e transformações de rodada

Foram implementados:

- `minisoc_aes_mix_columns`;
- `minisoc_aes_add_round_key`;
- `minisoc_aes_inv_sbox`;
- `minisoc_aes_inv_sub_bytes`;
- `minisoc_aes_inv_shift_rows`;
- `minisoc_aes_inv_mix_columns`.

Os módulos foram verificados utilizando valores intermediários da FIPS-197 para cifragem e decriptação.

Também foi definida a microarquitetura interna do AES utilizando uma abordagem **iterativa**, com reutilização dos blocos combinacionais ao longo das rodadas.

A arquitetura utiliza:

- registrador de estado de 128 bits;
- contador de rodadas;
- caminho de cifragem;
- caminho de decriptação;
- compartilhamento do bloco `AddRoundKey`;
- tratamento específico para a etapa inicial e para a rodada final;
- máquina de estados com `IDLE`, `INIT`, `ROUND` e `FINAL`.

A FSM determina quando cada etapa é executada, enquanto o datapath executa as transformações correspondentes.

A documentação da microarquitetura está disponível em:

```text
docs/architecture/aes_microarchitecture.md
```

Os diagramas do datapath e da máquina de estados também estão disponíveis em `docs/architecture/`.

## Semana 4 — Expansão de chave e datapath AES-128

Foram implementados:

- `minisoc_aes_key_exp`;
- `minisoc_aes_dp`.

### Expansão de chave

O módulo `minisoc_aes_key_exp` recebe uma chave AES-128 e disponibiliza as **11 round keys** necessárias ao algoritmo.

A estratégia adotada foi disponibilizar todas as round keys a partir da chave original.

Essa abordagem simplifica principalmente a decriptação, pois as chaves precisam ser utilizadas em ordem inversa.

A expansão de cada nova round key realiza:

- divisão da chave em quatro words de 32 bits;
- `RotWord`;
- `SubWord` utilizando a S-box;
- aplicação de `Rcon`;
- geração das novas words por operações XOR encadeadas.

As 11 round keys foram verificadas utilizando valores de referência da FIPS-197.

### Datapath AES-128

O módulo `minisoc_aes_dp` realiza o processamento completo de um bloco de 128 bits.

O datapath suporta:

- cifragem AES-128;
- decriptação AES-128;
- seleção das round keys;
- controle iterativo das rodadas;
- sinais `start`, `busy` e `done`;
- reutilização dos blocos combinacionais.

Na cifragem, a operação começa com:

```text
input_block XOR key_0
```

O resultado é armazenado no registrador de estado.

Nas rodadas intermediárias, o estado passa por:

```text
SubBytes
   ↓
ShiftRows
   ↓
MixColumns
   ↓
AddRoundKey
```

Na rodada final, `MixColumns` não é executado.

Na decriptação, são utilizadas as transformações inversas e as round keys em ordem inversa.

### Validação

Foram utilizados vetores de referência da FIPS-197 para validar o núcleo completo nos dois sentidos.

Um dos casos utilizados foi:

```text
Key:
000102030405060708090a0b0c0d0e0f

Plaintext:
00112233445566778899aabbccddeeff

Ciphertext:
69c4e0d86a7b0430d8cdb78070b4c55a
```

Outro caso utilizado foi:

```text
Key:
2b7e151628aed2a6abf7158809cf4f3c

Plaintext:
3243f6a8885a308d313198a2e0370734

Ciphertext:
3925841d02dc09fbdc118597196a0b32
```

Os testes de cifragem e decriptação passaram para os vetores utilizados.

# Execução dos testes

## Semana 2

Execute:

```bash
make week2
```

O comando executa os testes dos módulos desenvolvidos até a Semana 2.

## Semana 3

Execute:

```bash
make week3
```

O comando executa o lint e os testes das transformações diretas e inversas do AES.

Uma execução válida termina com:

```text
PASS: regressao RTL da Semana 3 concluida com sucesso.
```

## Semana 4

Execute:

```bash
make week4
```

O comando executa:

1. lint dos módulos utilizados pelo núcleo AES;
2. teste da expansão de chave AES-128;
3. teste completo de cifragem AES-128;
4. teste completo de decriptação AES-128.

Uma execução válida termina com:

```text
PASS: regressao RTL da Semana 4 concluida.
```

# Situação do projeto

Até a Semana 4, o núcleo AES-128 está funcional em simulação para cifragem e decriptação de um bloco de 128 bits.

## Concluído

- transformações diretas do AES;
- transformações inversas;
- expansão de chave AES-128;
- datapath iterativo;
- controle das rodadas;
- cifragem completa;
- decriptação completa;
- testes com vetores da FIPS-197;
- regressão automatizada pelo Makefile;
- lint dos módulos implementados.
