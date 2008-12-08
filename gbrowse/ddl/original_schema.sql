--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: attribute; Type: TABLE; Schema: public; Owner: db_public; Tablespace: 
--

CREATE TABLE attribute (
    id integer NOT NULL,
    attribute_id integer NOT NULL,
    attribute_value text
);


ALTER TABLE public.attribute OWNER TO db_public;

--
-- Name: attributelist; Type: TABLE; Schema: public; Owner: db_public; Tablespace: 
--

CREATE TABLE attributelist (
    id integer NOT NULL,
    tag character varying(50) NOT NULL
);


ALTER TABLE public.attributelist OWNER TO db_public;

--
-- Name: feature; Type: TABLE; Schema: public; Owner: db_public; Tablespace: 
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


ALTER TABLE public.feature OWNER TO db_public;

--
-- Name: locationlist; Type: TABLE; Schema: public; Owner: db_public; Tablespace: 
--

CREATE TABLE locationlist (
    id integer NOT NULL,
    seqname character varying(50) NOT NULL
);


ALTER TABLE public.locationlist OWNER TO db_public;

--
-- Name: meta; Type: TABLE; Schema: public; Owner: db_public; Tablespace: 
--

CREATE TABLE meta (
    name character varying(128) NOT NULL,
    value character varying(128) NOT NULL
);


ALTER TABLE public.meta OWNER TO db_public;

--
-- Name: name; Type: TABLE; Schema: public; Owner: db_public; Tablespace: 
--

CREATE TABLE name (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    display_name integer DEFAULT 0
);


ALTER TABLE public.name OWNER TO db_public;

--
-- Name: parent2child; Type: TABLE; Schema: public; Owner: db_public; Tablespace: 
--

CREATE TABLE parent2child (
    id integer NOT NULL,
    child integer NOT NULL
);


ALTER TABLE public.parent2child OWNER TO db_public;

--
-- Name: sequence; Type: TABLE; Schema: public; Owner: db_public; Tablespace: 
--

CREATE TABLE sequence (
    id integer NOT NULL,
    "offset" integer NOT NULL,
    sequence text
);


ALTER TABLE public.sequence OWNER TO db_public;

--
-- Name: typelist; Type: TABLE; Schema: public; Owner: db_public; Tablespace: 
--

CREATE TABLE typelist (
    id integer NOT NULL,
    tag character varying(100) NOT NULL
);


ALTER TABLE public.typelist OWNER TO db_public;

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
-- Name: attributelist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: db_public
--

ALTER SEQUENCE attributelist_id_seq OWNED BY attributelist.id;


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
-- Name: feature_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: db_public
--

ALTER SEQUENCE feature_id_seq OWNED BY feature.id;


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
-- Name: locationlist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: db_public
--

ALTER SEQUENCE locationlist_id_seq OWNED BY locationlist.id;


--
-- Name: typelist_id_seq; Type: SEQUENCE; Schema: public; Owner: db_public
--

CREATE SEQUENCE typelist_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.typelist_id_seq OWNER TO db_public;

--
-- Name: typelist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: db_public
--

ALTER SEQUENCE typelist_id_seq OWNED BY typelist.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: db_public
--

ALTER TABLE attributelist ALTER COLUMN id SET DEFAULT nextval('attributelist_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: db_public
--

ALTER TABLE feature ALTER COLUMN id SET DEFAULT nextval('feature_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: db_public
--

ALTER TABLE locationlist ALTER COLUMN id SET DEFAULT nextval('locationlist_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: db_public
--

ALTER TABLE typelist ALTER COLUMN id SET DEFAULT nextval('typelist_id_seq'::regclass);


--
-- Name: attributelist_pkey; Type: CONSTRAINT; Schema: public; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY attributelist
    ADD CONSTRAINT attributelist_pkey PRIMARY KEY (id);


--
-- Name: feature_pkey; Type: CONSTRAINT; Schema: public; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY feature
    ADD CONSTRAINT feature_pkey PRIMARY KEY (id);


--
-- Name: locationlist_pkey; Type: CONSTRAINT; Schema: public; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY locationlist
    ADD CONSTRAINT locationlist_pkey PRIMARY KEY (id);


--
-- Name: meta_pkey; Type: CONSTRAINT; Schema: public; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY meta
    ADD CONSTRAINT meta_pkey PRIMARY KEY (name);


--
-- Name: sequence_pkey; Type: CONSTRAINT; Schema: public; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY sequence
    ADD CONSTRAINT sequence_pkey PRIMARY KEY (id, "offset");


--
-- Name: typelist_pkey; Type: CONSTRAINT; Schema: public; Owner: db_public; Tablespace: 
--

ALTER TABLE ONLY typelist
    ADD CONSTRAINT typelist_pkey PRIMARY KEY (id);


--
-- Name: attribute_id; Type: INDEX; Schema: public; Owner: db_public; Tablespace: 
--

CREATE INDEX attribute_id ON attribute USING btree (id);


--
-- Name: attribute_id_val; Type: INDEX; Schema: public; Owner: db_public; Tablespace: 
--

CREATE INDEX attribute_id_val ON attribute USING btree (attribute_id, substr(attribute_value, 1, 10));


--
-- Name: attributelist_tag; Type: INDEX; Schema: public; Owner: db_public; Tablespace: 
--

CREATE INDEX attributelist_tag ON attributelist USING btree (tag);


--
-- Name: feature_stuff; Type: INDEX; Schema: public; Owner: db_public; Tablespace: 
--

CREATE INDEX feature_stuff ON feature USING btree (seqid, tier, bin, typeid);


--
-- Name: feature_typeid; Type: INDEX; Schema: public; Owner: db_public; Tablespace: 
--

CREATE INDEX feature_typeid ON feature USING btree (typeid);


--
-- Name: locationlist_seqname; Type: INDEX; Schema: public; Owner: db_public; Tablespace: 
--

CREATE INDEX locationlist_seqname ON locationlist USING btree (seqname);


--
-- Name: name_id; Type: INDEX; Schema: public; Owner: db_public; Tablespace: 
--

CREATE INDEX name_id ON name USING btree (id);


--
-- Name: name_name; Type: INDEX; Schema: public; Owner: db_public; Tablespace: 
--

CREATE INDEX name_name ON name USING btree (name);


--
-- Name: parent2child_id_child; Type: INDEX; Schema: public; Owner: db_public; Tablespace: 
--

CREATE INDEX parent2child_id_child ON parent2child USING btree (id, child);


--
-- Name: typelist_tab; Type: INDEX; Schema: public; Owner: db_public; Tablespace: 
--

CREATE INDEX typelist_tab ON typelist USING btree (tag);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

