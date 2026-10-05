# 霧境前線 / Mistfront

原創單機 3D 國戰原型，Godot **4.6.3**。目前 10 vs 10：1 名玩家、19 AI、第三人稱鏡頭、普攻、範圍技能、HP、死亡重生、據點與勝敗 HUD。

## 第二版改善

原創人形守衛：待機、走路、揮劍、施法、受擊與倒下動作；頭頂血條、傷害數字、劍光、衝擊波、小地圖、雙方據點條與技能冷卻提示。
HP 提高至 180，普攻 18、技能 28，受擊後 0.4 秒保護。重生後有 2 秒保護，出手即解除。空白鍵閃避可用來脫離集火。

![第二版技能回饋（場景內配置近戰展示）](docs/screenshots/combat-feedback.png)

## 啟動

使用 Godot 開啟 `project.godot`，按 F5。或在專案根目錄執行：

```sh
godot --path .
```

| 操作 | 功能 |
| --- | --- |
| WASD / 方向鍵 | 相對鏡頭移動 |
| 滑鼠 / 滾輪 | 旋轉鏡頭 / 縮放 |
| 左鍵 | 普攻，可按住 |
| 空白鍵 | 短距離閃避，2 秒冷卻 |
| Q | 範圍震盪斬，5 秒冷卻 |
| Tab | 切換範圍內敵方鎖定目標 |
| Esc / 點擊 | 釋放 / 捕捉滑鼠 |
| R / 結局按鈕 | 重開戰場 |

玩家屬藍方；摧毀紅方據點即勝利，藍方據點被摧毀即失敗。死亡 4 秒後復活。

## 驗證

```sh
bash scripts/verify.sh
```

驗證匯入、移動、戰鬥規則、動作/特效生命週期、輸入事件/HUD/重開，並執行最長 300 模擬秒的 19 AI 對戰（玩家閒置）。日誌保存於腳本輸出的 /tmp 目錄。無介面測試不等於真人遊玩平衡評估。

可選圖形測試（需要可用 DISPLAY）：

```sh
godot --audio-driver Dummy --path . --script tests/visual_capture.gd
```

雲端截圖保存到 `/workspace/validation-logs/mistfront-prototype.png`。Godot 若無法寫入使用者設定，將 XDG_CONFIG_HOME、XDG_CACHE_HOME、XDG_DATA_HOME 指向可寫目錄；驗證腳本預設使用 /workspace。

## 文件

- [工作宗旨](docs/PROJECT_CHARTER.md)：製作人的完整授權與工作原則。
- [設計概覽](docs/GAME_DESIGN_OVERVIEW.md)：原創規則與標示未查證的研究脈絡。
- [架構](docs/architecture.md)：模組責任、擴充到 50 vs 50 的準備與限制。
- [工作日誌](docs/WORK_LOG.md)：實作、測試、失敗與修正過程。

## 目前限制

原創低多邊形模型與程序關節動畫；尚無正式美術、骨骼蒙皮動畫、音效或音樂。場地為平地，装飾不阻擋移動；鏡頭尚無地形避障。AI 為正面戰線與側翼突擊，尚無完整小隊/指揮系統。50 vs 50、職業、領域與戰役尚未實作。
