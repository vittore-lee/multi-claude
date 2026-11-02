# claude-profiles

Claude 데스크톱 앱(macOS)을 **계정별로 동시에** 실행하기 위한 런처 생성 스크립트.
Run multiple Claude Desktop accounts side by side on macOS.

로그아웃 → 재로그인 없이, Dock 아이콘 클릭만으로 개인/회사 계정 창을 각각 띄울 수 있습니다.

## 동작 원리

Claude 데스크톱은 Electron 앱이며, `--user-data-dir` 플래그로 프로필 폴더를 분리하면 로그인 세션과 앱 설정이 독립된 인스턴스를 동시에 실행할 수 있습니다.
이 스크립트는 그 실행 명령을 감싼 작은 런처 앱(`.app`)을 `~/Applications`에 만듭니다.

- `Claude.app` 자체는 수정·복제하지 않습니다.
- 비공식 우회 방식입니다. Claude 앱 업데이트로 동작이 바뀔 수 있습니다.

## 설치

**일반 터미널(Terminal.app, iTerm 등)에서 실행하세요.** 아래 명령을 Claude Code 세션 입력창에 그대로 붙여넣으면 작업 요청으로 처리되어 실패합니다. Claude Code에 설치를 맡기려면 [Claude Code로 설치하기](#claude-code로-설치하기)를 참고하세요.

```bash
curl -fsSL https://raw.githubusercontent.com/vittore-lee/multi-claude/main/claude-profiles.sh -o ~/claude-profiles.sh

bash ~/claude-profiles.sh main        # 기본 계정 런처 → ~/Applications/Claude Main.app
bash ~/claude-profiles.sh add Work    # 추가 계정 런처 → ~/Applications/Claude Work.app
```

필요한 만큼 `add <이름>`으로 계정을 추가할 수 있습니다(영문·숫자·`-`·`_`).

## Claude Code로 설치하기

터미널 명령 대신 Claude Code에 설치를 맡길 수 있습니다.

**조건: 자기 Mac에서 실행되는 Claude Code 세션이어야 합니다.**

- 가능: Mac 터미널의 `claude`, Claude 데스크톱 앱 Code 탭에서 로컬 폴더로 연 세션
- 불가: claude.ai/code 웹 세션 등 클라우드 세션 (런처가 내 Mac이 아니라 클라우드 컨테이너에 생성되고, macOS가 아니라서 스크립트가 중단됩니다)

세션 입력창에 아래 문장을 붙여넣으세요. `Work`는 원하는 계정 이름으로 바꾸면 됩니다(영문·숫자·`-`·`_`).

```text
https://github.com/vittore-lee/multi-claude 의 README를 읽고 claude-profiles.sh 를 내려받아 설치해줘.
기본 계정 런처(main)와 추가 계정 런처(Work)를 만들어줘. 런처를 실행하지는 마.
설치가 끝나면 README의 '설정' 1~4단계를 내가 따라 할 수 있게 순서대로 안내해줘.
```

명령 실행 권한을 물으면 승인하세요. 설치가 끝나면 아래 [설정](#설정) 1~4단계(Dock 정리, 첫 로그인)는 직접 진행해야 합니다. Claude Code가 이 단계를 순서대로 안내해 줍니다.

## 설정

설치 스크립트는 런처만 만듭니다. 아래 4단계는 처음 한 번만 직접 진행하세요.

### 1단계. Dock의 기존 Claude 아이콘 제거

1. Dock의 Claude 아이콘을 우클릭(또는 control+클릭)합니다.
2. **옵션 → Dock에서 제거**를 선택합니다. Claude가 실행 중이면 **옵션 → Dock에 유지**의 체크를 해제합니다.

앱이 삭제되지는 않습니다. Dock에서 아이콘만 빠집니다.
이 아이콘을 남겨 두면 누를 때 계정이 섞여 열리므로 제거하는 것이 좋습니다([이유](#왜-기본-계정에도-런처가-필요한가)).

### 2단계. 런처를 Dock에 고정

1. 런처 폴더를 엽니다. 설치 직후에는 Finder에 자동으로 열려 있습니다. 닫았다면 Finder 메뉴에서 **이동 → 폴더로 이동**(⇧⌘G)을 누르고 `~/Applications`를 입력한 뒤 Return을 누릅니다.
2. `Claude Main`과 `Claude <이름>`(예: `Claude Work`)을 Dock으로 드래그합니다. Dock의 구분선 왼쪽, 앱 아이콘들 사이에 놓습니다.

> 런처는 **홈 폴더의 `~/Applications`**(`/Users/<사용자>/Applications`)에 생성됩니다.
> Finder 사이드바의 "응용 프로그램"(시스템 `/Applications`)과 다른 폴더입니다.

### 3단계. 기본 계정 열기

1. Dock의 `Claude Main`을 클릭합니다. 기존 계정으로 열립니다.
2. 보안 경고가 뜨면 Finder에서 런처를 우클릭하고 **열기**를 누른 뒤, 다시 **열기**를 누릅니다.
3. 그래도 열리지 않으면 **시스템 설정 → 개인정보 보호 및 보안**에서 아래쪽의 **그래도 열기**를 누릅니다.

### 4단계. 추가 계정 로그인

1. 열려 있는 Claude 창을 모두 종료합니다(⌘Q).
   - 브라우저 인증 후 돌아오는 `claude://` 링크가 다른 창으로 가는 것을 막기 위함입니다.
2. Dock의 `Claude Work`를 클릭하고 추가 계정으로 로그인합니다.
3. 로그인이 끝나면 `Claude Main`도 클릭합니다. 이제 두 계정 창이 동시에 떠 있습니다.

## 앱이 종료된 뒤 다시 열기

- Dock에 고정한 런처(`Claude Main` / `Claude <이름>`)를 클릭합니다. 로그인은 유지됩니다.
- Dock의 원래 Claude 아이콘은 쓰지 마세요. 기본 계정으로 열리거나, 이미 떠 있는 창만 앞으로 옵니다.
- 터미널: `open ~/Applications/"Claude <이름>.app"`

## 명령어

| 명령 | 설명 |
|---|---|
| `main` | 기본 계정 런처 생성 (기존 Claude 프로필 사용) |
| `add <이름>` | 추가 계정 런처 생성. 데이터: `~/Library/Application Support/Claude-<이름>` |
| `list` | 런처 목록과 실행 중인 인스턴스 확인 |
| `remove <이름>` | 런처 삭제 (계정 데이터 유지) |
| `remove <이름> --purge` | 런처 + 계정 데이터 폴더 삭제 (확인 후) |

## 왜 기본 계정에도 런처가 필요한가

Dock의 원래 Claude 아이콘은 같은 `Claude.app`이 이미 실행 중이면 새 창을 띄우지 않고 실행 중인 창을 앞으로 가져옵니다.
추가 계정 인스턴스도 같은 `Claude.app`이므로, 추가 계정이 먼저 떠 있으면 원래 아이콘으로는 기본 계정을 열 수 없습니다.
`Claude Main` 런처는 `open -n`으로 항상 새 인스턴스를 띄우고, 기본 계정 창이 이미 떠 있으면 중복 실행하지 않습니다.

## 주의사항

분리되는 것: 로그인 세션, 앱 캐시, `claude_desktop_config.json`(로컬 MCP 설정). 대화·프로젝트·커넥터는 계정 단위로 서버에 저장됩니다.

공유되는 것:

- **로컬 파일**: 같은 폴더를 두 계정 창에서 동시에 수정하면 서로의 변경을 덮어쓸 수 있습니다.
- **`~/.claude`**: Claude Code 설정·스킬·훅은 두 인스턴스가 공유합니다.
- **`claude://` 링크**: 로그인·커넥터 인증은 해당 인스턴스만 띄운 상태에서 진행하세요.
- **로컬 MCP 서버**: 고정 포트를 쓰는 서버는 한 계정 설정에만 등록하세요.

운영 팁:

- 로그아웃 대신 창 종료로 운용
- 앱 업데이트 후에는 모든 Claude 창을 종료하고 런처로 다시 열기
- 실행 중에 Dock에 나타나는 Claude 아이콘은 고정하지 않기 (플래그 없이 실행되어 기본 계정으로 열림)

## 제거

```bash
bash ~/claude-profiles.sh remove Work --purge
bash ~/claude-profiles.sh remove main
```

## 참고

- `--user-data-dir` 방식: https://philippstracker.com/multiple-claude-instances/

## License

MIT
