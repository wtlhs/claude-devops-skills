# 命令说明

## 支持命令

- `/requirement`
- `/task-split`
- `/dev-pick`
- `/dev-submit`
- `/review`
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

## 典型流程

```text
/requirement → /task-split → /dev-pick → /dev-submit → /review → /merge → /release
```
