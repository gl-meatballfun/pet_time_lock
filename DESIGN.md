# 健康/快乐/食物分值、商店与 AI 动态生成系统设计方案

## Context

当前应用已有宠物四维属性（健康/快乐/饥饿/知识）和答题奖励，但奖励机制单一：答题正确只固定加饥饿和知识，没有区分学科，也缺少货币积累和商店购买体系。用户希望：

1. 补充 **健康、快乐、食物** 三条分值体系。
2. 随机问题 / 任务完成 / 回答正确后可累积对应分值。
3. 累积的分值可在商店购买货品。
4. **快乐分值** 偏向语文、英语问题；**食物分值** 偏向理科（数学/物理）问题；**健康分值** 由日常任务、专注模式等产出。
5. 宠物生长阶段细化为：**蛋孵化期（3–9 天）、幼崽期（不少于 1 个月）、培育期（约半年）、成熟期（拔高并持续）**。
6. 接入大模型，根据宠物状态、主人学业情况、互动历史，动态生成宠物互动回复、每日任务和学习问题。

## Recommended Approach

### 1. 三种货币模型（`lib/models/app_models.dart`）

新增 `CurrencyWallet`：
- `happinessPoints`：快乐币（语文/英语答题）
- `foodPoints`：食物币（数学/物理答题）
- `healthPoints`：健康币（任务、专注、护理）
- `lastUpdatedAt`

新增 `ShopItem`：
- `id`, `name`, `description`, `iconEmoji`
- `category`：`food`（食物）/ `toy`（玩具）/ `medicine`（药品）/ `accessory`（装饰）
- `happinessCost` / `foodCost` / `healthCost`：三种货币成本
- `effectHealth` / `effectHappiness` / `effectHunger` / `effectKnowledge`：使用后的宠物属性变化
- `requiredStage`：购买所需最低宠物阶段
- `isConsumable`：是否消耗品
- `appearanceUnlock`：装饰品解锁的外观标识

新增 `InventoryItem`：
- `itemId`, `quantity`, `acquiredAt`

新增 `DailyTask`：
- `id`, `title`, `description`
- `taskType`：`answerQuestions` / `focusSession` / `feedPet` / `playWithPet` / `completeAnyContent`
- `targetCount` / `currentCount` / `completed`
- `rewardHealthPoints`：奖励健康币
- `assignedDate`：按天重置

新增 `RewardLog`：
- 记录所有货币收入/支出，便于调试和成就统计。

### 2. 数据库升级（`lib/data/database_helper.dart`）

- 数据库版本从 2 升级到 3。
- 新增表：`currency_wallet`、`shop_items`、`inventory`、`daily_tasks`、`reward_logs`。
- `onUpgrade` 中创建新表、初始化钱包、写入默认商品数据。
- 新增 CRUD 方法：钱包读写、商品列表、背包读写、每日任务读写、奖励日志写入。

### 3. 学科化答题奖励（`lib/bloc/pet_cubit.dart`）

修改 `answerQuestionCorrectly(String subject)`：
- `语文` / `英语` / `poem` / `english`：奖励 **快乐币**，少量恢复饥饿。
- `数学` / `物理` / `math` / `physics`：奖励 **食物币**，较多恢复饥饿。
- 奖励数额随年级增加，并带 0–5 随机加成。

新增方法：
- `earnHealthPoints(int amount, String source, String description)`：完成日常任务、专注模式等奖励健康币。
- `purchaseItem(String itemId)`：检查货币余额和阶段要求，扣款并加入背包。
- `useItem(String itemId)`：从背包使用物品，应用属性效果；消耗品减少数量，装饰品解锁外观。
- `_addCurrency(...)`：统一写入钱包和奖励日志的内部方法。

### 4. 状态层扩展（`lib/bloc/pet_state.dart`）

`PetManagerState` 增加 `CurrencyWallet? currencyWallet`。

### 5. 每日任务与进度（`lib/bloc/content_cubit.dart`）

- `ContentState` 增加 `List<DailyTask> dailyTasks`。
- 每天首次打开时自动生成 3 个任务：
  - 文科类任务（答语文/英语题）
  - 理科类任务（答数学/物理题）
  - 护理/专注类任务
- `incrementTaskProgress(TaskType type)`：完成对应行为时推进任务进度。
- `recordProgress(...)` 返回内容学科，便于外部路由奖励。

### 6. 答题弹窗改造（`lib/screens/content_card_dialog.dart`）

- `_checkAnswer` 时传入 `content.subject`。
- 正确后调用 `answerQuestionCorrectly(subject)`。
- 同时记录学习进度并推进 `answerQuestions` 类型任务。

### 7. 新增商店与背包界面

- `lib/screens/shop_screen.dart`：
  - 顶部显示三种货币余额。
  - 按分类 Tab 展示商品：食物、玩具、药品、装饰。
  - 每个商品显示价格、效果、阶段限制、购买按钮。
- `lib/screens/inventory_screen.dart`：
  - 展示已购买的物品。
  - 点击消耗品使用，点击装饰品装备/卸下。
- `lib/screens/daily_tasks_screen.dart`：
  - 今日任务列表、进度、领取奖励。

### 8. 主界面集成（`lib/screens/home_screen.dart`）

- 在统计卡上方或 AppBar 区域显示三种货币余额。
- AppBar 增加商店入口 `Icons.storefront` 和任务入口 `Icons.task_alt`（带未完成任务角标）。
- 使用物品后的属性变化通过 SnackBar 提示。

### 9. 默认商品设计

| 商品 | 分类 | 价格 | 效果 |
|---|---|---|---|
| 小饼干 | 食物 | 10 食物币 | 饥饿 +15，快乐 +5 |
| 豪华大餐 | 食物 | 30 食物币 | 饥饿 +30，快乐 +10，健康 +5 |
| 知识蛋糕 | 食物 | 10 快乐币 + 20 食物币 | 饥饿 +20，快乐 +15，知识 +10 |
| 弹力球 | 玩具 | 15 快乐币 | 快乐 +20，饥饿 -5 |
| 智力拼图 | 玩具 | 25 快乐币 | 快乐 +15，知识 +15 |
| 游戏机 | 玩具 | 50 快乐币 | 快乐 +30，健康 -5，饥饿 -10 |
| 草药 | 药品 | 10 健康币 | 健康 +20 |
| 恢复药水 | 药品 | 25 健康币 | 健康 +40，快乐 +5，饥饿 +5 |
| 万能灵药 | 药品 | 50 健康币 | 健康 +50，快乐 +20，饥饿 +20 |
| 学霸帽 | 装饰 | 30 快乐币 + 30 食物币 | 解锁外观配饰 |

### 10. 分值产出途径

| 行为 | 获得货币 | 说明 |
|---|---|---|
| 答对语文/英语题 | 快乐币 | 快乐分值的主要来源 |
| 答对数学/物理题 | 食物币 | 食物分值的主要来源 |
| 完成每日任务 | 健康币 | 健康分值的主要来源 |
| 专注模式 | 健康币 | 每 10 分钟 +2 健康币 |
| 宠物进化/首次满分等 | 健康币 | 成就一次性奖励 |

### 11. 宠物生长阶段重定义

将原有 0–4 阶段映射为四个真实时间阶段，基于 `PetState.createdAt` 与当前时间计算，同时保留 `growthXp` 作为辅助加速条件：

| 阶段 | 名称 | 时长 | 学习要求 | 问题难度与范围 |
|---|---|---|---|---|
| 0 | 蛋孵化期 | 3–9 天 | 以轻松互动、短问答为主 | 等于或略低于当前年级，趣味性强 |
| 1 | 幼崽期 | ≥ 1 个月 | 建立每日学习习惯 | **与当前学级基本持平**，可涵盖适龄日常知识（生活常识、安全、品德、兴趣科普等） |
| 2 | 培育期 | 约 6 个月 | 系统学习各学科知识技能 | **与当前学级基本持平并适当拓展**，持续引入适龄日常知识，培养综合素养 |
| 3 | 成熟期 | 持续 | 拔高训练，超过主人学级水平 | 明显高于当前年级，直到高中毕业仍可继续 |

阶段判定逻辑（`lib/bloc/pet_cubit.dart` 中新增 `PetStageResolver`）：
- 先按时间判定基础阶段。
- 若 `growthXp` 达到更高阶段阈值，可提前解锁（作为激励机制）。
- 成熟度达到后不再回退，持续提供拔高内容。

外观与对话随阶段变化：
- 蛋孵化期：蛋形态，只能显示简单情绪。
- 幼崽期：萌系幼宠，简短语言。
- 培育期：成长型宠物，可讲解知识点。
- 成熟期：完全体，可出难题、给学习建议。

### 12. 大模型动态生成服务

新增 `lib/services/llm_service.dart`：
- 配置 API：支持设置 Base URL、API Key、模型名（默认 Claude/OpenAI 兼容格式）。
- 统一方法 `generate(String prompt, {String? systemPrompt})`。
- 输出统一解析为 JSON，失败时返回 `null` 并触发本地 fallback。

#### 12.1 动态互动回复

当用户点击宠物、喂食、玩耍或触发超额提醒时，调用 LLM 生成宠物回复：

输入上下文：
- 宠物当前阶段、名字、外观
- 健康/快乐/饥饿/知识/纪律数值
- 主人年级、最近学习科目、今日已答题数
- 当前场景（问候、鼓励、提醒休息、答对题庆祝等）

输出格式：
```json
{
  "message": "主人今天英语答对了 3 题，我好开心呀！",
  "emotion": "happy",
  "suggestedAction": "再去挑战一道数学题吧？"
}
```

UI 在 `AnimatedPetWidget` 气泡和 `QuoteCardDialog` 中展示生成的文案。

#### 12.2 动态任务生成

每日首次进入应用时，调用 LLM 生成今日任务：

输入上下文：
- 宠物阶段
- 主人年级
- 昨日/近期薄弱科目（从 `user_progress` 中统计错误率）
- 当前宠物状态（如饥饿低则多给食物币任务）

输出格式：
```json
{
  "tasks": [
    {
      "title": "英语小达人",
      "description": "完成 2 道英语题，让宠物更快乐",
      "taskType": "answerQuestions",
      "subject": "英语",
      "targetCount": 2,
      "rewardHealthPoints": 10
    }
  ]
}
```

任务写入 `daily_tasks` 表，LLM 生成失败时使用本地模板生成。

#### 12.3 动态问题生成

当静态题库用尽或需要拓展时，调用 LLM 生成题目：

输入上下文：
- 年级
- 科目（若为文科则同时产出快乐币，理科则产出食物币）
- 当前阶段（难度控制）
- 宠物状态/互动历史

输出格式：
```json
{
  "id": "llm_math_001",
  "type": "math",
  "title": "生活中的分数",
  "content": "...",
  "question": "...",
  "options": ["A", "B", "C", "D"],
  "correctAnswer": "B",
  "explanation": "...",
  "estimatedSeconds": 60
}
```

**幼崽期 / 培育期出题原则：**
- 难度与广度与当前学级**基本持平**。
- 允许并鼓励涉猎**适龄日常知识**：生活常识、安全自护、品德礼仪、兴趣科普、传统文化、身心健康等。
- 内容由 LLM 直接安排，不局限于教材。

生成的题目缓存到 `educational_content` 表（标记 `is_local=0, is_downloaded=1`），并写入 `llm_generated_content` 元数据表记录来源 prompt。

### 13. 情绪价值与内容安全

所有 LLM 生成都必须满足以下要求，通过 system prompt 强制约束：

1. **情绪价值优先**：回复需温暖、鼓励、陪伴，避免说教、责备、制造焦虑。
2. **健康积极性**：内容不得包含暴力、恐怖、低俗、歧视、诱导危险行为；应传递自律、关爱、成长、好奇心等正向价值观。
3. **适龄性**：日常知识需符合学生年龄认知水平，避免成人化或过度商业化的内容。
4. **学科关联**：即使是日常知识，也要尽量与语文、英语、数学、物理等学科素养潜移默化地结合。

实现方式：
- `lib/data/llm_prompt_templates.dart` 中定义统一 system prompt 模板，明确上述约束。
- 对 LLM 输出进行本地校验：检查是否包含敏感词、选项是否完整、JSON 是否合法。
- 若输出不符合规范，自动 fallback 到本地模板，并记录到 `reward_logs` 或 `llm_quality_logs` 供后续优化。

### 14. 离线 Fallback 与缓存策略

- LLM 调用失败（网络、超时、配置缺失）时：
  - 互动回复：使用本地文案模板库。
  - 每日任务：使用模板任务库。
  - 问题生成：使用本地 `SeedData` 题库。
- 缓存生成的问题和任务 7 天，避免重复调用。
- 在设置页提供"使用 AI 生成"开关和 API 配置入口。

### 15. 配置管理

新增 `lib/services/llm_config_service.dart`：
- 使用 `SharedPreferences` 存储：
  - `llm_enabled`：是否启用大模型
  - `llm_base_url`
  - `llm_api_key`
  - `llm_model_name`
- 设置页新增"AI 设置"入口。

### 16. 阶段与 LLM 联动的奖励策略

| 阶段 | 问题生成侧重 | 任务生成侧重 | 互动风格 |
|---|---|---|---|
| 蛋孵化期 | 趣味性问答，低难度 | 每日签到、轻互动 | 卖萌、简短 |
| 幼崽期 | 与学级持平的基础题 + 适龄日常知识 | 培养每日学习习惯 | 鼓励、陪伴 |
| 培育期 | 与学级持平并拓展的综合题 + 日常知识 | 专题训练、错题巩固 | 讲解、引导 |
| 成熟期 | 高于当前年级的拔高题 | 挑战任务、竞赛难度 | 导师、伙伴 |

## Critical Files to Modify

- `lib/models/app_models.dart`
- `lib/data/database_helper.dart`
- `lib/bloc/pet_cubit.dart`
- `lib/bloc/pet_state.dart`
- `lib/bloc/content_cubit.dart`
- `lib/bloc/content_state.dart`
- `lib/screens/content_card_dialog.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/settings_screen.dart`
- 新增：`lib/screens/shop_screen.dart`
- 新增：`lib/screens/inventory_screen.dart`
- 新增：`lib/screens/daily_tasks_screen.dart`
- 新增：`lib/services/llm_service.dart`
- 新增：`lib/services/llm_config_service.dart`
- 新增：`lib/data/llm_prompt_templates.dart`

## Verification

1. 答对语文题后快乐币增加，答对数学题后食物币增加。
2. 每日任务生成、完成、重置正常。
3. 商店购买：余额足够则扣款并入库，不足则提示失败。
4. 使用物品后宠物属性按设计变化，消耗品数量减少。
5. 装饰品购买后可在宠物外观上体现。
6. 数据库升级：旧用户升级到 v3 后新表和初始商品正常创建。
7. 主界面正确显示三种货币余额。
8. 宠物阶段按时间正确判定（蛋孵化期 3–9 天、幼崽期 ≥1 个月等）。
9. LLM 开启时，能生成符合当前阶段和学科的任务/问题/回复。
10. LLM 关闭或失败时，应用能正常 fallback 到本地模板和题库。
