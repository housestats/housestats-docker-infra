FROM fedora
RUN yum -y install python3 python3-virtualenv git postgresql python3-psycopg2
RUN python3 -m virtualenv /app
RUN . /app/bin/activate; pip install git+https://github.com/larsks/skeetereater
COPY entrypoint.sh /entrypoint.sh
COPY schema.sql /etc/skeeter/schema.sql
ENTRYPOINT ["sh", "/entrypoint.sh"]
CMD ["/app/bin/skeeter", "-v"]
