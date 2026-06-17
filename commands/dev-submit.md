---
description: "自测并提交 PR：执行质量门禁后创建 Pull Request"
---

# 自测并提交 PR

## 配置

读取 `.claude-devops.yml`，确定：
- `$PROJECT_ROOT`
- `$DEFAULT_BRANCH`
- `$QUALITY_GATES`（`compile` / `typecheck` / `lint` / `test` / `build`）
- `$SCOPES`
- `$RELEASE_VERSION_FILE`

**用户参数**: $ARGUMENTS（可选：附加说明或 commit message）

## 核心原则：先证明可编译，再允许提交

`/dev-submit` 是提交前最后一道本地质量门禁。除纯文档变更外，必须在 commit / push / PR 之前完成“可编译证明”：

1. 至少执行一个能证明代码可编译的阻断门禁：优先 `compile`，其次 `typecheck`，最后 `build`
2. 对受影响代码继续执行 `lint`、`test`、`build` 中所有已启用且有命令的门禁
3. 任一必需门禁失败、缺失命令或被跳过，都禁止继续提交
4. 不允许用“稍后 CI 会跑”替代本地门禁
5. 只有用户明确确认“本次跳过本地门禁”时，才可继续；PR body 必须记录跳过原因和风险

## 步骤 1：预检查

1. 检查当前分支，禁止在 `$DEFAULT_BRANCH` 上继续
2. 检查工作区是否存在变更
3. 确认依赖可用：
   - Node：存在 `node_modules` 或可运行项目包管理器；缺失时先询问/执行安装
   - Python：确认虚拟环境或依赖安装状态
   - Java/Go：确认构建工具可用
4. 扫描敏感信息：
   - `.env`
   - 私钥 / token / password / secret
   - 大文件与意外产物

## 步骤 2：范围识别

- 根据完整 PR 变更集判断受影响 scope，必须同时覆盖当前分支已提交变更、staged、unstaged、untracked：
  - 优先 `git fetch origin "$DEFAULT_BRANCH"`，然后执行 `git diff --name-only "origin/$DEFAULT_BRANCH"...HEAD`
  - 如果没有远程或 fetch 失败，回退为 `git diff --name-only "$DEFAULT_BRANCH"...HEAD`
  - 再合并 `git diff --name-only HEAD`
  - 再合并 `git ls-files --others --exclude-standard`
  - 合并去重后作为本次 PR / 提交候选文件列表
- 不要只使用裸 `git diff --name-only` 或只看 `HEAD` 工作区差异，它会漏掉已暂存变更或当前分支上已提交但尚未进入 PR 的代码变更
- 区分变更类型：
  - **代码变更**：源代码、配置、依赖、构建脚本、数据库迁移、Dockerfile、CI 等
  - **流程/模板变更**：`commands/**`、`rules/**`、`templates/**`、`.github/workflows/**`、`install.sh`、`lib/**` 等会改变 skill 行为的文件；即使是 Markdown，也不能按纯文档跳过验证
  - **纯文档变更**：仅普通说明文档、图片等非运行时代码且不改变命令/规则/模板/CI 行为的文件
- 根据受影响 scope 选择需要执行的质量门禁：
  - 单仓项目：执行根项目门禁
  - monorepo：优先执行根项目聚合门禁；如果根门禁缺失，执行受影响 app/package 的等价命令
  - 共享库/配置变更：执行全量门禁，不只跑单个 app

## 步骤 3：补齐前置生成任务

如配置了 `stack.extras` 或检测到相关文件，先执行前置任务，再跑质量门禁：

- Prisma schema 变更或存在 Prisma：先执行 `prisma generate`
- 代码生成、schema 生成、OpenAPI client 生成等项目自定义任务：先执行对应生成命令
- 依赖锁文件变更：确认依赖已安装后再继续

前置任务失败时立即停止，不进入提交步骤。

## 步骤 4：执行质量门禁

### 4.1 必跑顺序

按以下顺序执行启用的 gate：

1. `compile`：编译 / 语法编译 / 构建测试类 / Go dry compile
2. `typecheck`：TypeScript、mypy、静态类型检查等
3. `lint`：lint / vet / ruff 等静态检查
4. `test`：自动化测试
5. `build`：生产构建或可发布包构建

### 4.2 命令解析规则

- 优先读取 `.claude-devops.yml -> stack.quality_gates.<gate>.command`
- 如果配置缺失，按项目现状自动推断：
  - Node：优先使用 `package.json` scripts（`typecheck` / `type-check` / `lint` / `test` / `build`）
  - TypeScript 无 script 时：使用 `npx tsc --noEmit`
  - Python：`python -m compileall .`、`ruff check .`、`pytest`
  - Maven：`mvn -q -DskipTests compile`、`mvn test`、`mvn -q -DskipTests package`
  - Gradle：`./gradlew testClasses`、`./gradlew test`、`./gradlew build`
  - Go：`go test ./... -run '^$'`、`go vet ./...`、`go test ./...`、`go build ./...`
- 如果某个必需 gate 无法解析命令，视为门禁失败：先补 `.claude-devops.yml`，不要直接跳过
- 如果相邻 gate 解析出完全相同的命令（例如 Node 项目中 `compile` 与 `typecheck` 都是 `pnpm typecheck`），只执行一次，并在结果中同时标记两个 gate 已由同一命令覆盖

### 4.3 阻断规则

- 任一步失败则停止
- 报告失败命令、退出码、关键错误摘要和建议修复方向
- 修复后必须从失败的 gate 重新执行，并继续后续 gate
- 禁止在质量门禁失败后 commit / push / 创建 PR
- 禁止只运行测试而不运行编译/类型检查；编译证明是强制项

### 4.4 纯文档变更例外

如果确认是纯文档变更：

- 可跳过 `compile` / `typecheck` / `test` / `build`
- 仍需执行可用的文档 lint / markdown 检查（如项目配置）
- PR body 必须说明“纯文档变更，运行时代码门禁不适用”

## 步骤 5：提交代码

只有步骤 4 全部通过后才允许提交：

- 按 conventional commits 生成 commit message
- scope 优先使用受影响模块标签
- commit body 说明 why，不要写冗余 what

## 步骤 6：创建 PR

- 基于 `.github/PULL_REQUEST_TEMPLATE.md` 生成 PR body
- PR body 必须包含 `Closes #XX` 关键词来关联对应 Issue（支持 `Closes` / `Fixes` / `Resolves`）
  - 如分支名含 Issue 编号（如 `feat/13-xxx`），关联 `Closes #13`
  - 如有多个关联 Issue，全部列出：`Closes #13, Closes #14`
  - 如无法推断 Issue 编号，提示用户手动提供
- PR body 的自测清单必须写明实际执行的命令和结果，例如：
  - `[x] compile/typecheck — pnpm typecheck — passed（两个 gate 命令相同，合并执行一次）`
  - `[x] lint — pnpm lint — passed`
  - `[x] test — pnpm test — passed`
  - `[x] build — pnpm build — passed`
- 更新 Issue/PR 状态为 `in-review`：优先更新 GitHub label 为 `status: in-review`；如项目使用 GitHub Projects，再同步项目字段

## 步骤 7：展示结果

输出：
- 执行过的门禁（命令 + 结果）
- 如有跳过项：跳过原因、用户确认情况、剩余风险
- commit message
- PR 链接
- 后续建议（如 `/pr-review latest`）
