#!/bin/sh

cat /dev/null |nc -N localhost 3505 || {
	exit 1
}

cp -a ${HOME}/.mail.log-offset ${HOME}/.mail.log-offset~

/usr/sbin/logtail -f /var/log/mail.log -o ${HOME}/.mail.log-offset \
		|${HOME}/bin/sa-parse-syslog.pl \
		|nc -N localhost 3505 || {
	echo "Error occurred, backing out offset-file."
	cp -a ${HOME}/.mail.log-offset~ ${HOME}/.mail.log-offset
}
