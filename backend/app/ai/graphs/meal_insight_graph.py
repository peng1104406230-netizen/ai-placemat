class MealInsightGraph:
    """Stub meal insight graph.

    TODO:
    - Replace this mock implementation with a real LangGraph workflow.
    - Add confidence checks and low-signal downgrade logic.
    - Plug in model provider configuration when AI integration starts.
    """

    def run(self, payload: dict) -> dict:
        avg_speed = payload.get("avgSpeed", 0)
        reminder_count = payload.get("reminderCount", 0)
        if avg_speed >= 18:
            ai_summary = "stub: AI 判断本餐前半段进食节奏偏快，建议优先延长停顿。"
        elif reminder_count > 0:
            ai_summary = "stub: AI 观察到提醒后节奏有所回落，可继续沿用当前提醒文案。"
        else:
            ai_summary = "stub: AI 认为本餐整体节奏较平稳，继续积累更多样本。"

        return {
            "aiSummaryText": ai_summary,
            "suggestions": [
                "stub: 下一餐优先关注开餐前 10 分钟的速度变化。",
                "stub: 后续接真实模型后再补自然语言个性化建议。",
            ],
        }
