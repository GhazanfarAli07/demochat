
#
# ---- Base Node ----
#
FROM alpine:3.5 AS base

# install node
RUN apk add --no-cache nodejs-current tini
# set working directory
WORKDIR /root/demochat
# Set tini as entrypoint
ENTRYPOINT ["/sbin/tini", "--"]
# copy project file
COPY package.json .

#
# ---- Dependencies ----
#
FROM base AS dependencies

# install compilers for node_gyp
RUN apk add --no-cache python make g++ krb5-dev

# install node packages
RUN npm set progress=false && npm config set depth 0
RUN npm install --only=production 
# copy production node_modules aside
RUN cp -R node_modules prod_node_modules
# install ALL node_modules
RUN npm install

#
# ---- Test ----
#
FROM dependencies AS test
COPY . .
RUN npm run lint
RUN npm run test

#
# ---- Release ----
#
FROM base AS release

# copy production node_modules
COPY --from=dependencies /root/demochat/prod_node_modules ./node_modules
# copy app sources
COPY . .
# expose port and define CMD
EXPOSE 5000
CMD npm run start

