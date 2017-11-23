FROM larsks/envtpl
RUN yum -y install dnf-plugins-core; \
	dnf -y copr enable larsks/collectd; \
	yum -y install collectd collectd-postgresql postgresql; yum clean all
COPY entrypoint.sh /entrypoint.sh
COPY schema.sql /etc/collectd/schema.sql.tpl
COPY collectd.conf /etc/collectd/collectd.conf.tpl
ENTRYPOINT ["sh", "/entrypoint.sh"]
CMD ["collectd", "-f"]
