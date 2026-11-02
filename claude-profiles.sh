#!/bin/bash
# claude-profiles.sh — Claude 데스크톱 앱을 계정별로 동시에 실행하기 위한 런처 생성기 (macOS)
#
# 원리: Claude 데스크톱은 Electron 앱이라 --user-data-dir 로 프로필 폴더를 분리하면
#       계정(로그인 세션·설정)이 독립된 인스턴스를 동시에 띄울 수 있다.
#       이 스크립트는 그 실행 명령을 감싼 작은 런처 앱(.app)을 ~/Applications 에 만든다.
#       Claude.app 자체는 수정하지 않는다. (비공식 우회 방식 — 앱 업데이트로 동작이 바뀔 수 있음)
#
# 사용법 (반드시 일반 터미널에서 실행. Claude Code 세션 입력창에 붙여넣지 말 것):
#   bash claude-profiles.sh main               기본 계정 런처 생성  → ~/Applications/Claude Main.app
#   bash claude-profiles.sh add <이름>         추가 계정 런처 생성  → ~/Applications/Claude <이름>.app
#   bash claude-profiles.sh list               런처 목록과 실행 상태 확인
#   bash claude-profiles.sh remove <이름>      런처 삭제 (계정 데이터는 유지)
#   bash claude-profiles.sh remove <이름> --purge   런처 + 계정 데이터 폴더 삭제
#   ('main' 을 이름으로 쓰면 기본 계정 런처가 대상)
#
# 설정 후:
#   1) Dock의 기존 Claude 아이콘 제거 (우클릭 → 옵션 → Dock에서 제거)
#   2) ~/Applications 의 런처들을 Dock에 고정. 실행 중에 생기는 Claude 아이콘은 고정하지 말 것
#   3) 추가 계정 첫 로그인은 다른 Claude 창을 모두 끈 상태에서 진행
#      (브라우저 인증 후 돌아오는 claude:// 링크가 다른 인스턴스로 가는 것을 방지)
#
# 주의:
#   - 같은 작업 폴더를 두 계정 창에서 동시에 수정하지 말 것 (파일 시스템은 공유됨)
#   - ~/.claude (Claude Code 설정·스킬·훅)는 두 인스턴스가 공유함
#   - 앱 업데이트 후에는 모든 Claude 창을 종료하고 런처로 다시 열 것

set -euo pipefail

CLAUDE_APP="/Applications/Claude.app"
CLAUDE_BIN="$CLAUDE_APP/Contents/MacOS/Claude"
LAUNCHER_DIR="$HOME/Applications"
DATA_BASE="$HOME/Library/Application Support"
BUNDLE_PREFIX="local.claude-launcher"

die()  { echo "오류: $*" >&2; exit 1; }
info() { echo "→ $*"; }

check_env() {
  [[ "$(uname)" == "Darwin" ]] || die "macOS 전용입니다."
  [[ -x "$CLAUDE_BIN" ]] || die "$CLAUDE_APP 이 없습니다. https://claude.ai/download 에서 설치하세요."
}

validate_name() {
  local name="$1"
  [[ -n "$name" ]] || die "이름을 지정하세요. 예: add Work"
  [[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || die "이름은 영문·숫자·-·_ 만 사용할 수 있습니다: $name"
  [[ "$(echo "$name" | tr '[:upper:]' '[:lower:]')" != "main" ]] || die "'main' 은 예약어입니다. 기본 계정은 'main' 명령을 쓰세요."
}

# 런처 앱 골격(Info.plist, 아이콘) 생성
make_bundle() {
  local app="$1" id="$2" display="$3"
  mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
  cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>launcher</string>
<key>CFBundleIdentifier</key><string>$id</string>
<key>CFBundleName</key><string>$display</string>
<key>CFBundleDisplayName</key><string>$display</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
</dict></plist>
EOF
  local icns
  icns="$(ls "$CLAUDE_APP"/Contents/Resources/*.icns 2>/dev/null | head -1 || true)"
  if [[ -n "$icns" ]]; then
    cp "$icns" "$app/Contents/Resources/AppIcon.icns"
  fi
  touch "$app"   # Finder/Dock 아이콘 캐시 갱신용
}

# 생성된 런처 위치를 Finder로 열어 줌 (/Applications 가 아니라 홈 폴더의 ~/Applications)
reveal() {
  info "런처 위치: $LAUNCHER_DIR  (시스템 /Applications 가 아니라 홈 폴더 안의 응용 프로그램 폴더)"
  info "Finder에서 열린 폴더의 런처를 Dock으로 드래그해 고정하세요."
  /usr/bin/open "$LAUNCHER_DIR" 2>/dev/null || true
}

cmd_main() {
  check_env
  local app="$LAUNCHER_DIR/Claude Main.app"
  mkdir -p "$LAUNCHER_DIR"
  make_bundle "$app" "$BUNDLE_PREFIX.main" "Claude Main"
  cat > "$app/Contents/MacOS/launcher" <<'EOF'
#!/bin/bash
# 기본 프로필용 런처: 기본 프로필 인스턴스가 이미 떠 있으면 중복 실행하지 않음
BIN="/Applications/Claude.app/Contents/MacOS/Claude"
while IFS= read -r line; do
  [[ "$line" == "$BIN" || "$line" == "$BIN "* ]] || continue
  [[ "$line" == *"--type="* || "$line" == *"--user-data-dir"* ]] && continue
  exit 0
done < <(ps -axo command)
exec /usr/bin/open -n -a /Applications/Claude.app
EOF
  chmod +x "$app/Contents/MacOS/launcher"
  info "생성: $app"
  info "기본 계정(기존 Claude 프로필)을 엽니다."
  reveal
}

cmd_add() {
  check_env
  local name="${1:-}"
  validate_name "$name"
  local app="$LAUNCHER_DIR/Claude $name.app"
  local data="$DATA_BASE/Claude-$name"
  mkdir -p "$LAUNCHER_DIR" "$data"
  make_bundle "$app" "$BUNDLE_PREFIX.$name" "Claude $name"
  cat > "$app/Contents/MacOS/launcher" <<'EOF'
#!/bin/bash
# 추가 프로필용 런처: 해당 프로필 인스턴스가 이미 떠 있으면 중복 실행하지 않음
BIN="/Applications/Claude.app/Contents/MacOS/Claude"
DATA="__DATA__"
mkdir -p "$DATA"
while IFS= read -r line; do
  [[ "$line" == "$BIN "* ]] || continue
  [[ "$line" == *"--type="* ]] && continue
  if [[ "$line" == *"--user-data-dir=$DATA" || "$line" == *"--user-data-dir=$DATA "* ]]; then
    exit 0
  fi
done < <(ps -axo command)
exec /usr/bin/open -n -a /Applications/Claude.app --args --user-data-dir="$DATA"
EOF
  # 데이터 경로 치환 (경로의 & 와 | 이스케이프)
  local esc
  esc="$(printf '%s' "$data" | sed -e 's/[&|\\]/\\&/g')"
  sed -i '' "s|__DATA__|$esc|" "$app/Contents/MacOS/launcher"
  chmod +x "$app/Contents/MacOS/launcher"
  info "생성: $app"
  info "데이터: $data"
  info "첫 로그인은 다른 Claude 창을 모두 종료한 뒤 이 런처로 진행하세요."
  reveal
}

cmd_list() {
  echo "[런처]"
  local found=0 app id
  shopt -s nullglob
  for app in "$LAUNCHER_DIR"/*.app; do
    id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null || true)"
    if [[ "$id" == "$BUNDLE_PREFIX".* ]]; then
      echo "  $(basename "$app")"
      found=1
    fi
  done
  [[ $found -eq 1 ]] || echo "  (없음)"

  echo "[실행 중인 Claude 인스턴스]"
  local running=0 line
  while IFS= read -r line; do
    [[ "$line" == "$CLAUDE_BIN" || "$line" == "$CLAUDE_BIN "* ]] || continue
    [[ "$line" == *"--type="* ]] && continue
    if [[ "$line" == *"--user-data-dir="* ]]; then
      echo "  프로필: ${line#*--user-data-dir=}"
    else
      echo "  프로필: 기본"
    fi
    running=1
  done < <(ps -axo command)
  [[ $running -eq 1 ]] || echo "  (없음)"
}

cmd_remove() {
  local name="${1:-}" purge="${2:-}"
  [[ -n "$name" ]] || die "삭제할 이름을 지정하세요. 예: remove Work"
  local app data
  if [[ "$(echo "$name" | tr '[:upper:]' '[:lower:]')" == "main" ]]; then
    app="$LAUNCHER_DIR/Claude Main.app"
    data=""
  else
    validate_name "$name"
    app="$LAUNCHER_DIR/Claude $name.app"
    data="$DATA_BASE/Claude-$name"
  fi
  if [[ -d "$app" ]]; then
    rm -rf "$app"
    info "런처 삭제: $app"
  else
    info "런처 없음: $app"
  fi
  if [[ "$purge" == "--purge" ]]; then
    [[ -n "$data" ]] || die "기본 계정 데이터는 이 스크립트로 삭제하지 않습니다."
    if [[ -d "$data" ]]; then
      read -r -p "계정 데이터 폴더를 삭제합니다 ($data). 진행할까요? [y/N] " ans
      if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
        rm -rf "$data"
        info "데이터 삭제: $data"
      else
        info "데이터 유지"
      fi
    fi
  elif [[ -n "$data" && -d "$data" ]]; then
    info "데이터는 유지됨: $data  (삭제하려면 --purge)"
  fi
}

usage() { sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; }

case "${1:-}" in
  main)   cmd_main ;;
  add)    cmd_add "${2:-}" ;;
  list)   cmd_list ;;
  remove) cmd_remove "${2:-}" "${3:-}" ;;
  ""|-h|--help|help) usage ;;
  *) die "알 수 없는 명령: $1  (help 참고)" ;;
esac
