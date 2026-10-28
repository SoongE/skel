# dotfiles

zinit + starship 기반 zsh 환경 설정 (macOS / Ubuntu 공용)

## 구조

| 경로 | 내용 |
| --- | --- |
| `install.sh` | OS 감지 후 패키지 설치 + dotfiles 복사 (`--link`면 심볼릭 링크) |
| `build_container.sh` | GPU 컨테이너 생성 → 사용자/sshd 설정 → 컨테이너 안에서 `install.sh` 실행 후 복사본 삭제 |
| `dotfiles/` | `zshrc`, `zprofile`, `zshenv`, `aliases`, `tmux.conf`, `starship.toml`, `gitconfig`(macOS) |
| `Brewfile` | macOS 패키지 목록 |
| `fonts/` | Helvetica Neue (Linux에서 시스템 폰트로 설치) |

머신별 설정은 `~/.zshrc.local`에 두면 `zshrc`가 마지막에 불러온다.

## 사용법

서버 (설치 후 clone 삭제):

```bash
git clone --depth=1 https://github.com/SoongE/skel.git ~/.dotfiles
~/.dotfiles/install.sh && rm -rf ~/.dotfiles
```

메인 Mac (repo에서 직접 관리):

```bash
~/Documents/scripts/install.sh --link
```

옵션: `--link` 심볼릭 링크로 연결, `--no-apt` (Linux) apt update/install 생략, `--no-python` (Linux) `~/.base_venv` 생성 생략

```bash
./build_container.sh <container_name> <host_name> <port> <image_name>
```

컨테이너 비밀번호는 실행 시 입력하거나 `CONTAINER_PASSWORD` 환경변수로 넘긴다.
