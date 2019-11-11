FROM centos:7

# Arguments set during docker-compose build -b --build from .env file
ARG versionTerraform
ARG versionAzureCli
ARG versionGit
ARG versionTflint
ARG versionJq
ARG versionDockerCompose

ENV versionTerraform=${versionTerraform} \
    versionAzureCli=${versionAzureCli} \
    versionGit=${versionGit} \
    versionTflint=${versionTflint} \
    versionJq=${versionJq} \
    versionDockerCompose=${versionDockerCompose}

RUN yum -y update && \
    yum -y autoremove

RUN yum -y groupinstall "Development Tools" && \
    yum -y install \
        gettext-devel \
        openssl-devel \
        perl-CPAN \
        perl-devel \
        zlib-devel \
        curl-devel && \
    #
    echo "Installing git ${versionGit}..." && \
    curl -sSL -o /tmp/git.tar.gz https://www.kernel.org/pub/software/scm/git/git-${versionGit}.tar.gz && \
    tar -xzvf /tmp/git.tar.gz -C /tmp && \
    cd /tmp/git-${versionGit} && \
    ./configure && make && make install && \
    # Clean-up
    rm -f /tmp/*.zip && rm -f /tmp/*.gz && \
    rm -rfd /tmp/git-${versionGit} && \
    yum -y groupremove "Development Tools" && \
    yum -y remove \
        curl-devel \
        openssl-devel && \
    yum -y autoremove && \
    yum -y install unzip

    # Install Docker CE CLI. 
RUN yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    yum -y install docker-ce-cli && \
    #
    # Install Terraform
    echo "Installing terraform ${versionTerraform}..." && \
    curl -sSL -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${versionTerraform}/terraform_${versionTerraform}_linux_amd64.zip 2>&1 && \
    unzip -d /usr/local/bin /tmp/terraform.zip && \
    #
    # Install Docker-Compose
    echo "Installing docker-compose ${versionDockerCompose}..." && \
    curl -sSL -o /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/${versionDockerCompose}/docker-compose-Linux-x86_64" && \
    chmod +x /usr/local/bin/docker-compose && \
    #
    # Install Azure-cli
    echo "Installing azure-cli ${versionAzureCli}..." && \
    rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    sh -c 'echo -e "[azure-cli] \n\
name=Azure CLI \n\
baseurl=https://packages.microsoft.com/yumrepos/azure-cli \n\
enabled=1 \n\
gpgcheck=1 \n\
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo' && \
    cat /etc/yum.repos.d/azure-cli.repo && \
    yum -y install azure-cli-${versionAzureCli} && \
    #
    echo "Installing jq ${versionJq}..." && \
    curl -sSL -o /usr/local/bin/jq -sSL -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-${versionJq}/jq-linux64 && \
    chmod +x /usr/local/bin/jq && \
    #
    echo "Installing graphviz ..." && \
    yum -y install graphviz && \
    # && echo "Installing tflint ..." \
    # && curl -sSL -o /tmp/tflint.zip https://github.com/wata727/tflint/releases/download/v${versionTflint}/tflint_linux_amd64.zip \
    # && unzip -d /usr/local/bin /tmp/tflint.zip \
    #
    # Clean-up
    rm -f /tmp/*.zip && rm -f /tmp/*.gz && \
    rm -rfd /tmp/git-${versionGit} && \
    yum -y groupremove "Development Tools" && \
    yum -y remove \
        curl-devel \
        openssl-devel && \
    yum -y autoremove && \
    #
    yum -y install make openssh-clients

RUN git clone https://github.com/aztfmod/landingzones.git /tf/landingzones && \
    git clone https://github.com/aztfmod/level0.git /tf/level0 && \
    echo "alias rover=/tf/rover/launchpad.sh" >> ~/.bashrc

RUN mkdir -p /root/.vscode-server /root/.vscode-server-insiders /root/.ssh 

WORKDIR /tf/rover

COPY ./scripts/launchpad.sh .
COPY ./scripts/functions.sh .

