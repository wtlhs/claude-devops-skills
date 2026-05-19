---
description: "任务拆分：从需求文档拆分为 GitHub Feature / Task Issues"
---

# 任务拆分

## 配置

执行前读取 `.claude-devops.yml`。如不存在，则自动检测项目根目录、scope 列表、GitHub 仓库和默认分支。

关键变量：
- `$PROJECT_ROOT`
- `$SCOPES`
- `$LABELS`
- `$DOMAIN_NAME`

**用户参数**: $ARGUMENTS（需求文档路径）

## 步骤 1：读取需求文档

- 读取用户指定的需求文档
- 提取背景、功能描述、验收标准、影响范围
- 读取项目现有 `.github/ISSUE_TEMPLATE/feature.yml` 与 `task.yml`
- 优先复用模板字段结构，不额外发明一套 body

## 步骤 2：拆分原子任务

拆分规则：
- 每个任务应可由一个开发者在一次会话中完成
- 每个任务有明确输入、输出、完成标准
- 按 scope 分组
- 如有数据库迁移、共享模块、基础设施变更，应独立成任务

## 步骤 3：先创建父 Feature Issue

父 Issue 结构需对齐 `feature.yml`：
- 背景与动机
- 功能描述
- 验收标准
- 影响范围
- 领域判断（如配置）
- 优先级
- 任务清单
- 依赖关系

## 步骤 4：创建子 Task Issues

子任务结构需对齐 `task.yml`：
- 任务描述
- 技术要点
- 完成标准
- 父需求 Issue
- 依赖任务
- 影响范围
- 优先级

## 步骤 5：回填父 Issue

- 将子任务 Issue 编号回填进父 Issue 的任务清单
- 写清依赖关系和建议开发顺序

## 步骤 6：展示结果

输出：
- 父 Issue 编号
- 子任务列表
- 建议开发顺序
- 如配置了 `domain.name`，附带该领域约束说明
