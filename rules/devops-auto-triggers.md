---
description: "自动触发 GitHub Flow 开发全流程命令"
---

# DevOps Commands 自动触发规则

当用户表达以下意图时，优先调用对应命令：

- 设计需求 / 写需求 / 整理需求 → `/requirement`
- 拆分 issues / 拆任务 / 拆成 issue → `/task-split`
- 认领任务 / 开始开发 → `/dev-pick`
- 提交代码 / 提交 PR → `/dev-submit`
- 审查 PR / review code → `/review`
- 合并 PR → `/merge`
- 发布版本 / 打 tag → `/release`
- 回滚版本 → `/rollback`
- 查看全流程状态 → `/lifecycle status`
- 部署 / 发布到服务器 → `/deploy`

补充规则：

1. 如果项目未配置 `.claude-devops.yml`，先按默认约定自动检测。
2. 如果 `deploy.enabled` 为 false，用户提到部署时，先引导其配置部署环境。
3. 如果项目定义了领域原则（如 BI-First / API-First），在 `/requirement`、`/task-split`、`/review` 中自动纳入判断。
4. 对于“先设计需求再拆任务”这类复合指令，按 `/requirement` → `/task-split` 顺序执行。
