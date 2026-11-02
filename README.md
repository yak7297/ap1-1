# macOS 개발 워크스테이션 구축

Apple Silicon Mac에서 터미널, 파일 권한, Docker, Git을 실습하고 NGINX 기반 커스텀 웹 서버를 실행했다. Docker Compose 단일 서비스 실행을 보너스로 수행했다.

## 실행 환경

- OS: macOS 27.0.1 / Apple Silicon
- Shell: zsh (`/bin/zsh`), macOS 터미널
- Git: 2.55.0
- Docker Engine/CLI: 29.9.2, Docker Desktop: 4.97.0
- Docker Compose: 5.6.1
- 편집기: Visual Studio Code
- 사용자 실습: 2026-11-02~03 (KST)

## 수행 체크리스트

- [x] 터미널 기본 조작 및 절대/상대 경로
- [x] 파일·디렉터리 권한 변경 전후 비교
- [x] Docker 설치·엔진 점검
- [x] hello-world 및 Ubuntu 실행
- [x] 컨테이너 접속·종료·유지 관찰
- [x] 이미지 목록, 컨테이너 시작/중지, 로그, 리소스 확인
- [x] 직접 작성한 Dockerfile로 이미지 빌드
- [x] 8080 포트 웹 응답 확인
- [x] 바인드 마운트 수정 반영
- [x] 볼륨 데이터 영속성 확인
- [x] Git 사용자 정보 및 main 기본 브랜치 확인
- [ ] VS Code의 GitHub 로그인 완료 화면 증거
- [x] 보너스: Compose 단일 서비스 up/ps/logs/down

GitHub 업로드 결과는 이 저장소의 커밋과 파일로 확인한다. VS Code에서 과제 폴더를 연 것은 확인했지만 GitHub 로그인 완료 화면은 아직 수집하지 않았다.

## 파일 구성

- [Dockerfile](Dockerfile): NGINX 베이스, 제목 라벨, HTML 복사, 80번 포트 선언
- [웹페이지](site/index.html): 최종 버전 2
- [Compose 설정](compose.yaml): 빌드·8082 포트·읽기 전용 바인드 마운트
- [실제 운영 로그](docs/logs/runtime.txt), [웹 응답/마운트 로그](docs/logs/web.txt), [볼륨 확인](docs/logs/volume.txt), [Git 설정](docs/logs/git.txt)
- [스크린샷 전체](docs/screenshots/)

## 재현 방법

Docker Desktop을 실행한 뒤 저장소를 내려받아 그 폴더에서 실행한다. 아래 명령은 빈 실습 환경을 기준으로 한다. 같은 이름의 기존 실습 컨테이너가 있으면 다른 이름/호스트 포트를 사용한다.

```bash
git clone https://github.com/yak7297/ap1-1.git
cd ap1-1
docker build -t dohyeon-web:1.0 .
docker run -d --name dohyeon-web -p 8080:80 dohyeon-web:1.0
curl -i http://localhost:8080
```

브라우저에서 `http://localhost:8080`으로 접속한다. `8080:80`은 호스트 8080을 컨테이너 80에 연결한다. `EXPOSE 80`만으로는 호스트에 포트가 공개되지 않는다.

최초 빌드 때 HTML은 버전 1이었다. 이후 호스트 파일을 버전 2로 수정했으므로 현재 소스로 새로 빌드하면 버전 2가 나온다. 베이스는 `nginx:alpine`이며, 빌드 캡처에서 사용된 digest는 `sha256:785835ea65db4bba6f021acc0f3be91b0fef76a53fe41f8588c6698d2a`다. 태그는 향후 변경될 수 있다.

## 터미널 기본 조작

아래는 사용자 실습 명령이며 결과는 캡처에 기록되어 있다.

```bash
mkdir -p ~/Documents/docker-workstation/practice
cd ~/Documents/docker-workstation
pwd
# /Users/ryudohyeon/Documents/docker-workstation
ls -la
cd practice
touch empty.txt
echo "My terminal practice" > original.txt
cat original.txt
# My terminal practice
cp original.txt copy.txt
mv copy.txt renamed.txt
ls -la
# empty.txt, original.txt, renamed.txt 확인
rm renamed.txt
ls -la
# empty.txt, original.txt만 남음
```

[폴더 생성](docs/screenshots/12-project-folder.png) · [파일 생성/복사/이름 변경](docs/screenshots/13-file-operations.png) · [삭제 후 확인](docs/screenshots/14-file-delete.png)

절대 경로는 `/Users/ryudohyeon/Documents/docker-workstation`처럼 루트부터 시작한다. 상대 경로 `practice`는 현재 폴더를 기준으로 한다. 재현할 때 개인 사용자 이름 대신 `~/Documents`나 저장소의 현재 경로를 사용한다.

## 권한 변경

```bash
mkdir permission-dir
ls -ld original.txt permission-dir
# -rw-r--r-- original.txt / drwxr-xr-x permission-dir
chmod 600 original.txt
chmod 700 permission-dir
ls -ld original.txt permission-dir
# -rw------- original.txt / drwx------ permission-dir
chmod 644 original.txt
chmod 755 permission-dir
ls -ld original.txt permission-dir
# -rw-r--r-- original.txt / drwxr-xr-x permission-dir
```

[권한 제한 전후](docs/screenshots/15-permissions-restrict.png) · [644/755 복원](docs/screenshots/16-permissions-restore.png)

`r=4`, `w=2`, `x=1`을 합산하며 소유자/그룹/기타 사용자 순이다. 644는 소유자 읽기·쓰기와 나머지 읽기, 755는 소유자 모든 권한과 나머지 읽기·실행이다. 디렉터리의 x는 내부로 접근하는 권한이다. root로 권한 거부를 검증한 것은 아니며, 여기서는 권한 비트 변경을 비교했다.

## Docker 기본 실습과 운영

```bash
docker --version
# Docker version 29.9.2, build a82e528
docker info
# Client 및 Server 정보 출력
docker run hello-world
# Hello from Docker!
docker run -it --name ubuntu-practice ubuntu:24.04 bash
# 아래는 Ubuntu 내부
pwd
# /
ls -la
echo "Hello from Ubuntu"
# Hello from Ubuntu
exit
# 아래는 macOS 터미널
docker ps -a
# ubuntu-practice: Exited (0)
docker start ubuntu-practice
docker exec -it ubuntu-practice bash
exit
docker ps
# ubuntu-practice: Up
docker images
docker logs ubuntu-practice
docker stats --no-stream ubuntu-practice
docker stop ubuntu-practice
docker ps -a
# ubuntu-practice: Exited (137)
```

처음에는 주 프로세스 bash에서 exit하여 컨테이너가 종료됐다. 재시작 후 exec로 연 별도 bash에서 exit했을 때는 주 bash가 남아 컨테이너가 유지됐다. attach는 기존 주 프로세스에 연결하고 exec는 추가 프로세스를 실행한다. 직접 관찰한 것은 최초 bash와 exec의 종료 차이이며 attach 명령 자체는 실행하지 않았다.

[중지 결과](docs/screenshots/11-docker-stop.png) · [추가로 수집한 실제 운영 로그](docs/logs/runtime.txt)

초기 hello-world/Ubuntu 캡처는 채팅에서 확인했으나 임시 파일 원본을 회수하지 못했다. 해당 구간은 확인된 명령과 핵심 출력을 위에 전사했다. 이후 캡처는 저장소에 보관했다.

## 커스텀 이미지와 포트

기존 NGINX 이미지의 기본 페이지를 직접 작성한 한국어 HTML로 교체했다. LABEL은 이미지 목적 식별에 사용하며 COPY는 HTML을 이미지 안에 포함한다.

```bash
docker build -t dohyeon-web:1.0 .
# Building ... FINISHED
docker run -d --name dohyeon-web -p 8080:80 dohyeon-web:1.0
curl -i http://localhost:8080
# HTTP/1.1 200 OK
# <p>페이지 버전: 1</p>
```

위 버전 1 응답과 포트 연결은 [실제 재확인 로그](docs/logs/web.txt)에 있다. 주소창에 8080이 보이는 브라우저 화면은 채팅에서 확인했지만 원본 캡처를 회수하지 못했다. 저장소에는 curl 증거를 제공한다. 과제의 주소창 포함 스크린샷을 엄격히 적용하면 이 캡처를 추가해야 한다.

## 바인드 마운트

```bash
docker run -d --name dohyeon-bind -p 8081:80 -v "$PWD/site:/usr/share/nginx/html:ro" dohyeon-web:1.0
# 최초 웹페이지 버전 1
sed -i '' 's/페이지 버전: 1/페이지 버전: 2/' site/index.html
grep '페이지 버전' site/index.html
# <p>페이지 버전: 2</p>
curl -i http://localhost:8081
# HTTP/1.1 200 OK / 페이지 버전: 2
```

위 sed는 macOS 문법이다. Linux에서는 `sed -i 's/페이지 버전: 1/페이지 버전: 2/' site/index.html`을 사용한다. 현재 파일은 이미 버전 2이므로 재실습 시 먼저 1로 바꾸거나 2→3으로 변경한다.

[수정 전](docs/screenshots/18-page-before-safari.png) · [수정 후](docs/screenshots/19-bind-page-after.png) · [실제 마운트 및 8080/8081 응답 비교](docs/logs/web.txt)

이미지를 다시 만들지 않아도 호스트 파일 변경이 연결된 컨테이너에 반영됐다. 원래 COPY로 실행한 8080은 버전 1, 마운트한 8081은 버전 2로 확인됐다. 브라우저 캡처에서는 Safari가 포트를 숨기므로 포트별 확인은 로그를 참고한다.

## 볼륨 영속성

```bash
docker volume create workstation-data
docker run -d --name volume-before -v workstation-data:/data ubuntu:24.04 sleep infinity
docker exec volume-before bash -c 'echo "Volume data survives" > /data/proof.txt'
docker exec volume-before cat /data/proof.txt
# Volume data survives
docker rm -f volume-before
docker run -d --name volume-after -v workstation-data:/data ubuntu:24.04 sleep infinity
docker exec volume-after cat /data/proof.txt
# Volume data survives
```

[삭제 전후 실제 실행 증거](docs/screenshots/20-volume-persistence.png) · [볼륨 추가 확인](docs/logs/volume.txt)

볼륨은 컨테이너와 별도로 관리된다. 컨테이너를 삭제해도 같은 볼륨을 새 컨테이너에 연결하면 저장된 파일을 읽을 수 있다. 바인드 마운트는 지정한 호스트 폴더를 연결하고, 여기의 named volume은 Docker가 관리하는 저장 공간이다.

## 보너스: Compose 단일 서비스

```bash
docker compose up -d
docker compose ps
# web: Up, 8082->80
curl http://localhost:8082
# HTML 응답, 페이지 버전 2
docker compose logs --tail 10
# GET / HTTP/1.1 200
docker compose down
docker compose ps -a
# 목록 비어 있음
```

[실행·접속·로그](docs/screenshots/21-compose-up.png) · [종료](docs/screenshots/22-compose-down.png)

Compose 파일은 빌드·포트·마운트를 선언하여 긴 실행 명령을 반복 입력하지 않고 같은 설정으로 재현하게 한다. down은 이 Compose 서비스와 네트워크를 제거하며 별도로 실행한 실습 컨테이너에는 영향을 주지 않는다.

## Git 및 GitHub

Git은 로컬 변경 이력을 관리하고 GitHub는 원격 저장소를 제공한다. 사용자 이름·이메일과 main 설정은 기존 설정에서 확인했다. 공개 로그의 이메일은 마스킹했다.

```bash
git config --get user.name
# Dohyeon Ryu
git config --get user.email
# [설정됨, 마스킹]
git config --get init.defaultBranch
# main
```

[설정 로그](docs/logs/git.txt) · [VS Code 소스 제어 초기 화면](docs/screenshots/23-vscode-source-control.png)

초기 VS Code 화면에서는 아직 로컬 저장소가 없었다. 제출 파일은 별도 작업 복사본에서 정리하여 지정된 GitHub 저장소에 업로드한다. 이 사실만으로 VS Code의 GitHub 로그인 완료를 증명하지는 않는다.

## 트러블슈팅

### 1. docker 명령을 찾지 못함

- 문제: macOS 터미널에서 `zsh: command not found: docker` 발생.
- 원인 가설: Docker가 설치되지 않았거나 CLI 경로가 준비되지 않음.
- 확인: Docker Desktop 설치·실행 후 `docker --version`과 `docker info` 재실행.
- 해결: Apple Silicon용 Docker Desktop을 설치하여 버전 및 Server 출력을 확인했다.

### 2. hello-world 실행 후 실행 중 컨테이너가 없음

- 문제: Docker Desktop에 `No containers are running` 표시.
- 원인 가설: 실행 실패 또는 정상 실행 후 종료.
- 확인: 터미널의 `Hello from Docker!`와 `docker ps -a`의 `Exited (0)` 확인.
- 결론: 메시지 출력 후 끝나는 정상 동작이며, 장시간 실행하는 서버와 다르다.

### 3. Safari 캡처에서 포트가 보이지 않음

- 문제: 주소창이 localhost만 표시해 접속 포트 판별이 어려움.
- 원인 가설: Safari가 주소 표시를 축약함.
- 확인/대안: 8080과 8081을 지정한 curl 응답 및 docker port/inspect를 별도 기록했다. 주소창 전체 캡처는 아직 추가하지 않았다.

## 증거 및 공개 범위

스크린샷은 실제 사용자 실행 화면이며 로그는 사용자 화면 전사 또는 추가 실제 조회 결과이다. 재현 명령과 실제 결과를 구분했다. 토큰·비밀번호·개인키는 저장하지 않는다. 빈 실습 디렉터리는 Git이 추적하지 않으므로 명령으로 다시 생성한다. 최종 제출 전 남은 VS Code 로그인 증거 및 주소창 캡처 요구를 확인한다.
