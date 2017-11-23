CREATE DATABASE {{COLLECTD_DB_NAME}};
\c {{COLLECTD_DB_NAME}}

CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Sample configuration:
-- ---------------------
--
-- <Plugin postgresql>
--     <Writer sqlstore>
--         Statement "SELECT collectd_insert($1, $2, $3, $4, $5, $6, $7, $8, $9);"
--     </Writer>
--     <Database collectd>
--         # ...
--         Writer sqlstore
--     </Database>
-- </Plugin>

CREATE TABLE identifiers (
    id integer NOT NULL PRIMARY KEY,
    host character varying(64) NOT NULL,
    plugin character varying(64) NOT NULL,
    plugin_inst character varying(64) DEFAULT NULL::character varying,
    type character varying(64) NOT NULL,
    type_inst character varying(64) DEFAULT NULL::character varying,

    UNIQUE (host, plugin, plugin_inst, type, type_inst)
);

CREATE SEQUENCE identifiers_id_seq
    OWNED BY identifiers.id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE identifiers
    ALTER COLUMN id
    SET DEFAULT nextval('identifiers_id_seq'::regclass);

-- create indexes for the identifier fields
CREATE INDEX identifiers_host ON identifiers USING btree (host);
CREATE INDEX identifiers_plugin ON identifiers USING btree (plugin);
CREATE INDEX identifiers_plugin_inst ON identifiers USING btree (plugin_inst);
CREATE INDEX identifiers_type ON identifiers USING btree (type);
CREATE INDEX identifiers_type_inst ON identifiers USING btree (type_inst);

CREATE TABLE "values" (
    id integer NOT NULL
        REFERENCES identifiers
        ON DELETE cascade,
    tstamp timestamp with time zone NOT NULL,
    name character varying(64) NOT NULL,
    value double precision NOT NULL
);

SELECT create_hypertable('values', 'tstamp');

CREATE OR REPLACE VIEW collectd
    AS SELECT host, plugin, plugin_inst, type, type_inst,
            host
                || '/' || plugin
                || CASE
                    WHEN plugin_inst IS NOT NULL THEN '-'
                    ELSE ''
                END
                || coalesce(plugin_inst, '')
                || '/' || type
                || CASE
                    WHEN type_inst IS NOT NULL THEN '-'
                    ELSE ''
                END
                || coalesce(type_inst, '') AS identifier,
            tstamp, name, value
        FROM identifiers
            JOIN values
            ON values.id = identifiers.id;

CREATE OR REPLACE FUNCTION collectd_insert(
        timestamp with time zone, character varying,
        character varying, character varying,
        character varying, character varying,
        character varying[], character varying[], double precision[]
    ) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE
    p_time alias for $1;
    p_host alias for $2;
    p_plugin alias for $3;
    p_plugin_instance alias for $4;
    p_type alias for $5;
    p_type_instance alias for $6;
    p_value_names alias for $7;
    -- don't use the type info; for 'StoreRates true' it's 'gauge' anyway
    -- p_type_names alias for $8;
    p_values alias for $9;
    ds_id integer;
    i integer;
BEGIN
    SELECT id INTO ds_id
        FROM identifiers
        WHERE host = p_host
            AND plugin = p_plugin
            AND COALESCE(plugin_inst, '') = COALESCE(p_plugin_instance, '')
            AND type = p_type
            AND COALESCE(type_inst, '') = COALESCE(p_type_instance, '');
    IF NOT FOUND THEN
        INSERT INTO identifiers (host, plugin, plugin_inst, type, type_inst)
            VALUES (p_host, p_plugin, p_plugin_instance, p_type, p_type_instance)
            RETURNING id INTO ds_id;
    END IF;
    i := 1;
    LOOP
        EXIT WHEN i > array_upper(p_value_names, 1);
        INSERT INTO values (id, tstamp, name, value)
            VALUES (ds_id, p_time, p_value_names[i], p_values[i]);
        i := i + 1;
    END LOOP;
END;
$_$;
