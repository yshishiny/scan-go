FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy dependency manifests
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Expose network port (Cloud Run defaults to 8080, Express falls back to 3000 locally)
EXPOSE 8080

# Run server
CMD [ "node", "server.js" ]
