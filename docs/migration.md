# 迁移指南

## 从 scm-bi-system 迁移到通用技能包

### 当前状态

`scm-bi-system` 当前在工作区级 `.claude/commands/` 中维护 10 个硬编码命令，路径、scope、部署目录和领域原则都与项目强绑定。

### 迁移目标

迁移后改为：

- 项目级 `.claude/commands/`
- 项目级 `.claude/rules/`
- 项目根 `.claude-devops.yml`
- 所有项目差异都通过配置表达

### 建议迁移步骤

1. 在 `scm-bi-system` 根目录执行 `install.sh`
2. 生成 `.claude-devops.yml`
3. 手工补齐以下项目特有配置：
   - `domain.name: BI-First`
   - `domain.principle`
   - `deploy.enabled: true`
   - `deploy.environments_dir`
   - `deploy.source_paths`
   - `deploy.service_aliases`
4. 验证 10 个命令行为与旧版一致
5. 将旧版工作区级命令移除

### scm-bi-system 建议补充配置

- `repository.project_path: "scm-bi-system"`
- `stack.type: "node-monorepo"`
- `stack.package_manager: "pnpm"`
- `stack.monorepo.tool: "turborepo"`
- `deploy.environments_dir: "../scm-docker-build/deploy/environments"`

### 验证清单

- `/requirement` 能正常产出需求文档
- `/task-split` 能按模板创建父子 issue
- `/dev-submit` 能按 pnpm + tsc + vitest + build 执行门禁
- `/deploy` 能识别 `test-demo` 环境并做服务推荐
