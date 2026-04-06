# AI 智能餐垫后端最小架构说明

## 当前范围

本阶段只建设最小后端版本，并且只覆盖以下 4 个业务模块：

1. settings
2. meal
3. report
4. trend

明确不在当前范围内的内容：

- 不做登录注册
- 不做 Redis
- 不做复杂聊天系统
- 不做 BLE 协议解析
- 不把 AI 放进实时判断链路

## 技术路线

- FastAPI
- PostgreSQL
- SQLAlchemy
- FastAPI BackgroundTasks
- LangGraph 位置先以 graph stub 表达，不接真实模型

## 匿名用户模型

- 前端首次启动生成 `anonymousUserId`
- 后端以 `anonymousUserId` 识别数据归属
- 不引入账号体系

## 当前工程结构

```text
backend/
  app/
    api/
      routes/
    schemas/
    models/
    services/
    ai/
      graphs/
    db/
    tasks/
    main.py
```

## 数据表

当前只定义 5 张表：

1. `users`
2. `user_settings`
3. `meal_sessions`
4. `meal_reports`
5. `trend_snapshots`

简化策略：

- `samples` 和 `events` 暂存为 `meal_sessions` 表中的 JSON 字段
- 这样先跑通最小版本，后续再按需要拆表

## 接口

当前后端对外接口：

- `GET /settings`
- `PUT /settings`
- `POST /meal/upload`
- `GET /meal/{mealId}`
- `GET /report/{mealId}`
- `GET /trend/7d`

说明：

- `GET /settings` 和 `GET /trend/7d` 通过 query 参数传 `anonymousUserId`
- `GET /meal/{mealId}` 与 `GET /report/{mealId}` 也要求携带 `anonymousUserId`，避免跨用户取数

## 规则与 AI 分层

### settings

- 负责提醒设置读写
- 默认值由后端补齐
- 字段保持与前端 camelCase 契约一致

### meal

- 负责接收单餐上传
- `samples` 和 `events` 先支持简化结构
- 上传成功后通过 `BackgroundTasks` 触发报告和趋势刷新

### report

- 先生成规则报告
- 再由 `meal_insight_graph` stub 补一个 AI 总结占位
- 当前不接真实模型

### trend

- 基于最近 7 条餐次近似生成 7 天趋势快照
- 再由 `trend_insight_graph` stub 补一个 AI 趋势总结占位

## Stub / TODO

当前明确仍是 stub 的部分：

- `backend/app/ai/graphs/meal_insight_graph.py`
- `backend/app/ai/graphs/trend_insight_graph.py`
- 真实 LangGraph 编排
- 真实模型接入
- 更细粒度的趋势统计口径
- 更稳健的异常处理与任务隔离

## 不做的事情

- 不引入 Redis
- 不加 chat 模块
- 不实现 BLE 协议处理
- 不实现登录注册
