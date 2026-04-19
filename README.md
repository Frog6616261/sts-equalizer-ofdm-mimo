# sts-equalizer-ofdm-mimo

## Overview

Данный проект посвящён моделированию системы связи LTE-подобного типа, использующей:

- OFDM (Orthogonal Frequency Division Multiplexing)
- MIMO (Multiple Input Multiple Output)
- Turbo coding и Viterbi decoding
- Передачу в условиях рэлеевских замираний (Rayleigh fading)

Основная цель — сравнение алгоритмов эквализации и детектирования в MIMO-OFDM системе по метрикам:

- BER (Bit Error Rate)
- EVM (Error Vector Magnitude)

---

## System Model

### Передатчик

1. Генерация битового сообщения  
2. Канальное кодирование:
   - Turbo code
   - Viterbi  
3. Интерливинг  
4. Модуляция (BPSK / QAM)  
5. OFDM:
   - IFFT  
   - Добавление cyclic prefix  
6. Передача через MIMO канал  

---

### Канал

### Канал

В проекте моделируется реалистичный беспроводной канал, включающий:

- **Rayleigh fading (рэлеевские замирания)**
- **AWGN (Additive White Gaussian Noise, АБГШ)**
- **Пространственную корреляцию антенн (correlation matrices)**
- **Частотно-селективный канал (в OFDM через FFT)**

---

#### Rayleigh fading

Канал моделируется как случайная матрица с комплексно-нормальным распределением:

$$
H \sim \mathcal{CN}(0,1)
$$

Это соответствует сценарию:

- отсутствует прямая видимость (NLOS)
- сигнал приходит как сумма большого числа отражённых компонент

Для MIMO:

$$
H \in \mathbb{C}^{N_r \times N_t}
$$

где:
- $N_t$ — число передающих антенн  
- $N_r$ — число принимающих антенн  

---

#### AWGN (АБГШ)

К шуму добавляется аддитивный белый гауссовский шум:

$$
n \sim \mathcal{CN}(0, \sigma^2)
$$

Итоговая модель сигнала:

$$
y = Hx + n
$$

где:
- $x$ — переданный вектор символов  
- $y$ — принятый сигнал  

Шум генерируется в функции:


---

#### Коррелированный MIMO канал

В реальных системах антенны могут быть коррелированы (например, из-за малого расстояния между ними).

В проекте реализована модель с использованием корреляционных матриц:

$$
H_{corr} = R_r^{1/2} \cdot H \cdot R_t^{1/2}
$$

где:
- $R_t$ — корреляция передающих антенн  
- $R_r$ — корреляция принимающих антенн  

Реализация:


---

#### Приёмник

1. Удаление cyclic prefix  
2. FFT  
3. Оценка канала (pilot symbols)  
4. Эквализация / детектирование  
5. Демодуляция  
6. Деинтерливинг  
7. Декодирование:
   - Turbo (Max-Log-MAP)  
   - Viterbi  

---

## Implemented Algorithms

### Линейные эквалайзеры

- ZF (Zero Forcing)
- MMSE (Minimum Mean Square Error)

---

### Оптимальные методы

- ML (Maximum Likelihood)

---

### STS (Tree Search / Sphere-like Detection)

- Использует:
  - pruning
  - backtracking
- Снижает сложность ML

---

## Channel Coding

### Turbo Codes

- Используются в LTE
- Max-Log-MAP decoding

---

## Results

### BER vs SNR (Equalizer Comparison)

Сравнение алгоритмов:

- ML
- STS
- MMSE
- ZF

![BER vs SNR](res/Ber%20compare.png)

---

### EVM Analysis

Сравнение EVM для линейных эквалайзеров:

- ZF
- MMSE

![BER vs SNR](res/Evm%20compare.png)


---

### Constellation Diagrams

Примеры созвездий после эквализации:

- После ZF
![BER vs SNR](res/constellations/ZF/After%20equalizer%20SNR_dB%20=%209.png)

- После MMSE

![BER vs SNR](res/constellations/MMSE/After%20equalizer%20SNR_dB%20=%209.png)


## References

### Books

- Proakis, J. G. — *Digital Communications*, 5th Edition  
- Yong Soo Cho, 
Jaekwon Kim,
 Won Young Yang, 
Chung G. Kang — *MIMO-OFDM WIRELESS COMMUNICATIONS
WITH MATLAB*  

---

### Sphere Decoding / Tree Search (STS)

- Studer, C., Wenk, M., Burg, A., Bölcskei, H. —  
  *Soft-Output Sphere Decoding: Performance and Implementation Aspects*,  
  Asilomar Conference, 2006  


---

### OFDM and LTE

- 3GPP TS 36.211 — *LTE Physical Channels and Modulation*  
- 3GPP TS 36.212 — *LTE Channel Coding*  
- 3GPP TS 36.213 — *LTE Physical Layer Procedures*  

---

