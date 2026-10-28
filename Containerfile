ARG ALPINE_VERSION=alpine:3.16

FROM $ALPINE_VERSION

ARG OTP_VERSION
ARG OTP_DOWNLOAD_SHA256
ARG REBAR3_VERSION
ARG REBAR3_DOWNLOAD_SHA256

ENV OTP_VERSION=$OTP_VERSION \
    REBAR3_VERSION=$REBAR3_VERSION

LABEL org.opencontainers.image.version=$OTP_VERSION

ADD ./patches /patches
RUN set -xe \
	&& OTP_DOWNLOAD_URL="https://github.com/erlang/otp/releases/download/OTP-$OTP_VERSION/otp_src_$OTP_VERSION.tar.gz" \
	&& apk upgrade --no-cache \
	&& apk add --no-cache --virtual .fetch-deps \
		curl \
		ca-certificates \
	&& curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
	&& echo "$OTP_DOWNLOAD_SHA256  otp-src.tar.gz" | sha256sum -c - \
	&& apk add --no-cache --virtual .build-deps \
		--repository=http://dl-cdn.alpinelinux.org/alpine/v3.12/main \
		bash \
		dpkg-dev dpkg \
		gcc \
		g++ \
		libc-dev \
		linux-headers=5.4.5-r1 \
		make \
		autoconf \
		ncurses-dev \
		openssl-dev \
		unixodbc-dev \
		lksctp-tools-dev \
		tar \
	&& apk add --no-cache --virtual .quilt-deps \
		quilt \
	&& export ERL_TOP="/usr/src/otp_src_${OTP_VERSION%%@*}" \
	&& mkdir -vp $ERL_TOP \
	&& tar -xzf otp-src.tar.gz -C $ERL_TOP --strip-components=1 --no-same-owner --no-same-permissions \
	&& rm otp-src.tar.gz \
	&& ( cd $ERL_TOP \
	  && if [ -f /patches/$OTP_VERSION/series ]; then QUILT_PATCHES=/patches/$OTP_VERSION quilt push -a ; fi \
	  && ./otp_build autoconf \
	  && gnuArch="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)" \
	  && ./configure --build="$gnuArch" \
	  && make -j$(getconf _NPROCESSORS_ONLN) \
	  && make install ) \
	&& rm -rf $ERL_TOP \
	&& find /usr/local -regex '/usr/local/lib/erlang/\(lib/\|erts-\).*/\(man\|doc\|obj\|c_src\|emacs\|info\|examples\)' | xargs rm -rf \
	&& find /usr/local -name src | xargs -r find | grep -v '\.hrl$' | xargs rm -v || true \
	&& find /usr/local -name src | xargs -r find | xargs rmdir -p || true \
	&& scanelf --nobanner -E ET_EXEC -BF '%F' --recursive /usr/local | xargs -r strip --strip-all \
	&& scanelf --nobanner -E ET_DYN -BF '%F' --recursive /usr/local | xargs -r strip --strip-unneeded \
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& REBAR3_DOWNLOAD_URL="https://github.com/erlang/rebar3/archive/${REBAR3_VERSION}.tar.gz" \
	&& curl -fSL -o rebar3-src.tar.gz "$REBAR3_DOWNLOAD_URL" \
	&& echo "${REBAR3_DOWNLOAD_SHA256}  rebar3-src.tar.gz" | sha256sum -c - \
	&& mkdir -p /usr/src/rebar3-src \
	&& tar -xzf rebar3-src.tar.gz -C /usr/src/rebar3-src --strip-components=1 --no-same-owner --no-same-permissions \
	&& rm rebar3-src.tar.gz \
	&& cd /usr/src/rebar3-src \
	&& for p in rebar3-$REBAR3_VERSION rebar3-$REBAR3_VERSION-otp-$OTP_VERSION; do \
		if [ -f /patches/$p/series ]; then \
			QUILT_PATCHES=/patches/$p QUILT_PC=.pc-$p quilt push -a ; \
		fi ; \
	   done \
	&& HOME=$PWD ./bootstrap \
	&& install -v ./rebar3 /usr/local/bin/ \
	&& cd / \
	&& rm -rf /usr/src/rebar3-src \
	&& rm -rf /patches \
	&& apk add --virtual .erlang-rundeps \
		$runDeps \
		lksctp-tools \
		ca-certificates \
	&& for c in emSign_ECC_Root_CA_-_G3 emSign_ECC_Root_CA_-_C3 emSign_Root_CA_-_C1; do \
		sed -i "s|^mozilla/$c\.crt\$|!&|" /etc/ca-certificates.conf ; \
	   done \
	&& update-ca-certificates \
	&& apk del .fetch-deps .build-deps .quilt-deps \
	&& erl -noshell -eval 'Bad = [N || C <- public_key:cacerts_get(), N <- [<<"emSign ECC Root CA - G3">>, <<"emSign ECC Root CA - C3">>, <<"emSign Root CA - C1">>], binary:match(element(2, C), N) =/= nomatch], io:format("Distrusted roots in OS store: ~p~n", [Bad]), halt(length(Bad))'

CMD ["erl"]
