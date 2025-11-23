# PWM Controller cu Interfață SPI - Proiect Verilog

## Descriere Generală

Acest proiect implementează un controller PWM (Pulse Width Modulation) configurabil prin interfață SPI. Sistemul permite controlul unui semnal PWM prin comenzi transmise de la un master SPI, oferind flexibilitate în configurarea perioadei, duty cycle-ului și modului de operare.

---

## Arhitectura Sistemului

Proiectul este structurat în **6 module Verilog** interconectate, fiecare cu responsabilități bine definite:

```
[spi_bridge] <---> [instr_dcd] <---> [regs] <---> [counter]
                                         |            |
                                         v            v
                                      [pwm_gen] --> [PWM Output]
```

---

## Module și Funcționalități

### 1. **top.v** - Modulul Principal (Top-Level)

**Rol:** Integrează toate modulele și realizează interconexiunile dintre ele.

**Interfețe:**
- **Intrări:**
  - `clk`, `rst_n` - Semnale de ceas și reset
  - `sclk`, `cs_n`, `miso` - Semnale SPI de la master
- **Ieșiri:**
  - `mosi` - Date SPI către master
  - `pwm_out` - Semnalul PWM generat

**Interconexiuni:**
- Conectează `spi_bridge` la `instr_dcd` prin semnalele `byte_sync`, `data_in`, `data_out`
- Conectează `instr_dcd` la `regs` prin semnalele `read`, `write`, `addr`, `data_read`, `data_write`
- Conectează `regs` la `counter` și `pwm_gen` prin semnalele de configurare
- Conectează `counter` la `pwm_gen` prin `counter_val`

---

### 2. **spi_bridge.v** - Interfața SPI

**Rol:** Implementează protocolul SPI slave și sincronizează comunicația cu ceasul sistemului.

**Funcționalități:**
- Sincronizare SCLK cu CLK (sistem de 2 flip-flop-uri pentru evitarea metastabilității)
- Recepție date (MOSI) pe frontul crescător al SCLK
- Transmisie date (MISO) pe frontul descrescător al SCLK
- Generare puls `byte_sync` după recepția celor 8 biți

**Comunicație cu alte module:**
- **→ instr_dcd:** 
  - `byte_sync` - puls de sincronizare (1 ciclu CLK) când un byte complet a fost recepționat
  - `data_in[7:0]` - byte-ul recepționat de la master
- **← instr_dcd:**
  - `data_out[7:0]` - byte-ul de transmis către master

**Detalii tehnice:**
- Shift register pentru serializare/deserializare
- MISO devine High-Z când CS_N este inactiv
- Contor de biți (3 biți) pentru tracking-ul byte-ului curent

---

### 3. **instr_dcd.v** - Decodor de Instrucțiuni

**Rol:** Decodifică comenzile SPI primite și generează operații de citire/scriere pentru registre.

**Protocol de Comunicație (2 bytes):**

**Byte 1 (SETUP):**
```
Bit 7: Operation (1=Write, 0=Read)
Bit 6: Memory Zone (1=High Byte, 0=Low Byte)
Bit 5-0: Base Address
```

**Byte 2 (DATA):**
- Pentru **Write:** conține valoarea de scris
- Pentru **Read:** se ignoră (răspunsul vine pe MISO)

**FSM (Finite State Machine):**
- **SETUP:** Primește primul byte și decodifică comanda
- **DATA:** Procesează al doilea byte (scrie sau finalizează citirea)

**⚠️ OPTIMIZARE CRITICĂ:**
Pentru operații de citire, semnalul `read` și adresa sunt activate **anticipat** în starea SETUP pentru a permite modulului `regs` să pregătească datele la timp pentru transmisie SPI.

**Comunicație cu alte module:**
- **← spi_bridge:**
  - `byte_sync` - notificare recepție byte
  - `data_in[7:0]` - byte recepționat
- **→ regs:**
  - `read` - puls de citire (1 ciclu)
  - `write` - puls de scriere (1 ciclu)
  - `addr[5:0]` - adresa registrului
  - `data_write[7:0]` - date de scris
- **← regs:**
  - `data_read[7:0]` - date citite (conectate direct la `data_out`)

---

### 4. **regs.v** - Banca de Registre

**Rol:** Gestionează registrele de configurare pentru counter și PWM generator.

**Mapa de Registre:**

| Adresă | Registru | Tip | Descriere |
|--------|----------|-----|-----------|
| 0x00 | PERIOD[7:0] | R/W | Byte inferior perioadă (16-bit) |
| 0x01 | PERIOD[15:8] | R/W | Byte superior perioadă |
| 0x02 | COUNTER_EN | R/W | Enable counter (bit 0) |
| 0x03 | COMPARE1[7:0] | R/W | Byte inferior comparator 1 |
| 0x04 | COMPARE1[15:8] | R/W | Byte superior comparator 1 |
| 0x05 | COMPARE2[7:0] | R/W | Byte inferior comparator 2 |
| 0x06 | COMPARE2[15:8] | R/W | Byte superior comparator 2 |
| 0x07 | COUNTER_RESET | W | Reset counter (auto-clear) |
| 0x08 | COUNTER_VAL[7:0] | RO | Valoare curentă counter (low) |
| 0x09 | COUNTER_VAL[15:8] | RO | Valoare curentă counter (high) |
| 0x0A | PRESCALE[7:0] | R/W | Factor de prescalare |
| 0x0B | UPNOTDOWN | R/W | Direcție numărare (1=down, 0=up) |
| 0x0C | PWM_EN | R/W | Enable PWM (bit 0) |
| 0x0D | FUNCTIONS[1:0] | R/W | Mod funcționare PWM |

**Comunicație cu alte module:**
- **← instr_dcd:**
  - `read`, `write` - comenzi
  - `addr[5:0]` - adresa registrului
  - `data_write[7:0]` - date de scris
- **→ instr_dcd:**
  - `data_read[7:0]` - date citite
- **← counter:**
  - `counter_val[15:0]` - valoarea curentă (read-only)
- **→ counter:**
  - `period[15:0]`, `en`, `count_reset`, `upnotdown`, `prescale[7:0]`
- **→ pwm_gen:**
  - `pwm_en`, `functions[7:0]`, `compare1[15:0]`, `compare2[15:0]`

**Funcționalitate Specială:**
- `count_reset` se auto-clearează după 1 ciclu (comportament de puls)
- Validarea adreselor prin `addr_valid`

---

### 5. **counter.v** - Numărător Configurabil

**Rol:** Implementează un numărător 16-bit cu prescaler și direcție configurabilă.

**Caracteristici:**
- **Prescaler:** Factor de împărțire 0-255 (prescale + 1)
- **Direcție:** Up-counting (`upnotdown=0`) sau Down-counting (`upnotdown=1`)
- **Perioadă:** 16-bit (0-65535)
- **Auto-reload:** La atingerea limitei, resetează/reîncarcă

**Logica de Funcționare:**

```
UP-counting (upnotdown=0):
  count: 0 → 1 → ... → (period-1) → 0 (wrap-around)

DOWN-counting (upnotdown=1):
  count: (period-1) → ... → 1 → 0 → (period-1) (wrap-around)
```

**Comunicație cu alte module:**
- **← regs:**
  - `period[15:0]`, `en`, `count_reset`, `upnotdown`, `prescale[7:0]`
- **→ regs, pwm_gen:**
  - `count_val[15:0]` - valoarea curentă a contorului

**Algoritm Prescaler:**
1. `prescale_cnt` se incrementează la fiecare ciclu de CLK (dacă `en=1`)
2. Când `prescale_cnt == prescale`, counter-ul principal se actualizează
3. `prescale_cnt` se resetează

---

### 6. **pwm_gen.v** - Generator PWM

**Rol:** Generează semnalul PWM bazat pe valoarea counter-ului și comparatori.

**Moduri de Funcționare (FUNCTIONS):**

**Mode 0 (`functions=0`):** PWM Standard (Active High)
```
pwm_out = 1 dacă count_val < compare1
pwm_out = 0 altfel
```

**Mode 1 (`functions=1`):** PWM Inversat (Active Low)
```
pwm_out = 0 dacă count_val < compare1
pwm_out = 1 altfel
```

**Mode 2+ (`functions≥2`):** PWM cu Fereastră (Window PWM)
```
Dacă compare1 < compare2:
  pwm_out = 1 dacă compare1 ≤ count_val < compare2
  pwm_out = 0 altfel
Altfel:
  pwm_out = 1 (invalid configuration)
```

**Comunicație cu alte module:**
- **← regs:**
  - `pwm_en`, `period[15:0]`, `functions[7:0]`, `compare1[15:0]`, `compare2[15:0]`
- **← counter:**
  - `count_val[15:0]`
- **→ top (output):**
  - `pwm_out` - semnalul PWM generat

**Comportament:**
- Când `pwm_en=0` sau `rst_n=0`, ieșirea este forțată la 0
- Actualizare sincronă la fiecare ciclu de CLK
---

## Considerații de Design

### Sincronizare și Timing
- **Clock Domain Crossing:** `spi_bridge` sincronizează SCLK cu CLK
- **Pulse Generation:** Semnalele `read/write` sunt active doar 1 ciclu
- **Look-Ahead Read:** În `instr_dcd`, citirile sunt inițiate anticipat pentru latență minimă

### Reset Behavior
- Reset asincron, activ pe nivel LOW (`rst_n`)
- Toate registrele se resetează la valori implicite sigure
- Counter și PWM pornesc dezactivate

### Securitate și Validare
- Adresele invalide sunt ignorate în `regs`
- MISO devine High-Z când CS_N este inactiv
- Auto-clear pentru `count_reset` previne stări blocate

---

## Autori si Contributii
- CORBEANU Tudor-Nicolae: Documentatie si spi_bridge
- IONESCU Raul-Andrei: instr_dcd si regs
- BALALAU Andrei-Valentin: pwm_gen si counter


---

