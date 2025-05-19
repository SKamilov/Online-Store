# build stage
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
WORKDIR /app/cmd/api
RUN CGO_ENABLED=0 go build -o /app/momo-api

# runtime
FROM bellsoft/liberica-runtime-container:jre-17-slim-musl
COPY --from=builder /app/momo-api /momo-api
EXPOSE 8081
ENTRYPOINT ["/momo-api"]