all: 
	@jbuilder build @install @DEFAULT


lib: all
	cp _build/default/src/main.bc.js lib/mlts-worker.js 
	#\
	#&& cp src/js/elpi-api.js lib/elpi-api.js \
	#&& sed -i bak 's/require/req2uire/' lib/elpi-worker.js
# We need to rename require by something else in elpi-worker.js
# because it doesn't play well with Parcel.

#	&& cp _build/default/src/elpiAPI.bc.js lib/elpi-api.js

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
