FROM ubuntu:20.04


# == Get ca-certificates up to date ==
RUN apt-get -y update
RUN apt-get -y install ca-certificates


# == Copy Data ==
COPY install_scripts /install_scripts

# == Configure Ubuntu ==
WORKDIR /install_scripts
RUN sh install_dependencies.sh
RUN sh add_users.sh

# == Set up the phabricator code base ==
RUN mkdir /srv/phabricator
RUN chown git:wwwgrp-phabricator /srv/phabricator
USER git
WORKDIR /srv/phabricator
#RUN git clone https://we.phabricator.it/source/phabricator.git
RUN git clone https://github.com/phacility/phabricator.git
#RUN git clone https://we.phabricator.it/source/arcanist.git
RUN git clone https://github.com/phacility/arcanist.git
USER root
WORKDIR /
RUN mkdir -p /var/tmp/phd/log
RUN chown phabricator-daemon:2000 /var/tmp/phd/log

# == Expose Ports ==

# Nginx
EXPOSE 80
# Aphlict
EXPOSE 22280
# SSH
EXPOSE 2222

# == Add service config files ==
ADD /config/nginx.conf.org /etc/nginx/
ADD /config/fastcgi.conf /etc/nginx/
ADD /config/php-fpm.conf /etc/php/7.4/fpm/
ADD /config/php.ini /etc/php/7.4/fpm/
ADD /config/aphlict.phabricator.json /install_scripts/

# == Add Supervisord config files ==
RUN mkdir -p /var/log/supervisor
RUN mkdir -p /etc/supervisor/conf.d/

ADD config/supervisord.conf /etc/supervisor/
COPY config/*.sv.conf /etc/supervisor/conf.d/

# == Configure phabricator SSH service ==
RUN mkdir /etc/phabricator-ssh
RUN mkdir /var/run/sshd/
RUN chmod 0755 /var/run/sshd
ADD config/sshd_config.phabricator /etc/phabricator-ssh/
ADD config/phabricator-ssh-hook.sh /etc/phabricator-ssh/
RUN chown root:root /etc/phabricator-ssh/*

# == Copy other scripts == #
COPY user-config /user-config
COPY startup.sh /

CMD bash ./startup.sh && supervisord
