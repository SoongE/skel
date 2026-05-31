#!/usr/bin/env python3
"""
PyCharm 원격 인터프리터 일괄 생성 스크립트

sshConfigs.xml에 정의된 SSH config들을 읽어서,
각 config에 대응하는 webServers.xml + jdk.table.xml 항목을 생성한다.

모든 서버가 동일한 원격 환경(파이썬 경로/venv/uv/프로젝트 경로)을 쓴다는 전제.
서버마다 경로가 다르면 PER_HOST 딕셔너리로 개별 지정 가능.

사용법:
    1. 아래 CONFIG 섹션의 경로/값을 본인 환경에 맞게 수정
    2. PyCharm을 완전히 종료
    3. python3 pycharm_interpreter_gens.py
    4. 생성된 두 파일을 options/ 폴더에 복사 (스크립트가 자동 백업/적용 옵션 제공)

    python3 pycharm_interpreter_gens.py --out ~/Desktop/pycharm_xml
    python3 pycharm_interpreter_gens.py --apply
"""

import re
import os
import sys
import uuid
import shutil
import argparse
from datetime import datetime

# ============================================================
# CONFIG — 본인 환경에 맞게 수정하세요
# ============================================================

# PyCharm 설정 폴더 (버전에 맞게)
PYCHARM_OPTIONS_DIR = os.path.expanduser(
    "~/Library/Application Support/JetBrains/PyCharm2026.1/options"
)

# 모든 서버 공통 원격 환경 설정 (dock1 인터프리터에서 가져온 값)
DEFAULTS = {
    "interpreter_path": "/home/seungmin/.base_venv/bin/python3",
    "py_version": "Python 3.12.3",
    "venv_path": "/home/seungmin/.base_venv",
    "uv_path": "/home/seungmin/.local/bin/uv",
    "uv_workdir": "/Users/soonge/Projects/LLM",
    "project_root_on_target": "/home/seungmin/dmount/LLM",
    "flavor_id": "UvSdkFlavor",  # UV 안 쓰면 "VirtualEnvSdkFlavor" 등으로 변경
}

# 서버마다 경로가 다른 경우만 여기에 오버라이드 (이름: {키: 값})
# 예) "dock5": {"project_root_on_target": "/home/seungmin/other"}
PER_HOST = {}

# 기존에 이미 만들어둔 인터프리터의 ID를 보존하고 싶을 때
# (이름: (webserver_id, sdk_uuid)) — 연결 깨짐 방지
PRESERVE_IDS = {
    "dock1": (
        "0ee22d53-34c0-4f1b-9b64-59261c85da3a",  # webServer id
        "ffa72c68-ee61-4e12-bd08-930a975b0319",  # SDK_UUID
    ),
}

# ============================================================
# 이하 로직 (보통 수정 불필요)
# ============================================================

SSH_PATTERN = re.compile(
    r'<sshConfig\b'
    r'(?=[^>]*\bhost="(?P<host>[^"]+)")'
    r'(?=[^>]*\bid="(?P<id>[^"]+)")'
    r'(?=[^>]*\bport="(?P<port>[^"]+)")'
    r'(?=[^>]*\bcustomName="(?P<name>[^"]+)")'
    r'[^>]*>'
)


def parse_ssh_configs(path):
    with open(path, encoding="utf-8") as f:
        data = f.read()
    configs = []
    for m in SSH_PATTERN.finditer(data):
        configs.append({
            "host": m.group("host"),
            "id": m.group("id"),
            "port": m.group("port"),
            "name": m.group("name"),
        })
    if not configs:
        sys.exit("ERROR: sshConfigs.xml에서 SSH config를 하나도 못 찾았습니다. "
                 "파일 경로/형식을 확인하세요.")
    # dockN 의 숫자 기준 정렬 (숫자 없으면 이름순 뒤로)
    def keyfn(c):
        nums = re.sub(r"\D", "", c["name"])
        return (0, int(nums)) if nums else (1, c["name"])
    configs.sort(key=keyfn)
    return configs


def opt(name, server):
    """서버별 오버라이드가 있으면 그 값, 없으면 기본값."""
    return PER_HOST.get(server, {}).get(name, DEFAULTS[name])


def xml_escape_attr(s):
    return (s.replace("&", "&amp;").replace('"', "&quot;")
             .replace("<", "&lt;").replace(">", "&gt;"))


def build(configs):
    web_blocks, jdk_blocks = [], []
    for c in configs:
        name = c["name"]
        if name in PRESERVE_IDS:
            web_id, sdk_uuid = PRESERVE_IDS[name]
        else:
            web_id, sdk_uuid = str(uuid.uuid4()), str(uuid.uuid4())

        web_blocks.append(
            f'      <webServer id="{web_id}" name="{name}">\n'
            f'        <fileTransfer accessType="SFTP" host="{c["host"]}" '
            f'port="{c["port"]}" sshConfigId="{c["id"]}" '
            f'sshConfig="{name}" authAgent="true" />\n'
            f'      </webServer>'
        )

        flavor_data = xml_escape_attr(
            '{"uvWorkingDirectory":"%s","venvPath":"%s","uvPath":"%s"}'
            % (opt("uv_workdir", name), opt("venv_path", name), opt("uv_path", name))
        )

        jdk_blocks.append(
            f'    <jdk version="2">\n'
            f'      <name value="{name}" />\n'
            f'      <type value="Python SDK" />\n'
            f'      <version value="{opt("py_version", name)}" />\n'
            f'      <homePath value="{opt("interpreter_path", name)}" />\n'
            f'      <roots>\n'
            f'        <classPath>\n'
            f'          <root type="composite" />\n'
            f'        </classPath>\n'
            f'        <sourcePath>\n'
            f'          <root type="composite" />\n'
            f'        </sourcePath>\n'
            f'      </roots>\n'
            f'      <additional SDK_UUID="{sdk_uuid}" '
            f'INTERPRETER_PATH="{opt("interpreter_path", name)}" '
            f'HELPERS_PATH="" VALID="true" RUN_AS_ROOT_VIA_SUDO="false">\n'
            f'        <setting name="FLAVOR_ID" value="{opt("flavor_id", name)}" />\n'
            f'        <setting name="FLAVOR_DATA" value="{flavor_data}" />\n'
            f'        <targetEnvironmentConfiguration name="{name}" type="ssh/web-deployment">\n'
            f'          <config>\n'
            f'            <option name="projectRootOnTarget" '
            f'value="{opt("project_root_on_target", name)}" />\n'
            f'            <option name="webServerConfigId" value="{web_id}" />\n'
            f'          </config>\n'
            f'        </targetEnvironmentConfiguration>\n'
            f'      </additional>\n'
            f'    </jdk>'
        )

    webservers = (
        '<application>\n'
        '  <component name="WebServers">\n'
        '    <option name="servers">\n'
        + "\n".join(web_blocks) + "\n"
        '    </option>\n'
        '  </component>\n'
        '</application>\n'
    )
    jdktable = (
        '<application>\n'
        '  <component name="ProjectJdkTable">\n'
        + "\n".join(jdk_blocks) + "\n"
        '  </component>\n'
        '</application>\n'
    )
    return webservers, jdktable


def validate(webservers, jdktable):
    import xml.dom.minidom as minidom
    minidom.parseString(webservers)
    minidom.parseString(jdktable)
    web_ids = set(re.findall(r'<webServer id="([^"]+)"', webservers))
    refs = set(re.findall(r'webServerConfigId" value="([^"]+)"', jdktable))
    if not refs.issubset(web_ids):
        sys.exit(f"ERROR: 매칭 안 되는 참조: {refs - web_ids}")


def main():
    ap = argparse.ArgumentParser(description="PyCharm 원격 인터프리터 일괄 생성")
    ap.add_argument("--options-dir", default=PYCHARM_OPTIONS_DIR,
                    help="PyCharm options 폴더 경로")
    ap.add_argument("--out", default=".", help="결과 파일 출력 폴더 (기본: 현재 폴더)")
    ap.add_argument("--apply", action="store_true",
                    help="생성 후 options 폴더에 바로 적용 (기존 파일 자동 백업)")
    args = ap.parse_args()

    ssh_path = os.path.join(args.options_dir, "sshConfigs.xml")
    if not os.path.exists(ssh_path):
        sys.exit(f"ERROR: {ssh_path} 가 없습니다. --options-dir 를 확인하세요.")

    configs = parse_ssh_configs(ssh_path)
    print(f"파싱된 SSH config {len(configs)}개:")
    for c in configs:
        print(f"  {c['name']:8s} host={c['host']:5s} port={c['port']}")

    webservers, jdktable = build(configs)
    validate(webservers, jdktable)
    print("\nXML 형식 및 ID 교차 참조 검증 통과")

    os.makedirs(args.out, exist_ok=True)
    web_out = os.path.join(args.out, "webServers.xml")
    jdk_out = os.path.join(args.out, "jdk.table.xml")
    with open(web_out, "w", encoding="utf-8") as f:
        f.write(webservers)
    with open(jdk_out, "w", encoding="utf-8") as f:
        f.write(jdktable)
    print(f"\n생성됨:\n  {web_out}\n  {jdk_out}")

    if args.apply:
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        for fname in ("webServers.xml", "jdk.table.xml"):
            target = os.path.join(args.options_dir, fname)
            if os.path.exists(target):
                bak = f"{target}.bak_{ts}"
                shutil.copy2(target, bak)
                print(f"백업: {bak}")
            shutil.copy2(os.path.join(args.out, fname), target)
            print(f"적용: {target}")
        print("\n완료. PyCharm을 실행하세요. "
              "(반드시 PyCharm이 꺼진 상태에서 --apply 를 실행했어야 합니다)")
    else:
        print("\n--apply 를 붙이면 options 폴더에 자동 적용(+백업)합니다. "
              "단, PyCharm을 먼저 완전히 종료하세요.")


if __name__ == "__main__":
    main()