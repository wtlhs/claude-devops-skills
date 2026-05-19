---
description: "部署到目标环境：按项目配置执行可选的多环境部署"
---

# 部署

## 配置

读取 `.claude-devops.yml`，确定：
- `$PROJECT_ROOT`
- `deploy.enabled`
- `deploy.environments_dir`
- `deploy.source_paths`
- `deploy.service_aliases`

**用户参数**: $ARGUMENTS（环境名 + 服务名/服务组）

## 前置判断

- 如 `deploy.enabled != true`，停止并提示：当前项目未启用部署模块，请先在 `.claude-devops.yml` 中配置 `deploy.enabled: true` 和环境目录。
- 如环境配置目录不存在，提示先创建并参考 `templates/deploy/environment.yml.template`

## 步骤 1：加载环境配置

- 从 `deploy.environments_dir` 读取环境配置文件
- 支持用户指定环境（如 `test-demo` / `production`）
- 未指定时默认使用项目约定的默认环境

## 步骤 2：分析近期变更

- 根据 `deploy.source_paths` 映射，识别哪些目录有变更
- 输出推荐部署的服务列表
- 询问用户确认实际部署范围

## 步骤 3：执行部署前检查

- 远程主机连通性
- 目标目录是否存在
- Docker / Compose / 运行时依赖是否就绪
- 必要环境变量和配置文件是否齐全

## 步骤 4：备份

- 备份 compose、环境配置、容器状态等关键信息

## 步骤 5：执行部署

- 代码变更：拉取代码 / 构建 / 重启服务
- 配置变更：同步配置 / 重启受影响服务
- 具体命令严格以环境配置中的约定为准

## 步骤 6：部署后验证

- 容器状态
- 日志中是否有明显错误
- 关键 HTTP 健康检查
- 如有静态产物校验，也一并验证

## 步骤 7：报告结果

- 输出已部署服务
- 验证结果
- 回滚建议
