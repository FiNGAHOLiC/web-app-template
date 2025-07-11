FROM node:22.17.0-slim AS base

ARG DATABASE_USER=''
ARG DATABASE_PASSWORD=''
ARG DATABASE_DB=''
ARG DATABASE_HOST=''
ARG DATABASE_PORT=''
ARG DATABASE_SCHEMA=''
ARG GOOGLE_CLIENT_ID=''
ARG GOOGLE_CLIENT_SECRET=''
ARG NEXT_PUBLIC_SITE_URL=''
ARG NEXTAUTH_SECRET=''
# start: otel #
ARG TRACE_EXPORTER_URL=''
# end: otel #
# start: stripe #
ARG STRIPE_PRICE_ID=''
ARG STRIPE_SECRET_KEY=''
ARG STRIPE_WEBHOOK_SECRET=''
# end: stripe #

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV DATABASE_USER=$DATABASE_USER
ENV DATABASE_PASSWORD=$DATABASE_PASSWORD
ENV DATABASE_DB=$DATABASE_DB
ENV DATABASE_HOST=$DATABASE_HOST
ENV DATABASE_PORT=$DATABASE_PORT
ENV DATABASE_SCHEMA=$DATABASE_SCHEMA
ENV GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
ENV GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET
ENV NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL
ENV NEXTAUTH_SECRET=$NEXTAUTH_SECRET
ENV NEXTAUTH_URL=$NEXT_PUBLIC_SITE_URL
# start: otel #
ENV TRACE_EXPORTER_URL=$TRACE_EXPORTER_URL
# end: otel #
# start: stripe #
ENV STRIPE_PRICE_ID=$STRIPE_PRICE_ID
ENV STRIPE_SECRET_KEY=$STRIPE_SECRET_KEY
ENV STRIPE_WEBHOOK_SECRET=$STRIPE_WEBHOOK_SECRET
# end: stripe #

COPY . /app
WORKDIR /app

RUN npm run setup
# for prisma
RUN apt-get update -y && apt-get install -y openssl

FROM base AS prod-deps

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm i --prod --frozen-lockfile
RUN pnpm prisma generate --generator client

FROM base AS build

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm i --frozen-lockfile
RUN pnpm build

FROM base AS app

COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=build /app/.next /app/.next

EXPOSE 3000
CMD ["pnpm", "start"]
