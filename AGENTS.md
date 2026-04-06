# AI 智能餐垫项目说明

## 项目目标
构建一个「AI 智能餐垫」MVP。

当前硬件简化为一台名为 `BH` 的 BLE 电子秤。前端 App 通过扫描蓝牙广播解析 manufacturer data 获取重量。第一版优先走“扫描广播包 + 解析数据”，不要优先依赖 GATT characteristic。

目标链路：
蓝牙重量 -> 餐次判断 -> 提醒设置 -> 单餐报告 -> 趋势报告 -> AI 总结/建议 -> 后续陪伴式对话

## 总体技术路线

### 前端
- Flutter
- 本地存储：SQLite / sqflite
- BLE：扫描广播获取数据
- 本地能力：
  - BLE scan service
  - manufacturer data parser
  - weight processor
  - meal engine
  - reminder service
  - reminder settings service
  - local settings cache
  - local db

### 后端
- FastAPI 作为主业务后端
- PostgreSQL 作为数据库
- 第一版不要引入 Redis
- 异步 AI 报告先用 FastAPI BackgroundTasks
- LangGraph 只用于 AI 工作流，不要把整个业务后端 graph 化

## 产品规则
- 实时吃饭判断不用 AI，主要靠规则算法
- AI 只负责：
  1. 单餐总结
  2. 趋势总结
  3. 陪伴式对话
  4. 督促与建议
- 不要把 BLE 协议解析放到后端
- 不要让联网成为提醒的前提
- 设置采用“本地优先，后端同步”

## 用户身份模型
- MVP 不做注册登录
- App 首次启动生成匿名 UUID，并持久化到本地
- 所有 meal / settings / report / trend / chat 数据都归属于 `anonymousUserId`

## 提醒设置规则
必须支持以下字段：
- reminderEnabled
- reminderFrequency
- reminderText
- voiceEnabled
- quietHours

要求：
- 用户可以编辑提醒文字内容
- 用户可以修改提醒语音内容
- 第一版优先采用“文字可编辑 + 系统 TTS 试播/播报”
- 不要第一版做复杂音色市场或云端语音文件管理

## 前端页面范围
只先做 5 个页面：
1. 设备连接 / 蓝牙调试页
2. 首页
3. 用餐实时页
4. 单餐报告页
5. 趋势 + 设置页

### 设备连接 / 蓝牙调试页
功能：
- 扫描 BH 设备
- 显示设备名、MAC、RSSI
- 显示 raw manufacturer data
- 显示解析后的重量值
- 便于验证 0g / 6g / 102g / 150g / 300g 等数据

### 首页
功能：
- 设备在线状态
- 最近一餐摘要
- 今日记录餐次
- 跳转到实时页 / 报告页 / 趋势页 / 设置页

### 用餐实时页
功能：
- 当前重量
- 当前速度
- 是否过快
- 开始/结束吃饭判断
- 触发提醒
- 记录提醒次数

### 单餐报告页
功能：
- 本餐时长
- 总进食克数
- 平均速度
- 峰值速度
- 提醒次数
- 一句话总结
- 预留 AI 单餐建议展示位

### 趋势 + 设置页
趋势：
- 最近 7 天平均速度
- 最近 7 天快吃次数
- 改善率
- 预留 AI 趋势总结展示位

设置：
- 提醒开关
- 提醒频率
- 提醒文字内容可编辑
- 语音内容可修改
- 语音试播
- 静音时段
- 本地缓存生效提示

## 后端模块范围
业务模块：
1. device
2. settings
3. meal
4. report
5. trend
6. chat

### device
- 绑定匿名用户与设备
- 保存 device name / mac / bind time
- 查询当前设备

### settings
- 保存和读取用户提醒设置
- 字段至少包括：
  - reminderEnabled
  - reminderFrequency
  - reminderText
  - voiceEnabled
  - quietHours

### meal
- 接收单餐上传数据
- 接收重量样本
- 接收提醒事件
- 接收餐次事件
- 数据归属于 anonymousUserId

### report
- 返回单餐报告
- 如果 AI 结果未生成，先返回规则报告
- AI 结果生成后可覆盖或补充

### trend
- 返回最近 7 天趋势
- 计算平均速度 / 快吃次数 / 改善率

### chat
- 陪伴式对话接口
- 为后续“督促 + 建议 + 陪伴”做准备
- 保存 thread / message / summary / memory 关联关系

## LangGraph AI 模块
1. meal_insight_graph
- 单餐 AI 总结
- 单餐建议
- 低可信数据降级

2. trend_insight_graph
- 趋势总结
- 趋势建议
- 样本不足时降级

3. companion_chat_graph
- 陪伴式对话
- 督促建议
- 基于用户近期餐次和偏好生成回复

## 数据与命名约定
- JSON 返回字段统一 camelCase
- 数据库表可用 snake_case
- 统一关键字段：
  - anonymousUserId
  - deviceId
  - mealId
  - weightGram
  - avgSpeed
  - peakSpeed
  - intakeGrams
  - reminderCount
  - reminderText
  - voiceEnabled
  - quietHours

## 工程结构要求
根目录应包含：
- frontend/
- backend/
- contracts/
- docs/

### 前端建议结构
frontend/
  lib/
    core/
      ble/
      parser/
      engine/
      reminder/
      storage/
      network/
    pages/
    models/
    providers/ or state/
    services/

### 后端建议结构
backend/
  app/
    api/
    schemas/
    models/
    services/
    ai/
      graphs/
      nodes/
      prompts/
    db/
    tasks/

### 契约与文档
- 在 contracts/ 下创建 api.yaml 或等价 OpenAPI 文件
- 在 docs/ 下输出 architecture.md
- 前后端都以 contracts/api.yaml 为准

## 实施顺序
### Phase 1
- 建项目目录
- 建 API 契约
- 建前端页面骨架
- 建后端模块骨架
- 建匿名用户模型
- 建 settings 模型
- 建 meal / report / trend 基础 schema

### Phase 2
- 完成前端蓝牙调试页骨架
- 完成 parser 抽象
- 完成本地 settings cache
- 完成后端 settings / meal / report 基础接口

### Phase 3
- 完成 meal engine 接口与占位实现
- 完成 report / trend 基础返回
- 完成 AI graph 骨架，不要求先接真实模型
- 完成 chat 模块骨架

### Phase 4
- 输出 TODO 和 next steps
- 明确哪些地方还是 mock / stub
- 明确 BLE 协议、真实 AI 模型接入点

## 重要约束
1. 不要为了显得高级而加入超出 MVP 的复杂功能
2. 第一版不要引入 Redis，除非只做扩展位
3. 不要把 BLE 协议解析放到后端
4. 不要把实时判断交给 AI
5. 不要依赖联网才能提醒
6. 不要把前后端字段命名写乱
7. 不要把代码写成一次性 demo，要有继续开发的清晰结构
8. 不要把 BH 协议偏移写死为唯一真相，要做成可调整 parser
9. 不要删除 AI chat / memory 的扩展空间
10. 不要做登录注册系统，匿名 UUID 即可

## 完成标准
1. 有清晰前端和后端工程结构
2. 前端 5 个页面骨架已创建
3. 前端已有 BLE / parser / engine / reminder / storage 基础模块
4. 后端已有 device / settings / meal / report / trend / chat 基础模块
5. 后端已有 LangGraph 3 个 graph 骨架
6. 已有 contracts/api.yaml
7. 已有 docs/architecture.md
8. 已有匿名用户 ID 策略
9. 已有 settings 本地优先、后端同步的设计与接口
10. 明确标注 mock / stub / TODO，不要伪装成已完成
