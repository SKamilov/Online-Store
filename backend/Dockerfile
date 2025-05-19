# build stage
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY backend/go.mod backend/go.sum ./
RUN go mod download
COPY backend/ .
RUN CGO_ENABLED=0 go build -o momo-api

# runtime
FROM bellsoft/liberica-runtime-container:jre-17-slim-musl
COPY --from=builder /app/momo-api /momo-api
EXPOSE 8081
ENTRYPOINT ["/momo-api"]