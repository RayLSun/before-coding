# before-coding

`before-coding` 是一个面向个人项目的开发前置技能。它把已经确认的产品行为、架构边界和验证方式落到项目文档中，再进入实现阶段，减少多轮迭代时把既有好实现改坏的问题。

它把职责分成两层：

- 技能仓库维护通用流程、模板、安装器和升级脚本。
- 目标项目维护自己的 `AGENTS.md`、`CLAUDE.md`、`docs/`、`.before-coding.json` 和业务测试。

`grill-me` 用于挖掘真实需求、用户、流程、边界和验收标准。只有在需要讨论现有文档缺陷时才使用 `grill-with-docs`；两者都需要时先完成 `grill-me`，再进行文档评审。技能完成需求和文档澄清后停止，不自动写业务代码。

## 安装

需要 Windows PowerShell 5.1 或更高版本。先把仓库克隆到本机：

```powershell
git clone git@github.com:RayLSun/before-coding.git
cd before-coding
```

把技能安装到目标项目的 Codex、Claude，或两种运行时：

```powershell
.\install-before-coding.ps1 `
  -ProjectPath 'D:\Projects\my-project' `
  -Runtime Both
```

如果目标目录不存在，脚本会先询问是否创建。目标项目已有同名技能时，默认逐项询问；也可以使用 `-OnConflict Skip` 保留现有内容，或使用 `-OnConflict BackupReplace` 先备份再替换。

## 项目初始化

安装技能后，在目标项目中创建开发基线文档：

```powershell
.\init-before-coding.ps1 `
  -ProjectPath 'D:\Projects\my-project' `
  -Runtime Both
```

初始化脚本会创建：

- `AGENTS.md`
- Claude 运行时需要的 `CLAUDE.md`（内容为 `@AGENTS.md`）
- `docs/product-contract.md`
- `docs/architecture.md`
- `docs/verification.md`
- `docs/changes/README.md`
- `.before-coding.json`

每个已有文件都会单独处理冲突，不会静默覆盖。初始化后，使用 `before-coding` 技能和 `grill-me` 讨论项目；若需要审查已有文档，再使用 `grill-with-docs`。

## 版本升级

从本仓库的当前版本更新目标项目中的技能副本：

```powershell
.\update-before-coding.ps1 `
  -ProjectPath 'D:\Projects\my-project' `
  -Runtime Both
```

升级脚本会：

- 备份已有的 `.agents/skills/before-coding` 和 `.claude/skills/before-coding`；
- 安装仓库当前版本的技能副本；
- 更新 `.before-coding.json` 的技能版本和更新时间；
- 保留目标项目的产品、架构、验证和变更文档。

升级后，其他模型仍可通过项目中的 `AGENTS.md` 或 `CLAUDE.md` 读取项目规则；需要使用技能本身的流程时，建议显式调用 `before-coding`，这样可以确保当前对话加载了完整的技能指令。

## 文档边界

| 文件 | 作用 |
|---|---|
| `AGENTS.md` | 项目级工作规则和文档入口 |
| `CLAUDE.md` | Claude Code 的共享入口，导入 `AGENTS.md` |
| `docs/product-contract.md` | 当前用户旅程、确认过的行为、不变量和范围 |
| `docs/architecture.md` | 模块职责、数据流、集成边界和架构决策 |
| `docs/verification.md` | 已运行的命令、验收场景和验证缺口 |
| `docs/changes/` | 新功能和跨模块变更的任务协议 |
| `.before-coding.json` | 初始化运行时、文件处理状态和技能版本 |

代码与文档不一致时，不要直接猜测哪一方正确；先记录差异，再根据用户确认更新基线。确认过的产品行为只有在明确批准后才能改变。

## 开发与验证

运行技能结构校验：

```powershell
python 'C:\Users\raysun\.codex\skills\.system\skill-creator\scripts\quick_validate.py' '.\before-coding'
```

运行 PowerShell 集成测试：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File '.\tests\test_install.ps1'
```

发布新版本时，更新 `VERSION` 和 `CHANGELOG.md`，运行上述检查，然后提交并创建版本标签：

```powershell
git add .
git commit -m "chore: release before-coding 0.2.0"
git tag v0.2.0
git push origin main --tags
```

## 许可证

本项目使用 MIT License，详见 [`LICENSE`](LICENSE)。
