SET search_path = public, pg_catalog;
--CREATE LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION mkViews(set_schemas pg_catalog.NAME[], temporary BOOLEAN) RETURNS void 
    AS $$
  DECLARE
    tables pg_catalog.NAME[];
    schemas pg_catalog.NAME[];
    schema_and_table TEXT[];
    mkview TEXT;
  BEGIN
    IF set_schemas IS NULL THEN
      SELECT ARRAY(SELECT DISTINCT tablename FROM pg_tables WHERE schemaname LIKE 'modencode_experiment_%_data') INTO tables;
      SELECT ARRAY(SELECT DISTINCT schemaname FROM pg_tables WHERE schemaname LIKE 'modencode_experiment_%_data') INTO schemas;
      RAISE NOTICE 'Using all modencode_experiment_..._default schemas: %', array_to_string(schemas, ', ');
    ELSE
      SELECT ARRAY(SELECT DISTINCT tablename FROM pg_tables WHERE schemaname = ANY(set_schemas)) INTO tables;
      SELECT ARRAY(SELECT DISTINCT schemaname FROM pg_tables WHERE schemaname = ANY(set_schemas)) INTO schemas;
    END IF;
    IF array_lower(schemas,1) IS NULL THEN
      RAISE NOTICE 'No schemas found to create views from.';
      RETURN;
    END IF;
    FOR i IN array_lower(tables,1)..array_upper(tables,1) LOOP
      IF temporary IS NULL OR temporary = TRUE THEN
        mkview := 'CREATE OR REPLACE TEMPORARY VIEW ' || tables[i] || ' AS ';
      ELSE
        mkview := 'CREATE OR REPLACE VIEW ' || tables[i] || ' AS ';
      END IF;
      schema_and_table := '{}';
      FOR j IN array_lower(schemas,1)..array_upper(schemas,1) LOOP
        schema_and_table := schema_and_table || ('SELECT * FROM ' || schemas[j] || '.' || tables[i]);
      END LOOP;
      mkview := mkview || array_to_string(schema_and_table, ' UNION ') || ';';
      EXECUTE mkview;
    END LOOP;
  END
$$ LANGUAGE plpgsql;

--
-- Name: attributelist_id_seq; Type: SEQUENCE; Schema: public; Owner: db_public
--

CREATE SEQUENCE attributelist_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.attributelist_id_seq OWNER TO db_public;

--
-- Name: feature_id_seq; Type: SEQUENCE; Schema: public; Owner: db_public
--

CREATE SEQUENCE feature_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;

ALTER TABLE public.feature_id_seq OWNER TO db_public;

--
-- Name: locationlist_id_seq; Type: SEQUENCE; Schema: public; Owner: db_public
--

CREATE SEQUENCE locationlist_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.locationlist_id_seq OWNER TO db_public;


--
-- Name: typelist_id_seq; Type: SEQUENCE; Schema: public; Owner: db_public
--

CREATE SEQUENCE typelist_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.typelist_id_seq OWNER TO db_public;


