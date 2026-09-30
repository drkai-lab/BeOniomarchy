<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/beoniomarchy-dark.png">
  <img alt="BeOniomarchy" src="docs/beoniomarchy.png" width="645">
</picture>

# BeOniomarchy v1.0

[English](README.md) | [日本語](README.ja.md) | 한국어 | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md)

BeOniomarchy는 그대로 놓인 [Omarchy](https://omarchy.org)를
"Oniomarchy", 즉 보안·개발 워크스테이션으로 바꿔 주는 도구입니다.
머신도 데스크톱도 그대로 두고 그 위에 얹습니다.

이름에 대해 먼저. [Oniomarchy](https://oniomarchy.com)는 SalimRK의 기존
프로젝트로, 같은 일을 훨씬 큰 도구 모음과 자체 서명 패키지 저장소로
합니다. 이 저장소는 같은 아이디어에 대한 또 다른 시도이며, 도구는 제
작은 소규모 구성입니다. Oniomarchy 그 자체가 아닙니다.

번호가 붙은 스크립트 아홉 개가 전부입니다. 평소 쓰는 스캐너와 감사 도구,
컨테이너와 쿠버네틱스 쪽, AI 도구 몇 가지, Qualys와 Checkmarx용 API
헬퍼, 제가 직접 쓰는 웹 / API 감사 스크립트와 리포트 생성기, 그리고
Omarchy 기본 테마 중 하나를 "Oniomarchy" 테마로 포크해 적용합니다.

특별한 장치는 없습니다. 쓴 파일, 만든 백업, 설치한 패키지를 한 줄씩 상태
파일에 적어 두는 것이 전부이고, `./uninstall.sh`가 읽는 것도 그 파일
뿐이라 상태에 없는 것을 제 마음대로 지우지 않습니다.

## 요구 사항

- Omarchy (`omarchy` CLI가 있는 Arch Linux)
- 패키지 설치용 `sudo`

## 설치

```bash
./install.sh --dry-run   # 할 일만 출력, 변경 없음
./install.sh             # 설치 (실행 전에 확인)
./install.sh --yes       # 확인 생략. stdin이 터미널이 아닐 때는 필수
```

한 번은 드라이런부터 돌려 보세요. 일부만 실행하고 싶으면:

```bash
./install.sh --list            # 모듈 목록
./install.sh --only 01,theme   # 이 둘만
```

모듈은 번호 순으로 실행됩니다:

| 모듈 | 하는 일 |
| --- | --- |
| `00-system` | 디렉터리, 기본 패키지, `~/.local/bin`의 `beoni-*` 링크 |
| `01-security` | nmap / lynis / clamav / yara, `beoni-audit` |
| `02-devtools` | lazygit / ripgrep / fzf / bat / eza / docker |
| `03-ai-tools` | uv / ollama |
| `04-cloud` | kubectl / helm / k9s / terraform / kustomize |
| `05-qualys` | `beoni-qualys` |
| `06-checkmarx` | `beoni-checkmarx` |
| `07-report` | Markdown 상태 리포트 작성 |
| `08-theme` | 기본 테마를 Oniomarchy로 포크하고 전환 |

## 삭제

```bash
./uninstall.sh --dry-run   # 무엇이 사라지는지 보기
./uninstall.sh --yes       # 삭제
```

만든 백업을 복원하고, 생성한 파일을 지우고, 이전 테마로 되돌린 뒤, 테마
포크를 없애고, 제가 설치한 패키지를 제거합니다. 상태 파일에 적힌 것만
건드리기 때문에 직접 깔아둔 것은 그대로 남습니다.

`--keep-packages`와 `--keep-theme`는 각각 건드리지 않고, `--purge`는
`~/.local/share/beoniomarchy/` 아래 리포트까지 지우며, `--list`는 상태
파일을 출력합니다. 중간에 실패해도 상태 파일은 그대로 남으니 다시 돌리면
멈춘 곳부터 이어집니다.

## 도구

`~/.local/bin`에 여섯 개가 놓입니다:

```bash
beoni-webaudit https://example.com        # 응답 보안 헤더
beoni-apiaudit https://api.example.com    # 인증 / CORS / 유출
beoni-reportgen -o report.md              # 시스템과 인스톨러 상태
beoni-audit                               # 열린 포트와 서비스
beoni-qualys hosts                        # Qualys API
beoni-checkmarx GET /projects             # Checkmarx API
```

인증 정보가 필요한 건 마지막 둘뿐입니다. 인스톨러가
`~/.config/beoniomarchy/`에 `qualys.env.example`과
`checkmarx.env.example`을 만들므로, 각각 `qualys.env`,
`checkmarx.env`로 복사해 값을 채우면 됩니다.

## 파일 위치

- 상태와 백업: `~/.local/state/beoniomarchy/`
- 리포트: `~/.local/share/beoniomarchy/reports/`

상태 파일은 `pkg`, `create`, `backup`, `dir`, `theme`, `themefork` 여섯
종류가 탭으로 구분된 일반 텍스트입니다. `cat`으로 그대로 읽을 수 있고,
데이터베이스 따위는 없습니다.
