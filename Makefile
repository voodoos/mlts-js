all: 
	@jbuilder build @install @DEFAULT


lib: all
	cp _build/default/src/main.bc.js lib/mlts-worker.js \
	&& cp src/js/mlts-api.js lib/mlts-api.js \
	&& sed -i 's/require/req2uire/' lib/mlts-worker.js
# We need to rename require by something else in mlts-worker.js
# because it doesn't play well with Parcel.


dev:
	rm lib/* && @jbuilder build @install @DEFAULT --dev

test:
	@jbuilder runtest

check: test

install:
	@jbuilder install

uninstall:
	@jbuilder uninstall

bench:
	@jbuilder build bench/bench.exe

.PHONY: clean pack doc all dev bench test check install uninstall

clean:
	jbuilder clean
