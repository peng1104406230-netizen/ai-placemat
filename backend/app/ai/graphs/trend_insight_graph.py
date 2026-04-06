class TrendInsightGraph:
    """Stub trend insight graph.

    TODO:
    - Replace this mock implementation with a real LangGraph workflow.
    - Add sample sufficiency checks and conservative downgrade rules.
    - Connect prompt templates and model routing later.
    """

    def run(self, payload: dict) -> dict:
        fast_meal_count = payload.get("fastMealCount", 0)
        improvement_rate = payload.get("improvementRate", 0)

        if fast_meal_count >= 4:
            ai_summary = "stub: AI 认为最近 7 天快吃餐次偏多，建议优先稳住第一阶段节奏。"
        elif improvement_rate > 0:
            ai_summary = "stub: AI 观察到近 7 天速度有改善，可以继续保持当前提醒方式。"
        else:
            ai_summary = "stub: AI 认为当前趋势尚不稳定，建议先继续积累样本。"

        return {
            "aiSummaryText": ai_summary,
        }
