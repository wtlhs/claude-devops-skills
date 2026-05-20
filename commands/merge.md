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
- 检查 PR body 是否包含 `Closes #XX` 关键词
  - 如缺失，从分支名或 commit message 中推断关联 Issue 并补上
  - 使用 `gh pr edit <PR#> --body` 更新 PR body

## 步骤 2：处理问题

- 如存在冲突，先向用户报告并给出处理方式
- 如 scope 明显偏离父任务，提示拆分或补 issue 说明

## 步骤 3：执行合并

- 默认使用 merge commit
- 合并后删除远程分支
- 如有本地 worktree，同步清理

## 步骤 4：收尾

- GitHub 会在合并时自动关闭 PR body 中 `Closes #XX` 引用的 Issue
- 合并后验证关联 Issue 是否已自动关闭，如未关闭则手动关闭并标记 `status: done`
- 建议下一步执行 `/release` 或 `/lifecycle status`
