--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

CREATE SCHEMA modencode_experiment_default_data;

SET search_path = modencode_experiment_default_data, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: attribute; Type: TABLE; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE TABLE attribute (
    id integer NOT NULL,
    attribute_id integer NOT NULL,
    attribute_value text
);


ALTER TABLE modencode_experiment_default_data.attribute OWNER TO db_public;

--
-- Name: attributelist; Type: TABLE; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE TABLE attributelist (
    id integer NOT NULL,
    tag character varying(50) NOT NULL
);


ALTER TABLE modencode_experiment_default_data.attributelist OWNER TO db_public;

--
-- Name: feature; Type: TABLE; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE TABLE feature (
    id integer NOT NULL,
    typeid integer NOT NULL,
    seqid integer,
    start integer,
    "end" integer,
    strand integer DEFAULT 0,
    tier integer,
    bin integer,
    indexed integer DEFAULT 1,
    object bytea NOT NULL
);


ALTER TABLE modencode_experiment_default_data.feature OWNER TO db_public;

--
-- Name: locationlist; Type: TABLE; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE TABLE locationlist (
    id integer NOT NULL,
    seqname character varying(50) NOT NULL
);


ALTER TABLE modencode_experiment_default_data.locationlist OWNER TO db_public;

--
-- Name: meta; Type: TABLE; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE TABLE meta (
    name character varying(128) NOT NULL,
    value character varying(128) NOT NULL
);


ALTER TABLE modencode_experiment_default_data.meta OWNER TO db_public;

--
-- Name: name; Type: TABLE; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE TABLE name (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    display_name integer DEFAULT 0
);


ALTER TABLE modencode_experiment_default_data.name OWNER TO db_public;

--
-- Name: parent2child; Type: TABLE; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE TABLE parent2child (
    id integer NOT NULL,
    child integer NOT NULL
);


ALTER TABLE modencode_experiment_default_data.parent2child OWNER TO db_public;

--
-- Name: sequence; Type: TABLE; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE TABLE sequence (
    id integer NOT NULL,
    "offset" integer NOT NULL,
    sequence text
);


ALTER TABLE modencode_experiment_default_data.sequence OWNER TO db_public;

--
-- Name: typelist; Type: TABLE; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE TABLE typelist (
    id integer NOT NULL,
    tag character varying(100) NOT NULL
);


ALTER TABLE modencode_experiment_default_data.typelist OWNER TO db_public;

--
-- Name: id; Type: DEFAULT; Schema: modencode_experiment_default_data; Owner: db_public
--

ALTER TABLE attributelist ALTER COLUMN id SET DEFAULT nextval('public.attributelist_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: modencode_experiment_default_data; Owner: db_public
--

ALTER TABLE feature ALTER COLUMN id SET DEFAULT nextval('public.feature_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: modencode_experiment_default_data; Owner: db_public
--

ALTER TABLE locationlist ALTER COLUMN id SET DEFAULT nextval('public.locationlist_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: modencode_experiment_default_data; Owner: db_public
--

ALTER TABLE typelist ALTER COLUMN id SET DEFAULT nextval('public.typelist_id_seq'::regclass);


--
-- Name: attributelist_pkey; Type: CONSTRAINT; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY attributelist
    ADD CONSTRAINT attributelist_pkey PRIMARY KEY (id);


--
-- Name: feature_pkey; Type: CONSTRAINT; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY feature
    ADD CONSTRAINT feature_pkey PRIMARY KEY (id);


--
-- Name: locationlist_pkey; Type: CONSTRAINT; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY locationlist
    ADD CONSTRAINT locationlist_pkey PRIMARY KEY (id);


--
-- Name: meta_pkey; Type: CONSTRAINT; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY meta
    ADD CONSTRAINT meta_pkey PRIMARY KEY (name);


--
-- Name: sequence_pkey; Type: CONSTRAINT; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY sequence
    ADD CONSTRAINT sequence_pkey PRIMARY KEY (id, "offset");


--
-- Name: typelist_pkey; Type: CONSTRAINT; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY typelist
    ADD CONSTRAINT typelist_pkey PRIMARY KEY (id);


--
-- Name: attribute_id; Type: INDEX; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE INDEX attribute_id ON attribute USING btree (id);


--
-- Name: attribute_id_val; Type: INDEX; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE INDEX attribute_id_val ON attribute USING btree (attribute_id, substr(attribute_value, 1, 10));


--
-- Name: attributelist_tag; Type: INDEX; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE INDEX attributelist_tag ON attributelist USING btree (tag);


--
-- Name: feature_stuff; Type: INDEX; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE INDEX feature_stuff ON feature USING btree (seqid, tier, bin, typeid);


--
-- Name: feature_typeid; Type: INDEX; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE INDEX feature_typeid ON feature USING btree (typeid);


--
-- Name: locationlist_seqname; Type: INDEX; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE INDEX locationlist_seqname ON locationlist USING btree (seqname);


--
-- Name: name_id; Type: INDEX; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE INDEX name_id ON name USING btree (id);


--
-- Name: name_name; Type: INDEX; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE INDEX name_name ON name USING btree (name);


--
-- Name: parent2child_id_child; Type: INDEX; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE INDEX parent2child_id_child ON parent2child USING btree (id, child);


--
-- Name: typelist_tab; Type: INDEX; Schema: modencode_experiment_default_data; Owner: db_public; Tablespace: 
--

CREATE INDEX typelist_tab ON typelist USING btree (tag);


SET search_path = public, pg_catalog;

--
-- PostgreSQL database dump complete
--

