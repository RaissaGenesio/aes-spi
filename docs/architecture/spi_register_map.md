| Addr | Registro | Acesso | Função |
|---|---|---|---|
| `0x00` | `KEY0` | R/W | `cfg_key[127:96]` |
| `0x01` | `KEY1` | R/W | `cfg_key[95:64]` |
| `0x02` | `KEY2` | R/W | `cfg_key[63:32]` |
| `0x03` | `KEY3` | R/W | `cfg_key[31:0]` |
| `0x04` | `IV0` | R/W | `cfg_iv[127:96]` |
| `0x05` | `IV1` | R/W | `cfg_iv[95:64]` |
| `0x06` | `IV2` | R/W | `cfg_iv[63:32]` |
| `0x07` | `IV3` | R/W | `cfg_iv[31:0]` |
| `0x08` | `COUNTER_HI` | R/W | `cfg_counter[63:32]` |
| `0x09` | `COUNTER_LO` | R/W | `cfg_counter[31:0]` |
| `0x0A` | `NUM_BLOCKS` | R/W | 1 a 256 blocos |
| `0x0B` | `AES_CONTROL` | R/W | START, DECRYPT, MODE |
| `0x0C` | `AES_STATUS` | R | BUSY, DONE, ERROR, BLOCKS_DONE |
| `0x0D` | `VERSION` | R | versão |
| `0x0E` | `SYSTEM_CONTROL` | R/W | MEM_SEL_AES, PLL_ENABLE, PLL_DIV_SEL |
| `0x0F` | `SYSTEM_STATUS` | R | PLL_LOCKED |
| `0x3F` | `NOP` | - | usado no retorno de leitura SPI |

