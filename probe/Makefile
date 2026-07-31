.DEFAULT_GOAL := help

install: ## Install dependencies
	pip install pyserial==3.5

test: ## Run probe-setup.py against mock machine simulator
	@python3 -c "\
	import subprocess, time, sys; \
	mock = subprocess.Popen(['python3', 'mock-machine.py'], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); \
	time.sleep(2); \
	probe = subprocess.Popen(['python3', 'probe-setup.py', '--port', '/tmp/cnc-sim'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT); \
	probe.stdin.write(b'\n' * 10); probe.stdin.flush(); \
	out, _ = probe.communicate(timeout=30); \
	mock.terminate(); mock.wait(); \
	sys.stdout.buffer.write(out); \
	sys.exit(probe.returncode)"

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
