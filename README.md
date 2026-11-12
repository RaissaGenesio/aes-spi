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
- **PLL Mock** — geração do clock utilizado pelo domínio do AES.

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
│   │   └── semana_03.md
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
│   │   └── minisoc_aes_inv_mix_columns.sv
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
- `docs/architecture/` — documentação de arquitetura, datapath e máquina de estados;
- `docs/reports/` — relatórios semanais;
- `rtl/minisoc_aes/` — módulos relacionados ao AES;
- `rtl/minisoc_mem/` — memória compartilhada;
- `rtl/minisoc_pll/` — modelo RTL do PLL;
- `rtl/minisoc_spi/` — front-end SPI e lógica associada;
- `rtl/minisoc_top.sv` — integração dos blocos do sistema;
- `tb/` — testbenches e arquivos utilizados na verificação;
- `formal/` — scripts e relatórios de verificação formal;
- `syn/` — scripts, constraints e relatórios de síntese;
- `upf/` — arquivos relacionados à intenção de potência e baixo consumo;
- `scripts/` — scripts auxiliares e automação;
- `models/` — modelos comportamentais auxiliares;
- `Makefile` — automação de lint, compilação e simulação.

## Estado atual

### Semana 1 — Ambiente e estudos

Foram realizados:

- configuração inicial do repositório;
- preparação do ambiente com VCS;
- estudo do AES e do protocolo SPI;
- criação de um fluxo mínimo de compilação, lint e simulação.

### Semana 2 — SubBytes e ShiftRows

Foram implementados:

- `minisoc_aes_sbox`;
- `minisoc_aes_sub_bytes`;
- `minisoc_aes_shift_rows`.

A S-box foi verificada para todas as **256 entradas possíveis**.

Os módulos `SubBytes` e `ShiftRows` foram verificados utilizando estados intermediários da FIPS-197, incluindo as rodadas 1 e 10.

### Semana 3 — Microarquitetura e transformações de rodada

Foram implementados:

- `minisoc_aes_mix_columns`;
- `minisoc_aes_add_round_key`;
- `minisoc_aes_inv_sbox`;
- `minisoc_aes_inv_sub_bytes`;
- `minisoc_aes_inv_shift_rows`;
- `minisoc_aes_inv_mix_columns`.

Os módulos foram verificados utilizando valores intermediários da FIPS-197 para cifragem e decriptação.

Também foi definida a microarquitetura interna do AES, utilizando uma abordagem iterativa com reutilização dos blocos combinacionais ao longo das rodadas.

A arquitetura proposta inclui:

- `State Register` de 128 bits;
- contador de rodadas;
- caminho de cifragem;
- caminho de decriptação;
- multiplexadores para tratamento da rodada inicial e final;
- compartilhamento do bloco `AddRoundKey`;
- máquina de estados com os estados `IDLE`, `INIT`, `ROUND` e `FINAL`;
- sinais de controle `round_reset`, `round_inc`, `state_we`, `init_round`, `final_round`, `decrypt`, `inv_mix_en` e `done`.

A documentação da microarquitetura está disponível em:

```text
docs/architecture/aes_microarchitecture.md
```

Os diagramas do datapath e da máquina de estados também estão disponíveis em `docs/architecture/`.

## Execução dos testes da Semana 2

Execute:

```bash
make week2
```

O comando executa:

1. lint dos módulos da Semana 2;
2. teste das 256 entradas da S-box;
3. teste do `SubBytes`;
4. teste do `ShiftRows`.

Uma execução válida termina com:

```text
PASS: Semana 2 concluida com sucesso.
```

## Execução dos testes da Semana 3

Execute:

```bash
make week3
```

O comando executa:

1. lint dos módulos RTL;
2. testes da S-box;
3. teste do `SubBytes`;
4. teste do `ShiftRows`;
5. teste do `MixColumns`;
6. teste do `AddRoundKey`;
7. teste do `InvSubBytes`;
8. teste do `InvShiftRows`;
9. teste do `InvMixColumns`.

Uma execução válida termina com:

```text
PASS: regressao RTL da Semana 3 concluida com sucesso.
```
