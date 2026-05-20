---
description: "自测并提交 PR：执行质量门禁后创建 Pull Request"
---

# 自测并提交 PR

## 配置

读取 `.claude-devops.yml`，确定：
- `$PROJECT_ROOT`
- `$DEFAULT_BRANCH`
- `$QUALITY_GATES`
- `$SCOPES`
- `$RELEASE_VERSION_FILE`

**用户参数**: $ARGUMENTS（可选：附加说明或 commit message）

## 步骤 1：预检查

1. 检查当前分支，禁止在 `$DEFAULT_BRANCH` 上继续
2. 检查工作区是否存在变更
3. 扫描敏感信息：
   - `.env`
   - 私钥 / token / password / secret
   - 大文件与意外产物

## 步骤 2：范围识别

- 根据 `git diff --name-only` 判断受影响 scope
- 根据受影响 scope 选择需要执行的质量门禁

## 步骤 3：执行质量门禁

按顺序执行启用的 gate：
1. typecheck
2. lint
3. test
4. build

规则：
- 任一步失败则停止
- 报告失败命令、错误摘要和修复建议
- 如配置了 `stack.extras`，可在门禁前执行如 `prisma generate`

## 步骤 4：提交代码

- 按 conventional commits 生成 commit message
- scope 优先使用受影响模块标签
- commit body 说明 why，不要写冗余 what

## 步骤 5：创建 PR

- 基于 `.github/PULL_REQUEST_TEMPLATE.md` 生成 PR body
- PR body 必须包含 `Closes #XX` 关键词来关联对应 Issue（支持 `Closes` / `Fixes` / `Resolves`）
  - 如分支名含 Issue 编号（如 `feat/13-xxx`），关联 `Closes #13`
  - 如有多个关联 Issue，全部列出：`Closes #13, Closes #14`
  - 如无法推断 Issue 编号，提示用户手动提供
- 更新 Issue/PR 状态为 `in-review`

## 步骤 6：展示结果

输出：
- 执行过的门禁
- commit message
- PR 链接
- 后续建议（如 `/pr-review latest`）
