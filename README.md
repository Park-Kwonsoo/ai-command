# ai-command

Ghostty + zsh 환경에서 자연어를 셸 명령으로 변환해 **입력줄에만 채워주는** 개인용 플러그인입니다.

API key를 직접 쓰지 않고, 이미 로그인된 CLI를 백엔드로 사용합니다.

- `codex`
- `claude`

자동 실행은 하지 않습니다.  
항상 생성된 명령을 보고 직접 Enter로 실행합니다.

---

## Features

- `# 자연어` 입력 후 Enter
- `Cmd+I`로 현재 입력 중인 자연어를 명령으로 변환
- 결과를 **실행하지 않고 BUFFER만 교체**
- Ghostty와 잘 맞는 간단한 키바인딩
- backend 전환 가능: `codex` / `claude`
- Warp 비슷한 경량 UX

---

## Why

이 플러그인은 아래 목적에 맞춰 만들었습니다.

- Ghostty는 유지하고 싶음
- Warp처럼 가끔 자연어로 명령을 만들고 싶음
- API key를 따로 관리하고 싶지 않음
- 이미 인증된 CLI 세션을 그대로 재사용하고 싶음
- 자동 실행은 위험하니 원하지 않음
이 플러그인의 UX 아이디어는 [`zsh-ai`](https://github.com/matheusml/zsh-ai) 같은 자연어 기반 zsh command helper 흐름을 참고했지만, 구현은 API key 대신 이미 인증된 CLI(`codex`, `claude`)를 사용하는 방향으로 다르게 구성했습니다.

---

## Requirements

- macOS
- zsh
- Ghostty
- 아래 중 하나 이상이 설치 및 로그인 완료 상태
  - `codex`
  - `claude`

---
## Final Configuration

아래 구성을 기준으로 사용합니다.

```text
~/.config/zsh/plugins/ai-command/
├── ai-command.zsh
├── bin/
│   └── ai-command-gen
└── setup.sh
---

## Directory Layout

추천 구조는 아래와 같습니다.

```text
~/.config/zsh/plugins/ai-command/
├── ai-command.zsh
├── bin/
│   └── ai-command-gen
├── README.md
└── .gitignore

## References

- [matheusml/zsh-ai](https://github.com/matheusml/zsh-ai)
  - `# 자연어` 형태의 UX를 참고한 프로젝트
  - 이 저장소는 API key/provider 중심 접근이지만, 이 플러그인은 같은 UX를 유지하면서 이미 로그인된 CLI(`codex`, `claude`)를 백엔드로 쓰는 방향으로 구성함
