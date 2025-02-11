.PHONY: build
build: genesis

.PHONY: genesis
genesis: genesis-el

.PHONY: genesis-el
genesis-el:
	cd el && . /apps/el-gen/.venv/bin/activate && ./build_el.sh

.PHONY: clean
clean:
	rm -rf build
