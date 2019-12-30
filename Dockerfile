FROM elixir:1.9.4-alpine as builder

ENV MIX_ENV=prod \
  LANG=C.UTF-8

RUN mkdir /app
WORKDIR /app

COPY config ./config
COPY lib ./lib
COPY mix.exs .
COPY mix.lock .

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix deps.compile
RUN mix release

FROM alpine AS app

ENV LANG=C.UTF-8

EXPOSE 5000

RUN apk update && apk add openssl ncurses-libs

RUN adduser -h /home/app -D app
WORKDIR /home/app
COPY --from=builder /app/_build .
RUN chown -R app: ./prod
USER app

# Run the Phoenix app
CMD ["./prod/rel/message_queue_example/bin/message_queue_example", "start"]