import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time


evidence = Path('runtime-evidence').resolve()
evidence.mkdir(exist_ok=True)
program = str(Path(sys.argv[1]).resolve())
checks = {}


def run_runtime(directory, name):
    logfile = evidence / f'{name}.log'
    with logfile.open('w') as output:
        process = subprocess.Popen([program], cwd=directory, stdout=output,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        try:
            deadline = time.monotonic() + 35
            while process.poll() is None and time.monotonic() < deadline:
                time.sleep(0.5)
            checks[f'{name}_running'] = process.poll() is None
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait(timeout=5)
    text = logfile.read_text(errors='replace')
    text = re.sub(r'(?i)(token[=:]\s*)[^\s]+', r'\1[redacted]', text)
    logfile.write_text(text)
    for key, marker in {
        'core': 'NapCat.Core Version:',
        'packet': '[PacketHandler] 初始化成功',
        'napi': '[Napi2NativeLoader] 加载成功',
        'ffmpeg': '使用 Native Addon 适配器',
    }.items():
        checks[f'{name}_{key}'] = marker in text
    print(text[-10000:], flush=True)


with tempfile.TemporaryDirectory(prefix='napcat nix # ') as temporary:
    directory = Path(temporary)
    run_runtime(directory, 'first')
    config = directory / 'data/napcat/config/audit.json'
    plugin = directory / 'data/napcat/plugins/audit.txt'
    checks['config_directory'] = config.parent.is_dir()
    checks['plugin_directory'] = plugin.parent.is_dir()
    if checks['config_directory'] and checks['plugin_directory']:
        config.write_text('{"audit":"preserve config"}')
        plugin.write_text('preserve plugin')
        run_runtime(directory, 'restart')
        checks['config_preserved'] = config.read_text() == '{"audit":"preserve config"}'
        checks['plugin_preserved'] = plugin.read_text() == 'preserve plugin'

(evidence / 'result.json').write_text(json.dumps(checks, indent=2))
print(json.dumps(checks), flush=True)
assert all(checks.values()), checks
