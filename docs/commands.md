# 命令说明

## 支持命令

- `/requirement`
- `/task-split`
- `/dev-pick`
- `/dev-submit`
- `/pr-review`
- `/merge`
- `/release`
- `/rollback`
- `/lifecycle`
- `/deploy`

## 基本原则

1. 所有命令优先读取 `.claude-devops.yml`
2. 如配置缺失，按项目现状自动检测
3. 如项目已有 GitHub 模板和规则，默认不覆盖
4. `/deploy` 默认关闭，需要在配置里显式开启

## `/dev-submit` 质量门禁

`/dev-submit` 在创建 commit / PR 前必须证明代码可编译：

- 代码变更至少通过 `compile`、`typecheck`、`build` 之一，其中优先使用 `compile`
- 继续执行所有已配置的 `lint`、`test`、`build`
- 任一必需门禁失败或缺失命令时停止，不允许提交
- 纯文档变更可以跳过运行时代码门禁，但需要在 PR body 写明原因

## 典型流程

```text
/requirement → /task-split → /dev-pick → /dev-submit → /pr-review → /merge → /release
```
