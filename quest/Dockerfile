FROM node:10

ENV SECRET_WORD "TwelveFactor"

WORKDIR /usr/src/app

COPY package*.json ./
COPY . .

RUN npm install

EXPOSE 3000

CMD [ "node", "src/000.js" ]

