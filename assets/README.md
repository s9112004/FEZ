# 原創原型素材

依最新決定，先使用本專案自行製作的低多邊形素材，不需要下載外部素材。

- `characters/sentinel.tscn`：目前使用的原創人形守衛，含關節節點、護甲、頭部、披風、劍盾；程序走路、攻擊、施法與待機由 scripts/visuals/sentinel_visual.gd 驅動。
- `characters/scout.tscn`：保留的第一版藍色斥候，含盔甲、頭盔、盾與劍的幾何模型。獨立視覺場景，尚無骨架動畫。
- `environment/arena_visual.tscn`：中央道路、藍紅旗幟、石堡與岩石。石堡對應據點中心，由 Stronghold 管理 HP 與勝負；裝飾幾何本身沒有碰撞。
- `audio/`、`ui/`：預留未來素材位置；目前未加入音樂或音效。

角色模型朝向本地 -Z，原點位於腳底，約 1.8 公尺高。藍紅隊共用模型，以獨立材質區別陣營。替換時維持此約定。
`UnitBody` 負責碰撞與移動，`Visual` 子節點負責外觀與朝向；視覺素材不含戰鬥邏輯。

全部模型由本專案的 BoxMesh、CylinderMesh、SphereMesh 與自訂材質構成；沒有下載或匯入原作素材。
未來若使用外部素材，記錄來源、作者、使用條件、下載日期與 SHA-256。
