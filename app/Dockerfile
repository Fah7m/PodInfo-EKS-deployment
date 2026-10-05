ARG GOLANG_VERSION=1.26
ARG ALPINE_VERSION=3.24

FROM golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} AS build

ARG REVISION=dev

WORKDIR /podinfo

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w \
    -X github.com/stefanprodan/podinfo/pkg/version.REVISION=${REVISION}" \
    -a -o bin/podinfo cmd/podinfo/*

FROM gcr.io/distroless/static-debian12

WORKDIR /app

COPY --from=build /podinfo/bin/podinfo ./podinfo

COPY ./ui ./ui

USER nonroot:nonroot

EXPOSE 9898

ENTRYPOINT ["./podinfo"]