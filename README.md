# AI 智能餐垫 | AI Smart Placemat

**通过 AI 和可穿戴传感器改善用户饮食习惯的智能产品。**

一款通过 BLE 电子秤实时监测用户进食节奏、识别过快进食、提供智能提醒，并通过 AI 生成单餐和趋势报告的饮食习惯改善产品。

---

## 🎯 产品定位

### 核心价值主张
- **实时感知** — 让用户第一次明确感知"我吃饭真的太快"
- **智能提醒** — 在吃得过快时进行低打扰提醒，不 interrupt 用餐流程
- **数据驱动** — 每餐后输出可信的进食速度报告和人工智能建议
- **陪伴式建议** — AI 分析体趋势，提出个性化改善方案

### MVP 主闭环
```
BLE 电子秤 → App BLE 扫描解析 → 本地规则判断 → 提醒触发 
    ↓
本地记录 → 后端上传 → 单餐报告 → 7 日趋势 → AI 总结与建议
```

---

## 📱 核心功能

### Phase 1：MVP 基础功能
- ✅ BLE 电子秤接入（广播包解析）
- ✅ 实时重量显示与进食速度监测
- ✅ 本地规则引擎判断过快进食
- ✅ 可配置的进食提醒（文字 + TTS 语音）
- ✅ 单餐报告（时长、进食量、平均速度、峰值速度）
- ✅ 7 天趋势汇总
- ✅ AI 单餐总结和建议
- ✅ 陪伴式对话能力框架

### 前端页面（5 大核心页面）
1. **设备连接 / 蓝牙调试页** — 扫描与验证电子秤，查看原始数据
2. **首页** — 设备状态、最近一餐、今日餐次、快捷导航
3. **实时用餐页** — 当前重量、进食速度、是否过快、提醒触发
4. **单餐报告页** — 本餐数据总结 + AI 建议
5. **趋势 + 设置页** — 7 日趋势、AI 趋势总结、提醒设置

### 后端业务模块
- `device` — 匿名用户与设备绑定
- `settings` — 提醒设置（频率、文字、语音、静音时段）
- `meal` — 进食数据存储与处理
- `report` — 单餐报告生成
- `trend` — 趋势聚合与分析
- `chat` — 陪伴式对话接口

---

## 🛠️ 技术栈

### 前端
| 组件 | 技术 | 用途 |
|------|------|------|
| 框架 | Flutter | 跨平台移动应用 |
| BLE | flutter_blue_plus | 蓝牙扫描与解析 |
| 本地存储 | sqflite | SQLite 数据库 |
| 本地缓存 | shared_preferences | 设置缓存 |
| 语音 | flutter_tts | 系统 TTS 语音播报 |
| 权限 | permission_handler | 蓝牙/位置权限管理 |

### 后端
| 组件 | 技术 | 用途 |
|------|------|------|
| 框架 | FastAPI | 异步 REST API 服务 |
| 数据库 | PostgreSQL | 持久化数据存储 |
| ORM | SQLAlchemy | 数据库操作 |
| 数据验证 | Pydantic | 请求与响应验证 |
| AI 工作流 | LangGraph | 多步 AI 任务编排 |
| 异步任务 | FastAPI BackgroundTasks | 异步报告生成 |

### Python 版本
- **最低要求**：Python 3.11+

---

## 📁 项目结构

```
ai-placemat/
├── frontend/                           # Flutter 前端项目
│   ├── lib/
│   │   ├── core/                      # 核心基础设施
│   │   │   ├── ble/                   # BLE 扫描与广播解析
│   │   │   ├── parser/                # 制造商数据解析器
│   │   │   ├── engine/                # 本地规则引擎
│   │   │   ├── reminder/              # 提醒管理服务
│   │   │   ├── storage/               # SQLite 本地存储
│   │   │   └── network/               # 后端 API 网络层
│   │   ├── models/                    # 数据模型 (Meal, Report, etc)
│   │   ├── pages/                     # 5 个核心页面
│   │   ├── providers/ or services/    # 业务状态 & 服务层
│   │   └── main.dart                  # 应用入口
│   ├── pubspec.yaml                   # 依赖管理
│   └── README.md                      # 前端开发指南
│
├── backend/                            # FastAPI 后端项目
│   ├── app/
│   │   ├── api/                       # REST API 路由
│   │   ├── schemas/                   # Pydantic 数据模型
│   │   ├── models/                    # SQLAlchemy ORM 模型
│   │   ├── services/                  # 业务逻辑层
│   │   ├── ai/                        # AI 工作流模块
│   │   │   ├── graphs/                # 3 个核心 Graph
│   │   │   ├── nodes/                 # Graph 节点定义
│   │   │   └── prompts/               # AI Prompt 模板
│   │   ├── db/                        # 数据库配置和初始化
│   │   ├── tasks/                     # 异步后台任务
│   │   └── main.py                    # FastAPI 应用主文件
│   ├── pyproject.toml                 # 依赖管理
│   └── README.md                      # 后端开发指南
│
├── contracts/                          # 前后端契约
│   └── api.yaml                       # OpenAPI 接口定义
│
├── docs/                               # 项目文档
│   ├── architecture.md                # 整体架构设计
│   ├── backend_architecture.md        # 后端详细设计
│   └── ...                            # 其他设计文档
│
├── AGENTS.md                          # 项目需求与工程指南
├── PRD.md                             # 产品定义文档
└── README.md                          # 本文件
```

---

## 🚀 快速开始

### 前置要求
- **前端**: Flutter SDK 3.3.0+, Dart
- **后端**: Python 3.11+, pip

### 后端启动

```bash
cd backend

# 安装依赖
pip install -e .

# 配置数据库
export DATABASE_URL="postgresql://user:password@localhost:5432/ai_placemat"

# 初始化数据库
python -c "from app.db import init_db; init_db()"

# 启动开发服务器
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API 将在 `http://localhost:8000` 启动，交互式文档 `http://localhost:8000/docs`

### 前端启动

```bash
cd frontend

# 安装依赖
flutter pub get

# 运行应用（以 iOS 为例）
flutter run -d iPhone
# 或 Android
flutter run -d android
```

---

## 🔑 核心设计决策

### 1. 匿名用户模型（No Login MVP）
- App 首次启动时生成唯一的 `anonymousUserId`，本地持久化
- 所有数据（meal, settings, report) 都关联 `anonymousUserId`
- 为后续接入登录预留扩展空间，但 MVP 不做注册登录

### 2. 设置本地优先，后端同步
```
用户编辑本地设置 → 立即生效（离线可用）
         ↓
    异步上传到后端
         ↓
    后端更新 → 其他端同步
```
保证：即使后端异常或离线，提醒仍可正常工作

### 3. BLE 广播包优先，GATT 为辅
- 首版通过 BLE 广播包解析重量数据
- `manufacturer data` 中包含实时重量字段
- 协议偏移不硬编码，支持可调解析器

### 4. 规则引擎处理实时判断，AI 处理离线分析
| 场景 | 引擎 | 说明 |
|------|------|------|
| 实时提醒 | 本地规则 | 不依赖 AI，响应快，离线可用 |
| 单餐总结 | AI | 生成可信报告与建议 |
| 趋势分析 | AI | 聚合 7 天数据给出改善建议 |
| 陪伴对话 | AI | 基于用户历史的个性化对话 |

### 5. 后端异步报告生成
- FastAPI BackgroundTasks 处理异步 AI 报告生成
- 用户先获得规则报告（快速）
- AI 报告生成后异步更新前端

---

## 📊 数据与命名约定

### JSON 响应字段统一为 camelCase
```json
{
  "anonymousUserId": "uuid-xxx",
  "mealId": "meal-123",
  "weightGram": 150,
  "avgSpeed": 12.5,
  "peakSpeed": 25.3,
  "intakeGrams": 300,
  "reminderCount": 2,
  "reminderText": "吃得有点快呢",
  "voiceEnabled": true
}
```

### 数据库表使用 snake_case
- `anonymous_users`
- `device_bindings`
- `meal_records`
- `meal_reports`
- ... 等

### 关键字段定义
| 字段 | 说明 |
|------|------|
| `anonymousUserId` | 匿名用户唯一标识 (UUID) |
| `mealId` | 单次进食唯一标识 |
| `mealStartTime` | 进食开始时间 |
| `weightGram` | 重量（克） |
| `avgSpeed` | 平均进食速度（克/分钟） |
| `peakSpeed` | 峰值进食速度（克/分钟） |
| `intakeGrams` | 本餐总进食量（克） |
| `reminderCount` | 本餐提醒次数 |

---

## 🧠 AI 工作流（LangGraph）

### 3 个核心 Graph

#### 1. `meal_insight_graph`
- **输入**: 单餐进食数据、设置
- **输出**: 可信单餐总结 + 建议
- **能力**: 进食速度分析、异常检测、个性化建议

#### 2. `trend_insight_graph`
- **输入**: 最近 7 天餐次数据
- **输出**: 趋势总结 + 改善建议
- **能力**: 速度趋势、快吃频率、改善率计算

#### 3. `companion_chat_graph`
- **输入**: 用户消息、历史餐次、用户偏好
- **输出**: 陪伴式对话回答
- **能力**: 督促、建议、个性化陪伴

---

## 🔄 MVP 实施阶段

### Phase 1：工程骨架
- [x] 创建项目目录与工程结构
- [x] 创建 API 契约 (`contracts/api.yaml`)
- [x] 创建前端页面骨架
- [x] 创建后端模块骨架
- [x] 建立匿名用户身份模型
- [x] 定义 settings / meal / report 数据模型

### Phase 2：核心能力
- [ ] 完成前端 BLE 扫描与广播解析
- [ ] 完成本地设置缓存与离线支持
- [ ] 完成后端 settings / meal / report API
- [ ] 完成数据库初始化脚本

### Phase 3：报告与趋势
- [ ] 实现本地规则引擎（进食速度判断）
- [ ] 实现单餐报告生成
- [ ] 实现 7 日趋势计算
- [ ] 完成 LangGraph AI 工作流骨架

### Phase 4：打磨与扩展
- [ ] AI 模型接入与 Prompt 优化
- [ ] 陪伴式对话能力完善
- [ ] 完整的集成测试
- [ ] 部署和文档完善

---

## 📚 API 契约

API 设计遵循 OpenAPI 3.0 规范，详见 [contracts/api.yaml](contracts/api.yaml)

关键资源端点：
- `POST /api/v1/devices/bind` — 绑定 BLE 设备
- `GET /api/v1/settings` — 获取用户提醒设置
- `PUT /api/v1/settings` — 更新提醒设置
- `POST /api/v1/meals` — 上传单餐数据
- `GET /api/v1/meals/{mealId}/report` — 获取单餐报告
- `GET /api/v1/trends/weekly` — 获取 7 日趋势
- `POST /api/v1/chat` — 发送对话消息

---

## 📖 文档

- [**架构设计**](docs/architecture.md) — 整体技术架构与设计原则
- [**后端架构**](docs/backend_architecture.md) — 后端详细设计
- [**产品需求**](AGENTS.md) — 项目 MVP 需求与工程指南
- [**产品定义**](PRD.md) — 完整产品文档（含上下文与决策）

---

## 🔨 本地开发

### 预装工具
- 数据库初始化：见 [backend/README.md](backend/README.md)
- 前端热重载支持：`flutter run` 自动 hot reload
- 后端开发：`uvicorn --reload` 自动重启

### 调试与验证

#### BLE 协议验证
1. 打开 App 的"设备连接 / 蓝牙调试页"
2. 扫描设备，查看原始 `manufacturer data`
3. 验证解析后的重量值是否准确
4. 支持可调的偏移量配置

#### API 集成测试
```bash
# 后端已启动（见快速开始）
# 打开 http://localhost:8000/docs
# 在 Swagger UI 内验证各个端点
```

---

## 🎓 重要约束与原则

| 原则 | 说明 |
|------|------|
| **不依赖在线** | 餐中提醒完全本地化，不需联网 |
| **本地优先** | 设置本地生效，异步上传后端同步 |
| **设计简洁** | 不为 MVP 增加超出范围的复杂功能 |
| **规则优先** | 实时判断用规则，不用 AI |
| **AI 补充** | AI 用于离线分析、报告、建议 |
| **无广告登录** | 匿名 UUID，不做注册登录 |
| **数据完全性** | 所有核心数据本地备份，确保离线可用 |
| **扩展预留** | 为后续登录、多设备、多语言预留接口 |

---

## 🤝 贡献指南

本项目目前处于 MVP 阶段，欢迎反馈与贡献。

- 问题反馈：提交 Issue
- 功能建议：讨论 Issue 或提交 PR
- 遵循项目约定：见 AGENTS.md 与 PRD.md

---

## 📄 许可证

MIT License - 见 [LICENSE](LICENSE)

---

## 📞 联系方式

项目相关问题、反馈或合作意向，欢迎联系项目团队。

---

**最后更新**: 2026 年 4 月  
**MVP 版本**: v0.1.0  
**项目状态**: 🚧 施工中 (Phase 1-2)
