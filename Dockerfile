FROM golang:1.8.3-alpine as build_golang

ARG APP_VERSION=unkown

ADD . /go/src/github.com/stefanprodan/mgob

WORKDIR /go/src/github.com/stefanprodan/mgob

RUN mkdir -p /dist
RUN go build -ldflags "-X main.version=$APP_VERSION" -o /dist/mgob github.com/stefanprodan/mgob



FROM alpine:3.6

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

ENV GOOGLE_CLOUD_SDK_VERSION 181.0.0
ENV PATH /root/google-cloud-sdk/bin:$PATH
ENV CONFD_VERSION 0.15.0

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="mgob" \
      org.label-schema.description="MongoDB backup automation tool" \
      org.label-schema.url="https://github.com/stefanprodan/mgob" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/stefanprodan/mgob" \
      org.label-schema.vendor="stefanprodan.com" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

RUN apk add --no-cache mongodb-tools ca-certificates
ADD https://dl.minio.io/client/mc/release/linux-amd64/mc /usr/bin
RUN chmod u+x /usr/bin/mc

WORKDIR /root/

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./confd /etc/confd

#install gcloud
# https://github.com/GoogleCloudPlatform/cloud-sdk-docker/blob/69b7b0031d877600a9146c1111e43bc66b536de7/alpine/Dockerfile
RUN apk --no-cache add \
        curl \
        python \
        py-crcmod \
        bash \
        libc6-compat \
        openssh-client \
        git \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GOOGLE_CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-${GOOGLE_CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-${GOOGLE_CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    ln -s /lib /lib64 && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version \
    && curl -sSL https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 -o /usr/local/bin/confd \
    && chmod +x /usr/local/bin/confd \
        /usr/local/bin/entrypoint.sh

COPY --from=build_golang /dist/mgob    .

VOLUME ["/config", "/storage", "/tmp", "/data"]

EXPOSE 8090

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD [ "./mgob" ]
