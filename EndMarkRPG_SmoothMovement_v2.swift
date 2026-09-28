import SwiftUI
import Combine

// ============================================================
// MARK: - 基本データ
// ============================================================

enum Element: String, CaseIterable, Codable {
    case normal = "無"
    case fire = "炎"
    case ice = "氷"
    case thunder = "雷"
    case dark = "闇"
    case light = "光"
}

enum Job: String, CaseIterable, Codable {
    case hero = "勇者"
    case warrior = "戦士"
    case mage = "魔法使い"
    case priest = "僧侶"
    case thief = "盗賊"
    case knight = "騎士"
    case ranger = "狩人"
}

// ============================================================
// MARK: - スキル
// ============================================================

struct Skill: Identifiable {
    let id: Int
    let name: String
    let element: Element
    let basePower: Int
    let mpCost: Int
}

// ============================================================
// MARK: - 武器
// ============================================================

struct Weapon: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let attack: Int
    let price: Int
    let rarity: String
}

// ============================================================
// MARK: - 敵
// ============================================================

struct Enemy: Identifiable {
    let id: Int
    let name: String
    let level: Int
    let hp: Int
    let attack: Int
    let defense: Int
    let exp: Int
    let gold: Int
    let element: Element

    let dropWeaponID: Int?
}

// ============================================================
// MARK: - 仲間
// ============================================================

struct Ally: Identifiable, Codable {
    let id: Int
    let name: String
    let job: Job

    var level: Int
    var hp: Int
    var maxHP: Int
    var attack: Int
    var defense: Int

    var active: Bool
    var weaponID: Int?
}

// ============================================================
// MARK: - NPC
// ============================================================

struct NPC: Identifiable {
    let id: Int
    let name: String
    let x: Int
    let y: Int
    let message: String
    let questText: String
}

// ============================================================
// MARK: - 宝箱
// ============================================================

struct Treasure: Identifiable {
    let id: Int
    let x: Int
    let y: Int
    let gold: Int
    let item: String
    let weaponID: Int?
    var opened: Bool
}

// ============================================================
// MARK: - ステージ
// ============================================================

struct StageInfo: Identifiable {
    let id: Int
    let name: String
    let description: String
    let boss: String
}

// ============================================================
// MARK: - セーブデータ
// ============================================================

struct SaveData: Codable {

    var level: Int
    var exp: Int
    var gold: Int

    var hp: Int
    var maxHP: Int

    var mp: Int
    var maxMP: Int

    var attack: Int
    var defense: Int

    var job: Job

    var playerX: Int
    var playerY: Int

    var currentStage: Int
    var storyProgress: Int

    var questAccepted: Bool
    var questCompleted: Bool
    var defeatedEnemies: Int

    var ownedWeaponIDs: [Int]
    var equippedWeaponID: Int?

    var allies: [Ally]

    var openedTreasureIDs: [Int]
}

// ============================================================
// MARK: - プレイヤー
// ============================================================

final class Player: ObservableObject {

    @Published var level = 1
    @Published var exp = 0
    @Published var gold = 100

    @Published var hp = 120
    @Published var maxHP = 120

    @Published var mp = 50
    @Published var maxMP = 50

    @Published var attack = 18
    @Published var defense = 10

    @Published var job: Job = .hero

    @Published var skills: [Skill] = []

    @Published var equippedWeaponID: Int? = nil

    @Published var ownedWeaponIDs: [Int] = [0]

    func expRequired() -> Int {
        return 80 + level * 45
    }

    func gainExp(_ amount: Int) -> Bool {

        exp += amount

        var leveled = false

        while exp >= expRequired() {

            exp -= expRequired()

            level += 1

            maxHP += 18
            hp = maxHP

            maxMP += 6
            mp = maxMP

            attack += 4
            defense += 2

            leveled = true
        }

        return leveled
    }

    func skillPower(_ skill: Skill) -> Int {
        return skill.basePower + level * 4
    }
}

// ============================================================
// MARK: - ゲーム本体
// ============================================================

enum MovementDirection {
    case up
    case down
    case left
    case right
}

final class RPGGame: ObservableObject {

    @Published var player = Player()

    // ワールド
    let worldWidth = 80
    let worldHeight = 80

    // 論理座標（セーブ・イベント判定用）
    @Published var playerX = 40
    @Published var playerY = 40

    // 表示座標（小数で連続移動するための座標）
    @Published var cameraX: CGFloat = 40
    @Published var cameraY: CGFloat = 40

    @Published var movementDirection: MovementDirection? = nil

    private var movementTimer: Timer?
    private var lastMovementTime = Date()
    private let movementSpeed: CGFloat = 4.5

    // ステージ
    @Published var currentStage = 1
    @Published var storyProgress = 0

    // 会話
    @Published var dialogueTitle = ""
    @Published var dialogueText = ""
    @Published var showingDialogue = false

    // 戦闘
    @Published var inBattle = false
    @Published var currentEnemy: Enemy?
    @Published var battleLog = ""

    // クエスト
    @Published var questAccepted = false
    @Published var questCompleted = false
    @Published var defeatedEnemies = 0

    // 宝箱
    @Published var treasures: [Treasure] = []

    // 仲間
    @Published var allies: [Ally] = []

    // メニュー
    @Published var showingGoddess = false
    @Published var showingCamp = false
    @Published var showingShop = false
    @Published var showingEquipment = false

    // 武器
    let weapons: [Weapon]

    // 敵
    let enemies: [Enemy]

    // スキル
    let skills: [Skill]

    // NPC
    let npcs: [NPC]

    // ステージ
    let stages: [StageInfo]

    init() {

        // ====================================================
        // 武器
        // ====================================================

        self.weapons = [

            Weapon(
                id: 0,
                name: "木の剣",
                attack: 0,
                price: 0,
                rarity: "初期"
            ),

            Weapon(
                id: 1,
                name: "鉄の剣",
                attack: 12,
                price: 300,
                rarity: "普通"
            ),

            Weapon(
                id: 2,
                name: "鋼の剣",
                attack: 25,
                price: 900,
                rarity: "普通"
            ),

            Weapon(
                id: 3,
                name: "炎の剣",
                attack: 42,
                price: 1800,
                rarity: "レア"
            ),

            Weapon(
                id: 4,
                name: "氷晶剣",
                attack: 55,
                price: 3000,
                rarity: "レア"
            ),

            Weapon(
                id: 5,
                name: "雷鳴剣",
                attack: 70,
                price: 5000,
                rarity: "超レア"
            ),

            Weapon(
                id: 6,
                name: "聖剣",
                attack: 100,
                price: 9000,
                rarity: "伝説"
            ),

            Weapon(
                id: 7,
                name: "魔王殺し",
                attack: 150,
                price: 0,
                rarity: "伝説"
            )
        ]

        // ====================================================
        // スキル600個
        // ====================================================

        var generatedSkills: [Skill] = []

        let prefixes = [
            "炎の",
            "氷の",
            "雷の",
            "闇の",
            "光の",
            "疾風の",
            "大地の",
            "星の",
            "聖なる",
            "破壊の",
            "絶望の",
            "終焉の"
        ]

        let names = [
            "斬撃",
            "衝撃",
            "矢",
            "波動",
            "爆裂",
            "連撃",
            "咆哮",
            "槍撃",
            "魔弾",
            "閃光",
            "呪撃",
            "剣舞"
        ]

        for i in 0..<600 {

            let skill = Skill(
                id: i,
                name: "\(prefixes[i % prefixes.count])\(names[i % names.count]) \(i + 1)",
                element: Element.allCases[i % Element.allCases.count],
                basePower: 15 + i % 80,
                mpCost: 3 + i % 20
            )

            generatedSkills.append(skill)
        }

        self.skills = generatedSkills

        // ====================================================
        // 敵500種類
        // ====================================================

        var generatedEnemies: [Enemy] = []

        let enemyNames = [
            "スライム",
            "ゴブリン",
            "オオカミ",
            "ゾンビ",
            "スケルトン",
            "オーク",
            "ドラゴン",
            "デーモン",
            "魔人",
            "巨人",
            "死神",
            "古代兵"
        ]

        for i in 0..<500 {

            let level = max(1, i / 12 + 1)

            let possibleDrop: Int?

            if i % 7 == 0 {
                possibleDrop = 1
            } else if i % 17 == 0 {
                possibleDrop = 2
            } else if i % 41 == 0 {
                possibleDrop = 3
            } else if i % 67 == 0 {
                possibleDrop = 4
            } else if i % 103 == 0 {
                possibleDrop = 5
            } else {
                possibleDrop = nil
            }

            let enemy = Enemy(
                id: i,
                name: "\(enemyNames[i % enemyNames.count])・\(i + 1)",
                level: level,
                hp: 50 + level * 15,
                attack: 8 + level * 3,
                defense: 4 + level * 2,
                exp: 20 + level * 12,
                gold: 10 + level * 8,
                element: Element.allCases[i % Element.allCases.count],
                dropWeaponID: possibleDrop
            )

            generatedEnemies.append(enemy)
        }

        self.enemies = generatedEnemies

        // ====================================================
        // ステージ40
        // ====================================================

        let stageNames = [
            "始まりの街",
            "始まりの街道",
            "緑の平原",
            "魔物の森",
            "古代遺跡",
            "小さな村",
            "王都への街道",
            "王都",
            "王都地下水路",
            "盗賊のアジト",
            "深緑の森",
            "巨大湖",
            "水晶洞窟",
            "山岳街道",
            "天空へ続く塔",
            "炎の山",
            "灼熱の砂漠",
            "砂漠の街",
            "地下神殿",
            "忘れられた墓地",
            "氷結大地",
            "氷の城",
            "白銀の森",
            "魔族領入口",
            "魔族領街道",
            "魔族の街",
            "黒い森",
            "暗黒洞窟",
            "魔王軍要塞",
            "要塞地下",
            "空中庭園",
            "天空遺跡",
            "星降る大地",
            "世界樹",
            "世界樹内部",
            "海底都市",
            "海底遺跡",
            "終焉への道",
            "魔王城",
            "終焉の間"
        ]

        var generatedStages: [StageInfo] = []

        for i in 0..<40 {

            generatedStages.append(
                StageInfo(
                    id: i + 1,
                    name: stageNames[i],
                    description: "第\(i + 1)エリア。",
                    boss: i == 39
                    ? "終焉の魔王"
                    : "エリアボス \(i + 1)"
                )
            )
        }

        self.stages = generatedStages

        // ====================================================
        // NPC
        // ====================================================

        self.npcs = [

            NPC(
                id: 1,
                name: "村長",
                x: 42,
                y: 40,
                message: "この世界には大きな闇が迫っている。",
                questText: "魔物を3体倒してくれ。"
            ),

            NPC(
                id: 2,
                name: "謎の少女",
                x: 48,
                y: 45,
                message: "あなた……その紋章を持っているのね。",
                questText: "古代遺跡に眠る宝を探して。"
            ),

            NPC(
                id: 3,
                name: "老騎士",
                x: 35,
                y: 42,
                message: "魔王軍は王都へ近づいている。",
                questText: "北の街道を突破せよ。"
            )
        ]

        // ====================================================
        // 仲間
        // ====================================================

        self.allies = [

            Ally(
                id: 1,
                name: "リゼット",
                job: .mage,
                level: 1,
                hp: 70,
                maxHP: 70,
                attack: 10,
                defense: 5,
                active: true,
                weaponID: nil
            ),

            Ally(
                id: 2,
                name: "カイル",
                job: .warrior,
                level: 1,
                hp: 100,
                maxHP: 100,
                attack: 20,
                defense: 12,
                active: false,
                weaponID: nil
            ),

            Ally(
                id: 3,
                name: "シエラ",
                job: .priest,
                level: 1,
                hp: 75,
                maxHP: 75,
                attack: 8,
                defense: 7,
                active: false,
                weaponID: nil
            ),

            Ally(
                id: 4,
                name: "ゼノ",
                job: .thief,
                level: 1,
                hp: 80,
                maxHP: 80,
                attack: 17,
                defense: 8,
                active: false,
                weaponID: nil
            ),

            Ally(
                id: 5,
                name: "アルト",
                job: .knight,
                level: 1,
                hp: 120,
                maxHP: 120,
                attack: 15,
                defense: 18,
                active: false,
                weaponID: nil
            ),

            Ally(
                id: 6,
                name: "紗夜",
                job: .ranger,
                level: 1,
                hp: 85,
                maxHP: 85,
                attack: 18,
                defense: 9,
                active: false,
                weaponID: nil
            )
        ]

        // ====================================================
        // 宝箱
        // ====================================================

        self.treasures = [

            Treasure(
                id: 1,
                x: 44,
                y: 42,
                gold: 100,
                item: "薬草",
                weaponID: nil,
                opened: false
            ),

            Treasure(
                id: 2,
                x: 50,
                y: 48,
                gold: 250,
                item: "鉄の剣",
                weaponID: 1,
                opened: false
            ),

            Treasure(
                id: 3,
                x: 32,
                y: 38,
                gold: 500,
                item: "鋼の剣",
                weaponID: 2,
                opened: false
            )
        ]

        // 初期スキル
        player.skills = Array(generatedSkills.prefix(8))

        startMovementLoop()
    }

    deinit {
        movementTimer?.invalidate()
    }

    // ========================================================
    // MARK: なめらかな移動
    // ========================================================

    private func startMovementLoop() {
        movementTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in
            self?.updateContinuousMovement()
        }
    }

    func setMovementDirection(_ direction: MovementDirection?) {
        if inBattle {
            movementDirection = nil
            return
        }

        movementDirection = direction
        lastMovementTime = Date()
    }

    private func updateContinuousMovement() {
        guard !inBattle, let direction = movementDirection else {
            lastMovementTime = Date()
            return
        }

        let now = Date()
        let deltaTime = min(0.05, max(0, now.timeIntervalSince(lastMovementTime)))
        lastMovementTime = now

        var dx: CGFloat = 0
        var dy: CGFloat = 0

        switch direction {
        case .up:
            dy = -movementSpeed * CGFloat(deltaTime)
        case .down:
            dy = movementSpeed * CGFloat(deltaTime)
        case .left:
            dx = -movementSpeed * CGFloat(deltaTime)
        case .right:
            dx = movementSpeed * CGFloat(deltaTime)
        }

        let nextX = min(CGFloat(worldWidth - 1), max(0, cameraX + dx))
        let nextY = min(CGFloat(worldHeight - 1), max(0, cameraY + dy))

        // 壁・マップ端に当たったらそこで止める
        if nextX != cameraX || nextY != cameraY {
            cameraX = nextX
            cameraY = nextY
        }

        // 表示上のカメラ位置から現在マスを更新
        let newPlayerX = Int(floor(cameraX + 0.5))
        let newPlayerY = Int(floor(cameraY + 0.5))

        if newPlayerX != playerX || newPlayerY != playerY {
            playerX = newPlayerX
            playerY = newPlayerY

            checkLocations()
            checkTreasure()
            checkNPC()

            if Int.random(in: 1...100) <= 8 {
                startRandomBattle()
            }

            updateStage()
        }
    }

    // 旧 move API も残しておく（既存処理との互換用）
    func move(dx: Int, dy: Int) {
        guard !inBattle else { return }

        let direction: MovementDirection?

        if dx > 0 {
            direction = .right
        } else if dx < 0 {
            direction = .left
        } else if dy > 0 {
            direction = .down
        } else if dy < 0 {
            direction = .up
        } else {
            direction = nil
        }

        setMovementDirection(direction)
    }

    // ========================================================
    // MARK: 装備攻撃力
    // ========================================================

    var totalAttack: Int {

        let weaponAttack = equippedWeapon()?.attack ?? 0

        return player.attack + weaponAttack
    }

    func equippedWeapon() -> Weapon? {

        guard let id = player.equippedWeaponID else {
            return weapons.first
        }

        return weapons.first {
            $0.id == id
        }
    }


    // ========================================================
    // MARK: 場所チェック
    // ========================================================

    func checkLocations() {

        // 女神像
        if playerX == 40 && playerY == 40 {
            showDialogue(
                title: "女神像",
                text: "ここには女神像がある。"
            )
        }

        // キャンプ
        if playerX == 45 && playerY == 40 {
            showDialogue(
                title: "キャンプ",
                text: "ここなら安全に休めそうだ。"
            )
        }

        // 武器屋
        if playerX == 35 && playerY == 40 {
            showDialogue(
                title: "武器屋",
                text: "武器を購入できる。"
            )
        }
    }

    // ========================================================
    // MARK: ステージ
    // ========================================================

    func updateStage() {

        let newStage = min(
            40,
            max(1, 1 + storyProgress / 3)
        )

        if newStage > currentStage {

            currentStage = newStage

            // ストーリー進行武器
            storyWeaponReward()

            showDialogue(
                title: "ステージ進行",
                text:
                    "第\(currentStage)ステージ\n" +
                    stages[currentStage - 1].name
            )
        }
    }

    func storyWeaponReward() {

        var weaponID: Int?

        switch currentStage {

        case 5:
            weaponID = 1

        case 10:
            weaponID = 2

        case 16:
            weaponID = 3

        case 22:
            weaponID = 4

        case 30:
            weaponID = 5

        case 40:
            weaponID = 7

        default:
            break
        }

        if let id = weaponID {
            obtainWeapon(id)
        }
    }

    // ========================================================
    // MARK: NPC
    // ========================================================

    func checkNPC() {

        for npc in npcs {

            let distance =
                abs(npc.x - playerX) +
                abs(npc.y - playerY)

            if distance <= 1 {

                showDialogue(
                    title: npc.name,
                    text:
                        npc.message +
                        "\n\nクエスト\n" +
                        npc.questText
                )

                return
            }
        }
    }

    func acceptQuest() {

        questAccepted = true

        showDialogue(
            title: "クエスト受注",
            text: "魔物を3体倒そう！"
        )
    }

    // ========================================================
    // MARK: 宝箱
    // ========================================================

    func checkTreasure() {

        for index in treasures.indices {

            if treasures[index].opened {
                continue
            }

            if treasures[index].x == playerX &&
                treasures[index].y == playerY {

                treasures[index].opened = true

                player.gold += treasures[index].gold

                var text =
                    "\(treasures[index].gold)Gを手に入れた！"

                if let weaponID = treasures[index].weaponID {

                    obtainWeapon(weaponID)

                    if let weapon = weaponByID(weaponID) {
                        text += "\n\(weapon.name)も手に入れた！"
                    }
                }

                showDialogue(
                    title: "宝箱",
                    text: text
                )
            }
        }
    }

    // ========================================================
    // MARK: 戦闘
    // ========================================================

    func startRandomBattle() {

        guard !inBattle else {
            return
        }

        let enemy = enemies.randomElement()!

        currentEnemy = enemy
        inBattle = true
        movementDirection = nil

        battleLog =
            "\(enemy.name)が現れた！"
    }

    func startBossBattle() {

        let level = max(
            10,
            currentStage * 2
        )

        currentEnemy = Enemy(
            id: 9999,
            name: stages[currentStage - 1].boss,
            level: level,
            hp: 250 + level * 30,
            attack: 25 + level * 5,
            defense: 12 + level * 3,
            exp: 200 + level * 30,
            gold: 500 + level * 50,
            element: .dark,
            dropWeaponID: currentStage >= 20 ? 6 : nil
        )

        inBattle = true
        movementDirection = nil

        battleLog =
            "\(stages[currentStage - 1].boss)が現れた！！"
    }

    // ========================================================
    // MARK: 通常攻撃
    // ========================================================

    func attackEnemy() {

        guard var enemy = currentEnemy else {
            return
        }

        let damage = max(
            1,
            totalAttack +
            Int.random(in: 0...8) -
            enemy.defense / 3
        )

        enemy = Enemy(
            id: enemy.id,
            name: enemy.name,
            level: enemy.level,
            hp: max(0, enemy.hp - damage),
            attack: enemy.attack,
            defense: enemy.defense,
            exp: enemy.exp,
            gold: enemy.gold,
            element: enemy.element,
            dropWeaponID: enemy.dropWeaponID
        )

        currentEnemy = enemy

        battleLog =
            "\(damage)ダメージを与えた！"

        if enemy.hp <= 0 {
            winBattle()
        } else {
            enemyAttack()
        }
    }

    // ========================================================
    // MARK: スキル
    // ========================================================

    func useSkill(_ skill: Skill) {

        guard var enemy = currentEnemy else {
            return
        }

        if player.mp < skill.mpCost {

            battleLog = "MPが足りない！"
            return
        }

        player.mp -= skill.mpCost

        let damage = max(
            1,
            player.skillPower(skill) +
            Int.random(in: 0...15) -
            enemy.defense / 4
        )

        enemy = Enemy(
            id: enemy.id,
            name: enemy.name,
            level: enemy.level,
            hp: max(0, enemy.hp - damage),
            attack: enemy.attack,
            defense: enemy.defense,
            exp: enemy.exp,
            gold: enemy.gold,
            element: enemy.element,
            dropWeaponID: enemy.dropWeaponID
        )

        currentEnemy = enemy

        battleLog =
            "\(skill.name)！\n\(damage)ダメージ！"

        if enemy.hp <= 0 {
            winBattle()
        } else {
            enemyAttack()
        }
    }

    // ========================================================
    // MARK: 敵攻撃
    // ========================================================

    func enemyAttack() {

        guard let enemy = currentEnemy else {
            return
        }

        let damage = max(
            1,
            enemy.attack +
            Int.random(in: 0...8) -
            player.defense / 2
        )

        player.hp = max(
            0,
            player.hp - damage
        )

        battleLog +=
            "\n\(enemy.name)の攻撃！\n\(damage)ダメージ！"

        if player.hp <= 0 {

            player.hp = player.maxHP
            player.mp = player.maxMP

            player.gold =
                max(
                    0,
                    player.gold - 100
                )

            inBattle = false
            currentEnemy = nil

            playerX = 40
            playerY = 40

            cameraX = 40
            cameraY = 40

            showDialogue(
                title: "力尽きた",
                text:
                    "女神像まで戻された……\n" +
                    "100G失った。"
            )
        }
    }

    // ========================================================
    // MARK: 回復
    // ========================================================

    func heal() {

        if player.mp >= 10 {

            player.mp -= 10

            player.hp = min(
                player.maxHP,
                player.hp + 40 + player.level * 5
            )

            battleLog = "HPを回復した！"

            enemyAttack()

        } else {

            battleLog = "MPが足りない！"
        }
    }

    // ========================================================
    // MARK: 逃走
    // ========================================================

    func escape() {

        if Int.random(in: 1...100) <= 70 {

            inBattle = false
            currentEnemy = nil

            battleLog = "逃げ切った！"

        } else {

            battleLog = "逃げられない！"

            enemyAttack()
        }
    }

    // ========================================================
    // MARK: 勝利
    // ========================================================

    func winBattle() {

        guard let enemy = currentEnemy else {
            return
        }

        let gainedExp = enemy.exp
        let gainedGold = enemy.gold

        player.gold += gainedGold

        let leveled =
            player.gainExp(gainedExp)

        defeatedEnemies += 1
        storyProgress += 1

        var message =
            "\(enemy.name)を倒した！\n" +
            "\(gainedExp)EXP\n" +
            "\(gainedGold)G"

        // 武器ドロップ
        if let dropID = enemy.dropWeaponID {

            let alreadyOwned =
                player.ownedWeaponIDs.contains(dropID)

            if !alreadyOwned {

                obtainWeapon(dropID)

                if let weapon = weaponByID(dropID) {

                    message +=
                        "\n\n⚔️ \(weapon.name)をドロップ！"
                }
            }
        }

        // クエスト
        if questAccepted &&
            defeatedEnemies >= 3 &&
            !questCompleted {

            questCompleted = true

            player.gold += 500

            message +=
                "\n\n📜 クエスト達成！\n500G獲得！"
        }

        inBattle = false
        currentEnemy = nil

        updateAllies()

        if leveled {

            message +=
                "\n\n🎉 レベルアップ！\nLv.\(player.level)"
        }

        showDialogue(
            title: "戦闘勝利",
            text: message
        )
    }

    // ========================================================
    // MARK: 仲間
    // ========================================================

    func updateAllies() {

        let required =
            min(
                6,
                storyProgress / 5
            )

        for index in allies.indices {

            if index < required {
                allies[index].active = true
            }
        }
    }

    // ========================================================
    // MARK: 武器
    // ========================================================

    func weaponByID(
        _ id: Int
    ) -> Weapon? {

        return weapons.first {
            $0.id == id
        }
    }

    func obtainWeapon(
        _ id: Int
    ) {

        if !player.ownedWeaponIDs.contains(id) {

            player.ownedWeaponIDs.append(id)
        }
    }

    func buyWeapon(
        _ weapon: Weapon
    ) {

        if player.ownedWeaponIDs.contains(weapon.id) {

            equipWeapon(weapon.id)

            return
        }

        if player.gold < weapon.price {

            showDialogue(
                title: "武器屋",
                text: "お金が足りない！"
            )

            return
        }

        player.gold -= weapon.price

        player.ownedWeaponIDs.append(
            weapon.id
        )

        player.equippedWeaponID =
            weapon.id

        showDialogue(
            title: "購入",
            text:
                "\(weapon.name)を購入して装備した！"
        )
    }

    func equipWeapon(
        _ id: Int
    ) {

        guard player.ownedWeaponIDs.contains(id) else {
            return
        }

        player.equippedWeaponID = id

        showDialogue(
            title: "装備変更",
            text:
                "\(weaponByID(id)?.name ?? "武器")を装備した！"
        )
    }

    // ========================================================
    // MARK: 女神像
    // ========================================================

    func useGoddessStatue() {

        player.hp = player.maxHP
        player.mp = player.maxMP

        // 死亡した仲間を全員蘇生
        for index in allies.indices {

            if allies[index].hp <= 0 {

                allies[index].hp =
                    allies[index].maxHP
            }
        }

        showingGoddess = true
    }

    func saveGame() {

        let data = SaveData(

            level: player.level,
            exp: player.exp,
            gold: player.gold,

            hp: player.hp,
            maxHP: player.maxHP,

            mp: player.mp,
            maxMP: player.maxMP,

            attack: player.attack,
            defense: player.defense,

            job: player.job,

            playerX: playerX,
            playerY: playerY,

            currentStage: currentStage,
            storyProgress: storyProgress,

            questAccepted: questAccepted,
            questCompleted: questCompleted,
            defeatedEnemies: defeatedEnemies,

            ownedWeaponIDs:
                player.ownedWeaponIDs,

            equippedWeaponID:
                player.equippedWeaponID,

            allies: allies,

            openedTreasureIDs:
                treasures
                    .filter { $0.opened }
                    .map { $0.id }
        )

        do {

            let encoded =
                try JSONEncoder().encode(data)

            UserDefaults.standard.set(
                encoded,
                forKey: "END_MARK_RPG_SAVE"
            )

            showDialogue(
                title: "セーブ完了",
                text: "女神像に冒険の記録を保存した！"
            )

        } catch {

            showDialogue(
                title: "セーブ失敗",
                text: "セーブできませんでした。"
            )
        }
    }

    func loadGame() {

        guard let data =
                UserDefaults.standard.data(
                    forKey: "END_MARK_RPG_SAVE"
                )
        else {

            showDialogue(
                title: "セーブデータなし",
                text: "保存された冒険記録がありません。"
            )

            return
        }

        do {

            let save =
                try JSONDecoder().decode(
                    SaveData.self,
                    from: data
                )

            player.level = save.level
            player.exp = save.exp
            player.gold = save.gold

            player.hp = save.hp
            player.maxHP = save.maxHP

            player.mp = save.mp
            player.maxMP = save.maxMP

            player.attack = save.attack
            player.defense = save.defense

            player.job = save.job

            playerX = save.playerX
            playerY = save.playerY

            cameraX = CGFloat(save.playerX)
            cameraY = CGFloat(save.playerY)
            movementDirection = nil

            currentStage = save.currentStage
            storyProgress = save.storyProgress

            questAccepted =
                save.questAccepted

            questCompleted =
                save.questCompleted

            defeatedEnemies =
                save.defeatedEnemies

            player.ownedWeaponIDs =
                save.ownedWeaponIDs

            player.equippedWeaponID =
                save.equippedWeaponID

            allies = save.allies

            for index in treasures.indices {

                treasures[index].opened =
                    save.openedTreasureIDs.contains(
                        treasures[index].id
                    )
            }

            showDialogue(
                title: "ロード完了",
                text:
                    "冒険の記録を読み込んだ！"
            )

        } catch {

            showDialogue(
                title: "ロード失敗",
                text:
                    "セーブデータを読み込めませんでした。"
            )
        }
    }

    // ========================================================
    // MARK: キャンプ
    // ========================================================

    func useCamp() {

        player.hp = player.maxHP
        player.mp = player.maxMP

        showingCamp = true
    }

    // ========================================================
    // MARK: スキル
    // ========================================================

    func learnRandomSkill() {

        guard let skill =
                skills.randomElement()
        else {
            return
        }

        if !player.skills.contains(
            where: { $0.id == skill.id }
        ) {

            player.skills.append(skill)

            showDialogue(
                title: "スキル習得",
                text:
                    "\(skill.name)を覚えた！"
            )
        }
    }

    // ========================================================
    // MARK: 会話
    // ========================================================

    func showDialogue(
        title: String,
        text: String
    ) {

        dialogueTitle = title
        dialogueText = text

        showingDialogue = true
    }

    func closeDialogue() {

        showingDialogue = false
    }
}

// ============================================================
// MARK: - ワールド
// ============================================================

struct WorldView: View {

    @ObservedObject var game: RPGGame

    let columns = 15
    let rows = 11

    var body: some View {
        GeometryReader { geo in
            let tileSize = min(
                geo.size.width / CGFloat(columns),
                geo.size.height / CGFloat(rows)
            )

            ZStack {
                Color.black

                // カメラは小数座標で動く。
                // そのため背景タイルも一緒にスライドして、マス目移動感がなくなる。
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { column in
                        let baseX = Int(floor(game.cameraX)) - columns / 2 + column
                        let baseY = Int(floor(game.cameraY)) - rows / 2 + row

                        let offsetX = (CGFloat(baseX) - game.cameraX) * tileSize
                        let offsetY = (CGFloat(baseY) - game.cameraY) * tileSize

                        Rectangle()
                            .fill(tileColor(x: baseX, y: baseY))
                            .frame(
                                width: tileSize - 1,
                                height: tileSize - 1
                            )
                            .position(
                                x: geo.size.width / 2 + offsetX + tileSize / 2,
                                y: geo.size.height / 2 + offsetY + tileSize / 2
                            )
                    }
                }

                placeEmoji("🗿", x: 40, y: 40, tileSize: tileSize, size: geo.size)
                placeEmoji("⛺", x: 45, y: 40, tileSize: tileSize, size: geo.size)
                placeEmoji("⚔️", x: 35, y: 40, tileSize: tileSize, size: geo.size)

                ForEach(game.npcs) { npc in
                    placeEmoji("👤", x: npc.x, y: npc.y, tileSize: tileSize, size: geo.size)
                }

                ForEach(game.treasures) { treasure in
                    if !treasure.opened {
                        placeEmoji("🎁", x: treasure.x, y: treasure.y, tileSize: tileSize, size: geo.size)
                    }
                }

                // 主人公は画面中央に固定。
                // 絵文字ではなく、髪・顔・服・腕・脚を図形で描いた主人公。
                PlayerSpriteView(game: game, size: tileSize * 1.15)
                    .position(
                        x: geo.size.width / 2,
                        y: geo.size.height / 2
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .clipped()
    }

    @ViewBuilder
    func placeEmoji(
        _ emoji: String,
        x: Int,
        y: Int,
        tileSize: CGFloat,
        size: CGSize
    ) -> some View {
        let dx = (CGFloat(x) - game.cameraX) * tileSize
        let dy = (CGFloat(y) - game.cameraY) * tileSize

        if abs(dx) < tileSize * CGFloat(columns / 2 + 1) &&
            abs(dy) < tileSize * CGFloat(rows / 2 + 1) {
            Text(emoji)
                .font(.system(size: tileSize * 0.65))
                .position(
                    x: size.width / 2 + dx,
                    y: size.height / 2 + dy
                )
        }
    }

    func tileColor(x: Int, y: Int) -> Color {
        if x < 0 || x >= game.worldWidth || y < 0 || y >= game.worldHeight {
            return .black
        }

        if x % 10 == 0 || y % 10 == 0 {
            return .brown.opacity(0.65)
        }

        if (x * 17 + y * 13) % 19 == 0 {
            return .green.opacity(0.7)
        }

        if (x * 7 + y * 5) % 47 == 0 {
            return .blue.opacity(0.55)
        }

        return .green.opacity(0.25)
    }
}

// ============================================================
// MARK: - ステータス
// ============================================================

struct StatusView: View {

    @ObservedObject var game: RPGGame

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            Text(
                "🧙 Lv.\(game.player.level) " +
                "\(game.player.job.rawValue)"
            )
            .font(.headline)

            HStack {

                Text(
                    "HP \(game.player.hp)/\(game.player.maxHP)"
                )

                Spacer()

                Text(
                    "MP \(game.player.mp)/\(game.player.maxMP)"
                )
            }

            ProgressView(
                value:
                    Double(game.player.hp),

                total:
                    Double(game.player.maxHP)
            )

            HStack {

                Text(
                    "EXP \(game.player.exp)/" +
                    "\(game.player.expRequired())"
                )

                Spacer()

                Text(
                    "💰 \(game.player.gold)G"
                )
            }

            HStack {

                Text(
                    "⚔️ 攻撃 \(game.totalAttack)"
                )

                Spacer()

                Text(
                    "🛡️ 防御 \(game.player.defense)"
                )
            }

            Text(
                "第\(game.currentStage)：" +
                "\(game.stages[game.currentStage - 1].name)"
            )
            .font(.caption)
        }
        .padding(10)
        .background(
            RoundedRectangle(
                cornerRadius: 12
            )
            .fill(
                Color.black.opacity(0.08)
            )
        )
    }
}

// ============================================================
// MARK: - 主人公グラフィック
// ============================================================

struct PlayerSpriteView: View {

    @ObservedObject var game: RPGGame
    let size: CGFloat

    private var walking: Bool {
        game.movementDirection != nil
    }

    private var walkPhase: CGFloat {
        let value = (game.cameraX + game.cameraY) * .pi
        return walking ? sin(value) : 0
    }

    private var facingLeft: Bool {
        if case .left = game.movementDirection { return true }
        return false
    }

    var body: some View {
        ZStack {
            // 影
            Ellipse()
                .fill(Color.black.opacity(0.22))
                .frame(width: size * 0.55, height: size * 0.16)
                .offset(y: size * 0.46)

            // 足
            RoundedRectangle(cornerRadius: size * 0.06)
                .fill(Color(red: 0.12, green: 0.16, blue: 0.22))
                .frame(width: size * 0.16, height: size * 0.32)
                .rotationEffect(.degrees(Double(walkPhase * 12)))
                .offset(x: -size * 0.14, y: size * 0.30)

            RoundedRectangle(cornerRadius: size * 0.06)
                .fill(Color(red: 0.12, green: 0.16, blue: 0.22))
                .frame(width: size * 0.16, height: size * 0.32)
                .rotationEffect(.degrees(Double(-walkPhase * 12)))
                .offset(x: size * 0.14, y: size * 0.30)

            // マント／上着
            RoundedRectangle(cornerRadius: size * 0.14)
                .fill(Color.blue)
                .frame(width: size * 0.52, height: size * 0.58)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.14)
                        .stroke(Color.white.opacity(0.35), lineWidth: max(1, size * 0.025))
                )
                .offset(y: size * 0.05)

            // ベルト
            Rectangle()
                .fill(Color.brown)
                .frame(width: size * 0.52, height: size * 0.08)
                .offset(y: size * 0.18)

            // 腕
            RoundedRectangle(cornerRadius: size * 0.07)
                .fill(Color(red: 0.95, green: 0.72, blue: 0.52))
                .frame(width: size * 0.13, height: size * 0.36)
                .rotationEffect(.degrees(Double(-10 - walkPhase * 10)))
                .offset(x: -size * 0.34, y: size * 0.08)

            RoundedRectangle(cornerRadius: size * 0.07)
                .fill(Color(red: 0.95, green: 0.72, blue: 0.52))
                .frame(width: size * 0.13, height: size * 0.36)
                .rotationEffect(.degrees(Double(10 + walkPhase * 10)))
                .offset(x: size * 0.34, y: size * 0.08)

            // 首
            Rectangle()
                .fill(Color(red: 0.95, green: 0.72, blue: 0.52))
                .frame(width: size * 0.18, height: size * 0.14)
                .offset(y: -size * 0.30)

            // 顔
            Circle()
                .fill(Color(red: 1.0, green: 0.78, blue: 0.58))
                .frame(width: size * 0.58, height: size * 0.58)
                .offset(y: -size * 0.46)

            // 髪
            Circle()
                .fill(Color(red: 0.16, green: 0.08, blue: 0.05))
                .frame(width: size * 0.62, height: size * 0.48)
                .offset(y: -size * 0.59)

            // 前髪
            Path { path in
                path.move(to: CGPoint(x: -size * 0.28, y: -size * 0.54))
                path.addLine(to: CGPoint(x: -size * 0.08, y: -size * 0.67))
                path.addLine(to: CGPoint(x: size * 0.03, y: -size * 0.53))
                path.addLine(to: CGPoint(x: size * 0.18, y: -size * 0.68))
                path.addLine(to: CGPoint(x: size * 0.30, y: -size * 0.52))
                path.closeSubpath()
            }
            .fill(Color(red: 0.16, green: 0.08, blue: 0.05))

            // 目
            Circle()
                .fill(Color.black)
                .frame(width: size * 0.065, height: size * 0.09)
                .offset(x: facingLeft ? -size * 0.16 : size * 0.16, y: -size * 0.45)

            Circle()
                .fill(Color.black)
                .frame(width: size * 0.065, height: size * 0.09)
                .offset(x: facingLeft ? -size * 0.03 : size * 0.03, y: -size * 0.45)

            // マントの留め具
            Circle()
                .fill(Color.yellow)
                .frame(width: size * 0.09, height: size * 0.09)
                .offset(y: -size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

// ============================================================
// MARK: - キーボード操作
// ============================================================

struct KeyboardControlView: View {

    @ObservedObject var game: RPGGame
    @FocusState private var keyboardFocused: Bool

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .focusable()
            .focused($keyboardFocused)
            .onAppear {
                keyboardFocused = true
            }
            .onTapGesture {
                keyboardFocused = true
            }
            .onKeyPress(phases: [.down, .repeat]) { keyPress in
                switch keyPress.key {
                case .upArrow:
                    game.setMovementDirection(.up)
                case .downArrow:
                    game.setMovementDirection(.down)
                case .leftArrow:
                    game.setMovementDirection(.left)
                case .rightArrow:
                    game.setMovementDirection(.right)
                default:
                    switch keyPress.characters.lowercased() {
                    case "w": game.setMovementDirection(.up)
                    case "s": game.setMovementDirection(.down)
                    case "a": game.setMovementDirection(.left)
                    case "d": game.setMovementDirection(.right)
                    default: return .ignored
                    }
                }
                return .handled
            }
            .onKeyPress(phases: [.up]) { keyPress in
                switch keyPress.key {
                case .upArrow, .downArrow, .leftArrow, .rightArrow:
                    game.setMovementDirection(nil)
                default:
                    if ["w", "a", "s", "d"].contains(keyPress.characters.lowercased()) {
                        game.setMovementDirection(nil)
                    }
                }
                return .handled
            }
    }
}

// ============================================================
// MARK: - 移動
// ============================================================

struct MovementView: View {

    @ObservedObject var game: RPGGame

    var body: some View {
        VStack(spacing: 8) {
            DirectionButton(emoji: "⬆️") {
                game.setMovementDirection(.up)
            } onRelease: {
                game.setMovementDirection(nil)
            }

            HStack(spacing: 25) {
                DirectionButton(emoji: "⬅️") {
                    game.setMovementDirection(.left)
                } onRelease: {
                    game.setMovementDirection(nil)
                }

                Button("⏺️") {
                    game.setMovementDirection(nil)
                }
                .font(.system(size: 28))
                .buttonStyle(.bordered)

                DirectionButton(emoji: "➡️") {
                    game.setMovementDirection(.right)
                } onRelease: {
                    game.setMovementDirection(nil)
                }
            }

            DirectionButton(emoji: "⬇️") {
                game.setMovementDirection(.down)
            } onRelease: {
                game.setMovementDirection(nil)
            }
        }
    }
}

struct DirectionButton: View {
    let emoji: String
    let onPress: () -> Void
    let onRelease: () -> Void

    var body: some View {
        Text(emoji)
            .font(.system(size: 28))
            .frame(width: 58, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress()
                    }
                    .onEnded { _ in
                        onRelease()
                    }
            )
    }
}

// ============================================================
// MARK: - 戦闘
// ============================================================

struct BattleView: View {

    @ObservedObject var game: RPGGame

    var body: some View {

        VStack(spacing: 10) {

            if let enemy =
                game.currentEnemy {

                Text("⚔️ BATTLE")
                    .font(.largeTitle)
                    .bold()

                Text(enemy.name)
                    .font(.title2)
                    .bold()

                Text(
                    "Lv.\(enemy.level) HP \(enemy.hp)"
                )

                Text(game.battleLog)
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding()
                    .background(
                        RoundedRectangle(
                            cornerRadius: 12
                        )
                        .fill(
                            Color.gray.opacity(0.15)
                        )
                    )

                HStack {

                    Button("⚔️ 攻撃") {
                        game.attackEnemy()
                    }

                    Button("💚 回復") {
                        game.heal()
                    }

                    Button("🏃 逃走") {
                        game.escape()
                    }
                }
                .buttonStyle(
                    .borderedProminent
                )

                ScrollView(
                    .horizontal
                ) {

                    HStack {

                        ForEach(
                            Array(
                                game.player.skills.prefix(8)
                            )
                        ) { skill in

                            Button {

                                game.useSkill(
                                    skill
                                )

                            } label: {

                                VStack {

                                    Text(
                                        skill.name
                                    )
                                    .font(
                                        .caption
                                    )

                                    Text(
                                        "\(game.player.skillPower(skill))"
                                    )
                                    .font(
                                        .caption2
                                    )
                                }
                            }
                            .buttonStyle(
                                .bordered
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 18
            )
            .fill(
                Color.red.opacity(0.08)
            )
        )
    }
}

// ============================================================
// MARK: - 女神像画面
// ============================================================

struct GoddessView: View {

    @ObservedObject var game: RPGGame

    var body: some View {

        VStack(spacing: 12) {

            Text("🗿 女神像")
                .font(.title)
                .bold()

            Text(
                "女神像の力によって\n" +
                "冒険者たちの傷を癒すことができる。"
            )
            .multilineTextAlignment(.center)

            Button("💾 セーブ") {
                game.saveGame()
            }

            Button("❤️ 全回復・仲間蘇生") {
                game.useGoddessStatue()
            }

            Button("⚔️ 装備変更") {
                game.showingGoddess = false
                game.showingEquipment = true
            }

            Button("📂 ロード") {
                game.loadGame()
            }

            Button("閉じる") {
                game.showingGoddess = false
            }
        }
        .padding(25)
        .frame(maxWidth: 350)
        .background(
            RoundedRectangle(
                cornerRadius: 20
            )
            .fill(Color.white)
        )
    }
}

// ============================================================
// MARK: - キャンプ
// ============================================================

struct CampView: View {

    @ObservedObject var game: RPGGame

    var body: some View {

        VStack(spacing: 12) {

            Text("⛺ キャンプ")
                .font(.title)
                .bold()

            Text("安全に休める場所。")

            Button("❤️ 休む") {
                game.useCamp()

                game.showDialogue(
                    title: "キャンプ",
                    text:
                        "ゆっくり休んだ。\n" +
                        "HPとMPが全回復した！"
                )
            }

            Button("⚔️ 装備変更") {

                game.showingCamp = false
                game.showingEquipment = true
            }

            Button("閉じる") {
                game.showingCamp = false
            }
        }
        .padding(25)
        .frame(maxWidth: 350)
        .background(
            RoundedRectangle(
                cornerRadius: 20
            )
            .fill(Color.white)
        )
    }
}

// ============================================================
// MARK: - 武器屋
// ============================================================

struct ShopView: View {

    @ObservedObject var game: RPGGame

    var body: some View {

        VStack(spacing: 8) {

            Text("⚔️ 武器屋")
                .font(.title)
                .bold()

            Text(
                "所持金：\(game.player.gold)G"
            )

            ScrollView {

                VStack(spacing: 8) {

                    ForEach(
                        game.weapons.filter {
                            $0.price > 0
                        }
                    ) { weapon in

                        HStack {

                            VStack(
                                alignment: .leading
                            ) {

                                Text(
                                    weapon.name
                                )
                                .bold()

                                Text(
                                    "\(weapon.rarity) / 攻撃+\(weapon.attack)"
                                )
                                .font(
                                    .caption
                                )
                            }

                            Spacer()

                            if game.player.ownedWeaponIDs.contains(
                                weapon.id
                            ) {

                                Button("装備") {
                                    game.equipWeapon(
                                        weapon.id
                                    )
                                }

                            } else {

                                Button(
                                    "\(weapon.price)G"
                                ) {
                                    game.buyWeapon(
                                        weapon
                                    )
                                }
                            }
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 10
                            )
                            .fill(
                                Color.gray.opacity(0.1)
                            )
                        )
                    }
                }
            }

            Button("閉じる") {
                game.showingShop = false
            }
        }
        .padding(20)
        .frame(
            maxWidth: 380,
            maxHeight: 500
        )
        .background(
            RoundedRectangle(
                cornerRadius: 20
            )
            .fill(Color.white)
        )
    }
}

// ============================================================
// MARK: - 装備画面
// ============================================================

struct EquipmentView: View {

    @ObservedObject var game: RPGGame

    var body: some View {

        VStack(spacing: 10) {

            Text("⚔️ 装備")
                .font(.title)
                .bold()

            if let weapon =
                game.equippedWeapon() {

                Text(
                    "現在の武器：\(weapon.name)"
                )
            }

            Text(
                "総攻撃力：\(game.totalAttack)"
            )

            ScrollView {

                VStack(spacing: 8) {

                    ForEach(
                        game.weapons.filter {
                            game.player.ownedWeaponIDs.contains(
                                $0.id
                            )
                        }
                    ) { weapon in

                        Button {

                            game.equipWeapon(
                                weapon.id
                            )

                        } label: {

                            HStack {

                                Text(
                                    weapon.name
                                )

                                Spacer()

                                Text(
                                    "+\(weapon.attack)"
                                )

                                if game.player.equippedWeaponID
                                    == weapon.id {

                                    Text("✓")
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 10
                                )
                                .fill(
                                    Color.gray.opacity(0.12)
                                )
                            )
                        }
                    }
                }
            }

            Button("閉じる") {
                game.showingEquipment = false
            }
        }
        .padding(20)
        .frame(
            maxWidth: 380,
            maxHeight: 500
        )
        .background(
            RoundedRectangle(
                cornerRadius: 20
            )
            .fill(Color.white)
        )
    }
}

// ============================================================
// MARK: - メイン画面
// ============================================================

struct ContentView: View {

    @StateObject private var game =
        RPGGame()

    var body: some View {

        ZStack {

            KeyboardControlView(game: game)

            VStack(spacing: 8) {

                StatusView(
                    game: game
                )

                WorldView(
                    game: game
                )
                .frame(
                    height: 380
                )

                if game.inBattle {

                    BattleView(
                        game: game
                    )

                } else {

                    MovementView(
                        game: game
                    )

                    HStack {

                        Button("📜 クエスト") {

                            if game.questCompleted {

                                game.showDialogue(
                                    title: "クエスト",
                                    text:
                                        "クエスト達成済み！"
                                )

                            } else if game.questAccepted {

                                game.showDialogue(
                                    title: "クエスト",
                                    text:
                                        "あと\(max(0, 3 - game.defeatedEnemies))体！"
                                )

                            } else {

                                game.acceptQuest()
                            }
                        }

                        Button("✨ スキル") {
                            game.learnRandomSkill()
                        }

                        Button("👥 仲間") {

                            let names =
                                game.allies
                                    .filter {
                                        $0.active
                                    }
                                    .map {
                                        $0.name
                                    }
                                    .joined(
                                        separator: "、"
                                    )

                            game.showDialogue(
                                title: "仲間",
                                text:
                                    names.isEmpty
                                    ? "まだ仲間はいない。"
                                    : names
                            )
                        }
                    }
                    .buttonStyle(
                        .bordered
                    )

                    // 場所メニュー
                    HStack {

                        if game.playerX == 40 &&
                            game.playerY == 40 {

                            Button("🗿 女神像") {

                                game.useGoddessStatue()
                            }
                        }

                        if game.playerX == 45 &&
                            game.playerY == 40 {

                            Button("⛺ キャンプ") {

                                game.showingCamp = true
                            }
                        }

                        if game.playerX == 35 &&
                            game.playerY == 40 {

                            Button("⚔️ 武器屋") {

                                game.showingShop = true
                            }
                        }
                    }
                    .buttonStyle(
                        .borderedProminent
                    )

                    // ボス戦
                    Button("👑 ボスに挑む") {

                        game.startBossBattle()
                    }
                    .buttonStyle(
                        .bordered
                    )
                }
            }
            .padding()

            // 会話
            if game.showingDialogue {

                Color.black
                    .opacity(0.45)
                    .ignoresSafeArea()

                VStack(spacing: 15) {

                    Text(
                        game.dialogueTitle
                    )
                    .font(.title)
                    .bold()

                    Text(
                        game.dialogueText
                    )
                    .multilineTextAlignment(
                        .center
                    )

                    Button("閉じる") {

                        game.closeDialogue()
                    }
                    .buttonStyle(
                        .borderedProminent
                    )
                }
                .padding(25)
                .frame(
                    maxWidth: 360
                )
                .background(
                    RoundedRectangle(
                        cornerRadius: 20
                    )
                    .fill(Color.white)
                )
                .shadow(
                    radius: 20
                )
            }

            // 女神像
            if game.showingGoddess {

                Color.black
                    .opacity(0.45)
                    .ignoresSafeArea()

                GoddessView(
                    game: game
                )
            }

            // キャンプ
            if game.showingCamp {

                Color.black
                    .opacity(0.45)
                    .ignoresSafeArea()

                CampView(
                    game: game
                )
            }

            // 武器屋
            if game.showingShop {

                Color.black
                    .opacity(0.45)
                    .ignoresSafeArea()

                ShopView(
                    game: game
                )
            }

            // 装備
            if game.showingEquipment {

                Color.black
                    .opacity(0.45)
                    .ignoresSafeArea()

                EquipmentView(
                    game: game
                )
            }
        }
    }
}

// ============================================================
// MARK: - アプリ起動
// ============================================================

@main
struct EndMarkRPGApp: App {

    var body: some Scene {

        WindowGroup {

            ContentView()
        }
    }
}

