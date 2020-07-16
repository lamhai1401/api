FROM node:alpine
LABEL maintainer="HaiLam"

# It is important that these ARG's are defined after the FROM statement
ARG ACCESS_TOKEN_USR="lamhai1401"
ARG ACCESS_TOKEN_PWD="a89467165b65849946ad2cbefe336345059bc290"

# git is required to fetch go dependencies
RUN apk add --no-cache ca-certificates git make musl-dev go htop

# Create the user and group files that will be used in the running 
# container to run the process as an unprivileged user.
RUN mkdir /user && \
    echo 'nobody:x:65534:65534:nobody:/:' > /user/passwd && \
    echo 'nobody:x:65534:' > /user/group

# Create a netrc file using the credentials specified using --build-arg
RUN printf "machine github.com\n\
    login ${ACCESS_TOKEN_USR}\n\
    password ${ACCESS_TOKEN_PWD}\n\
    \n\
    machine api.github.com\n\
    login ${ACCESS_TOKEN_USR}\n\
    password ${ACCESS_TOKEN_PWD}\n"\
    >> /root/.netrc
RUN chmod 600 /root/.netrc

# setup go env
ENV GO111MODULE=on
ENV GIT_TERMINAL_PROMPT=1
ENV GONOPROXY=github.com/beowulflab/*
ENV GOPRIVATE=github.com/beowulflab/*
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH
RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin

# Export udp port
EXPOSE 20000-64000:20000-64000/udp
EXPOSE 20000-64000:20000-64000

#Setup process manager
ENV PORT=80
ENV INSTANCE_TYPE=SERVER
ENV LIVESTREAM_MANAGER_URL=wss://classroom-test.dechen.app

WORKDIR /usr/local/src
# RUN ls -l
RUN git clone https://github.com/beowulflab/classroom-process-manager --branch=v2

WORKDIR /usr/local/src/classroom-process-manager

RUN npm install --no-audit
RUN npm run build
RUN npm install -g pm2
RUN pwd

WORKDIR /usr/local/src

RUN git clone https://github.com/beowulflab/classroom-core --branch=master

COPY ./ /${GOPATH}/src/github.com/beowulflab/classroom-core
WORKDIR /${GOPATH}/src/github.com/beowulflab/classroom-core

# ENV ROLE="MASTER"
# ENV ROLE="REPEATER"

RUN go mod download
RUN go clean
RUN go build -o classroom-core

RUN chmod 777 classroom-core
RUN rm -f /usr/local/src/classroom-process-manager/classroom-core
RUN cp classroom-core /usr/local/src/classroom-process-manager

WORKDIR /usr/local/src/classroom-process-manager

CMD ["node", "dist/index.js"]

# ADD entrypoint.sh /
# ENTRYPOINT ["sh" ,"/entrypoint.sh"]