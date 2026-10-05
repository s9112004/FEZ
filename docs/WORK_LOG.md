# 開發工作日誌

所有日期以 Asia/Taipei 記錄。記錄可觀察的工作與結果；不包含未執行的測試或虛構的網頁研究。

## 2026-10-06 — 接手與設計

- 檢查 /workspace/FEZ：只有移動與原創角色/戰場視覺；Git 尚無提交，現有檔案皆未追蹤，保留。
- 保存製作人指令：PROJECT_CHARTER.md；建立 AGENTS.md 與 GAME_DESIGN_OVERVIEW.md。
- 檢查工具：沒有可操作 Browser/Computer Use。Godot 可用；沒有 xvfb-run。
- 查找官方、維基、巴哈：均 403，沒有看到網站內容。以既有玩法知識建立標示未查證的設計脈絡，開發不依賴參考圖。
- 實作順序：鏡頭與移動 → 共用戰鬥/死亡重生 → 19 AI/據點/HUD → 功能測試與視覺可執行性驗證。

### 增量 A — 玩家與共用戰鬥

- 增加第三人稱軌道鏡頭（滑鼠/縮放）、相對鏡頭移動與控制器意圖介面。
- UnitBody 增加陣營、HP、冷卻、死亡與重生方法、原創角色陣營材質與頭頂血量。
- Stronghold 與 CombatSystem 分開，玩家/AI 共用距離、朝向、友傷排除與傷害規則。
- 預備比賽組裝與功能測試；尚未宣稱可玩或測試通过。

### 增量 B — AI、據點與 HUD；第一次驗證

- 組裝 20 個角色（玩家 + 19 AI）、雙方據點、目標標記、攻擊圈與 HUD。
- `godot --headless --path . --quit-after 180`：MATCH START 正確，無腳本錯誤。
- 舊移動 smoke：通過移動、地面、邊界與斜向速度。
- `tests/battle_smoke.gd`：26 項通過、0 失敗；包含玩家控制、友傷、距離/朝向、冷卻、死亡/重生、據點傷害、勝敗與終局停止。
- 第一次完整 AI 模擬失敗：300 模擬秒、665 死亡、656 重生、據點傷害 0，未結束。原因：所有 AI 優先追逐中央敵人，形成無限戰線。
- 修正設計：每方 4 名側翼突擊，走不同側路，僅處理近身敵人；其餘保持正面進攻。不降低測試要求，也不以自動扣據點血量代替 AI 進攻。

### AI 失敗追查與圖形驗證

- 縮小突擊 AI 尋敵範圍、保留路線目標後仍未結束：300 秒，578 死亡/571 重生，據點傷害 516。
- 改為側路到敵方後方，仍未結束：542 死亡/535 重生，據點傷害 68。
- 診斷逐段單位位置、目標與側路階段：正面 AI 的 18 公尺尋敵使其過早追逐側翼；突擊遭追擊時朝向前路，普攻无法命中身後敵人。
- 修正：近身攻擊時面向目標；正面尋敵半徑縮至 8，突擊為 3；突擊到敵方後方再切据點，接近據點優先攻擊據點。
- 最終整場模擬通過：47.2 模擬秒、73 死亡、65 重生、据點總傷害 1996、藍方勝利。使用实际 19 AI 與閒置玩家，未以自動扣血或降低測試要求讓它通過。
- 圖形工具：無 Xvfb，但既有 Xorg 與 dummy driver 可用；啟動 :99，不開 TCP 連線。Godot 使用 Mesa llvmpipe 成功呈現並保存截圖。
- 實際查看第一張截圖發現己方石堡遮擋出生鏡頭；將 slot 0 出生設為中線較前方，重新截圖確認角色與戰場清楚可見。
- 圖形 driver 只回報無法設定 V-Sync 的 warning，沒有 script/runtime error；目前為軟體渲染，不據此宣稱 50 vs 50 效能。
- 輸入測試初次 6/7 通過：勝利 HUD 取樣早於 _process。SceneTree.process_frame 發出在節點更新前；改等完整一個更新週期後驗證 UI，保留顯示檢查。

### 最終驗證與交付

- `bash scripts/verify.sh`：退出 0，Godot import 無 ERROR；移動 smoke 通過；戰鬥 26/26、輸入/HUD/重開 7/7；19 AI 整場模擬通過，47.2 模擬秒產生藍方勝利。
- 真實輸入測試透過 Input.parse_input_event 發送 W、Tab、Q、左鍵、R，驗證移動、鎖定、技能、普攻、勝利 HUD 與重新載入場景；不是只直接呼叫傷害方法。
- 圖形版測試實際發送滑鼠移動事件，驗證 camera yaw 改變；PASS: graphical mouse orbit input，截圖保存退出 0。
- 日誌副本：docs/validation/verify.log、battle-simulation.log、visual.log；截圖：docs/screenshots/prototype.png。
- 新增 verify.sh：保留原始命令退出狀態，另掃描 Godot SCRIPT ERROR/ERROR，避免 import 退出 0 的假成功。
- 儲存環境草稿 install_script（版本檢查與完整驗證）、start_skill（專案宗旨、啟動、headless 與圖形指引）。工具已確認 saved；尚未發布，尚未驗證新任務恢復。
- 限制：網頁來源尚未查證、無音樂/音效/骨架動畫、平地只有地板碰撞、無鏡頭地形避障。無真人手感測試或 50 vs 50 效能證據。後續先打磨核心戰鬥，再加入後續系統。
- 保留既有檔案，未刪除資料；Git 尚無提交，專案檔案為未追蹤，未自行推送或建立 PR。

## 2026-10-06 — 準備 GitHub 交付

- 製作人授權：先推上 GitHub，再於本機下載與安裝。
- 查核 origin 為 github.com/s9112004/FEZ；git ls-remote 成功但沒有 refs，遠端尚空。
- 本地 work 分支為未提交狀態，改名 main，準備首次提交。
- 交付包含 Godot 專案、原創素材、設計/工作宗旨/日誌、測試與截圖；排除 .godot/ 快取。
- 遊戲程式未再變更，沿用上一輪已通過的完整驗證結果。
- 首次提交 ae6101e 成功推送至 origin/main，已設定追蹤分支；遠端 main 與本地提交一致。
- GitHub 本機下載入口：https://github.com/s9112004/FEZ/archive/refs/heads/main.zip 。解壓後使用 Godot 4.6.3 匯入 project.godot，按 F5。
