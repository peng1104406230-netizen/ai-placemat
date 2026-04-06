# AI 智能餐垫前端阶段架构说明

## 当前范围

本阶段建设 Flutter 前端，并继续维护 `contracts/api.yaml` 和 `docs/architecture.md` 两个公共文件。

明确不在本阶段实现的内容：

- 不实现任何 backend 调用
- 不接真实业务网络接口
- 不实现 FastAPI
- 不实现 LangGraph

## 前端目标

围绕 MVP 主链路，先把以下前端骨架建立起来：

1. 匿名用户 ID 本地生成与缓存
2. 扫描 `BH` BLE 广播包的服务骨架
3. `manufacturer data` 解析器骨架
4. 重量处理器骨架
5. 用餐状态判断引擎骨架
6. 提醒服务骨架
7. 设置本地缓存与本地数据库骨架
8. 五个页面的导航和占位 UI

## 前端链路

当前前端阶段围绕本地链路搭建：

`BLE scan -> raw manufacturer data -> parser -> stable weight -> meal engine -> reminder -> local storage`

设计原则：

- 餐中判断必须本地完成，不依赖联网
- parser 不把 `BH` 协议偏移写死为唯一真相
- 设置采用本地优先设计
- `reminderText`、`voiceEnabled`、`quietHours` 必须作为一等字段进入模型和页面
- 所有结构化字段统一使用 camelCase

## 目录规划

```text
frontend/
  lib/
    core/
      ble/
      parser/
      engine/
      reminder/
      storage/
    models/
    pages/
    providers/
    services/
```

各目录职责：

- `core/ble/`: 扫描 `BH` 广播包的本地服务接口与真实 BLE 插件接入入口
- `core/parser/`: 可调整的 `manufacturer data` 解析 stub
- `core/engine/`: 重量处理器与餐次判断引擎
- `core/reminder/`: 本地提醒与 TTS 播报占位
- `core/storage/`: 匿名用户、本地设置、本地数据库占位
- `models/`: 页面和本地模块共享的数据结构
- `pages/`: 五个 MVP 页面骨架
- `providers/`: 应用内状态聚合
- `services/`: 应用启动和依赖装配的轻量入口

## 匿名用户策略

- App 首次启动时在本地生成 `anonymousUserId`
- 当前阶段已接入匿名用户仓储接口，并通过 `shared_preferences` 做本地持久化
- 后续如接服务端，同一字段继续沿用，不改名

建议持久化方案：

- 当前实现：用轻量本地键值存储持久化 `anonymousUserId`
- 备选：后续也可随 SQLite 初始化一起落盘

## 设置本地优先策略

当前设置模型最少包含：

- `reminderEnabled`
- `reminderFrequency`
- `reminderText`
- `voiceEnabled`
- `quietHours`

当前阶段已实现本地缓存读写，不实现远端同步。

本地优先读写策略：

1. App 启动时先加载本地设置
2. 餐中提醒只读取本地设置
3. 用户修改设置时先写入本地缓存并立即生效
4. 后续若需要远端同步，只能作为附加流程，不能阻塞本地提醒

## BLE 与 Parser 设计

### BLE Scan

BLE 服务当前已接入 `flutter_blue_plus`，目标行为是：

- 扫描周围 BLE 广播包
- 在调试页中突出展示 `BH` 候选设备
- 读取广播中的 `manufacturer data`
- 输出可供调试页展示的设备信息、RSSI、raw hex、service data 和接收时间

当前状态：

- 代码层已经具备真实扫描入口
- 调试页已可触发真实扫描或载入本地预览广播
- 调试页会保留最近 20 个原始扫描设备
- 调试页会额外保留最近 `BH` 样本列表，便于协议收敛前采样
- macOS 真机运行当前仍受 CocoaPods TLS 环境问题影响，不是 Flutter 代码语法问题

### BH 样本采集准备

当前 parser 收敛前，调试页优先支持人工采样记录：

- 当前 `BH` 广播会在页面顶部高亮显示
- 当前 `BH` 的 `manufacturer data` 可直接复制
- 整条 `BH` 样本可直接复制，包含时间戳、MAC、RSSI、manufacturer data、service data、connectable
- 最近 `BH` 样本列表按时间倒序保留，便于记录 `0g / 6g / 10g / 20g / 102g / 150g / 300g`

这一阶段不改 parser 协议真值，只做采样准备。

### Parser

Parser 当前必须保持“可调整”：

- 允许配置候选偏移
- 允许配置字节序
- 允许配置缩放因子
- 返回置信度和说明
- 当前仅提供 stub 结果与示例逻辑，不把任何偏移视为最终协议

## 页面范围

本阶段完成以下页面骨架：

1. 设备连接 / 蓝牙调试页
2. 首页
3. 用餐实时页
4. 单餐报告页
5. 趋势 + 设置页

这些页面当前只承载结构、导航、字段占位和 mock 数据展示，不代表真实业务已完成。

## Mock / Stub / TODO 原则

为了避免误导，所有未完成能力都显式标注：

- `stub`: 有接口和默认行为，但没有真实实现
- `mock`: 仅用固定示例数据驱动页面
- `TODO`: 明确后续接真实 BLE、TTS、SQLite 或网络同步的位置

## Local DB 接口层设计

当前阶段已经落下最小可用本地数据库版本，使用 `sqflite` / `sqflite_common_ffi`。

建议最小表意对象：

- `LocalMealRecord`
- `LocalWeightSample`
- `LocalReminderEvent`

当前接口分层：

- `MealRecordStore`
- `WeightSampleStore`
- `ReminderEventStore`

当前最小表：

- `meal_records`
- `weight_samples`
- `reminder_events`

这样后续继续扩展 SQLite 结构时，不需要推翻页面层和业务层源码。

## 后续前端阶段建议

1. 修复 macOS 侧 CocoaPods TLS 环境，恢复插件可运行链路
2. 把 parser 调试能力做成可配置实验面板
3. 用真实重量流持续驱动 `weight processor -> meal engine -> reminder`
4. 把本地餐次写入从 demo seed 过渡到真实实时记录
5. 在保持本地优先前提下，再考虑后续与 backend 的同步
