FROM nginx:alpine
LABEL org.opencontainers.image.title="dohyeon-workstation"
COPY site/ /usr/share/nginx/html/
EXPOSE 80
