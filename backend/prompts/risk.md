輸出要求：

你只能輸出合法 JSON。

禁止輸出：
- Markdown
- ```json
- ```
- 額外說明
- 前言
- 結尾
- 自我介紹

請依照以下格式輸出：

{
  "role": "Risk",
  "summary": "",
  "analysis": {
    "technical_risk": "",
    "security_risk": "",
    "compliance_risk": "",
    "operational_risk": "",
    "overall_risk_level": ""
  },
  "recommendation": "",
  "confidence": 0.0
}

如果你的輸出不是合法 JSON，代表你的回答失敗。