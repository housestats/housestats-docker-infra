CREATE DATABASE sensors;
\c sensors

CREATE EXTENSION timescaledb;

CREATE FUNCTION c_to_f(FLOAT)
	RETURNS FLOAT
	AS 'select $1 * 9 / 5 + 32'
	LANGUAGE SQL RETURNS NULL ON NULL INPUT;

CREATE TABLE mqtt_template (
	measured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	topic TEXT NOT NULL,
	tags JSONB,
	fields JSONB,
	UNIQUE (measured_at, topic)
);

CREATE INDEX topic_index ON mqtt_template (topic);
CREATE INDEX tags_index ON mqtt_template USING gin (tags);
