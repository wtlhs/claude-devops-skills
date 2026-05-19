---
description: "合并 Pull Request：检查 CI、Review、范围一致性后完成合并"
---

# 合并 PR

## 配置

读取 `.claude-devops.yml`，确定：
- `$PROJECT_ROOT`
- `$DEFAULT_BRANCH`
- `$SCOPES`

**用户参数**: $ARGUMENTS（PR 编号，或 `latest`）

## 步骤 1：预检查

- 确认 PR 存在且处于 open
- 检查 CI 是否通过
- 检查是否已有 review approval
- 检查是否有 merge conflict
- 检查改动范围是否与关联 issue 大体一致

## 步骤 2：处理问题

- 如存在冲突，先向用户报告并给出处理方式
- 如 scope 明显偏离父任务，提示拆分或补 issue 说明

## 步骤 3：执行合并

- 默认使用 merge commit
- 合并后删除远程分支
- 如有本地 worktree，同步清理

## 步骤 4：收尾

- 关闭关联 issue 或更新状态为 done
- 建议下一步执行 `/release` 或 `/lifecycle status`
