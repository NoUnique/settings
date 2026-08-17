# 맥북 셋업 기록

새 MacBook을 바닥부터 설정하는 과정 기록. Claude Code와 함께 진행.

## 다음 맥에서는 이렇게

```bash
./setup.sh --check   # 현재 상태 점검
./setup.sh           # 전체 실행
```

```
mac-setup/
├── setup.sh          오케스트레이터 (사람 개입을 앞뒤로 몰아넣음)
├── Brewfile          설치할 패키지 선언
├── SETUP-LOG.md      이 문서 — 왜 그렇게 했는지, 어디서 막혔는지
└── scripts/
    ├── git-identity.sh
    ├── ssh-config.sh
    ├── display-more-space.sh
    └── rectangle.sh
```

**설계 원칙: 사람 개입을 앞뒤로 몰아넣고 가운데를 통으로 자동화한다.**

| 순서 | 누가 | 내용 |
|---|---|---|
| ① 앞 | 사람 | TCC 권한 2개 (0번 항목) — 보안 결정이라 위임 불가 |
| ② 앞 | 사람 | `sudo -v` 비밀번호 **1회** — 이후 keepalive로 유지 |
| ③ 중간 | 자동 | CLT · Homebrew · Brewfile · 각종 설정 주입 |
| ④ 뒤 | 사람 | `gh auth login`, SSH passphrase — 자격증명이라 위임 불가 |

중간에 튀어나오는 GUI 창(앱 첫 실행 안내 등)은 Claude가 화면을 캡처해 좌표로 클릭한다.
0번 항목의 권한이 그걸 가능하게 한다.

Claude가 **하지 않는 것**: 비밀번호·passphrase 입력, TCC 권한 토글 클릭.
전자는 자격증명이고 후자는 "Claude에게 권한을 줄지"를 결정하는 스위치라, 사람 몫이다.

## 머신 정보

| 항목 | 값 |
|---|---|
| 시작일 | 2026-08-15 |
| 아키텍처 | arm64 (Apple Silicon) |
| macOS | 26.6.1 (25G76) |
| 사용자 | nounique (admin 그룹) |
| 기본 셸 | /bin/zsh |

---

## 0. Claude에게 컴퓨터 제어 권한 주기 ⭐

**이 항목을 가장 먼저 해야 한다.** 이게 없으면 GUI 창이 뜰 때마다 사람이 클릭해야 하고,
"명령 한 줄로 맥 전체 세팅"이 성립하지 않는다.

시스템 설정 > 개인정보 보호 및 보안 에서 **두 항목** 모두 켠다:

| 항목 | 켜면 가능해지는 것 |
|---|---|
| **손쉬운 사용** | 창·버튼 읽기, 메뉴 조작, 키 입력 (`osascript` / System Events) |
| **화면 기록** | 화면 캡처 (`screencapture` → Claude가 이미지로 직접 확인) |

둘 다 있으면 **화면을 보고 좌표를 계산해 클릭**할 수 있다 (`brew install cliclick`).

### 함정: 목록에 `Claude`가 두 개 나온다

```
claude   ← 소문자, 일반 아이콘   ★ 이걸 켜야 한다
Claude   ← 대문자, Anthropic 아이콘
```

macOS의 권한(TCC)은 앱이 아니라 **코드 서명된 바이너리 단위**로 부여된다. Claude 데스크탑
앱은 실제 작업을 별도 서명된 하위 번들에 위임하므로 둘이 각각 등록된다:

```
/Applications/Claude.app                                  ← 대문자 Claude (UI 본체)
  └ Contents/Helpers/disclaimer
      └ ~/Library/Application Support/Claude/
            claude-code/<버전>/claude.app/.../claude       ← 소문자 claude ★ 명령이 실제로 도는 곳
          └ /bin/zsh
```

대문자만 켜면 계속 `-1728` / `-25211` 에러가 난다.

경로에 버전 번호가 박혀 있지만 TCC는 경로가 아니라 서명으로 식별하므로 업데이트돼도
권한은 유지된다. 업데이트 후 막히면 목록에서 다시 켜면 된다.

### 설정 창 바로 열기

```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
```

### 동작 확인

```bash
osascript -e 'tell application "System Events" to get UI elements enabled'   # → true
osascript -e 'tell application "System Events" to tell process "Finder" to get name of front window'
screencapture -x /tmp/t.png && echo ok
```

### 한계: 접근성 API를 안 열어주는 앱이 있다

Rectangle이 그렇다. 프로세스는 보이는데 창 조회가 `-25211`로 막힌다.
이런 앱은 **좌표 클릭**으로 처리한다 — 앱의 협조가 필요 없다.

```bash
screencapture -x /tmp/s.png     # 화면을 캡처해서 Claude가 눈으로 확인
cliclick c:1342,535             # 논리 좌표로 클릭
```

**좌표 계산 주의**: 레티나 캡처는 논리 해상도의 2배다. 이 맥은 논리 1680x1050 →
캡처 3360x2100. `cliclick`은 **논리 좌표**를 쓰므로 캡처 이미지 좌표를 2로 나눠야 한다.

---

## 1. Xcode Command Line Tools ✅

```bash
xcode-select --install
```

**결과**

- 설치 경로: `/Library/Developer/CommandLineTools`
- 기본 git: `/usr/bin/git` → git 2.50.1 (Apple Git-155)

**메모**
Apple이 제공하는 git은 macOS 업데이트에 묶여 있어 버전이 뒤처진다. 그래서 2단계에서
Homebrew로 최신 git을 따로 설치하고 PATH 우선순위로 그쪽을 쓰게 만든다.

---

## 2. Homebrew 설치 ✅

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**결과**

- Homebrew 6.0.17, 설치 경로 `/opt/homebrew` (Apple Silicon 표준 경로)

### 함정: sudo 비밀번호가 계속 틀렸다

설치 도중 `sudo: 3 incorrect password attempts` →
`Need sudo access on macOS (e.g. the user nounique needs to be an Administrator)!`

**원인은 한글 입력기.** 터미널 비밀번호 프롬프트에서 입력 소스가 한글이면 알파벳이
제대로 입력되지 않는다. 비밀번호는 화면에 표시되지 않으니 알아채기도 어렵다.
Homebrew의 에러 메시지는 "관리자가 아닌 것 같다"고 잘못 안내하는데, 실제로는
`id -Gn`으로 admin 그룹 소속이 이미 확인된 상태였다.

**해결**: `Caps Lock`(또는 `Ctrl+Space`)으로 영문 전환 후 재입력.

**다음 맥에서 쓸 순서** — 설치 스크립트를 통째로 다시 돌리기 전에 비밀번호부터 검증:

```bash
sudo -v
```

성공하면 인증이 5분간 캐시되므로, 이어서 설치 스크립트를 돌리면 비밀번호를 다시 묻지 않는다.

### PATH 설정

설치 후 `brew` 명령을 찾게 하려면 셸 설정이 필요하다. 로그인 셸에서 한 번만 평가되면
되므로 `~/.zshrc`가 아니라 `~/.zprofile`에 넣는다.

`~/.zprofile` (새로 생성):

```sh
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
```

`brew shellenv`는 `PATH`, `MANPATH`, `INFOPATH`를 한꺼번에 잡아준다. PATH를 직접
문자열로 박아 넣는 것보다 이 방식이 낫다.

---

## 3. Homebrew로 git 설치 ✅

```bash
brew install git
```

**결과**

- git 2.55.0 (의존성으로 `gettext`, `libunistring`, `pcre2` 함께 설치)
- Apple git 2.50.1 → Homebrew git 2.55.0

**검증** (`zsh -lc`로 새 로그인 셸에서 확인)

```
which git : /opt/homebrew/bin/git
version   : git version 2.55.0
```

PATH 앞부분:

```
/opt/homebrew/bin
/opt/homebrew/sbin
/usr/local/bin
/System/Cryptexes/App/usr/bin
/usr/bin      ← Apple git은 여기. 뒤에 있으므로 가려진다
```

`/opt/homebrew/bin`이 `/usr/bin`보다 앞에 오기 때문에 Homebrew git이 우선한다.
Apple git이 사라진 게 아니라 가려진 것이고, 필요하면 `/usr/bin/git`으로 직접 호출 가능.

**메모**
- `gitk`, `git-gui`는 별도 formula (`brew install git-gui`)
- `git-svn`도 별도 formula
- zsh 자동완성이 `/opt/homebrew/share/zsh/site-functions`에 설치됨. 아직 `~/.zshrc`가
  없어서 `compinit`이 안 돌아가므로 자동완성은 미작동 상태 — zsh 설정 단계에서 처리.

---

## 4. git 전역 신원 설정 ✅

```bash
git config --global user.name "NoUnique"
git config --global user.email "kofmap@gmail.com"
```

`~/.gitconfig` 생성됨:

```ini
[user]
	name = NoUnique
	email = kofmap@gmail.com
```

### 값을 추측하지 말고 GitHub에서 확인한 방법

`user.name`은 GitHub 로그인과 다를 수 있고, 대소문자 표기(`nounique` vs `NoUnique`)도
헷갈리기 쉽다. 기존 커밋과 신원이 어긋나면 GitHub 기여 그래프가 끊기므로 실제 값을 확인했다.

**1) 로그인의 정확한 대소문자** — GitHub API는 canonical 표기를 돌려준다
(URL은 대소문자를 구분하지 않으므로 아무렇게나 조회해도 된다):

```bash
curl -sS https://api.github.com/users/nounique | grep '"login"'
# → "login": "NoUnique"
```

프로필의 `name`과 `email` 필드는 둘 다 비공개(null)라서 여기서는 답이 안 나왔다.

**2) 실제 커밋 author** — 이게 진짜 근거다. 공개 저장소 커밋에는 author의 name/email이
그대로 들어 있다:

```bash
curl -sS "https://api.github.com/repos/NoUnique/<repo>/commits?author=NoUnique&per_page=30"
```

응답의 `commit.author.{name,email}`을 집계한 결과, 4개 저장소 74개 커밋이 전부
`NoUnique <kofmap@gmail.com>`으로 일치 → 이 값을 그대로 설정.

**메모**
- 커밋 이메일을 공개하고 싶지 않다면 GitHub의 `<id>+<login>@users.noreply.github.com`을
  쓰는 방법도 있다. 단, 이 계정은 이미 공개 커밋에 `kofmap@gmail.com`이 남아 있어
  지금 와서 바꿔도 실익이 없어 기존 값을 유지했다.
- zsh 주의: `for r in $repo` 처럼 따옴표 없는 변수 확장이 zsh에서는 단어 분리를
  하지 않는다(bash와 다름). 스크립트를 옮겨 쓸 때 걸린다.

---

## 5. GitHub CLI(gh) 설치 + 인증 ✅

```bash
brew install gh
gh auth login
```

gh 2.97.0 설치. `gh auth login`은 대화형이라 직접 실행해야 한다.

| 프롬프트 | 선택 |
|---|---|
| Where do you use GitHub? | GitHub.com |
| Preferred protocol for Git operations | **SSH** |
| Generate a new SSH key...? | Yes |
| Enter a passphrase | 설정함 |
| Title for your SSH key | (기본값 `GitHub CLI` → 나중에 변경, 6번 참고) |
| How would you like to authenticate? | Login with a web browser |

**결과** (`gh auth status`)

```
✓ Logged in to github.com account NoUnique (keyring)
  Git operations protocol: ssh
  Token scopes: 'admin:public_key', 'gist', 'read:org', 'repo'
```

### SSH 대신 HTTPS를 고를 뻔한 지점

"push할 때마다 아이디·비번을 입력해서 한 번 더 생각할 기회를 갖고 싶다"는 이유로 HTTPS를
고민했는데, 그건 성립하지 않는다:

- GitHub은 2021년 8월부터 git 작업에 **계정 비밀번호를 받지 않는다.** HTTPS는 비밀번호
  자리에 Personal Access Token을 넣어야 하는데, 손으로 칠 만한 문자열이 아니다.
- `gh auth login`에서 HTTPS를 고르면 gh가 credential helper로 등록돼 **아무것도 묻지 않게**
  된다. 프롬프트를 원하는 목적과 정반대다.

"매번 확인받고 싶다"를 실제로 구현하려면 SSH 키에 passphrase를 걸고 키체인에 **등록하지
않는** 쪽이다(매 접속마다 물어봄). 단 이건 push뿐 아니라 fetch/pull/clone 전부에 걸린다.
push에만 걸고 싶으면 키는 키체인에 넣고 pre-push 훅으로 확인 단계를 만드는 쪽이 정확하다.

→ 이번엔 **키체인 등록(편의) 쪽으로 결정.**

**메모**: `gh`의 인증 토큰과 SSH 키 passphrase는 서로 다른 것이다. 토큰은 gh가 알아서
macOS 키체인(keyring)에 넣지만, **SSH passphrase 키체인 연동은 gh가 해주지 않는다.**
6번에서 직접 설정.

---

## 6. SSH 키 + 키체인 연동 ✅

`gh auth login`이 `~/.ssh/id_ed25519`(ed25519, passphrase 있음)를 생성하고 GitHub에
자동 등록했다. 브라우저에서 공개키를 복붙하는 과정이 없어지는 게 gh를 먼저 설치한 이득.

### ~/.ssh/config (직접 작성)

```sshconfig
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  UseKeychain yes
```

```bash
chmod 600 ~/.ssh/config
```

- `UseKeychain yes` — passphrase를 macOS 키체인에 저장. **재부팅 후에도 다시 묻지 않는다.**
- `AddKeysToAgent yes` — 키를 ssh-agent에 자동 등록. 별도 `ssh-add` 불필요.
- 두 옵션 덕분에 **최초 1회 접속 시 입력한 passphrase가 그대로 키체인에 들어간다.**

### 키 정리 — 제목 변경은 삭제 후 재등록

GitHub에 이전 키(`NoUnique-MacBookProM1`, ssh-rsa, 2025-07-30)가 남아 있었다. 확인 결과
**이 맥을 밀기 전의 키**였다:

```
Model Identifier : MacBookPro17,1
Chip             : Apple M1
ComputerName     : NoUnique-MacBookProM1
```

`~/.ssh`에 `id_rsa`가 없으므로 개인키는 이미 소실 → 아무도 못 쓰는 죽은 키. 삭제 안전.

**GitHub API에는 SSH 키 제목을 수정하는 엔드포인트가 없다.** 등록/삭제만 가능하므로
"이름 변경"은 삭제 후 같은 공개키를 새 제목으로 재등록하는 방식이다. 개인키는 그대로라
로컬 설정은 건드릴 필요 없다.

```bash
gh ssh-key delete <이전_RSA_키_ID> --yes
gh ssh-key delete <방금_등록된_키_ID> --yes
gh ssh-key add ~/.ssh/id_ed25519.pub --title "NoUnique-MacBookProM1"
gh ssh-key list   # 키 하나만 남았는지 확인
```

### 연결 검증

```bash
ssh -T git@github.com
```

- 최초 접속이므로 host 신뢰 확인 → `yes`
- passphrase 입력 → **이 시점에 키체인에 저장됨**
- `Hi NoUnique! You've successfully authenticated...` 출력되면 성공

**메모**: passphrase 입력도 화면에 표시되지 않는다. 2번의 한글 입력기 함정이 여기서도 동일.

**검증 결과** — 지문이 세 곳에서 모두 일치:

```bash
ssh-keygen -lf ~/.ssh/id_ed25519.pub   # 256 SHA256:LTPb2KEzmV0SA0pl8h/NpGV3Be/E0NfOhh+ow7g7iTc
ssh-add -l                             # 동일 지문 → 키체인 저장 + agent 등록 성공
gh ssh-key list                        # NoUnique-MacBookProM1 하나만 등록됨
```

`ssh-add -l`에 키가 보이면 키체인 연동이 된 것이다. 안 보이면 `~/.ssh/config`의
`UseKeychain`/`AddKeysToAgent`가 적용되지 않은 것이니 config 위치와 권한(600)을 확인.

### 정리: "이름 변경"이 실제로 한 일

헷갈리기 쉬워서 남겨둔다. 세 가지는 서로 다른 대상이다.

| 대상 | 무슨 일이 있었나 |
|---|---|
| 로컬 개인키 `~/.ssh/id_ed25519` | **손대지 않음.** gh가 만든 파일 그대로 |
| GitHub 등록 레코드 | **삭제 후 재등록.** 같은 공개키 + 새 제목 |
| 이전 RSA 키 | **영구 삭제.** ①②와 무관한 별개의 키 |

GitHub의 SSH key는 (공개키 + 제목) 한 쌍의 레코드이고 제목 수정 API가 없다. 열쇠는 그대로
두고 명부의 이름표만 다시 쓴 것 — 키를 새로 깎은 게 아니므로 로컬 설정은 그대로 유효하다.

**메모**: GitHub 제목은 계정 쪽 라벨일 뿐 로컬 키 파일에는 기록되지 않는다. 공개키 맨 뒤의
comment 필드(보통 `user@host`)는 그와 별개이고, gh가 만든 키는 이 자리가 비어 있다
(`ssh-keygen -lf`가 `no comment`로 표시). 인증에는 영향 없음.

---

## 7. Google Chrome 설치 ✅

```bash
brew install --cask google-chrome
```

Chrome 151.0.7922.138 → `/Applications/Google Chrome.app`

**메모**
- `--cask`는 GUI 앱용. formula(CLI 도구)와 네임스페이스가 다르다.
- Chrome 캐스크는 sudo가 필요 없다(.app을 옮기기만 함). pkg 인스톨러를 쓰는 일부 캐스크는
  비밀번호를 요구한다.
- 기본 브라우저 지정은 CLI로 완결되지 않는다. macOS가 시스템 확인 창을 띄우므로 마지막
  클릭은 사람이 해야 한다. Chrome 첫 실행 시 직접 물어보는 게 가장 간단.
  (시스템 설정 > 데스크탑 및 Dock > 기본 웹 브라우저 에서도 변경 가능)

---

## 8. 디스플레이 스케일링 — "추가 공간" ✅

14인치급 작은 화면을 쓰므로, 화면에 들어가는 정보량을 최대로 올린다.
(시스템 설정 > 디스플레이 > 추가 공간 과 동일한 결과)

### GUI 없이 CLI로 처리

```bash
brew install displayplacer
displayplacer list          # screen id와 가능한 모드 확인
```

이 맥의 출력:

```
Persistent screen id: 37D8832A-2D66-02CA-B9F7-8F30A301B230
Type: MacBook built in screen
  mode 0: res:960x600   scaling:on
  mode 1: res:1024x640  scaling:on
  mode 2: res:1280x800  scaling:on   ← 기본값
  mode 3: res:1440x900  scaling:on   ← 설정 전 상태
  mode 4: res:1680x1050 scaling:on   ← "추가 공간"
```

적용:

```bash
displayplacer "id:37D8832A-2D66-02CA-B9F7-8F30A301B230 res:1680x1050 hz:60 color_depth:8 scaling:on origin:(0,0) degree:0"
```

### 주의: 해상도 값은 기종마다 다르다

**다음 맥에서 이 명령을 그대로 복사하면 안 된다.** screen id도 다르고 모드 목록도 다르다.
반드시 `displayplacer list`로 확인한 뒤 **가장 큰 `scaling:on` 모드**를 고를 것.
그게 "추가 공간"에 해당한다.

| 기종 | 물리 해상도 | "추가 공간" |
|---|---|---|
| 13" M1 MBP (MacBookPro17,1) — **이 맥** | 2560x1600 | 1680x1050 |
| 14" M1 Pro/Max | 3024x1964 | 1800x1169 |

**메모**
- `scaling:on` = HiDPI(레티나) 렌더링. 논리 해상도만 넓어지고 글자는 선명하게 유지된다.
  픽셀이 늘어난 게 아니라 UI 요소가 작아져서 정보 밀도가 올라가는 것.
- `scaling:off` 모드를 고르면 진짜 저해상도가 되어 글자가 뭉갠다. 반드시 `on`으로.
- 재부팅 후에도 유지되는지 확인할 것. 되돌아간다면 시스템 설정에서 한 번 지정해두면 된다.
- `displayplacer`는 외부 모니터 배치까지 스크립트로 재현할 수 있어서, 도킹 환경을 쓰게 되면
  그때 다시 쓸모가 있다.

---

## 9. Rectangle (창 배치) ✅

```bash
brew install --cask rectangle
```

Rectangle 0.98. 설치 후 **손쉬운 사용 권한**을 켜야 동작한다
(시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용 > Rectangle).

첫 실행 시 단축키 프리셋을 묻는다 → **권장 설정** 선택.
(Spectacle 프리셋은 2018년 단종된 이전 앱의 배열을 재현한 것으로, 조합키가 ⌥⌘ 기반이라
앱 단축키와 충돌이 잦다. 그 앱을 쓰던 사람의 손버릇 보존용.)

### 단축키 배열 — 권장 설정 + 커스텀 6개

**실행: [`scripts/rectangle.sh`](scripts/rectangle.sh)** (설치 + 설정 자동화)

키보드 위치가 곧 의미가 되게 배치한다:

```
  E        T        ← 1/4 계열
  D        F        ← 1/3 계열
 (왼쪽 작은 조각)  (오른쪽 큰 나머지)
```

| 키 | 액션 | 조합 |
|---|---|---|
| ⌃⌥D | 처음 1/3 | **1/3 + 2/3** |
| ⌃⌥F | 마지막 2/3 | |
| ⌃⌥E | 첫번째 1/4 | **1/4 + 3/4** |
| ⌃⌥T | 마지막 3/4 | |
| ⌃⌥⌘C | 가운데 절반 | 1/4 + **1/2** + 1/4 |

### 핵심: 자리마다 키를 배정할 필요가 없다

Rectangle은 **같은 단축키를 반복하면 붙는 모서리는 고정한 채 폭이 순환**한다
(`SubsequentExecutionMode` / `selectedCycleSizes`, 기본 활성).

즉 오른쪽 1/4이 필요하면 ⌃⌥T를 반복해서 3/4에서 계속 줄이면 된다.
`네번째 1/4`, `가운데 1/3` 같은 절대 위치 액션에는 키를 배정하지 않고 **일부러 비운다.**
**외울 키는 D/F/E/T 넷뿐이다.**

### 권장 설정 프리셋과의 차이 6개

권장 설정을 그대로 쓰면 안 되고, 아래 6개를 바꿔야 위 배열이 된다:

| 액션 (plist 키) | 권장 설정 기본값 | 설정값 |
|---|---|---|
| 마지막 2/3 `lastTwoThirds` | ⌃⌥T | **⌃⌥F** |
| 첫번째 1/4 `firstFourth` | (없음) | **⌃⌥E** |
| 마지막 3/4 `lastThreeFourths` | (없음) | **⌃⌥T** |
| 가운데 절반 `centerHalf` | (없음) | **⌃⌥⌘C** |
| 가운데 1/3 `centerThird` | ⌃⌥F | **비움** |
| 마지막 1/3 `lastThird` | ⌃⌥G | **비움** |
| 처음 2/3 `firstTwoThirds` | ⌃⌥E | **비움** |
| 가운데 2/3 `centerTwoThirds` | ⌃⌥R | **비움** |

E·F·T가 기본값에서 다른 액션에 물려 있어서, **비우는 작업과 지정하는 작업이 짝을 이룬다.**

### plist 조작 방법

```bash
# 반드시 종료 상태에서. 실행 중이면 종료할 때 메모리 내용으로 덮어쓴다.
killall Rectangle

defaults write com.knollsoft.Rectangle alternateDefaultShortcuts -bool true  # 권장 설정 프리셋
defaults write com.knollsoft.Rectangle subsequentExecutionMode -int 1        # 크기 순환

# 지정: keyCode + modifierFlags
defaults write com.knollsoft.Rectangle lastTwoThirds -dict keyCode -int 3 modifierFlags -int 786432

# 비움: 빈 dict
defaults write com.knollsoft.Rectangle centerThird -dict

open -a Rectangle
```

| 값 | 의미 |
|---|---|
| `786432` | ⌃⌥ |
| `1835008` | ⌃⌥⌘ |
| `917504` | ⌃⌥⇧ |
| keyCode | D=2 F=3 C=8 E=14 T=17 U=32 I=34 J=38 K=40 / ←123 →124 ↓125 ↑126 |

**메모** — Rectangle의 액션은 전부 **절대 위치**다. 앱 바이너리에서 확인한 액션 목록:

```
firstThird centerThird lastThird / firstTwoThirds centerTwoThirds lastTwoThirds
firstFourth secondFourth thirdFourth lastFourth / firstThreeFourths centerThreeFourths lastThreeFourths
```

`nextThird` / `previousThird` 처럼 **위치를 순환시키는 액션은 없다.** 순환은 오직 "크기"
축에서만 일어난다. 원조 Spectacle 앱에는 위치 순환이 있었지만 Rectangle은 그걸 구현하지
않았고, Spectacle 프리셋도 조합키만 바꿀 뿐 액션은 Rectangle 것을 쓴다.

---

## 10. 전원 관리 — 잠들지 않게 ✅

**실행: [`scripts/power-keep-awake.sh`](scripts/power-keep-awake.sh)**

Claude Code 세션과 원격 개발 연결을 계속 띄워두려면 필수. 기본값이 **AC 전원에서도
`sleep 1`(유휴 1분)** 이라 세션이 계속 끊긴다.

**방침: 전원 소스와 무관하게 절대 잠들지 않는다. 화면만 꺼진다.**

### 설정 전후

```
                    전      후
SleepDisabled      (없음) →  1     ← 뚜껑 닫아도 안 잠듦 (전역)
AC     sleep         1   →  0
       displaysleep 10   → 10
배터리 sleep         1   →  0     ← 배터리에서도 안 잠듦
       displaysleep  2   →  5
```

```bash
sudo pmset -a sleep 0            # -a = 전원 소스 무관
sudo pmset -a disablesleep 1     # 뚜껑 닫기까지 차단
sudo pmset -c displaysleep 10    # 화면은 꺼진다 (AC 10분 / 배터리 5분)
sudo pmset -b displaysleep 5
pmset -g custom                  # 확인
```

### GUI 경로와, pmset을 쓰는 이유

시스템 설정 > 배터리 > 옵션... > **"디스플레이가 꺼져 있을 때 전원 어댑터 사용 시
컴퓨터를 자동으로 잠자지 않게 하기"** 가 AC의 `sleep 0`에 해당한다.

**단 이 토글은 Touch ID 인증을 요구하고, AC에만 적용되며, 뚜껑 닫기는 못 막는다.**
그래서 GUI로는 목표를 달성할 수 없다. `pmset`이 유일한 경로다.

### 뚜껑 닫기 — `disablesleep`

위의 `sleep 0`은 **유휴 잠자기만** 막는다. 뚜껑을 닫으면 여전히 잠든다.
`caffeinate`도 마찬가지로 유휴만 막을 뿐 뚜껑은 못 막는다.

뚜껑까지 막는 건 이것 하나다:

```bash
sudo pmset -a disablesleep 1
pmset -g | grep SleepDisabled     # → SleepDisabled  1
```

**`man pmset`에 문서화되어 있지 않다.** 그래서 man에서 검색해도 안 나오지만 동작하며,
결과는 `pmset -g`의 `SleepDisabled` 키로 확인된다. 외장 디스플레이 없이도 뚜껑을 닫은 채
계속 돌릴 수 있다.

`/Library/Preferences/com.apple.PowerManagement.plist`에 저장되므로 재부팅해도 유지된다.

### ⚠️ 대가: 가방에 넣을 때

배터리에서도 잠들지 않으므로, 뚜껑을 닫고 가방에 넣으면 밀폐 공간에서 계속 돌면서
발열하고 배터리가 마른다. **의도한 동작이지만 이동 시에는 대가가 있다.**

토글을 만들어뒀다:

```bash
scripts/power-keep-awake.sh off      # 이동 전 — 잠자기 복구
scripts/power-keep-awake.sh on       # 책상 복귀 후
scripts/power-keep-awake.sh status   # 현재 상태
```

sudo 캐시가 있으면 그대로 쓰고, 없으면 GUI 인증 창을 띄운다
(`osascript ... with administrator privileges`). Claude는 비밀번호를 입력하지 않으므로
이 창에 사람이 입력한다 — 대신 창을 띄우는 것까지는 Claude가 한다.

### 임시로만 막고 싶을 때

설정을 건드리지 않는 방법:

```bash
caffeinate -is        # Ctrl+C 하면 원상복구
caffeinate -is <명령>  # 그 명령이 도는 동안만
```

단 위에 적었듯 **뚜껑 닫기는 못 막는다.** 유휴 잠자기 전용이다.

---

## 11. 알림 전부 끄기 ✅

**실행: [`scripts/notifications-off.sh`](scripts/notifications-off.sh)**

방침: 보안에 치명적인 것이 아니면 알림은 전부 끈다.

13개 앱 전부 `알림 허용` 해제:
나의 찾기 · 메시지 · 스크린 타임 · 지갑 · 팁 · 홈 · Claude · FaceTime · Finder ·
Game Center · Google Chrome(2개) · Kerberos

### CLI가 없다 — GUI 자동화가 유일한 경로

알림 설정에는 `defaults`로 건드릴 수 있는 공개 경로가 없다.

- 예전에 쓰이던 `~/Library/Preferences/com.apple.ncprefs.plist`는 **macOS 26에 존재하지
  않는다**(확인함). `defaults read com.apple.ncprefs`도 빈 결과.
- 저장 위치·형식이 문서화되어 있지 않다.

그래서 접근성 API로 시스템 설정 UI를 직접 조작한다. **0번 항목의 손쉬운 사용 권한이 필수.**

### UI 자동화에서 막혔던 지점들

| 문제 | 해결 |
|---|---|
| 앱 목록 버튼에 이름이 없음 (`name = missing value`, 자식 요소도 없음) | 이름을 미리 읽지 않고 **인덱스로 열어** 상세 화면에서 앱 이름을 읽는다 |
| 목록 그룹의 인덱스가 불안정 | "버튼이 5개 넘게 든 그룹"으로 **탐색해서** 찾는다 |
| `⌘[` 뒤로가기가 루프 안에서 실패 | 툴바의 `뒤로` 버튼(`button 1 of group 1 of group 1 of toolbar 1`)을 클릭 |
| 사이드바 `알림` 재선택으로 복귀 시도 → 무반응 | 이미 선택된 항목이라 이동이 일어나지 않음. 위와 동일하게 처리 |
| 창 제목이 바뀌면 미리 잡아둔 버튼 참조가 무효화 | 루프 안에서 **매번 새로 조회** |
| AppleScript `set before to ...` 구문 오류 | `before`는 예약어. 변수명 변경 |

### 하위 설정은 건드릴 필요 없다

`알림 허용`을 끄면 하위 항목이 전부 `enabled=false`가 되어 적용되지 않는다.
메시지 앱에서 확인한 값:

```
[알림 허용] value=0 enabled=true
[긴급한 알림] value=1 enabled=false   ← 값은 남아 있지만 비활성
[중요한 알림] value=1 enabled=false
[배지/사운드/요약] value=1 enabled=false
```

목록에서 메시지 부제가 "중요"로 보이는 건 저장된 값의 잔상이다. 실제로는 꺼져 있다.

### 남는 것: "앱 백그라운드 활동" 알림

`'GoogleUpdater' 앱은 백그라운드에서 실행될 수 있습니다` 류의 알림은 **앱 목록에 없다.**
macOS의 백그라운드 항목 관리가 보내는 시스템 알림이고, **백그라운드 항목이 새로 등록될 때만**
뜬다. 설치 작업 중에 몰려 보였을 뿐 상시로 뜨는 게 아니다.

없애려면 시스템 설정 > 일반 > 로그인 항목 및 확장 프로그램 에서 해당 항목 자체를 끄는
방법뿐인데, GoogleUpdater를 끄면 **Chrome 자동 업데이트가 멈춘다.** 보안 업데이트가 걸려
있으므로 권하지 않는다.

**메모**: 새 앱을 설치하면 알림이 켜진 채로 목록에 추가된다. 스크립트는 멱등하므로
앱을 설치한 뒤 다시 실행하면 된다.

### 이미 화면에 떠 있는 배너는 따로 지워야 한다

**실행: [`scripts/notifications-clear.sh`](scripts/notifications-clear.sh)**

설정을 끄는 것은 "앞으로 올 알림"에만 적용된다. 이미 전달되어 우측 상단에 쌓인 배너는
그대로 남는다. 알림 스타일이 "알림(Alerts)"인 항목은 직접 닫기 전까지 사라지지 않는다.

배너의 접근성 경로:

```
NotificationCenter 프로세스
└ window 1  (전체 화면 크기 1680x1050 — 이게 배너 컨테이너)
  └ group 1 → group 1 → scroll area 1 → group 1
    └ group  ← 배너 하나당 group 하나
```

같은 프로세스에 180x180짜리 window가 여러 개 더 있는데 그건 **위젯**이다(날씨 등).
크기로 구분할 것.

**⚠️ 배너 개수에 따라 트리 구조가 달라진다:**

```
여러 개: scroll area → group(컨테이너) → group, group, ...   ← 각각이 배너
한 개  : scroll area → group                                  ← 이게 곧 배너
```

개수만 세는 코드는 배너가 1개일 때 0으로 오판한다. **"static text를 직접 가진 group"** 을
배너로 판정해야 한다.

닫기(X) 버튼은 **마우스를 올려야 AX 트리에 나타난다** (호버 전 `buttons=0` 확인).
`cliclick`으로 배너 중앙에 호버한 뒤 `click button 1`을 호출한다.

`killall NotificationCenter`로는 **지워지지 않는다.** DB에 남아 있어 재표시된다.

**백그라운드 데몬으로 만들 수 없다.** 호버가 필요해서 마우스를 움직여야 하고, 그러면
사용자의 커서를 뺏는다. 작업을 마칠 때 한 번씩 호출하는 용도로 쓴다.

### 자기 자신이 알림을 만든다

`key-remap.sh`가 등록하는 LaunchAgent(`com.nounique.keyremap`) 때문에
`'hidutil' 앱은 백그라운드에서 실행될 수 있습니다` 알림이 떴다.
**LaunchAgent를 등록하면 그 직후 배너가 하나 생긴다.** 등록 후에는 이 스크립트를 같이 돌릴 것.

**메모** — AppleScript에서 숫자를 `&`로 이으면 문자열이 아니라 리스트가 된다.
좌표를 셸로 넘길 때 `(cx as string) & " " & (cy as string)` 처럼 명시적으로 변환해야 한다.
이걸 놓쳐서 좌표가 깨졌었다.

---

## 12. 키 리매핑 — Caps Lock → Esc, 우측 ⌘ → 한/영 ✅

**실행: [`scripts/key-remap.sh`](scripts/key-remap.sh)** (`on` / `off` / `status`)

| 키 | 결과 |
|---|---|
| Caps Lock | Esc |
| 우측 Command | 한/영 전환 |

### Karabiner-Elements를 쓰지 않았다

이 두 매핑만 필요하다면 과하다 — 드라이버 확장(시스템 확장) 승인, 입력 모니터링 권한,
백그라운드 데몬 두 개가 따라온다. macOS 내장 `hidutil`은 **권한 승인이 하나도 없다.**

### 2단계 구성

```bash
# 1) 물리 키 → 다른 키 코드
hidutil property --set '{"UserKeyMapping":[
  {"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029},
  {"HIDKeyboardModifierMappingSrc":0x7000000E7,"HIDKeyboardModifierMappingDst":0x70000006D}
]}'

# 2) F18을 "이전 입력 소스 선택"(hotkey id 60)에 지정
#    parameters = (문자, 가상키코드, 수식키플래그)
#    65535=문자없음, 79=F18 가상키코드, 8388608=0x800000 Function 플래그
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '...'
```

HID usage 코드 (`0x7000000xx` = Keyboard/Keypad page):

| 코드 | 키 | 코드 | 키 |
|---|---|---|---|
| `0x39` | Caps Lock | `0x29` | Escape |
| `0xE7` | Right GUI (⌘) | `0x6D` | F18 |
| `0x90` | LANG1 (한/영) | `0x91` | LANG2 (한자) |

### 함정: LANG1은 동작하지 않았다

처음엔 우측 Command → **LANG1**(한국어 키보드의 물리 한/영 키가 보내는 코드)로 시도했다.
되면 가장 깔끔한 방법이다 — 물리 한/영 키와 완전히 동일해지고 단축키 지정이 필요 없다.

**hidutil 매핑은 적용됐지만 macOS가 LANG1을 입력 소스 전환으로 받아주지 않았다.**
(같은 명령으로 넣은 Caps Lock → Esc는 정상 동작 → hidutil 자체는 문제 없음이 확인됨)

그래서 아무 데도 쓰이지 않는 **F18**로 우회했다. 입력 소스가 ABC와 두벌식 둘뿐이라
"이전 입력 소스 선택"이 곧 한/영 토글이 된다.

### 재부팅 대응

`hidutil` 설정은 메모리에만 남는다. LaunchAgent `com.nounique.keyremap`을 만들어
로그인 시 재적용한다(`RunAtLoad`). 스크립트의 `on`이 등록까지 처리한다.

`symbolichotkeys`는 파일에 저장되지만 **완전히 반영되려면 로그아웃이 필요할 수 있다.**

**메모**
- ⚠️ 우측 Command는 더 이상 수식키가 아니다. `⌘C` 등은 좌측 Command만 동작한다.
- 단축키 GUI 지정을 자동화할 때: 단축키 칸을 **더블클릭**하면 편집 모드가 되고,
  `osascript -e 'tell application "System Events" to key code 79'` 로 F18을 보내면 기록된다.

### 별개 이슈: 한글 조합 중 ⌘A가 한 번에 안 먹는다

**이 변경과 무관하다.** 좌측 Command는 건드리지 않았다.

한글은 조합형이라 `한` 한 글자를 치는 중에도 ㅎ→하→한 으로 조합이 진행된다. 이때 오는 키
이벤트를 **입력기가 먼저 가로채 조합을 확정하는 데 소비**하므로, 첫 `⌘A`가 먹히고 두 번째가
앱에 전달된다. macOS 기본 한글 입력기의 오래된 동작이고 설정으로 끌 수 없다.

구분법: 조합 중이 아닐 때나 영문 입력 상태에서는 항상 한 번에 동작한다.

해결하려면 입력기 교체(구름 입력기 `brew install --cask gureumkim`)뿐인데, Apple 두벌식을
입력 소스에서 빼야 F18 토글이 깨지지 않는다(3개를 순환하게 됨).
→ 이번엔 그냥 두기로 함.

---

## 13. 메뉴 막대 — 배터리 백분율 표시 ✅

**실행: [`scripts/menubar.sh`](scripts/menubar.sh)**

```bash
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
defaults write com.apple.controlcenter BatteryShowPercentage -bool true
killall ControlCenter
```

GUI 경로는 시스템 설정 > 제어 센터 > 배터리 > 백분율 보기.
`defaults`로 끝나므로 GUI 자동화가 필요 없다.

**메모**
- 제어 센터 항목은 `com.apple.controlcenter` 도메인에 있다.
- 변경 후 **`killall ControlCenter`** 를 해야 반영된다. 안 하면 값만 바뀌고 화면은 그대로다.
- `-currentHost`와 일반 도메인 양쪽에 쓴다. macOS 버전에 따라 읽는 쪽이 다르다.

---

## 14. VS Code + Claude Code 확장 ✅

**[`Brewfile`](Brewfile)에 선언** — 별도 스크립트가 필요 없다.

```ruby
cask "visual-studio-code"
vscode "anthropic.claude-code"
```

```bash
brew bundle --file=Brewfile
```

**결과**

- Visual Studio Code 1.133.0
- `anthropic.claude-code` 2.1.233

**메모**
- `brew bundle`은 `vscode "..."` 항목을 만나면 `code --install-extension`을 대신 호출한다.
  확장도 선언으로 관리되므로 스크립트를 따로 둘 이유가 없다.
- 캐스크가 `code`와 `code-tunnel`을 `/opt/homebrew/bin/`에 링크해준다.
  VS Code 안에서 "Shell Command: Install 'code' command in PATH"를 실행할 필요가 없다.
- 확장 ID 확인: `code --list-extensions --show-versions`
- 현재 상태 확인: `brew bundle check --file=Brewfile`

### 첫 실행 온보딩 (자동 처리 가능)

VS Code를 처음 열면 세 화면이 순서대로 뜬다. 전부 GUI 클릭이라 Claude가 처리한다.

| 화면 | 처리 |
|---|---|
| `Sign in to use GitHub Copilot` | **Continue without Signing In** — 승인이 아니라 거절이라 자동 처리 가능 |
| 테마 선택 (`Make It Yours`) | 기본값 `Dark 2026` 유지 → Continue |
| `Build with AI Agents` | Get Started |

### 남는 수동 단계: Claude Code 로그인

활동 표시줄의 Anthropic 아이콘 → 로그인 방식 선택:

```
Claude.ai Subscription   ← Claude Pro / Max / Team / Enterprise 구독 (이 계정은 Max)
Anthropic Console        ← API 사용량 과금
Bedrock, Foundry, Vertex ← 서드파티 제공자
```

**계정 인증이라 사람이 해야 한다.** `gh auth login`, SSH passphrase와 같은 부류.

터미널에서 `claude`를 실행하는 방식도 동일한 계정을 쓴다.

### Codex 확장

```ruby
vscode "openai.chatgpt"   # 표시 이름은 "Codex – OpenAI's coding agent"
```

**확장 ID가 `openai.codex`가 아니라 `openai.chatgpt`다.** 표시 이름과 다르니 주의.
설치 후 확인:

```bash
code --list-extensions --show-versions
python3 -c "import json;p=json.load(open('$HOME/.vscode/extensions/openai.chatgpt-*/package.json'));print(p['displayName'])"
```

ChatGPT 계정 로그인이 필요하며 이 역시 사람이 해야 한다.

### ⚠️ GUI 자동화 사고: 최전면 앱 확인 없이 키 입력 금지

VS Code를 재로드하려고 `⌘⇧P` → "Reload Window" → Enter를 보냈는데,
**입력이 Claude 앱으로 들어가 "Ad window"라는 빈 대화가 생성됐다.**

원인: `tell application "Visual Studio Code" to activate` 가 동작하지 않았다.
**AppleScript 프로세스 이름은 `Code`다** (`Visual Studio Code`가 아님).
활성화 실패를 확인하지 않고 키를 보내서 최전면이던 다른 앱이 입력을 받았다.

**규칙: `keystroke`를 보내기 전에 반드시 최전면 앱을 검증한다.**

```bash
osascript -e 'tell application "System Events" to set frontmost of process "Code" to true'
sleep 2
FRONT=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true')
[ "$FRONT" = "Code" ] || { echo "최전면 아님 — 중단"; exit 1; }
# 여기서부터 keystroke
```

좌표 클릭(`cliclick`)은 대상 창을 직접 찍으므로 이 문제가 없다.
**키 입력은 최전면에 종속되므로 검증이 필수다.**

덧붙여 이번 경우 재로드 자체가 불필요했다 — `code --install-extension`으로 설치하면
확장이 곧바로 활성화된다(편집기 탭 우측에 아이콘이 뜨는 것으로 확인).

---

## 15. 터미널 — Ghostty ✅

**실행: [`scripts/ghostty.sh`](scripts/ghostty.sh) / 설정: [`config/ghostty/config`](config/ghostty/config)**

Ghostty 1.3.1. 설정 파일을 **이 저장소에 두고 `~/.config/ghostty/config`로 심볼릭 링크**한다.
다음 맥에서는 저장소만 클론하면 터미널 설정이 따라온다.

### iTerm2 대신 Ghostty를 고른 이유

- **설정이 텍스트 파일 한 장.** iTerm2는 바이너리 plist라 git 관리가 고약하다.
  "다음 맥에서 재현"이 목표인 이 저장소의 방향과 맞지 않는다.
- Quick Terminal(상단에서 내려오는 창)이 기본 내장 — iTerm2의 Hotkey Window 대응
- Swift + Metal 네이티브 (Electron 기반 Hyper/Tabby와 다름)

### Quick Terminal

```
keybind = global:opt+cmd+key_t=toggle_quick_terminal
quick-terminal-position = top
quick-terminal-space-behavior = move
quick-terminal-autohide = true
```

`position`·`space-behavior`·`autohide`는 사실 기본값이지만 의도를 드러내려고 명시했다.
`space-behavior = move` 덕분에 **어느 데스크탑에 있든 현재 화면으로 따라온다.**

**이것만 기본 키바인드가 없다** — "There is no default keybind for toggling the quick
terminal." 직접 지정해야 기능이 켜진다.

### 함정 4개 — 전부 여기서 걸렸다

**① 인라인 주석을 지원하지 않는다**

```
quick-terminal-position = top   # 상단에서 내려옴     ← 오류
```

`top   # 상단에서 내려옴` 전체를 값으로 읽어 `invalid value`가 난다.
**주석은 반드시 별도 줄에 쓸 것.**

**② `+validate-config`는 오류 메시지에 "error"를 쓰지 않는다**

```
config:1:quick-terminal-position: invalid value "top   # ...", valid values are: ...
```

`grep -qi error`로 판정하면 오류를 놓친다. **종료 코드로 판정할 것** (정상 0 / 오류 1).

```bash
if OUT=$(ghostty +validate-config 2>&1); then echo 통과; else echo "$OUT"; fi
```

**③-1 Ghostty가 실행 중이어야 한다 → 로그인 항목 등록**

전역 단축키는 Ghostty 프로세스가 살아 있을 때만 동작한다. **⌘Q로 완전히 종료하면
단축키도 죽는다.** 재부팅 후 매번 손으로 실행하지 않도록 로그인 항목에 등록한다.

```bash
osascript -e 'tell application "System Events" to make login item at end \
  with properties {path:"/Applications/Ghostty.app", hidden:true}'
```

`hidden:true`라 로그인 시 창을 띄우지 않고 조용히 실행된다 — 부팅할 때마다 터미널 창이
튀어나오지 않으면서 단축키는 살아 있다.

**창만 닫는 건 괜찮다.** `quit-after-last-window-closed = false`가 macOS 기본값이라
마지막 창을 닫아도 앱은 살아 있다.

**⚠️ `macos-hidden = always`는 쓰지 않았다.** Dock/앱 전환기에서 제외하는 옵션이고
"quick-terminal 위주 사용자를 위한 것"이라 딱 맞아 보이지만, 문서에 단서가 있다:

> When the macOS application is hidden, **keyboard layout changes will no longer be
> automatic.** This is a limitation of macOS.

한/영을 쓰는 환경에서는 위험하다. Dock에 Ghostty를 고정해둔 것(17번)과도 어긋난다.

**③ 전역 단축키에는 손쉬운 사용 권한이 필요하다**

문서: "On macOS, this feature requires accessibility permissions to be granted to Ghostty.
... If the permissions are not granted, the keybind will not work."

권한이 없으면 **Ghostty가 포커스를 가졌을 때만** 동작한다(일반 키바인드로 격하).
시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용에서 Ghostty를 켜고 **앱을 재시작**해야 한다.

**④ ★ 한글 입력 상태에서 단축키가 먹지 않는다 → 물리 키로 지정**

가장 값진 발견. 원인은 Ghostty가 아니라 **문자 기반 매칭**이다.

| 표기 | 매칭 방식 | 한글 입력 상태 |
|---|---|---|
| `t` | 유니코드 문자 | ❌ T 키가 `ㅅ`으로 변환되어 매칭 실패 |
| **`key_t`** | **물리 키 위치** (W3C `KeyT`) | ✅ 입력 소스와 무관 |

문서: "Physical keys always match with a higher priority than Unicode codepoints."
W3C 코드는 스네이크 케이스도 지원한다(`key_t` = `KeyT`).

**이건 Ghostty만의 문제가 아니다.** 한글을 쓰는 환경에서 문자 기반 단축키는 전부 같은
함정을 갖는다. 다른 도구를 설정할 때도 **물리 키 지정이 가능한지 먼저 확인할 것.**

### 폰트 — 한글이 어색하게 보이던 문제

```
font-family = "JetBrains Mono"
font-family = "D2Coding"
font-size = 13
```

`font-family`를 **여러 번 쓰면 앞에서부터 찾는 폴백 목록**이 된다.
(덮어쓰려면 `font-family = ""` 로 목록을 비운 뒤 다시 지정)

**원인**: 기본 상태에서는 이 값이 비어 있어 Ghostty 내장 JetBrains Mono만 쓰는데,
**거기엔 한글 글리프가 없다.** macOS가 임의의 폰트로 대체하면서 한글만 어색해진다.

**D2Coding을 고른 기준은 폭이다.** 네이버가 만든 한글 코딩 폰트로 **한글 글리프 폭이
영문의 정확히 2배**다. 이게 안 맞으면 터미널에서 표·정렬이 어긋난다.
터미널용 한글 폰트를 고를 때 가장 먼저 볼 조건이 이것.

**함정: 내장 폰트는 이름으로 참조할 수 없다**

`ghostty +list-fonts`에 JetBrains Mono가 나오지 않는다. 앱에 임베드된 것이라 시스템
폰트가 아니기 때문이다. **폴백 목록을 쓰려면 1순위 폰트도 시스템에 설치해야 한다.**

```bash
brew install --cask font-jetbrains-mono font-d2coding
```

대안 (마음에 안 들 경우):

| 폰트 | 특징 |
|---|---|
| D2Coding 단독 | 영문까지 D2Coding. 한글·영문 굵기가 완전히 통일된다 |
| Sarasa Mono K | Iosevka + Source Han Sans 기반. 폭 정렬 정확 |
| Noto Sans Mono CJK KR | 무난하나 다소 두껍다 |

### 외형

```
background-opacity = 0.5
background-blur = true
```

투명도 50%. 블러를 같이 켜는 게 중요하다 — 투명도만 높이면 뒤 내용이 그대로 비쳐
글자를 읽기 어렵다. 블러가 대비를 살려준다.

**메모**
- 설정 키/액션은 추측하지 말고 바이너리에서 확인할 것:
  `ghostty +show-config --default --docs` / `+list-actions` / `+list-themes`
- 우측 Command는 한/영 키라(12번) 단축키에는 **좌측** Command를 써야 한다.
- 캐스크가 zsh/bash/fish 자동완성과 man 페이지도 함께 링크해준다.

---

## 16. zsh 설정 — 자동완성 + 히스토리 ✅

**실행: [`scripts/zsh.sh`](scripts/zsh.sh) / 설정: [`config/zsh/zshrc`](config/zsh/zshrc)**

Ghostty와 같은 방식. 저장소에 두고 `~/.zshrc`로 심볼릭 링크한다.

### 역할 분담 — zprofile vs zshrc

| 파일 | 실행 시점 | 담당 |
|---|---|---|
| `~/.zprofile` | 로그인 시 **1회** | PATH 등 환경변수 (`brew shellenv`, 2번 항목) |
| `~/.zshrc` | 대화형 셸을 열 **때마다** | 자동완성 · 히스토리 · 별칭 · 프롬프트 |

**PATH를 `.zshrc`에 넣으면 셸을 열 때마다 중복 append 된다.** 넣지 말 것.

### 자동완성이 죽어 있던 이유

Homebrew formula들이 자동완성 파일을 설치하고(`_git` `_gh` `_brew` `_ghostty`),
`brew shellenv`가 FPATH 등록까지 해준다. **그런데 `compinit`을 부르는 곳이 없었다.**
`~/.zshrc`가 아예 없었으므로 전부 무용지물이었다.

```zsh
autoload -Uz compinit
compinit
```

### 함정: 비로그인 대화형 셸에서는 FPATH가 없다

`brew shellenv`는 `~/.zprofile`에 있고, **`.zprofile`은 로그인 셸에서만 실행된다.**

| 셸 종류 | `.zprofile` | 결과 |
|---|---|---|
| 터미널 앱이 여는 셸 (로그인+대화형) | ✅ | 정상 |
| `zsh -i` (비로그인 대화형) | ❌ | FPATH 없음 → `git` 외 전부 실패 |

`git`만 살아남는 건 zsh가 자체 `_git`을 시스템 경로에 갖고 있기 때문이다.

`.zshrc`가 스스로 보장하도록 했다. `${fpath[(I)...]}`는 일치하는 마지막 인덱스(없으면 0)라
중복 추가를 막는다:

```zsh
if [[ -d /opt/homebrew/share/zsh/site-functions ]] \
   && (( ${fpath[(I)/opt/homebrew/share/zsh/site-functions]} == 0 )); then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi
```

### 함정: `compinit -C`는 새 자동완성을 못 찾는다

`compinit`은 fpath 전체를 훑어 느리다(수백 ms). 셸을 열 때마다 내는 비용이라
`.zcompdump`가 24시간 이내면 캐시를 쓰도록 했다.

**단 `-C`는 보안 검사뿐 아니라 "새 자동완성 함수 탐색"도 건너뛴다.**
새 도구를 설치한 직후 자동완성이 안 잡히면:

```bash
rm -f ~/.zcompdump && exec zsh
```

### 히스토리

```zsh
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY       # 실행 시각/소요 시간 기록
setopt SHARE_HISTORY          # 여러 터미널 간 실시간 공유
setopt HIST_IGNORE_ALL_DUPS   # 중복은 마지막 것만
setopt HIST_IGNORE_SPACE      # 공백으로 시작하면 기록 안 함 (비밀 다룰 때)
setopt HIST_VERIFY            # !! 확장 시 바로 실행하지 않고 보여줌
```

`HIST_IGNORE_SPACE`가 실용적이다 — 토큰이 들어간 명령은 앞에 공백을 붙여 치면 남지 않는다.

### 검증

```bash
zsh -lic 'for c in git gh brew ghostty; do echo "$c ${_comps[$c]}"; done'
zsh -ic  'compaudit'   # 권한 경고 없어야 함
```

**메모** — `bindkey -v`(vim 키 바인딩)는 주석으로만 넣어뒀다. vim에 익숙해도 줄 편집 동작이
크게 바뀌는 변경이라 기본으로 켜지 않았다. 원하면 주석만 풀면 된다.

---

## 17. Dock 정리 ✅

**실행: [`scripts/dock.sh`](scripts/dock.sh)**

왼쪽부터의 순서:

```
Finder · 앱 · App Store · 시스템 설정 · iPhone 미러링 · 메모 · TV · 음악
       │ Google Chrome · Ghostty · VS Code · Claude
```

앱 목록이 스크립트 상단의 배열 하나로 정리돼 있다. 순서 변경·추가는 그 배열만 고치면 된다.

### Finder는 설정으로 제어할 수 없다

**`persistent-apps`에 들어 있지 않다.** Dock이 항상 맨 왼쪽에 고정으로 그리는 특별 항목이라
제거하거나 순서를 바꿀 수 없다. 휴지통도 마찬가지로 `persistent-others` 소속이라 별개다.

### 아이콘 하나의 구조

```
tile-data.file-data._CFURLString      file:// URL
tile-data.file-data._CFURLStringType  15 (= file URL)
tile-type                             "file-tile"
```

```bash
defaults write com.apple.dock persistent-apps -array          # 비우고
defaults write com.apple.dock persistent-apps -array-add '…'  # 순서대로 채운다
killall Dock
```

### 함정: 경로의 공백은 %20으로 인코딩해야 한다

`Google Chrome.app`, `App Store.app`, `iPhone Mirroring.app`, `Visual Studio Code.app`,
`System Settings.app` — 이 맥에서만 5개가 해당한다.
인코딩하지 않으면 Dock이 **물음표 아이콘**으로 표시한다.

### 크기와 자동 숨김 — 결론은 "크기를 줄이지 말고 숨겨라"

처음엔 독이 화면을 너무 먹어서 크기를 48 → 36으로 줄였는데 **아이콘이 알아보기 힘들었다.**
42도 여전히 작았다. **문제는 아이콘 크기가 아니라 독이 상시 자리를 차지하는 것**이었다.

자동 숨김을 켜면 평소 공간을 전혀 쓰지 않으므로 크기를 줄일 이유가 사라진다.
→ **기본 48로 되돌리고 자동 숨김을 켰다.**

```bash
defaults write com.apple.dock tilesize -int 48              # 기본 48, 범위 16~128
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0.15    # 가장자리 닿고 올라오기까지(초)
defaults write com.apple.dock autohide-time-modifier -float 0.5   # 애니메이션 속도, 작을수록 빠름
```

`autohide-delay` 기본값(약 0.5초)은 굼뜨다. 그렇다고 `0`으로 두면 커서가 아래를 스치기만
해도 튀어나와 거슬린다. 0.15가 타협점이다.

확대 효과는 꺼둔 상태다. 원하면:

```bash
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 64
```

### 최근 사용한 응용 프로그램 영역

```bash
defaults write com.apple.dock show-recents -bool false
```

켜져 있으면 구분선 오른쪽에 최근 실행 앱이 자동으로 붙어 고정 목록과 중복돼 보인다.
되돌리려면 `-bool true`.

### 실행 중인 앱은 고정과 무관하게 표시된다

독 오른쪽에 고정하지 않은 앱이 보이는 건 **지금 실행 중이라서**다(아이콘 아래 점).
종료하면 사라진다. 설정으로 없앨 수 있는 게 아니며, `show-recents`와도 다른 것이다.

### 검증

```bash
defaults read com.apple.dock persistent-apps \
  | grep '_CFURLString"' | sed 's/.*file:\/\///;s/\/";//;s/%20/ /g' | nl
```

**메모** — grep 패턴에 `_CFURLString`만 쓰면 `_CFURLStringType`에도 걸려 개수가 두 배로
세어진다. 따옴표까지 포함해 `'_CFURLString"'` 로 쓸 것.

---

## 18. 트랙패드 — 탭하여 클릭 ✅

**실행: [`scripts/trackpad.sh`](scripts/trackpad.sh)**

증상 두 가지:
1. 트랙패드를 살짝 터치해도 클릭이 안 됨
2. 두 손가락을 대도 우클릭이 안 됨

### ★ 둘은 별개 문제가 아니다

설정을 읽어보니:

```
Clicking            = 0    ← 탭하여 클릭 꺼짐
TrackpadRightClick  = 1    ← 두 손가락 보조 클릭은 이미 켜져 있었다
```

**두 번째가 안 된 원인이 첫 번째였다.** `Clicking = 0`이면 두 손가락으로 *눌러야* 우클릭이
되고, 살짝 *대기만* 해서는 반응하지 않는다. 설정 이름만 보면 독립적으로 보이지만
**두 손가락 탭은 탭하여 클릭에 종속된다.** `Clicking = 1` 하나로 둘 다 해결됐다.

### 도메인이 여러 개다

| 도메인 / 키 | 대상 |
|---|---|
| `com.apple.AppleMultitouchTrackpad` | 내장 트랙패드 |
| `com.apple.driver.AppleBluetoothMultitouch.trackpad` | Magic Trackpad (외장) |
| `NSGlobalDomain com.apple.mouse.tapBehavior` | 시스템 전역 |
| 위 키의 `-currentHost` 판본 | 이것도 함께 써야 확실하다 |

### 함정: defaults만으로는 즉시 반영되지 않는다

값을 쓰고 시스템 설정을 열면 **토글은 이미 켜진 상태로 보이는데 실제 동작은 안 한다.**
트랙패드 드라이버가 설정을 다시 읽지 않았기 때문이다.

**해결: 시스템 설정 > 트랙패드에서 `탭하여 클릭하기` 토글을 껐다 켠다.**
GUI 토글은 드라이버에 즉시 통지되므로 그 시점에 반영된다.
(Claude가 `cliclick`으로 대신 처리 가능 — 0번 항목의 권한 필요)

로그아웃 후 재로그인해도 반영되지만 그쪽이 더 번거롭다.

**메모** — 이 "값은 맞는데 드라이버가 안 읽음" 패턴은 트랙패드 외의 입력 장치 설정에서도
나타난다. `defaults` 적용 후 동작하지 않으면 **해당 GUI 토글을 껐다 켜는 것**을 먼저 시도할 것.

**메모**
- `tcpkeepalive 1`, `powernap 1`은 기본으로 켜져 있어 네트워크 연결이 유지된다.
- `ttyskeepawake 1`도 기본값 — 활성 SSH 세션이 있으면 그 자체로 잠자기를 막는다.
- `disksleep`은 SSD라 세션에 영향 없다.
