FROM alpine:latest

ENV DB_HOST=db_host \
    DB_USER=db_user \
    DB_PASSWORD=db_password \
    DB_NAME=db_name

WORKDIR /home/user

COPY internet_speedtest_tracker.sh /home/user/internet_speedtest_tracker.sh

RUN apk update && \
	apk add \
        mysql-client \
        speedtest-cli \
		jq

RUN chmod +x /home/user/internet_speedtest_tracker.sh

CMD ["/bin/sh", "/home/user/internet_speedtest_tracker.sh"]
