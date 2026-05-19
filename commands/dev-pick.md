---
description: "认领 Issue 并创建开发分支"
---

# 认领开发任务

## 配置

读取 `.claude-devops.yml`，确定：
- `$PROJECT_ROOT`
- `$DEFAULT_BRANCH`
- `$SCOPES`
- GitHub labels 体系

**用户参数**: $ARGUMENTS（Issue 编号，或 `next`）

## 步骤 1：选择任务

- 如用户指定编号，读取该 issue
- 如输入 `next`，优先选择 `status: todo` 且未被阻塞的任务
- 检查依赖任务是否已完成

## 步骤 2：理解任务

- 提取任务描述、完成标准、影响范围、父需求、依赖任务
- 用 3-5 个要点复述任务边界，再开始开发

## 步骤 3：创建开发分支

分支名格式：`feat/{issue编号}-{kebab-case-summary}`

- 基于 `$DEFAULT_BRANCH` 创建新分支
- 如项目使用 worktree，可提示或进入 worktree 模式

## 步骤 4：更新 Issue 状态

- 打 `status: in-progress`
- 如原有 `status: todo`，移除或替换
- 输出开发前检查清单
