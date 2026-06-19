# AGENTS.md

本文件用于指导 agent 推进 Deng Killer 项目。请先阅读根目录 `PRD.md`，再动手修改代码。

## 项目定位

Deng Killer 的第一版目标是“对话中的事实护盾”：记录对话，抽取可核验事实主张，对可疑或重要主张进行证据核验，并用低打扰方式提醒用户。

请始终遵守以下产品边界：

- 这是事实核验助手，不是帮助用户赢辩论、压制对方或生成攻击性话术的工具。
- 输出应帮助用户识别“哪些话值得查”，并给出温和、可用于真实对话的更准确说法。
- 初步分类只代表可疑程度，不应被当作最终真伪结论。
- 高风险领域，如政治、医疗、法律、投资，不给最终决策建议；只给证据、限制和谨慎提示。

## 当前仓库结构

- `PRD.md`：产品需求和系统方案的主要来源。
- `frontend/`：当前 iPhone MVP，使用 Swift 6、SwiftUI 和 XcodeGen。
- `frontend/DengKillerCore/`：核心业务逻辑，包括 transcript、claim scoring、verification client 协议和 view model。
- `frontend/DengKillerApp/`：SwiftUI 应用壳和展示层。
- `frontend/DengKillerTests/`：核心逻辑测试。
- `frontend/DengKillerUITests/`：iOS UI 测试。
- `backend/`：计划中的 FastAPI 核验服务，目前尚未实现。

## 默认推进顺序

优先保持现有 Swift 前端 MVP 可用，再逐步补齐真实能力：

1. 维护并扩展现有 mock conversation flow、claim scoring 和 review flow。
2. 接入真实音频采集和 ASR，但必须保持“完整句子才触发处理”。
3. 将规则和 mock scorer 演进为 claim extraction、worthiness scoring 和 initial classification。
4. 增加后端 FastAPI verification service，只接收单条待核验 claim 和最小必要上下文。
5. 接入搜索、轻量 RAG 和 evidence judgement，最终输出必须保留证据摘要。

不要在没有明确需求时引入大规模重构、复杂状态管理框架、完整账号系统或云端会话存储。

## 隐私红线

隐私边界是核心产品约束。任何实现都必须默认保护用户完整对话：

- 默认不上传完整音频。
- 默认不上传完整转写。
- 默认不上传 speaker 历史、完整会话上下文或普通 claim。
- 后端默认只接收单条待核验事实主张和最小必要上下文。
- 后端默认不保存完整对话、完整转写、音频或普通 claim。
- 只有在用户明确授权后，才可保存高置信错误样例或公开证据缓存。

涉及网络请求、存储、日志、分析埋点和错误上报时，先检查是否违反以上边界。测试中应覆盖“只发送单条 claim 和最小上下文”的行为。

## 产品交互原则

- ASR partial transcript 不触发 claim processing；只有 final sentence 进入后续流程。
- `checkworthy_score` 低于 0.40 的内容默认忽略。
- `0.40...0.70` 的内容记录到会后复盘，避免打扰当前对话。
- `0.70...1.00` 且值得核验的内容进入核验队列。
- UI 提醒应低打扰，优先总结“发现 N 条可能错误”，不要实时打断式纠错。
- 用户可见文案应温和、具体、可解释，避免羞辱、嘲讽或攻击性表达。
- 对 `uncertain`、`needs_context`、`controversial` 保持不确定性，不要强行改写成 true/false。

## 工程约定

- 使用 Swift 6 和 SwiftUI，遵循现有代码风格。
- 核心业务逻辑放在 `DengKillerCore`，UI 层保持薄层。
- 使用协议隔离外部服务，例如 `VerificationClient`，方便 mock 和测试。
- 新增可测试业务行为时，优先补充 `frontend/DengKillerTests`。
- 改动 SwiftUI 可见行为或 accessibility identifier 时，同步考虑 `frontend/DengKillerUITests`。
- 修改 `frontend/project.yml` 后，需要重新生成 Xcode 项目。
- 不要把产品规则散落在 UI 视图里；claim scoring、状态转换、隐私边界应留在 core 层。
- 保持中英文命名现状：代码标识符用英文，面向用户文案可用中文。

## 后端约定

后端尚未实现。未来新增后端时，默认采用 PRD 建议的 Python + FastAPI：

- API 以单条 claim verification 为核心，不设计上传完整会话的接口。
- 请求体包含 claim、最小上下文、语言和领域类型即可，除非 PRD 或用户明确要求更多字段。
- 响应应包含 verdict、confidence、issue、correction 和 evidence_summary。
- evidence verification 必须基于搜索或权威资料摘要，不只依赖模型直觉。
- 日志中不得记录完整私密对话或未经授权的原始用户 claim。

## 验证命令

核心逻辑测试：

```sh
cd frontend
swift test
```

修改 `frontend/project.yml` 后重新生成 Xcode 项目：

```sh
cd frontend
tools/xcodegen/xcodegen/bin/xcodegen generate
```

完整 iOS 测试需要可用模拟器：

```sh
cd frontend
xcodebuild test -project DengKiller.xcodeproj -scheme DengKillerApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO
```

## 提交前检查

- 变更是否符合 `PRD.md` 的 MVP 范围。
- 是否保持低打扰提醒，而不是实时打断式纠错。
- 是否保留证据链和不确定性表达。
- 是否没有上传或保存完整音频、完整转写或完整会话。
- 是否更新或新增了对应测试。
- 至少运行 `cd frontend && swift test`，除非本次变更完全不涉及代码且说明原因。
