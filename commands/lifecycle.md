---
description: "全流程编排：统一串联 requirement → task-split → dev-pick → dev-submit → pr-review → merge → release"
---

# 开发全流程编排

## 配置

读取 `.claude-devops.yml`，确定：
- `$PROJECT_ROOT`
- `$DEFAULT_BRANCH`
- 可用命令与启用模块

**用户参数**: $ARGUMENTS（start / next / review / merge / release / status）

## 支持子命令

- `/lifecycle start "需求描述"` → `/requirement` → `/task-split`
- `/lifecycle next` → 自动选择下一个可做任务 → `/dev-pick`
- `/lifecycle review [PR#]` → `/pr-review`
- `/lifecycle merge [PR#]` → `/merge`
- `/lifecycle release [type]` → `/release`
- `/lifecycle status` → 展示 open issues / open PRs / 最近 tags / 下一步建议

## status 输出建议

- Todo 任务数
- In-progress 任务数
- 待审 PR
- 最近版本
- 建议下一步操作

## 注意

- 该命令是 orchestrator，不重复实现子命令细节
- 需要时直接调用对应命令
