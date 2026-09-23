# DINO LINE 98 — TỔNG HỢP LUẬT CHƠI

> Tài liệu này được viết bằng cách **đọc thẳng từ code** (`index.html` + 5 file config `*.js`), không viết theo trí nhớ.
> Ngày cập nhật luật sản phẩm: **22/09/2026**.
> Các giá trị được đánh dấu **MỚI** là yêu cầu cân bằng cần được đồng bộ vào code/build khách (`Dino-Line-98-standalone.html`).
>
> Nguồn: `index.html`, `booster-config.js`, `chest-config.js`, `collection-config.js`, `lucky-wheel-config.js`, `dino-home-config.js`.

---

## MỤC LỤC

1. [Bàn cờ & nước đi](#1-bàn-cờ--nước-đi)
2. [Ăn hàng & tính điểm](#2-ăn-hàng--tính-điểm)
3. [Trứng & lồng ấp (hatchery)](#3-trứng--lồng-ấp-hatchery)
4. [Nhiệm vụ màn](#4-nhiệm-vụ-màn)
5. [Màn khó — trứng đá & vật cản](#5-màn-khó--trứng-đá--vật-cản)
6. [Qua màn & thua](#6-qua-màn--thua)
7. [Phần thưởng qua màn (rương cuối màn)](#7-phần-thưởng-qua-màn-rương-cuối-màn)
8. [Rương (Chest)](#8-rương-chest)
9. [Booster — búa & đổi chỗ](#9-booster--búa--đổi-chỗ)
10. [Bộ sưu tập khủng long (mảnh ghép)](#10-bộ-sưu-tập-khủng-long-mảnh-ghép)
11. [Vòng quay may mắn](#11-vòng-quay-may-mắn)
12. [Cửa hàng & tiền tệ](#12-cửa-hàng--tiền-tệ)
13. [Hồ sơ & danh hiệu](#13-hồ-sơ--danh-hiệu)
14. [Bản đồ 100 màn](#14-bản-đồ-100-màn)
15. [Farm — nuôi khủng long](#15-farm--nuôi-khủng-long)
16. [Bảng xếp hạng người chơi thật](#16-bảng-xếp-hạng-người-chơi-thật)
17. [Bảng khoá lưu (localStorage)](#17-bảng-khoá-lưu-localstorage)
18. [Bảng tra nhanh mọi hằng số](#18-bảng-tra-nhanh-mọi-hằng-số)

---

## 1. BÀN CỜ & NƯỚC ĐI

| Luật | Giá trị |
|---|---|
| Kích thước bàn | **9 × 9** (`SIZE = 9`) |
| Số màu trứng người chơi thu thập | **7** (`NCOLOR = 7`) |
| Màu thứ 8 | **Trứng đá / xám** (`GRAY = 7`) — không tính vào nhiệm vụ |
| Trứng sinh ra mỗi lượt | **3** (`SPAWN = 3`) |
| Số trứng cần để ăn 1 hàng | **5** (`LINE = 5`) |

**7 màu chơi được:** đỏ, xanh lá, xanh dương, vàng, tím, xanh ngọc (cyan), cam.
Màu thứ 8 (xám) là **trứng đá** — xem [mục 5](#5-màn-khó--trứng-đá--vật-cản).

### Cách đi
- Chạm 1 quả trứng → chạm ô trống → trứng **đi theo đường ngắn nhất** tới đó.
- Tìm đường bằng **BFS 4 hướng** (lên / xuống / trái / phải), **chỉ đi qua ô trống**. Không đi chéo, không nhảy qua trứng khác, không đi xuyên vật cản.
- **Không có đường đi ⇒ nước đi không hợp lệ** (trứng đứng yên).

### Nhịp một lượt
```
Người chơi đi 1 nước
   ├─ Nếu tạo được hàng ≥5 → ĂN HÀNG → KHÔNG sinh trứng mới (được đi tiếp miễn phí)
   └─ Nếu không ăn được    → sinh 3 trứng mới theo ô xem trước (preview)
                              → 3 trứng xem trước của lượt sau hiện lên
```
- Trò chơi luôn hiện **3 trứng xem trước** của lượt kế tiếp.
- Nếu ô xem trước bị chiếm mất, trứng sẽ rơi vào một ô trống khác bất kỳ.
- **Ăn được hàng ⇒ giữ nguyên 3 quả báo trước** (không tiêu, không sinh mới) — đây là phần thưởng cho nước đi giỏi.
- **3 quả mới rơi xuống cũng có thể tự tạo thành hàng ≥5 và vỡ ngay**, vẫn tính điểm và nuôi lồng ấp bình thường.
- Trứng trong lồng **nở ở ĐẦU nước đi**, TRƯỚC khi thu trứng của nước đó → trứng vừa ăn sớm nhất cũng chỉ được ấp từ lượt sau.

---

## 2. ĂN HÀNG & TÍNH ĐIỂM

### Hàng hợp lệ
Quét **4 hướng**: `ngang [0,1]`, `dọc [1,0]`, `chéo xuôi [1,1]`, `chéo ngược [1,-1]`.
Hàng dài **≥ 5 quả cùng màu** thì vỡ. Hàng 6, 7, 8, 9 quả đều vỡ hết (không giới hạn ở 5).

Một nước đi có thể vỡ **nhiều hàng cùng lúc** (ví dụ hình chữ thập) — tất cả đều được tính.

### Điểm
> **1 quả trứng vỡ = 1 điểm.** (`updateScore(cleared.length)`)

Không có hệ số combo, không có nhân điểm, không có thưởng chuỗi. Ăn 5 quả = 5 điểm, ăn 9 quả = 9 điểm.

- Điểm hiện tại hiển thị trên **HUD**.
- **Điểm cao nhất** lưu ở khoá `line98_best`, chỉ tăng, không reset khi qua màn.
- Có **đồng hồ đếm thời gian đã chơi** (đếm lên, không phải đếm ngược — bản đếm ngược đã bỏ vì vật cản đủ khó rồi). Đồng hồ **dừng khi pause**.

---

## 3. TRỨNG & LỒNG ẤP (HATCHERY)

Đây là hệ thống cốt lõi phân biệt game này với Line 98 truyền thống.

### 3.1 Trứng nào được vào lồng ấp?
> **CHỈ trứng có màu trùng với một nhiệm vụ CHƯA hoàn thành mới đi vào lồng ấp.**

- Trứng màu khác (kể cả màu đẹp) → **chỉ vỡ lấy điểm**, không vào lồng.
- Màu nào đã đủ chỉ tiêu → trứng màu đó **từ đó về sau chỉ tính điểm**, và kho trứng tồn của màu đó bị **xoá sạch** (`eggPool = eggPending = 0`).

### 3.2 Số lồng & sức chứa
- Có **2 lồng ấp** (2 nest) đặt trên bệ ấp.
- Mỗi nước nạp trứng, tối đa **2 quả** được đưa vào lồng (mỗi lồng 1 quả).
- Trứng ăn được xếp vào **kho theo màu** (`eggPool[color]`); lồng lấy trứng ra từ kho này.

### 3.3 Nhịp NỔ ↔ NẠP (rất quan trọng)
```
Nước A: ăn trứng  →  2 quả vừa ăn được NẠP NGAY vào lồng trống (loadPendingEggsNow)
Nước B: đầu nước  →  trứng trong lồng NỞ / UNG   (crackedThisMove = true)
                     → hết nước B KHÔNG nạp (bỏ qua 1 nhịp)
Nước C:            →  nạp lứa tiếp theo
```
Nói gọn: **1 nước vỡ trứng → 1 nước nghỉ → rồi mới nạp tiếp.** Cơ chế chốt bằng cờ `crackedThisMove` trong `finishTurn()`:

```js
function finishTurn(){
  if(crackedThisMove){ crackedThisMove=false; return; }   // nước vừa nổ: KHÔNG nạp
  loadNextEggs();
}
```

**Ngoại lệ có chủ đích:** nếu ngay trong nước đi đó vừa ăn được trứng đúng màu và còn lồng trống, trứng **vào lồng ngay lập tức** (không phải chờ 1 nước) — trừ khi nước đó đã có trứng vỡ (`blockedByCrack` chốt trước khi khủng long bay đi).

### 3.4 Tỉ lệ nở
| Hằng số | Giá trị | Ý nghĩa |
|---|---|---|
| `HATCH_RATE` | **0.20 (20%) — MỚI** | Mỗi trứng có 20% nở thành công trước khi áp dụng cơ chế chống đen. |
| `PITY` | **8** | Chống đen: 7 quả ung liên tiếp → **quả thứ 8 chắc chắn nở**. |

Công thức thực tế: `lucky = Math.random() < HATCH_RATE || dryStreak >= PITY - 1`

### 3.5 Kết quả nở
- **NỞ THÀNH CÔNG:** `quest.got++` (tăng 1 con cho nhiệm vụ màu đó), khủng long **bay** từ lồng ra đứng lên bệ đá / nền rừng. Hiện toast `hatch-success`.
- **UNG (thất bại):** hiện toast `hatch-failed` + hiệu ứng **khói xanh lá** bốc lên. Trứng mất, `dryStreak++`.
- Khi một màu đã đủ chỉ tiêu, lồng đang ấp màu đó **dừng ấp ngay** (`slots[i] = null`).

### 3.6 Chỗ đứng của khủng long đã nở
- Khủng long đứng trên các **bậc thang đá / nền rừng** của ảnh nền (`#platformLayer`).
- **Màn ngang:** bậc 1 dành riêng cho lồng ấp; khủng long đứng bậc 2–6 (tối đa 2 con/bậc), rồi tới vỉa hè và nền đất (tối đa 4 con/hàng) → khoảng 18 chỗ trên điện thoại.
- **Màn dọc:** đứng trên dầm đá vòm (tối đa 4), rồi các hàng vỉa hè bên dưới.
- Hết chỗ thì vòng lại có độ lệch (từ màn ~19 trở đi khủng long sẽ chồng hàng).

---

## 4. NHIỆM VỤ MÀN

### Công thức sinh nhiệm vụ
```js
function makeQuest(lv){
  const total  = lv;                 // MÀN N = cần nở đúng N con
  const nTypes = lv >= 3 ? 2 : 1;    // từ màn 3 trở đi: 2 MÀU
  // màn 1-2: 1 màu, cần đủ `lv` con
  // màn ≥3 : chia đôi -> màu A cần ceil(lv/2), màu B cần phần còn lại
}
```

| Màn | Số màu | Chỉ tiêu |
|---|---|---|
| 1 | 1 màu | 1 con |
| 2 | 1 màu | 2 con |
| 3 | 2 màu | 2 + 1 |
| 4 | 2 màu | 2 + 2 |
| 5 | 2 màu | 3 + 2 |
| 10 | 2 màu | 5 + 5 |
| 50 | 2 màu | 25 + 25 |
| 100 | 2 màu | 50 + 50 |

- Màu được **bốc ngẫu nhiên** trong 7 màu, 2 màu không trùng nhau.
- Nhiệm vụ hiển thị trên **bảng TARGET**; mỗi lồng có **biển số** ghi màu + `đã có / cần`.
  (Nếu màn chỉ có 1 màu → chỉ lồng số 0 gắn biển.)
- **Hoàn thành khi:** `quest.every(q => q.got >= q.need)` — tất cả các màu đều đủ.

---

## 5. MÀN KHÓ — TRỨNG ĐÁ & VẬT CẢN

Trứng xám (`GRAY = 7`) **chỉ xuất hiện ở các màn khó đã định sẵn**:

```js
const HARD_LEVELS = { 2:1, 5:2, 10:3, 20:4, 40:5, 70:6, 99:7 };
```

| Màn | Số vật cản phải tạo |
|---|---|
| 2 | 1 |
| 5 | 2 |
| 10 | 3 |
| 20 | 4 |
| 40 | 5 |
| 70 | 6 |
| 99 | 7 |

Mọi màn khác: **không có trứng xám**.

### Luật trứng đá
- `GRAY_RATE = 0.30` **— MỚI** → khi màn còn cần tạo vật cản, mỗi trứng sinh ra có **30%** là trứng xám.
- Ăn được **5 trứng xám thành hàng** → tạo **1 vật cản cố định** (`OBST = -2`, tường đá khủng long) tại ô kết thúc nước đi (hoặc ô xám ở giữa hàng).
- Vật cản **không thể đi xuyên qua**, không ăn được bằng nước đi thường (chỉ búa đá phá được).
- Khi đã tạo đủ `obTarget()` vật cản → `sweepGrayEggs()` **quét sạch mọi trứng xám còn lại trên bàn** và đổi màu các ô xem trước xám thành màu thường. Từ đó màn chơi không sinh trứng xám nữa.

---

## 6. QUA MÀN & THUA

### Qua màn
- Điều kiện duy nhất: **hoàn thành nhiệm vụ** (nở đủ số khủng long mỗi màu).
- Khi qua màn:
  1. Mở khoá checkpoint kế tiếp trên bản đồ (`unlockMapLevel(level+1)`), phát âm thanh `levelWin` (+ `levelUnlock` sau 650ms nếu đây là màn mới mở lần đầu).
  2. Khủng long avatar trên bản đồ dời sang checkpoint mới.
  3. Mở **popup phần thưởng** (xem mục 7).
- Popup có 2 lối ra:
  - **NEXT** → vào thẳng màn kế tiếp, không quay về bản đồ.
  - **HOME** → về bản đồ.
- Hết màn 100 → về bản đồ (không có màn 101).
- **Điểm KHÔNG reset khi qua màn** — cộng dồn suốt phiên.

### Thua
> **Thua khi bàn cờ đầy** — không còn ô trống để sinh trứng.

Màn hình hiện: `💀 Board full! · Level N · Score: S`.
**Không có giới hạn số nước đi và không có đồng hồ đếm ngược.**

---

## 7. PHẦN THƯỞNG QUA MÀN (RƯƠNG CUỐI MÀN)

Mỗi lần qua màn được mở **1 rương** với 1–3 ô thưởng.

### Số ô thưởng
```js
REWARD_COUNT_WEIGHTS = [[1, 45], [2, 35], [3, 20]]
```
| Số ô | Tỉ lệ |
|---|---|
| 1 ô | 45% |
| 2 ô | 35% |
| 3 ô | 20% |

### Bảng quay mỗi ô (`REWARD_POOL`)
| Phần thưởng | Trọng số | Tỉ lệ (~) | Số lượng | Độ hiếm |
|---|---:|---:|---|---|
| Xu | 50 | 44.6% | **Theo màn — xem bảng dưới (bước 10) — MỚI** | Common |
| Mảnh khủng long (ngẫu nhiên) | 25 | 22.3% | 1 | Rare |
| Búa (hammer) | 15 | 13.4% | 1–2 | Uncommon |
| Đổi chỗ (swap) | 10 | 8.9% | 1–2 | Uncommon |
| Rương | 12 | 10.7% | 1 | Rare |

> Tổng trọng số 112.

### Xu tăng theo màn — MỚI

Khi một ô thưởng quay trúng xu, số xu được lấy theo **màn vừa hoàn thành**:

| Màn | Xu / ô trúng xu | Trung bình / ô |
|---|---:|---:|
| 1–10 | 80–160 | 120 |
| 11–25 | 120–240 | 180 |
| 26–50 | 180–360 | 270 |
| 51–75 | 260–520 | 390 |
| 76–100 | 360–720 | 540 |

- Mọi khoảng đều quay theo bước 10 xu.
- Với trung bình **1,75 ô thưởng/màn** và xác suất ô xu **44,6%**, phần xu kỳ vọng lần lượt khoảng **94 / 141 / 211 / 304 / 422 xu mỗi màn** (chưa quy đổi giá trị mảnh, booster và rương).
- Chơi lại màn cũ chỉ nhận **50% số xu** (làm tròn xuống bội số 10); mảnh, booster và rương giữ nguyên tỉ lệ. Luật này ngăn farm màn 1 nhưng vẫn thưởng cho người muốn chơi lại.
- Kết quả vẫn phải được quay và lưu trước hoạt ảnh như luật chống gian lận bên dưới.

### Luật chống gian lận / mất phần thưởng
- Kết quả được **quay và LƯU TRƯỚC khi chạy hoạt ảnh** (khoá `line98_lvreward`).
- Trạng thái giao dịch: `pending` → `granted` → `closed`.
- Tắt app giữa chừng → mở lại sẽ hiện **đúng rương cũ**, **không quay lại** (`restoreLevelReward()`).
- Nhật ký giao dịch ở `line98_lvreward_log`.

---

## 8. RƯƠNG (CHEST)

### 8.1 Các loại rương
| Rương | Giá (xu) | Số ô tối đa | Nội dung |
|---|---:|---:|---|
| **Gold** (`chest_gold`) | **1 500 — MỚI** | 3 | **Chỉ xu**: 300–1 500 (bước 50) |
| **Item** (`chest_item`) | **1 800 — MỚI** | 3 | 1–3 ô booster — tỉ lệ ô: 1 ô 40%, 2 ô 40%, 3 ô 20% |
| **Fragment** (`chest_fragment`) | **3 000 — MỚI** | 3 | **Bảo đảm** 1–3 mảnh khủng long (tính theo từng mảnh) |
| **Mixed** (`chest_mixed`) | **2 400 — MỚI** | 3 | Xu 200–800 (w40) / búa (w20) / swap (w15) / mảnh (w25). Ô: 1 ô 30%, 2 ô 45%, 3 ô 25% |
| **Special** (`chest_special`) | **12 000 — MỚI** | 5 | **Bảo đảm** 2 000–5 000 xu (bước 100) **+ 1 khủng long premium**, kèm 3–5 búa (w55) hoặc 3–5 swap (w45) |

> Khi code hoá, giá trị xu kỳ vọng của rương Gold phải **thấp hơn giá mua** (mục tiêu 65–75% giá) để tránh vòng lặp mua rương sinh lời vô hạn. Rương rơi miễn phí không chịu giới hạn này.

### 8.2 Rương rơi ra từ màn chơi
```js
CHEST_DROP_WEIGHTS = [["chest_gold",35], ["chest_item",30], ["chest_fragment",20], ["chest_mixed",15]]
```
| Rương | Tỉ lệ |
|---|---:|
| Gold | 35% |
| Item | 30% |
| Fragment | 20% |
| Mixed | 15% |

> **Rương Special KHÔNG BAO GIỜ rơi từ màn chơi** — chỉ mua được trong Store.

### 8.3 Kho rương
- Sức chứa kho: **5 rương** (`CHEST_MAX_SLOTS = 5`).
- Khoá lưu: `line98_chests` (kho) và `line98_chest_tx` (giao dịch mở rương).
- **Vào kho rương:** mở **Profile → tab CHESTS** (từ 15/9/2026 — trước đó là nút Chest riêng ngoài màn Home + bảng chọn rương riêng, cả hai đã bỏ). Ô thứ 3 trên biển hiệu Home nay là **Ranking** (chưa có tính năng, bấm chỉ hiện "Coming Soon").
- Popup Profile có 2 tab: **COLLECTION** (lưới dino + bảng chi tiết + nút hành động) và **CHESTS** (5 loại rương, số lượng `x0…`); badge tổng số rương nằm trên nút tab CHESTS.
- Bấm 1 ô rương có hàng → đóng Profile, mở màn mở rương; bấm **X** ở màn mở rương → quay lại đúng tab CHESTS.
- Màn mở rương có nút **OPEN AGAIN** và **CLAIM**; bấm CLAIM → chữ đổi thành **DONE**; bấm DONE → tắt hẳn màn rương.

---

## 9. BOOSTER — BÚA & ĐỔI CHỖ

### 9.1 Danh sách (8 loại)
| ID | Tên | Giá | Trọng số rơi | Miễn phí? | Tác dụng |
|---|---|---:|---:|:---:|---|
| `hammer_basic` | Búa cơ bản | 300 | 40 | ✅ | Phá **1 quả trứng thường** |
| `hammer_stone` | Búa đá | 500 | 15 | — | Phá **1 ô bất kỳ**, kể cả **trứng đá & tường vật cản** |
| `hammer_cross` | Búa chữ thập | 600 | 20 | — | Phá **cả hàng + cả cột** (tối đa 17 ô), **bỏ qua đá** |
| `hammer_harvest` | Búa thu hoạch | 800 | 15 | — | Phá vùng **3×3** — và **TÍNH LÀ ĂN ĐƯỢC** (nuôi lồng ấp + cộng điểm) |
| `hammer_spread` | Búa lan màu | 1 000 | 6 | — | **9 ô xung quanh** đổi sang màu ô đã chọn, rồi kiểm tra hàng |
| `hammer_color` | Búa đồng màu | 1 500 | 4 | — | **Xoá sạch mọi trứng cùng màu** trên bàn |
| `swap_pair` | Đổi chỗ 2 quả | 300 | 70 | ✅ | Hoán vị 2 quả trứng, rồi kiểm tra hàng |
| `swap_shuffle` | Xáo bàn | 600 | 30 | — | **Xáo lại toàn bộ trứng** (tường vật cản giữ nguyên), rồi kiểm tra hàng |

> ⚠️ Chỉ **búa thu hoạch (3×3)** mới nuôi lồng ấp. Các búa khác chỉ dọn bàn, **không cộng điểm, không tính nhiệm vụ**.

### 9.2 Số lần dùng & hồi chiêu
- Khi bắt đầu: `toolUses[id] = free ? 1 : 0` → người chơi luôn có sẵn **1 búa cơ bản + 1 đổi chỗ**.
- **Hồi chiêu:** `TOOL_RECOVERY_MS = 60 × 60 × 1000` → **loại miễn phí hồi 1 lượt dùng mỗi giờ** (tính theo **giờ thật**, chạy cả khi đang pause).
- Loại miễn phí **luôn được sàn tối thiểu 1 lượt dùng** (không bao giờ về 0).
- Lưu ở khoá `line98_tools` (có chuyển đổi dữ liệu cũ dạng `{hammer, swap}`).
- Bảng chọn booster (`#toolPicker`) canh thẳng hàng với HUD.

---

## 10. BỘ SƯU TẬP KHỦNG LONG (MẢNH GHÉP)

| Luật | Giá trị |
|---|---|
| Số khủng long premium | **5** |
| Số mảnh cần để mở khoá 1 con | **8** (`fragmentGoal: 8`) |
| Giá mua thẳng trong Store | **6 000 xu mỗi con — MỚI** (`storePrice: 6000`) |
| Avatar mặc định | `spiderman` |
| Khi đã đủ cả 5 con | Mảnh nhặt được **đổi thành 150 xu** (`fullCoinFallback: 150`) |

### Danh sách
| ID | Loài | Độ hiếm |
|---|---|---|
| `spiderman` | Triceratops | Rare |
| `akatsuki` | Stegosaurus | Epic |
| `batman` | Triceratops | Epic |
| `captain` | T-Rex | Rare |
| `doraemon` | Triceratops | Legendary |

### Nguồn mảnh
Rương · phần thưởng qua màn · vòng quay may mắn → `rollFragment()` → `addFragments()`.

### Trạng thái nút (trong popup Profile)
`FIND MORE` (chưa đủ mảnh) → `UNLOCK` (đủ 8 mảnh) → `SET AVATAR` (đã mở khoá) → `IN USE` (đang dùng).

Giao diện bộ sưu tập được **gộp chung vào popup Profile** (từ 10/09/2026). Khoá lưu: `line98_collection`.

---

## 11. VÒNG QUAY MAY MẮN

| Luật | Giá trị |
|---|---|
| Lượt quay miễn phí mỗi ngày | **1** (`dailyFreeSpins: 1`) |
| Lượt quay thêm | Xem **quảng cáo có thưởng** (timeout 45 giây) |
| Chuỗi điểm danh | **7 ngày** — ngày thứ 7 được **+1 lượt quay** |
| Bỏ lỡ 1 ngày | **Reset chuỗi về 0** (`resetOnMissedDay: true`) |
| Thời gian quay | 4 200 ms, tối thiểu 5 vòng + 0–2 vòng ngẫu nhiên |

### 8 ô thưởng
| Ô | Phần thưởng | Trọng số | Tỉ lệ (~) |
|---|---|---:|---:|
| `coin_small` | 100 xu | 28 | 28% |
| `fragment_1` | 1 mảnh | 16 | 16% |
| `hammer_1` | 1 búa | 14 | 14% |
| `swap_1` | 1 swap | 12 | 12% |
| `coin_large` | 500 xu | 10 | 10% |
| `fragment_2` | 2 mảnh | 8 | 8% |
| `hammer_2` | 2 búa | 7 | 7% |
| `swap_2` | 2 swap | 5 | 5% |

> Tổng trọng số 100 → trọng số = phần trăm.

Khoá lưu: `line98_lucky_wheel` (giữ tối đa 200 ID đã nhận để chống nhận trùng).

---

## 12. CỬA HÀNG & TIỀN TỆ

### Tiền tệ
- Đơn vị duy nhất: **XU (coin)**.
- **Số xu khởi điểm: 500 — MỚI** (`STORE_START_COINS = 500`).
- Khoá lưu: `line98_coins` (xu) và `line98_inv` (kho vật phẩm).

### 5 tab
| Tab | Bán gì |
|---|---|
| **Boosters** | 8 loại búa/swap ở [mục 9](#9-booster--búa--đổi-chỗ) |
| **Chests** | 5 loại rương ở [mục 8](#8-rương-chest) — kể cả Special 8 000 |
| **Coins** | Gói xu nạp tiền thật |
| **Dino** | 5 khủng long premium (**6 000 xu/con — MỚI**) — mua = mở khoá ngay |
| **Pet** | Khủng long nuôi + thức ăn (dòng mua khủng long luôn nằm TRÊN thức ăn) |

### Gói xu (IAP)
| Gói | Số xu | Giá |
|---|---:|---:|
| `coins_s` | 500 | $0.99 |
| `coins_m` | **1 700 — MỚI** | $2.99 |
| `coins_l` | **6 000 — MỚI** | $7.99 |

> Hiện đang dùng **hook IAP giả lập** (placeholder) — cần nối cổng thanh toán thật trước khi phát hành.

### Nguyên tắc cân bằng kinh tế — MỚI

- Không so trực tiếp “bao nhiêu xu” với game khác vì đơn vị tiền là tuỳ ý; so theo **số màn hoặc thời gian chơi cần để mua một món**.
- Ở màn 1–10, một booster cơ bản giá 300 xu tương đương khoảng **3 màn** tiền thưởng kỳ vọng; vật phẩm mạnh cần khoảng **6–17 màn**. Ở màn cao, thu nhập tăng để giá không trở thành bức tường vô lý.
- Một dino premium giá 6 000 xu tương đương khoảng **14 màn cuối** chỉ tính phần xu; đây là mục tiêu dài hạn, còn đường 8 mảnh vẫn có giá trị.
- Farm tối đa 480 xu/ngày chỉ tương đương khoảng **1–5 màn tuỳ chặng**, nên không thay thế việc chơi game.
- Gói IAP lớn phải có bonus rõ: gói M hơn khoảng 12% và gói L hơn khoảng 48% xu/USD so với gói S.
- Đây là bộ số khởi điểm để soft-launch. Theo dõi `coin earned/spent`, số dư theo level, tỉ lệ mua booster, tỉ lệ hết xu và thời gian mở dino; chỉ điều chỉnh sau khi có dữ liệu người chơi thật.

Store là **popup đè lên bản đồ**; đóng bằng nút X, phím Esc, hoặc bấm nền.

---

## 13. HỒ SƠ & DANH HIỆU

| Luật | Giá trị |
|---|---|
| Tên mặc định | `DINO98` |
| Độ dài tên tối đa | **16 ký tự** |
| Khoá lưu | `line98_profile` |

### Danh hiệu (theo checkpoint cao nhất đã mở)
| Danh hiệu | Yêu cầu |
|---|---|
| **Rookie** | Màn ≥ 1 |
| **Hunter** | Màn ≥ 11 |
| **Master** | Màn ≥ 31 |
| **Collector** | Màn ≥ 61 |
| **Legend** | Màn ≥ 91 |

Popup Profile là **một popup gộp: Hồ sơ + Bộ sưu tập**. Bấm ra nền **KHÔNG đóng** popup (phải bấm X).
Avatar chọn từ các khủng long đã mở khoá.

---

## 14. BẢN ĐỒ 100 MÀN

| Luật | Giá trị |
|---|---|
| Tổng số màn | **100** (`MAP_LEVEL_COUNT = 100`) |
| Cấu tạo | 8 ảnh xếp chồng, mỗi ảnh 2048×1024 → tổng 2048×8192 |
| Hướng đi | **Màn 1 ở ĐÁY bản đồ**, leo dần lên trên |
| Khoá tiến độ | `dino-line-98-unlocked-level` |
| Khoá vị trí avatar | `dino-line-98-avatar-level` |

### Luật mở khoá
```js
unlockedMapLevel() = clamp(saved, 1, 100)      // mặc định 1
unlockMapLevel(n)  = max(hiện tại, min(100, n)) // CHỈ TĂNG, không bao giờ tụt
```
- Chỉ bấm vào được checkpoint **≤ màn cao nhất đã mở**.
- Bấm vào checkpoint **đã khoá** → node **rung lắc** báo chưa mở.
- Có thể **chơi lại** bất kỳ màn đã mở (avatar sẽ đi tới đó).
- Avatar khủng long tự động **đi sang checkpoint mới** sau khi qua màn, và bản đồ tự cuộn để checkpoint hiện tại nằm giữa màn hình.

---

## 15. FARM — NUÔI KHỦNG LONG

Màn **FARM toàn màn hình** (thay cho popup Dino Home cũ). Khoá lưu: `line98_dino_home`.

### 15.1 Sinh xu
| Luật | Giá trị |
|---|---|
| Tốc độ sinh xu | **20 xu/giờ, CỐ ĐỊNH — MỚI** (`flatCoinRate: true`) |
| Trần xu tích luỹ | **2 000 xu — MỚI** |
| Thời gian offline tối đa được tính | **24 giờ — MỚI** |

| Thời gian | Xu nhận được |
|---|---:|
| 1 giờ | 20 |
| 6 giờ | 120 |
| 12 giờ | 240 |
| 24 giờ (trần offline) | 480 |

> So với luật cũ, một lần offline tối đa giảm từ **7 200 xu (100 × 72 giờ)** xuống **480 xu (20 × 24 giờ)**, tức giảm **93,3%**. Farm là nguồn phụ để giữ chân người chơi, không được vượt nguồn xu từ chơi màn.

### 15.2 Cho ăn = KÉO – THẢ (từ 14/09/2026)
1. Bấm **FEED** → khay thức ăn trượt lên.
2. **Chạm** một ô thức ăn → **chỉ CHỌN** (viền vàng), **không cho ăn**.
3. **Kéo** ô đó ra → khay lùi xuống; kéo tới đúng khủng long thì **chính con khủng long phóng to nhẹ** báo "thả vào đây" (từ 15/09/2026 **không còn vòng tròn vàng** quanh pet).
4. **Thả trúng khủng long** → mới thật sự cho ăn (trừ 1 món, Health đầy).
   - Thả **hụt** → món bay về ô cũ, **không trừ gì**.
   - Vùng thả được nới rộng **22%** quanh khung khủng long cho dễ trúng.
   - Còn nhiều Health → vẫn hỏi xác nhận **sau khi thả** (xem 15.2 dưới).
5. Ô **hết hàng (x0)** → không nhấc lên kéo được; **chạm** vào để mua bằng xu / xem quảng cáo / mở Store.
6. Bàn phím (Enter/Space) không kéo được → vẫn cho ăn trực tiếp.

### 15.3 Bong bóng xu (từ 15/09/2026)

Cách "vui" để nhận xu, song song với nút **CLAIM**.

| Luật | Giá trị |
|---|---|
| Chạm vào khủng long | Pet nhún một cái + bung ra **1 – 2 bong bóng xà phòng**, mỗi bong bóng có 1 đồng xu bên trong |
| Số xu trong 1 bong bóng | Ngẫu nhiên quanh mức **(số xu đang chờ ÷ 5)**, tối thiểu 1 xu |
| Tổng xu của tất cả bong bóng | **Đúng bằng số xu đang chờ** tại lúc đó (VD 20 xu → khoảng 5 bong bóng, cộng lại = 20) |
| Chạm vào bong bóng | Bong bóng vỡ, hiện **"+n"** bay lên, xu vào ví ngay |
| Bong bóng không ai chạm | Tự vỡ sau **9 giây** — **không mất xu**, phần đó quay lại hàng chờ |
| Tối đa cùng lúc trên màn | **8 bong bóng** |
| Bấm nút **CLAIM** | Nhận hết một lần + dọn sạch bong bóng đang bay (không nhận trùng) |

- Xu **chỉ bị trừ khỏi hàng chờ đúng lúc bong bóng vỡ do người chơi chạm** — đóng màn Farm hay xoay máy đều không mất xu.
- Chỉnh trong `DINO_HOME_CONFIG.farm.coinBubble`: `perTapMin / perTapMax / targetCount / maxOnScreen / lifetimeMs` (lifetime tối thiểu 1 200 ms).

### 15.4 Thức ăn
| Món | Thời gian no | Giá | Số lượng khởi điểm | Gói 3 |
|---|---:|---|---:|---:|
| **BERRY SNACK** | 1 giờ | **5 xu — MỚI** | 5 | **15 xu** |
| **MEAT BOWL** | 6 giờ | **25 xu — MỚI** | 3 | **75 xu** |
| **GIANT STEAK** | 12 giờ | **45 xu — MỚI** (Store) | 1 | **135 xu** |
| **DINO FEAST** | 24 giờ | **Quảng cáo có thưởng** | 0 | **90 xu — MỚI** |

- Giới hạn quảng cáo có thưởng: **5 lần/ngày**.
- Cho ăn khi còn no nhiều (còn > 30% thời gian **và** > 600 giây) → **hỏi xác nhận** trước khi ghi đè (tránh phí thức ăn).

### 15.5 Tâm trạng (theo thanh Health, giảm tuyến tính)
| Health | Tâm trạng |
|---|---|
| ≥ 71% | 😊 **HAPPY** |
| ≥ 40% | 🙂 **NORMAL** |
| < 40% | 😟 **HUNGRY** |

Thanh trạng thái hiện **trên đầu** thú nuôi, đổi màu theo tâm trạng.

### 15.6 Thú nuôi
| ID | Giá | Mặc định có sẵn |
|---|---:|:---:|
| `triceratops` | 1 200 | ✅ (thú mặc định) |
| `trex` | 1 500 | ✅ |

Nền farm đổi theo hướng máy (dọc / ngang). Thanh công cụ **FEED – CLAIM – bảng xu** đặt cách mép trên 5%.

---

## 16. BẢNG XẾP HẠNG NGƯỜI CHƠI THẬT

> **MỚI:** Ranking chỉ hiển thị tài khoản người chơi thật. Không chèn bot, tên giả hoặc điểm giả để lấp bảng.

### Điều kiện tham gia
- Người chơi phải đăng nhập bằng một tài khoản có `userId` duy nhất; tài khoản Guest vẫn chơi được nhưng **không được gửi điểm lên bảng** cho tới khi liên kết tài khoản.
- Tên hiển thị lấy từ Profile, nhưng server lưu và xếp hạng theo `userId` — đổi tên không tạo người chơi mới.
- Mỗi `userId` chỉ có **1 dòng** trên mỗi bảng; chỉ cập nhật khi thành tích mới tốt hơn.

### Các bảng
| Bảng | Xếp hạng chính | Phá hoà |
|---|---|---|
| **Tiến độ** | Màn cao nhất đã hoàn thành | Tổng điểm hợp lệ cao hơn → thời điểm đạt thành tích sớm hơn |
| **Điểm tuần** | Tổng điểm hợp lệ trong tuần | Màn hoàn thành trong tuần nhiều hơn → đạt điểm sớm hơn |

- Có phạm vi **Global** và **Friends** khi hệ thống bạn bè đã sẵn sàng.
- Bảng tuần reset lúc **00:00 UTC thứ Hai**; lưu lịch sử mùa để trao thưởng sau khi khoá kết quả.

### Bắt buộc dùng server
- Không đọc bảng xếp hạng trực tiếp từ `localStorage`. Client gửi sự kiện hoàn thành màn; **server kiểm tra và ghi điểm** rồi mới trả thứ hạng.
- Payload tối thiểu: `userId`, `level`, `scoreDelta`, `durationMs`, `runId`, `buildVersion`, `completedAt` và chữ ký phiên.
- `runId` phải chống gửi trùng; giới hạn tốc độ gửi; từ chối điểm âm, điểm vượt ngưỡng luật chơi, build cũ bị khoá và thời lượng bất khả thi.
- Có cờ review/ban và log audit. Thành tích bị nghi gian lận tạm ẩn khỏi Global trong lúc kiểm tra.
- Nếu offline, lưu hàng đợi sự kiện có chữ ký và đồng bộ khi có mạng; UI ghi rõ **“Chờ đồng bộ”**, không tự coi local score là hạng thật.

---

## 17. BẢNG KHOÁ LƯU (localStorage)

| Khoá | Nội dung |
|---|---|
| `line98_best` | Điểm cao nhất |
| `dino-line-98-unlocked-level` | Màn cao nhất đã mở (1–100) |
| `dino-line-98-avatar-level` | Vị trí avatar trên bản đồ |
| `line98_profile` | Tên người chơi + hồ sơ |
| `line98_coins` | Số xu |
| `line98_inv` | Kho vật phẩm mua trong Store |
| `line98_tools` | Số lần dùng & thời điểm hồi chiêu của booster |
| `line98_chests` | Kho rương |
| `line98_chest_tx` | Giao dịch mở rương |
| `line98_collection` | Mảnh ghép + khủng long đã mở khoá |
| `line98_lvreward` | Phần thưởng qua màn hiện tại |
| `line98_lvreward_log` | Nhật ký phần thưởng qua màn |
| `line98_lucky_wheel` | Vòng quay: lượt quay, chuỗi ngày, ID đã nhận |
| `line98_dino_home` | Farm: thức ăn, xu tích luỹ, thú đang nuôi |

> Toàn bộ đi qua `SaveManager` — nếu trình duyệt chặn localStorage, game vẫn chạy được (dữ liệu chỉ giữ trong phiên).

---

## 18. BẢNG TRA NHANH MỌI HẰNG SỐ

```js
/* ===== BÀN CỜ ===== */
SIZE              = 9         // bàn 9x9
NCOLOR            = 7         // 7 màu chơi được
GRAY              = 7         // index màu trứng đá
OBST              = -2        // ô vật cản cố định
SPAWN             = 3         // trứng sinh mỗi lượt
LINE              = 5         // độ dài hàng tối thiểu

/* ===== LỒNG ẤP ===== */
HATCH_RATE        = 0.20      // MỚI: 20% nở; pity quả thứ 8
PITY              = 8         // 7 quả ung -> quả thứ 8 chắc nở
GRAY_RATE         = 0.30      // MỚI: 30% trứng xám khi màn còn cần vật cản
HARD_LEVELS       = {2:1, 5:2, 10:3, 20:4, 40:5, 70:6, 99:7}

/* ===== NHIỆM VỤ ===== */
total             = level     // màn N = N con
nTypes            = level>=3 ? 2 : 1

/* ===== ĐIỂM ===== */
điểm              = số trứng vỡ (1 quả = 1 điểm, không combo)

/* ===== PHẦN THƯỞNG QUA MÀN ===== */
REWARD_COUNT_WEIGHTS = [[1,45],[2,35],[3,20]]
REWARD_POOL tổng trọng số = 112 (xu 50 / mảnh 25 / búa 15 / rương 12 / swap 10)
xu/ô theo màn     = 80–160 / 120–240 / 180–360 / 260–520 / 360–720
replayCoinRate    = 0.50      // chơi lại màn cũ nhận 50% xu

/* ===== RƯƠNG ===== */
CHEST_MAX_SLOTS   = 5
CHEST_DROP_WEIGHTS = gold 35 / item 30 / fragment 20 / mixed 15  (special KHÔNG rơi)

/* ===== BOOSTER ===== */
TOOL_RECOVERY_MS  = 3_600_000  // 1 giờ/lượt, chỉ loại free
miễn phí          = hammer_basic, swap_pair (luôn tối thiểu 1 lượt)

/* ===== BỘ SƯU TẬP ===== */
fragmentGoal      = 8         // 8 mảnh = 1 khủng long
fullCoinFallback  = 150       // đủ cả 5 con -> mảnh đổi 150 xu
storePrice        = 6000      // MỚI: giá mua thẳng 1 dino premium

/* ===== VÒNG QUAY ===== */
dailyFreeSpins    = 1
streakDays        = 7         // ngày 7 = +1 lượt
adTimeoutMs       = 45_000

/* ===== STORE ===== */
STORE_START_COINS = 500       // MỚI

/* ===== DANH HIỆU ===== */
Rookie 1 / Hunter 11 / Master 31 / Collector 61 / Legend 91

/* ===== BẢN ĐỒ ===== */
MAP_LEVEL_COUNT   = 100

/* ===== FARM ===== */
baseCoinsPerHour  = 20 (flatCoinRate = true) // MỚI
pendingCoinsCap   = 2_000     // MỚI
maxOfflineHours   = 24        // MỚI
mood              = HAPPY ≥71% / NORMAL ≥40% / HUNGRY <40%
```

---

## ⚠️ CẢNH BÁO TRƯỚC KHI PHÁT HÀNH

| Mục | Vấn đề |
|---|---|
| Đồng bộ code | Các giá trị **MỚI** trong tài liệu (`HATCH_RATE`, `GRAY_RATE`, reward xu, giá Store và Farm) phải được cập nhật vào config/build trước khi phát hành. |
| Gói xu IAP | Đang là **hook giả lập**, chưa nối cổng thanh toán. |
| Quảng cáo có thưởng | `RewardedAdService` là mock — **không được để mock ads trong bản phát hành**. |
| Ranking thật | Cần backend xác thực, lưu thành tích phía server và chống gian lận; `localStorage` không đủ để vận hành bảng xếp hạng thật. |

---

*File này chỉ mô tả LUẬT CHƠI. Chi tiết kỹ thuật (layout, asset, build pipeline, test) nằm ở thư mục memory và các script `test_*.py`.*
