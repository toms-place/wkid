FROM mcr.microsoft.com/oss/go/microsoft/golang:1.24.6-bookworm AS builder

RUN go install github.com/Azure/azure-workload-identity/cmd/azwi@v1.5.1
RUN go install github.com/mikefarah/yq/v4@v4.48.1

FROM mcr.microsoft.com/cbl-mariner/distroless/base:2.0-nonroot

WORKDIR /

COPY --from=builder /go/bin/azwi /usr/local/bin
COPY --from=builder /go/bin/yq /usr/local/bin

ENV PUBLIC_KEY_PATH=/etc/kubernetes/pki/sa.pub
ENV OUTPUT_FILE=/web/jwks.json
ENV ADDITIONAL_FLAGS=""

# Kubernetes runAsNonRoot requires USER to be numeric
USER 65532:65532
ENTRYPOINT [ "/usr/local/bin/azwi" ]
