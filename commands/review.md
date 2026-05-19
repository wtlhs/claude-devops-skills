---
description: "PR 审查：按配置定义的多维度执行代码审查"
---

# PR 审查

## 配置

读取 `.claude-devops.yml`，确定：
- `$PROJECT_ROOT`
- `$REVIEW_DIMENSIONS`
- `$DOMAIN_NAME`
- `$DEFAULT_BRANCH`

**用户参数**: $ARGUMENTS（PR 编号，或 `latest`）

## 步骤 1：选择 PR

- 如指定 PR 编号，则读取该 PR
- 如输入 `latest`，读取最新待审查 PR
- 获取标题、描述、关联 issue、变更文件、CI 状态

## 步骤 2：读取变更

- 查看完整 diff，而不是只看最后一个 commit
- 必要时读取受影响文件完整上下文

## 步骤 3：按维度审查

逐条执行 `review.dimensions` 中定义的维度，例如：
- correctness
- code-standards
- security
- performance
- testing
- documentation
- deployment

如配置了 `domain.name`，增加对应领域原则检查。

## 步骤 4：形成结论

分类输出：
- CRITICAL
- HIGH
- MEDIUM
- LOW

优先处理 CRITICAL / HIGH，再考虑是否自动修复非设计性问题。

## 步骤 5：写回审查结果

- 可执行 `gh pr review`
- 也可先向用户展示摘要，再等待确认是否发出 review
