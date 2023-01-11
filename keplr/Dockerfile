# docker build . -t joe-keplr
FROM node:18

WORKDIR /usr/src/app


COPY package*.json ./
RUN npm ci --only=production

COPY . .

ENV NODE_OPTIONS=--openssl-legacy-provider

# http port
EXPOSE 91 

# run the webpack
CMD [ "npm", "run", "dev" ]


# docker run -p 91:91 joe-keplr