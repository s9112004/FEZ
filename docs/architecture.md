# 專案架構

先讀 PROJECT_CHARTER.md。遊戲名稱：霧境前線 / Mistfront；Godot 4.6.3、GDScript、單機 3D、Compatibility renderer。

| 路徑 | 責任 |
| --- | --- |
| scenes/battle/battle.tscn | 戰場入口 |
| scripts/battle/battle_world.gd | 比賽組裝、單位登錄、出生/重生、勝負、集中尋敵與鎖定 |
| scripts/core/battle_config.gd | 人口與比賽參數，預設每方 10；每方最多 50 是配置上限，不是效能保證 |
| scripts/actors/unit_body.gd | 移動物理、HP/生命週期、朝向；不直接讀玩家輸入 |
| scripts/actors/stronghold.gd | 據點生命值與摧毀事件 |
| scripts/combat/combat_system.gd | 共用普攻/技能、距離、冷卻、朝向、友傷規則 |
| scripts/controllers | 玩家输入、軌道鏡頭、AI 意圖；不直接改 HP |
| scripts/ui | 血量、戰況、目標、冷卻、結果與小地圖 |
| scripts/visuals | 原創人形程序關節動畫、揮劍軌跡與衝擊波特效 |
| assets | 原創角色與戰場裝飾，與遊戲邏輯分開 |
| tests | 真實場景功能、輸入、AI 全場模擬、圖形截圖 |
| scripts/verify.sh | 匯入與必要測試；檢查退出狀態及 Godot error log |

## 目前資料流

輸入/AI → 移動意圖與攻擊請求 → UnitBody/CombatSystem → 傷害/死亡事件 → BattleWorld 排程重生或終局 → HUD。

生命週期由同一批 20 個角色重用，死亡角色停止移動/攻擊；據點摧毀後停戰與停止重生。R 重新載入戰場，避免殘留單位、計時器或結果。

AI 敌人查詢每 0.2 秒錯峰執行，使用中央快取列表，不每幀掃場景樹。每幀軟分離仍是 O(N²)，50 vs 50 前必須量測並考慮空間索引/分批更新。現場為無障礙平地，只有地板碰撞，石堡/岩石是裝飾；新增障礙時導入導航網格與鏡頭避障。

## 後續分拆時機

- 三職業前：把普攻/技能數值與效果拆成 Resource，降低 CombatSystem 的常數耦合。
- 資源/領域前：由 BattleWorld 拆出 MatchDirector 與 UnitRegistry，領域與建築独立服務。
- 大地圖前：空間查詢、導航、AI 小隊/指揮與效能 profiler。
- 現階段不預先引入 ECS、多執行緒或連線系統。

第一個里程碑已具備戰鬥閉環；已有基本程序動畫；正式骨骼蒙皮動畫、音樂、複雜地形與 50 vs 50 效能尚未完成。
