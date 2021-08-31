.PHONY: docs

docs: *.lua
	ldoc -d $@ $+
