---
description: "版本发布：生成 CHANGELOG、Tag 和 GitHub Release"
---

# 发布版本

## 配置

读取 `.claude-devops.yml`，确定：
- `$PROJECT_ROOT`
- `$DEFAULT_BRANCH`
- `$VERSION_FILE`
- `$CHANGELOG_FILE`
- `$CONVENTIONAL_COMMITS`
- `$DEPLOY_ENABLED`

**用户参数**: $ARGUMENTS（major / minor / patch，或留空自动判断）

## 步骤 1：检查发布前提

- 当前分支应与 `$DEFAULT_BRANCH` 同步
- 工作区应干净
- 最近需要发布的 PR 已全部合并

## 步骤 2：确定版本号

- 如用户指定 major/minor/patch，则按指定升级
- 否则根据 conventional commits 自动推断
- 更新版本文件中的版本字段

## 步骤 3：生成 CHANGELOG

- 汇总自上一个 tag 以来的 commit/PR
- 归类为 feat / fix / refactor / docs / chore
- 写入 `$CHANGELOG_FILE`

## 步骤 4：创建 tag 和 release

- 创建 Git tag
- 推送 tag
- 创建 GitHub Release

## 步骤 5：后续动作

- 如 `deploy.enabled=true`，询问是否触发 `/deploy`
- 否则提示用户下一步可部署或通知团队
