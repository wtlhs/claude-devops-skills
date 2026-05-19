---
description: "版本回滚：优先使用非破坏性 revert，必要时再执行强制回退"
---

# 回滚版本

## 配置

读取 `.claude-devops.yml`，确定：
- `$PROJECT_ROOT`
- `$DEFAULT_BRANCH`
- `$DEPLOY_ENABLED`

**用户参数**: $ARGUMENTS（版本号，如 `v1.2.3`，或 `prev`）

## 步骤 1：确定回滚目标

- 读取最近 tags
- 确定用户想回滚到的版本
- 分析该范围内的 commits / PR / migrations

## 步骤 2：选择回滚方式

默认：
- 使用 `git revert` 生成回滚提交 / PR（非破坏性）

紧急场景：
- 仅在用户明确确认时，使用强制回退

## 步骤 3：风险检查

- 检查是否有数据库 migration
- 检查是否涉及外部接口或环境变量调整
- 给出回滚影响摘要

## 步骤 4：执行与验证

- 生成回滚分支或提交
- 如 `deploy.enabled=true`，提示后续部署回滚版本
