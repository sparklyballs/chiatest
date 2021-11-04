ARG UBUNTU_VER="focal"
FROM ubuntu:${UBUNTU_VER}

# build arguments
ARG DEBIAN_FRONTEND=noninteractive
ARG RELEASE

# environment variables
ENV \
	farmer_address="null" \
	farmer="false" \
	farmer_port="null" \
	full_node_port="null" \
	harvester="false" \
	keys="generate" \
	log_level="INFO" \
	plots_dir="/plots" \
	testnet="false" \
	TZ="UTC"

# install dependencies
RUN \
	apt-get update \
	&& apt-get install -y \
	--no-install-recommends \
		acl \
		bc \
		ca-certificates \
		curl \
		git \
		jq \
		lsb-release \
		openssl \
		python3 \
		sudo \
		tar \
		tzdata \
		unzip \
	\
# set timezone
	\
	&& ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime \
	&& echo "$TZ" > /etc/timezone \
	&& dpkg-reconfigure -f noninteractive tzdata \
	\
# cleanup
	\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# set workdir for build stage
WORKDIR /chia-blockchain

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# build package
RUN \
	if [ -z ${RELEASE+x} ]; then \
	RELEASE=$(curl -u "${SECRETUSER}:${SECRETPASS}" -sX GET "https://api.github.com/repos/Chia-Network/chia-blockchain/releases/latest" \
	| jq -r ".tag_name"); \
	fi \
	&& git clone -b "${RELEASE}" https://github.com/Chia-Network/chia-blockchain.git \
		/chia-blockchain \		
	&& git submodule update --init mozilla-ca \
	&& sh install.sh \
	\
# cleanup
	\
	&& rm -rf \
		/root/.cache \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# set additional runtime environment variables
ENV \
	PATH=/chia-blockchain/venv/bin:$PATH \
	CONFIG_ROOT=/root/.chia/mainnet

# copy local files
COPY docker-*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-*.sh

# entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-start.sh"]
