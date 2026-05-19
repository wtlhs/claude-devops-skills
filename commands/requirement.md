---
description: "需求分析：读取配置驱动的结构化需求文档生成"
---

# 需求分析

## 配置

执行前读取项目根目录的 `.claude-devops.yml`。如不存在，则自动检测：
- 项目根目录
- 需求文档目录（默认 `docs/requirements`）
- 默认分支与 GitHub 远程
- 领域原则（如已配置）

关键变量：
- `$PROJECT_ROOT`
- `$REQUIREMENTS_DIR`
- `$DOMAIN_NAME`
- `$DOMAIN_QUESTIONS`
- `$SCOPES`

**用户参数**: $ARGUMENTS（需求描述文本，或需求文档路径）

## 步骤 1：理解需求

- 解析用户输入的需求描述
- 如输入为文件路径，读取文件内容
- 理解业务背景、目标用户、核心场景
- 优先对齐项目现有 `.github/ISSUE_TEMPLATE/feature.yml` 的字段顺序和措辞
- 如配置了 `domain.name`，按该领域原则做一轮适配判断

## 步骤 2：结构化判断

至少确认：
1. 该需求能否在当前项目边界内完成？
2. 影响哪些 scope？
3. 是否有明确验收标准？
4. 是否需要外部系统支持？
5. 如配置了 `domain.check_questions`，逐条回答

## 步骤 3：生成需求文档

输出到 `$REQUIREMENTS_DIR`，文件命名：`{三位序号}-{kebab-case-title}.md`

文档结构应尽量对齐 feature issue 模板：
- 背景与动机
- 功能描述
- 用户故事
- 核心场景
- 边界情况
- 非功能需求
- 验收标准
- 影响范围
- 领域判断（如已配置）
- 优先级
- 待确认问题

## 步骤 4：展示并确认

- 向用户展示生成内容
- 等待用户确认后，再作为 `/task-split` 的输入
