--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: $temporary_chado_schema_name$; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA $temporary_chado_schema_name$;
CREATE SCHEMA $temporary_chado_schema_name$_data;


--
-- Name: SCHEMA $temporary_chado_schema_name$; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA $temporary_chado_schema_name$ IS 'Schema for storing per-experiment chado data';


SET search_path = $temporary_chado_schema_name$_data, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: acquisition; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE acquisition (
    acquisition_id integer NOT NULL,
    assay_id integer NOT NULL,
    protocol_id integer,
    channel_id integer,
    acquisitiondate timestamp without time zone DEFAULT now(),
    name text,
    uri text
);
CREATE TRIGGER acquisition_acquisitiondate_trigger BEFORE INSERT OR UPDATE ON acquisition
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.acquisition_acquisitiondate_trigger_func();


--
-- Name: TABLE acquisition; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE acquisition IS 'This represents the scanning of hybridized material. The output of this process is typically a digital image of an array.';


--
-- Name: acquisition_relationship; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE acquisition_relationship (
    acquisition_relationship_id integer NOT NULL,
    subject_id integer NOT NULL,
    type_id integer NOT NULL,
    object_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER acquisition_relationship_rank_trigger BEFORE INSERT OR UPDATE ON acquisition_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.acquisition_relationship_rank_trigger_func();


--
-- Name: TABLE acquisition_relationship; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE acquisition_relationship IS 'Multiple monochrome images may be merged to form a multi-color image. Red-green images of 2-channel hybridizations are an example of this.';


--
-- Name: acquisitionprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE acquisitionprop (
    acquisitionprop_id integer NOT NULL,
    acquisition_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER acquisitionprop_rank_trigger BEFORE INSERT OR UPDATE ON acquisitionprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.acquisitionprop_rank_trigger_func();


--
-- Name: TABLE acquisitionprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE acquisitionprop IS 'Parameters associated with image acquisition.';


--
-- Name: analysis; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE analysis (
    analysis_id integer NOT NULL,
    name character varying(255),
    description text,
    program character varying(255) NOT NULL,
    programversion character varying(255) NOT NULL,
    algorithm character varying(255),
    sourcename character varying(255),
    sourceversion character varying(255),
    sourceuri text,
    timeexecuted timestamp without time zone DEFAULT now() NOT NULL
);
CREATE TRIGGER analysis_timeexecuted_trigger BEFORE INSERT OR UPDATE ON analysis
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.analysis_timeexecuted_trigger_func();


--
-- Name: TABLE analysis; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE analysis IS 'An analysis is a particular type of a
    computational analysis; it may be a blast of one sequence against
    another, or an all by all blast, or a different kind of analysis
    altogether. It is a single unit of computation.';


--
-- Name: COLUMN analysis.name; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN analysis.name IS 'A way of grouping analyses. This
    should be a handy short identifier that can help people find an
    analysis they want. For instance "tRNAscan", "cDNA", "FlyPep",
    "SwissProt", and it should not be assumed to be unique. For instance, there may be lots of separate analyses done against a cDNA database.';


--
-- Name: COLUMN analysis.program; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN analysis.program IS 'Program name, e.g. blastx, blastp, sim4, genscan.';


--
-- Name: COLUMN analysis.programversion; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN analysis.programversion IS 'Version description, e.g. TBLASTX 2.0MP-WashU [09-Nov-2000].';


--
-- Name: COLUMN analysis.algorithm; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN analysis.algorithm IS 'Algorithm name, e.g. blast.';


--
-- Name: COLUMN analysis.sourcename; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN analysis.sourcename IS 'Source name, e.g. cDNA, SwissProt.';


--
-- Name: COLUMN analysis.sourceuri; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN analysis.sourceuri IS 'This is an optional, permanent URL or URI for the source of the  analysis. The idea is that someone could recreate the analysis directly by going to this URI and fetching the source data (e.g. the blast database, or the training model).';


--
-- Name: analysisfeature; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE analysisfeature (
    analysisfeature_id integer NOT NULL,
    feature_id integer NOT NULL,
    analysis_id integer NOT NULL,
    rawscore double precision,
    normscore double precision,
    significance double precision,
    identity double precision
);


--
-- Name: TABLE analysisfeature; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE analysisfeature IS 'Computational analyses generate features (e.g. Genscan generates transcripts and exons; sim4 alignments generate similarity/match features). analysisfeatures are stored using the feature table from the sequence module. The analysisfeature table is used to decorate these features, with analysis specific attributes. A feature is an analysisfeature if and only if there is a corresponding entry in the analysisfeature table. analysisfeatures will have two or more featureloc entries,
 with rank indicating query/subject';


--
-- Name: COLUMN analysisfeature.rawscore; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN analysisfeature.rawscore IS 'This is the native score generated by the program; for example, the bitscore generated by blast, sim4 or genscan scores. One should not assume that high is necessarily better than low.';


--
-- Name: COLUMN analysisfeature.normscore; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN analysisfeature.normscore IS 'This is the rawscore but
    semi-normalized. Complete normalization to allow comparison of
    features generated by different programs would be nice but too
    difficult. Instead the normalization should strive to enforce the
    following semantics: * normscores are floating point numbers >= 0,
    * high normscores are better than low one. For most programs, it would be sufficient to make the normscore the same as this rawscore, providing these semantics are satisfied.';


--
-- Name: COLUMN analysisfeature.significance; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN analysisfeature.significance IS 'This is some kind of expectation or probability metric, representing the probability that the analysis would appear randomly given the model. As such, any program or person querying this table can assume the following semantics:
   * 0 <= significance <= n, where n is a positive number, theoretically unbounded but unlikely to be more than 10
  * low numbers are better than high numbers.';


--
-- Name: COLUMN analysisfeature.identity; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN analysisfeature.identity IS 'Percent identity between the locations compared.  Note that these 4 metrics do not cover the full range of scores possible; it would be undesirable to list every score possible, as this should be kept extensible. instead, for non-standard scores, use the analysisprop table.';


--
-- Name: analysisprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE analysisprop (
    analysisprop_id integer NOT NULL,
    analysis_id integer NOT NULL,
    type_id integer NOT NULL,
    value text
);


--
-- Name: applied_protocol; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE applied_protocol (
    applied_protocol_id integer NOT NULL,
    protocol_id integer NOT NULL
);


--
-- Name: applied_protocol_data; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE applied_protocol_data (
    applied_protocol_data_id integer NOT NULL,
    applied_protocol_id integer NOT NULL,
    data_id integer NOT NULL,
    direction character(6) NOT NULL,
    CONSTRAINT applied_protocol_data_direction_check CHECK (((direction = 'input'::bpchar) OR (direction = 'output'::bpchar)))
);


--
-- Name: arraydesign; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE arraydesign (
    arraydesign_id integer NOT NULL,
    manufacturer_id integer NOT NULL,
    platformtype_id integer NOT NULL,
    substratetype_id integer,
    protocol_id integer,
    dbxref_id integer,
    name text NOT NULL,
    version text,
    description text,
    array_dimensions text,
    element_dimensions text,
    num_of_elements integer,
    num_array_columns integer,
    num_array_rows integer,
    num_grid_columns integer,
    num_grid_rows integer,
    num_sub_columns integer,
    num_sub_rows integer
);


--
-- Name: TABLE arraydesign; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE arraydesign IS 'General properties about an array.
An array is a template used to generate physical slides, etc.  It
contains layout information, as well as global array properties, such
as material (glass, nylon) and spot dimensions (in rows/columns).';


--
-- Name: arraydesignprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE arraydesignprop (
    arraydesignprop_id integer NOT NULL,
    arraydesign_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER arraydesignprop_rank_trigger BEFORE INSERT OR UPDATE ON arraydesignprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.arraydesignprop_rank_trigger_func();


--
-- Name: TABLE arraydesignprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE arraydesignprop IS 'Extra array design properties that are not accounted for in arraydesign.';


--
-- Name: assay; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE assay (
    assay_id integer NOT NULL,
    arraydesign_id integer NOT NULL,
    protocol_id integer,
    assaydate timestamp without time zone DEFAULT now(),
    arrayidentifier text,
    arraybatchidentifier text,
    operator_id integer NOT NULL,
    dbxref_id integer,
    name text,
    description text
);
CREATE TRIGGER assay_assaydate_trigger BEFORE INSERT OR UPDATE ON assay
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.assay_assaydate_trigger_func();


--
-- Name: TABLE assay; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE assay IS 'An assay consists of a physical instance of
an array, combined with the conditions used to create the array
(protocols, technician information). The assay can be thought of as a hybridization.';


--
-- Name: assay_biomaterial; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE assay_biomaterial (
    assay_biomaterial_id integer NOT NULL,
    assay_id integer NOT NULL,
    biomaterial_id integer NOT NULL,
    channel_id integer,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER assay_biomaterial_rank_trigger BEFORE INSERT OR UPDATE ON assay_biomaterial
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.assay_biomaterial_rank_trigger_func();


--
-- Name: TABLE assay_biomaterial; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE assay_biomaterial IS 'A biomaterial can be hybridized many times (technical replicates), or combined with other biomaterials in a single hybridization (for two-channel arrays).';


--
-- Name: assay_project; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE assay_project (
    assay_project_id integer NOT NULL,
    assay_id integer NOT NULL,
    project_id integer NOT NULL
);


--
-- Name: TABLE assay_project; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE assay_project IS 'Link assays to projects.';


--
-- Name: assayprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE assayprop (
    assayprop_id integer NOT NULL,
    assay_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER assayprop_rank_trigger BEFORE INSERT OR UPDATE ON assayprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.assayprop_rank_trigger_func();


--
-- Name: TABLE assayprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE assayprop IS 'Extra assay properties that are not accounted for in assay.';


--
-- Name: attribute; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE attribute (
    attribute_id integer NOT NULL,
    name character varying(255),
    heading character varying(255) NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    value text,
    type_id integer NOT NULL,
    dbxref_id integer
);
CREATE TRIGGER attribute_rank_trigger BEFORE INSERT OR UPDATE ON attribute
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.attribute_rank_trigger_func();


--
-- Name: attribute_organism; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE attribute_organism (
    attribute_organism_id integer NOT NULL,
    organism_id integer,
    attribute_id integer
);


--
-- Name: biomaterial; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE biomaterial (
    biomaterial_id integer NOT NULL,
    taxon_id integer,
    biosourceprovider_id integer,
    dbxref_id integer,
    name text,
    description text
);


--
-- Name: TABLE biomaterial; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE biomaterial IS 'A biomaterial represents the MAGE concept of BioSource, BioSample, and LabeledExtract. It is essentially some biological material (tissue, cells, serum) that may have been processed. Processed biomaterials should be traceable back to raw biomaterials via the biomaterialrelationship table.';


--
-- Name: biomaterial_dbxref; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE biomaterial_dbxref (
    biomaterial_dbxref_id integer NOT NULL,
    biomaterial_id integer NOT NULL,
    dbxref_id integer NOT NULL
);


--
-- Name: biomaterial_relationship; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE biomaterial_relationship (
    biomaterial_relationship_id integer NOT NULL,
    subject_id integer NOT NULL,
    type_id integer NOT NULL,
    object_id integer NOT NULL
);


--
-- Name: TABLE biomaterial_relationship; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE biomaterial_relationship IS 'Relate biomaterials to one another. This is a way to track a series of treatments or material splits/merges, for instance.';


--
-- Name: biomaterial_treatment; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE biomaterial_treatment (
    biomaterial_treatment_id integer NOT NULL,
    biomaterial_id integer NOT NULL,
    treatment_id integer NOT NULL,
    unittype_id integer,
    value real,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER biomaterial_treatment_rank_trigger BEFORE INSERT OR UPDATE ON biomaterial_treatment
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.biomaterial_treatment_rank_trigger_func();


--
-- Name: TABLE biomaterial_treatment; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE biomaterial_treatment IS 'Link biomaterials to treatments. Treatments have an order of operations (rank), and associated measurements (unittype_id, value).';


--
-- Name: biomaterialprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE biomaterialprop (
    biomaterialprop_id integer NOT NULL,
    biomaterial_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER biomaterialprop_rank_trigger BEFORE INSERT OR UPDATE ON biomaterialprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.biomaterialprop_rank_trigger_func();


--
-- Name: TABLE biomaterialprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE biomaterialprop IS 'Extra biomaterial properties that are not accounted for in biomaterial.';


--
-- Name: channel; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE channel (
    channel_id integer NOT NULL,
    name text NOT NULL,
    definition text NOT NULL
);


--
-- Name: TABLE channel; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE channel IS 'Different array platforms can record signals from one or more channels (cDNA arrays typically use two CCD, but Affymetrix uses only one).';


--
-- Name: cvtermpath; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE cvtermpath (
    cvtermpath_id integer NOT NULL,
    type_id integer,
    subject_id integer NOT NULL,
    object_id integer NOT NULL,
    cv_id integer NOT NULL,
    pathdistance integer
);


--
-- Name: TABLE cvtermpath; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE cvtermpath IS 'The reflexive transitive closure of
the cvterm_relationship relation.';


--
-- Name: COLUMN cvtermpath.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvtermpath.type_id IS 'The relationship type that
this is a closure over. If null, then this is a closure over ALL
relationship types. If non-null, then this references a relationship
cvterm - note that the closure will apply to both this relationship
AND the OBO_REL:is_a (subclass) relationship.';


--
-- Name: COLUMN cvtermpath.cv_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvtermpath.cv_id IS 'Closures will mostly be within
one cv. If the closure of a relationship traverses a cv, then this
refers to the cv of the object_id cvterm.';


--
-- Name: COLUMN cvtermpath.pathdistance; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvtermpath.pathdistance IS 'The number of steps
required to get from the subject cvterm to the object cvterm, counting
from zero (reflexive relationship).';


--
-- Name: common_ancestor_cvterm; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW common_ancestor_cvterm AS
    SELECT p1.subject_id AS cvterm1_id, p2.subject_id AS cvterm2_id, p1.object_id AS ancestor_cvterm_id, p1.pathdistance AS pathdistance1, p2.pathdistance AS pathdistance2, (p1.pathdistance + p2.pathdistance) AS total_pathdistance FROM cvtermpath p1, cvtermpath p2 WHERE (p1.object_id = p2.object_id);


--
-- Name: VIEW common_ancestor_cvterm; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW common_ancestor_cvterm IS 'The common ancestor of any
two terms is the intersection of both terms ancestors. Two terms can
have multiple common ancestors. Use total_pathdistance to get the
least common ancestor';


--
-- Name: common_descendant_cvterm; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW common_descendant_cvterm AS
    SELECT p1.object_id AS cvterm1_id, p2.object_id AS cvterm2_id, p1.subject_id AS ancestor_cvterm_id, p1.pathdistance AS pathdistance1, p2.pathdistance AS pathdistance2, (p1.pathdistance + p2.pathdistance) AS total_pathdistance FROM cvtermpath p1, cvtermpath p2 WHERE (p1.subject_id = p2.subject_id);


--
-- Name: VIEW common_descendant_cvterm; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW common_descendant_cvterm IS 'The common descendant of
any two terms is the intersection of both terms descendants. Two terms
can have multiple common descendants. Use total_pathdistance to get
the least common ancestor';


--
-- Name: contact; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE contact (
    contact_id integer NOT NULL,
    type_id integer,
    name character varying(255) NOT NULL,
    description character varying(255)
);


--
-- Name: TABLE contact; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE contact IS 'Model persons, institutes, groups, organizations, etc.';


--
-- Name: COLUMN contact.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN contact.type_id IS 'What type of contact is this?  E.g. "person", "lab".';


--
-- Name: contact_relationship; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE contact_relationship (
    contact_relationship_id integer NOT NULL,
    type_id integer NOT NULL,
    subject_id integer NOT NULL,
    object_id integer NOT NULL
);


--
-- Name: TABLE contact_relationship; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE contact_relationship IS 'Model relationships between contacts';


--
-- Name: COLUMN contact_relationship.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN contact_relationship.type_id IS 'Relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed.';


--
-- Name: COLUMN contact_relationship.subject_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN contact_relationship.subject_id IS 'The subject of the subj-predicate-obj sentence. In a DAG, this corresponds to the child node.';


--
-- Name: COLUMN contact_relationship.object_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN contact_relationship.object_id IS 'The object of the subj-predicate-obj sentence. In a DAG, this corresponds to the parent node.';


--
-- Name: contactprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE contactprop (
    contactprop_id integer NOT NULL,
    contact_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER contactprop_rank_trigger BEFORE INSERT OR UPDATE ON contactprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.contactprop_rank_trigger_func();


--
-- Name: control; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE control (
    control_id integer NOT NULL,
    type_id integer NOT NULL,
    assay_id integer NOT NULL,
    tableinfo_id integer NOT NULL,
    row_id integer NOT NULL,
    name text,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER control_rank_trigger BEFORE INSERT OR UPDATE ON control
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.control_rank_trigger_func();


--
-- Name: cv; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE cv (
    cv_id integer NOT NULL,
    name character varying(255) NOT NULL,
    definition text
);


--
-- Name: TABLE cv; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE cv IS 'A controlled vocabulary or ontology. A cv is
composed of cvterms (AKA terms, classes, types, universals - relations
and properties are also stored in cvterm) and the relationships
between them.';


--
-- Name: COLUMN cv.name; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cv.name IS 'The name of the ontology. This
corresponds to the obo-format -namespace-. cv names uniquely identify
the cv. In OBO file format, the cv.name is known as the namespace.';


--
-- Name: COLUMN cv.definition; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cv.definition IS 'A text description of the criteria for
membership of this ontology.';


--
-- Name: cvterm; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE cvterm (
    cvterm_id integer NOT NULL,
    cv_id integer NOT NULL,
    name character varying(1024) NOT NULL,
    definition text,
    dbxref_id integer NOT NULL,
    is_obsolete integer DEFAULT 0 NOT NULL,
    is_relationshiptype integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER cvterm_is_obsolete_trigger BEFORE INSERT OR UPDATE ON cvterm
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cvterm_is_obsolete_trigger_func();
CREATE TRIGGER cvterm_is_relationshiptype_trigger BEFORE INSERT OR UPDATE ON cvterm
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cvterm_is_relationshiptype_trigger_func();


--
-- Name: TABLE cvterm; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE cvterm IS 'A term, class, universal or type within an
ontology or controlled vocabulary.  This table is also used for
relations and properties. cvterms constitute nodes in the graph
defined by the collection of cvterms and cvterm_relationships.';


--
-- Name: COLUMN cvterm.cv_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvterm.cv_id IS 'The cv or ontology or namespace to which
this cvterm belongs.';


--
-- Name: COLUMN cvterm.name; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvterm.name IS 'A concise human-readable name or
label for the cvterm. Uniquely identifies a cvterm within a cv.';


--
-- Name: COLUMN cvterm.definition; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvterm.definition IS 'A human-readable text
definition.';


--
-- Name: COLUMN cvterm.dbxref_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvterm.dbxref_id IS 'Primary identifier dbxref - The
unique global OBO identifier for this cvterm.  Note that a cvterm may
have multiple secondary dbxrefs - see also table: cvterm_dbxref.';


--
-- Name: COLUMN cvterm.is_obsolete; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvterm.is_obsolete IS 'Boolean 0=false,1=true; see
GO documentation for details of obsoletion. Note that two terms with
different primary dbxrefs may exist if one is obsolete.';


--
-- Name: COLUMN cvterm.is_relationshiptype; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvterm.is_relationshiptype IS 'Boolean
0=false,1=true relations or relationship types (also known as Typedefs
in OBO format, or as properties or slots) form a cv/ontology in
themselves. We use this flag to indicate whether this cvterm is an
actual term/class/universal or a relation. Relations may be drawn from
the OBO Relations ontology, but are not exclusively drawn from there.';


--
-- Name: cv_cvterm_count; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW cv_cvterm_count AS
    SELECT cv.name, count(*) AS num_terms_excl_obs FROM (cv JOIN cvterm USING (cv_id)) WHERE (cvterm.is_obsolete = 0) GROUP BY cv.name;


--
-- Name: VIEW cv_cvterm_count; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW cv_cvterm_count IS 'per-cv terms counts (excludes obsoletes)';


--
-- Name: cv_cvterm_count_with_obs; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW cv_cvterm_count_with_obs AS
    SELECT cv.name, count(*) AS num_terms_incl_obs FROM (cv JOIN cvterm USING (cv_id)) GROUP BY cv.name;


--
-- Name: VIEW cv_cvterm_count_with_obs; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW cv_cvterm_count_with_obs IS 'per-cv terms counts (includes obsoletes)';


--
-- Name: cvterm_relationship; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE cvterm_relationship (
    cvterm_relationship_id integer NOT NULL,
    type_id integer NOT NULL,
    subject_id integer NOT NULL,
    object_id integer NOT NULL
);


--
-- Name: TABLE cvterm_relationship; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE cvterm_relationship IS 'A relationship linking two
cvterms. Each cvterm_relationship constitutes an edge in the graph
defined by the collection of cvterms and cvterm_relationships. The
meaning of the cvterm_relationship depends on the definition of the
cvterm R refered to by type_id. However, in general the definitions
are such that the statement "all SUBJs REL some OBJ" is true. The
cvterm_relationship statement is about the subject, not the
object. For example "insect wing part_of thorax".';


--
-- Name: COLUMN cvterm_relationship.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvterm_relationship.type_id IS 'The nature of the
relationship between subject and object. Note that relations are also
housed in the cvterm table, typically from the OBO relationship
ontology, although other relationship types are allowed.';


--
-- Name: COLUMN cvterm_relationship.subject_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvterm_relationship.subject_id IS 'The subject of
the subj-predicate-obj sentence. The cvterm_relationship is about the
subject. In a graph, this typically corresponds to the child node.';


--
-- Name: COLUMN cvterm_relationship.object_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvterm_relationship.object_id IS 'The object of the
subj-predicate-obj sentence. The cvterm_relationship refers to the
object. In a graph, this typically corresponds to the parent node.';


--
-- Name: cv_leaf; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW cv_leaf AS
    SELECT cvterm.cv_id, cvterm.cvterm_id FROM cvterm WHERE (NOT (cvterm.cvterm_id IN (SELECT cvterm_relationship.object_id FROM cvterm_relationship)));


--
-- Name: VIEW cv_leaf; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW cv_leaf IS 'the leaves of a cv are the set of terms
which have no children (terms that are not the object of a
relation). All cvs will have at least 1 leaf';


--
-- Name: cv_link_count; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW cv_link_count AS
    SELECT cv.name AS cv_name, relation.name AS relation_name, relation_cv.name AS relation_cv_name, count(*) AS num_links FROM ((((cv JOIN cvterm ON ((cvterm.cv_id = cv.cv_id))) JOIN cvterm_relationship ON ((cvterm.cvterm_id = cvterm_relationship.subject_id))) JOIN cvterm relation ON ((cvterm_relationship.type_id = relation.cvterm_id))) JOIN cv relation_cv ON ((relation.cv_id = relation_cv.cv_id))) GROUP BY cv.name, relation.name, relation_cv.name;


--
-- Name: VIEW cv_link_count; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW cv_link_count IS 'per-cv summary of number of
links (cvterm_relationships) broken down by
relationship_type. num_links is the total # of links of the specified
type in which the subject_id of the link is in the named cv';


--
-- Name: cv_path_count; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW cv_path_count AS
    SELECT cv.name AS cv_name, relation.name AS relation_name, relation_cv.name AS relation_cv_name, count(*) AS num_paths FROM ((((cv JOIN cvterm ON ((cvterm.cv_id = cv.cv_id))) JOIN cvtermpath ON ((cvterm.cvterm_id = cvtermpath.subject_id))) JOIN cvterm relation ON ((cvtermpath.type_id = relation.cvterm_id))) JOIN cv relation_cv ON ((relation.cv_id = relation_cv.cv_id))) GROUP BY cv.name, relation.name, relation_cv.name;


--
-- Name: VIEW cv_path_count; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW cv_path_count IS 'per-cv summary of number of
paths (cvtermpaths) broken down by relationship_type. num_paths is the
total # of paths of the specified type in which the subject_id of the
path is in the named cv. See also: cv_distinct_relations';


--
-- Name: cv_root; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW cv_root AS
    SELECT cvterm.cv_id, cvterm.cvterm_id AS root_cvterm_id FROM cvterm WHERE ((NOT (cvterm.cvterm_id IN (SELECT cvterm_relationship.subject_id FROM cvterm_relationship))) AND (cvterm.is_obsolete = 0));


--
-- Name: VIEW cv_root; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW cv_root IS 'the roots of a cv are the set of terms
which have no parents (terms that are not the subject of a
relation). Most cvs will have a single root, some may have >1. All
will have at least 1';


--
-- Name: cvterm_dbxref; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE cvterm_dbxref (
    cvterm_dbxref_id integer NOT NULL,
    cvterm_id integer NOT NULL,
    dbxref_id integer NOT NULL,
    is_for_definition integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER cvterm_dbxref_is_for_definition_trigger BEFORE INSERT OR UPDATE ON cvterm_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cvterm_dbxref_is_for_definition_trigger_func();


--
-- Name: TABLE cvterm_dbxref; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE cvterm_dbxref IS 'In addition to the primary
identifier (cvterm.dbxref_id) a cvterm can have zero or more secondary
identifiers/dbxrefs, which may refer to records in external
databases. The exact semantics of cvterm_dbxref are not fixed. For
example: the dbxref could be a pubmed ID that is pertinent to the
cvterm, or it could be an equivalent or similar term in another
ontology. For example, GO cvterms are typically linked to InterPro
IDs, even though the nature of the relationship between them is
largely one of statistical association. The dbxref may be have data
records attached in the same database instance, or it could be a
"hanging" dbxref pointing to some external database. NOTE: If the
desired objective is to link two cvterms together, and the nature of
the relation is known and holds for all instances of the subject
cvterm then consider instead using cvterm_relationship together with a
well-defined relation.';


--
-- Name: COLUMN cvterm_dbxref.is_for_definition; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvterm_dbxref.is_for_definition IS 'A
cvterm.definition should be supported by one or more references. If
this column is true, the dbxref is not for a term in an external database -
it is a dbxref for provenance information for the definition.';


--
-- Name: cvtermprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE cvtermprop (
    cvtermprop_id integer NOT NULL,
    cvterm_id integer NOT NULL,
    type_id integer NOT NULL,
    value text DEFAULT ''::text NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER cvtermprop_value_trigger BEFORE INSERT OR UPDATE ON cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cvtermprop_value_trigger_func();
CREATE TRIGGER cvtermprop_rank_trigger BEFORE INSERT OR UPDATE ON cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cvtermprop_rank_trigger_func();


--
-- Name: TABLE cvtermprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE cvtermprop IS 'Additional extensible properties can be attached to a cvterm using this table. Corresponds to -AnnotationProperty- in W3C OWL format.';


--
-- Name: COLUMN cvtermprop.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvtermprop.type_id IS 'The name of the property or slot is a cvterm. The meaning of the property is defined in that cvterm.';


--
-- Name: COLUMN cvtermprop.value; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvtermprop.value IS 'The value of the property, represented as text. Numeric values are converted to their text representation.';


--
-- Name: COLUMN cvtermprop.rank; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvtermprop.rank IS 'Property-Value ordering. Any
cvterm can have multiple values for any particular property type -
these are ordered in a list using rank, counting from zero. For
properties that are single-valued rather than multi-valued, the
default 0 value should be used.';


--
-- Name: cvtermsynonym; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE cvtermsynonym (
    cvtermsynonym_id integer NOT NULL,
    cvterm_id integer NOT NULL,
    synonym character varying(1024) NOT NULL,
    type_id integer
);


--
-- Name: TABLE cvtermsynonym; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE cvtermsynonym IS 'A cvterm actually represents a
distinct class or concept. A concept can be refered to by different
phrases or names. In addition to the primary name (cvterm.name) there
can be a number of alternative aliases or synonyms. For example, "T
cell" as a synonym for "T lymphocyte".';


--
-- Name: COLUMN cvtermsynonym.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN cvtermsynonym.type_id IS 'A synonym can be exact,
narrower, or broader than.';


--
-- Name: data; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE data (
    data_id integer NOT NULL,
    name character varying(255),
    heading character varying(255) NOT NULL,
    value text,
    type_id integer,
    dbxref_id integer
);


--
-- Name: data_attribute; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE data_attribute (
    data_attribute_id integer NOT NULL,
    data_id integer NOT NULL,
    attribute_id integer NOT NULL
);


--
-- Name: data_feature; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE data_feature (
    data_feature_id integer NOT NULL,
    feature_id integer,
    data_id integer
);


--
-- Name: data_organism; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE data_organism (
    data_organism_id integer NOT NULL,
    organism_id integer,
    data_id integer
);


--
-- Name: data_wiggle_data; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE data_wiggle_data (
    data_wiggle_data_id integer NOT NULL,
    wiggle_data_id integer,
    data_id integer
);


--
-- Name: db; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE db (
    db_id integer NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    urlprefix character varying(255),
    url character varying(255)
);


--
-- Name: TABLE db; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE db IS 'A database authority. Typical databases in
bioinformatics are FlyBase, GO, UniProt, NCBI, MGI, etc. The authority
is generally known by this shortened form, which is unique within the
bioinformatics and biomedical realm.  To Do - add support for URIs,
URNs (e.g. LSIDs). We can do this by treating the URL as a URI -
however, some applications may expect this to be resolvable - to be
decided.';


--
-- Name: dbxref; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE dbxref (
    dbxref_id integer NOT NULL,
    db_id integer NOT NULL,
    accession character varying(255) NOT NULL,
    version character varying(255) DEFAULT ''::character varying NOT NULL,
    description text
);
CREATE TRIGGER dbxref_version_trigger BEFORE INSERT OR UPDATE ON dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.dbxref_version_trigger_func();


--
-- Name: TABLE dbxref; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE dbxref IS 'A unique, global, public, stable identifier. Not necessarily an external reference - can reference data items inside the particular chado instance being used. Typically a row in a table can be uniquely identified with a primary identifier (called dbxref_id); a table may also have secondary identifiers (in a linking table <T>_dbxref). A dbxref is generally written as <DB>:<ACCESSION> or as <DB>:<ACCESSION>:<VERSION>.';


--
-- Name: COLUMN dbxref.accession; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN dbxref.accession IS 'The local part of the identifier. Guaranteed by the db authority to be unique for that db.';


--
-- Name: db_dbxref_count; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW db_dbxref_count AS
    SELECT db.name, count(*) AS num_dbxrefs FROM (db JOIN dbxref USING (db_id)) GROUP BY db.name;


--
-- Name: VIEW db_dbxref_count; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW db_dbxref_count IS 'per-db dbxref counts';


--
-- Name: dbxrefprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE dbxrefprop (
    dbxrefprop_id integer NOT NULL,
    dbxref_id integer NOT NULL,
    type_id integer NOT NULL,
    value text DEFAULT ''::text NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER dbxrefprop_value_trigger BEFORE INSERT OR UPDATE ON dbxrefprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.dbxrefprop_value_trigger_func();
CREATE TRIGGER dbxrefprop_rank_trigger BEFORE INSERT OR UPDATE ON dbxrefprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.dbxrefprop_rank_trigger_func();


--
-- Name: TABLE dbxrefprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE dbxrefprop IS 'Metadata about a dbxref. Note that this is not defined in the dbxref module, as it depends on the cvterm table. This table has a structure analagous to cvtermprop.';


--
-- Name: featureloc; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE featureloc (
    featureloc_id integer NOT NULL,
    feature_id integer NOT NULL,
    srcfeature_id integer,
    fmin integer,
    is_fmin_partial boolean DEFAULT false NOT NULL,
    fmax integer,
    is_fmax_partial boolean DEFAULT false NOT NULL,
    strand smallint,
    phase integer,
    residue_info text,
    locgroup integer DEFAULT 0 NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    CONSTRAINT featureloc_c2 CHECK ((fmin <= fmax))
);
CREATE TRIGGER featureloc_rank_trigger BEFORE INSERT OR UPDATE ON featureloc
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featureloc_rank_trigger_func();
CREATE TRIGGER featureloc_locgroup_trigger BEFORE INSERT OR UPDATE ON featureloc
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featureloc_locgroup_trigger_func();
CREATE TRIGGER featureloc_is_fmax_partial_trigger BEFORE INSERT OR UPDATE ON featureloc
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featureloc_is_fmax_partial_trigger_func();
CREATE TRIGGER featureloc_is_fmin_partial_trigger BEFORE INSERT OR UPDATE ON featureloc
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featureloc_is_fmin_partial_trigger_func();


--
-- Name: TABLE featureloc; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE featureloc IS 'The location of a feature relative to
another feature. Important: interbase coordinates are used. This is
vital as it allows us to represent zero-length features e.g. splice
sites, insertion points without an awkward fuzzy system. Features
typically have exactly ONE location, but this need not be the
case. Some features may not be localized (e.g. a gene that has been
characterized genetically but no sequence or molecular information is
available). Note on multiple locations: Each feature can have 0 or
more locations. Multiple locations do NOT indicate non-contiguous
locations (if a feature such as a transcript has a non-contiguous
location, then the subfeatures such as exons should always be
manifested). Instead, multiple featurelocs for a feature designate
alternate locations or grouped locations; for instance, a feature
designating a blast hit or hsp will have two locations, one on the
query feature, one on the subject feature. Features representing
sequence variation could have alternate locations instantiated on a
feature on the mutant strain. The column:rank is used to
differentiate these different locations. Reflexive locations should
never be stored - this is for -proper- (i.e. non-self) locations only; nothing should be located relative to itself.';


--
-- Name: COLUMN featureloc.feature_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureloc.feature_id IS 'The feature that is being located. Any feature can have zero or more featurelocs.';


--
-- Name: COLUMN featureloc.srcfeature_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureloc.srcfeature_id IS 'The source feature which this location is relative to. Every location is relative to another feature (however, this column is nullable, because the srcfeature may not be known). All locations are -proper- that is, nothing should be located relative to itself. No cycles are allowed in the featureloc graph.';


--
-- Name: COLUMN featureloc.fmin; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureloc.fmin IS 'The leftmost/minimal boundary in the linear range represented by the featureloc. Sometimes (e.g. in Bioperl) this is called -start- although this is confusing because it does not necessarily represent the 5-prime coordinate. Important: This is space-based (interbase) coordinates, counting from zero. To convert this to the leftmost position in a base-oriented system (eg GFF, Bioperl), add 1 to fmin.';


--
-- Name: COLUMN featureloc.is_fmin_partial; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureloc.is_fmin_partial IS 'This is typically
false, but may be true if the value for column:fmin is inaccurate or
the leftmost part of the range is unknown/unbounded.';


--
-- Name: COLUMN featureloc.fmax; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureloc.fmax IS 'The rightmost/maximal boundary in the linear range represented by the featureloc. Sometimes (e.g. in bioperl) this is called -end- although this is confusing because it does not necessarily represent the 3-prime coordinate. Important: This is space-based (interbase) coordinates, counting from zero. No conversion is required to go from fmax to the rightmost coordinate in a base-oriented system that counts from 1 (e.g. GFF, Bioperl).';


--
-- Name: COLUMN featureloc.is_fmax_partial; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureloc.is_fmax_partial IS 'This is typically
false, but may be true if the value for column:fmax is inaccurate or
the rightmost part of the range is unknown/unbounded.';


--
-- Name: COLUMN featureloc.strand; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureloc.strand IS 'The orientation/directionality of the
location. Should be 0, -1 or +1.';


--
-- Name: COLUMN featureloc.phase; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureloc.phase IS 'Phase of translation with
respect to srcfeature_id.
Values are 0, 1, 2. It may not be possible to manifest this column for
some features such as exons, because the phase is dependant on the
spliceform (the same exon can appear in multiple spliceforms). This column is mostly useful for predicted exons and CDSs.';


--
-- Name: COLUMN featureloc.residue_info; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureloc.residue_info IS 'Alternative residues,
when these differ from feature.residues. For instance, a SNP feature
located on a wild and mutant protein would have different alternative residues.
for alignment/similarity features, the alternative residues is used to
represent the alignment string (CIGAR format). Note on variation
features; even if we do not want to instantiate a mutant
chromosome/contig feature, we can still represent a SNP etc with 2
locations, one (rank 0) on the genome, the other (rank 1) would have
most fields null, except for alternative residues.';


--
-- Name: COLUMN featureloc.locgroup; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureloc.locgroup IS 'This is used to manifest redundant,
derivable extra locations for a feature. The default locgroup=0 is
used for the DIRECT location of a feature. Important: most Chado users may
never use featurelocs WITH logroup > 0. Transitively derived locations
are indicated with locgroup > 0. For example, the position of an exon on
a BAC and in global chromosome coordinates. This column is used to
differentiate these groupings of locations. The default locgroup 0
is used for the main or primary location, from which the others can be
derived via coordinate transformations. Another example of redundant
locations is storing ORF coordinates relative to both transcript and
genome. Redundant locations open the possibility of the database
getting into inconsistent states; this schema gives us the flexibility
of both warehouse instantiations with redundant locations (easier for
querying) and management instantiations with no redundant
locations. An example of using both locgroup and rank: imagine a
feature indicating a conserved region between the chromosomes of two
different species. We may want to keep redundant locations on both
contigs and chromosomes. We would thus have 4 locations for the single
conserved region feature - two distinct locgroups (contig level and
chromosome level) and two distinct ranks (for the two species).';


--
-- Name: COLUMN featureloc.rank; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureloc.rank IS 'Used when a feature has >1
location, otherwise the default rank 0 is used. Some features (e.g.
blast hits and HSPs) have two locations - one on the query and one on
the subject. Rank is used to differentiate these. Rank=0 is always
used for the query, Rank=1 for the subject. For multiple alignments,
assignment of rank is arbitrary. Rank is also used for
sequence_variant features, such as SNPs. Rank=0 indicates the wildtype
(or baseline) feature, Rank=1 indicates the mutant (or compared) feature.';


--
-- Name: dfeatureloc; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW dfeatureloc AS
    SELECT featureloc.featureloc_id, featureloc.feature_id, featureloc.srcfeature_id, featureloc.fmin AS nbeg, featureloc.is_fmin_partial AS is_nbeg_partial, featureloc.fmax AS nend, featureloc.is_fmax_partial AS is_nend_partial, featureloc.strand, featureloc.phase, featureloc.residue_info, featureloc.locgroup, featureloc.rank FROM featureloc WHERE ((featureloc.strand < 0) OR (featureloc.phase < 0)) UNION SELECT featureloc.featureloc_id, featureloc.feature_id, featureloc.srcfeature_id, featureloc.fmax AS nbeg, featureloc.is_fmax_partial AS is_nbeg_partial, featureloc.fmin AS nend, featureloc.is_fmin_partial AS is_nend_partial, featureloc.strand, featureloc.phase, featureloc.residue_info, featureloc.locgroup, featureloc.rank FROM featureloc WHERE (((featureloc.strand IS NULL) OR (featureloc.strand >= 0)) OR (featureloc.phase >= 0));


--
-- Name: eimage; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE eimage (
    eimage_id integer NOT NULL,
    eimage_data text,
    eimage_type character varying(255) NOT NULL,
    image_uri character varying(255)
);


--
-- Name: COLUMN eimage.eimage_data; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN eimage.eimage_data IS 'We expect images in eimage_data (e.g. JPEGs) to be uuencoded.';


--
-- Name: COLUMN eimage.eimage_type; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN eimage.eimage_type IS 'Describes the type of data in eimage_data.';


--
-- Name: element; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE element (
    element_id integer NOT NULL,
    feature_id integer,
    arraydesign_id integer NOT NULL,
    type_id integer,
    dbxref_id integer
);


--
-- Name: TABLE element; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE element IS 'Represents a feature of the array. This is typically a region of the array coated or bound to DNA.';


--
-- Name: element_relationship; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE element_relationship (
    element_relationship_id integer NOT NULL,
    subject_id integer NOT NULL,
    type_id integer NOT NULL,
    object_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER element_relationship_rank_trigger BEFORE INSERT OR UPDATE ON element_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.element_relationship_rank_trigger_func();


--
-- Name: TABLE element_relationship; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE element_relationship IS 'Sometimes we want to combine measurements from multiple elements to get a composite value. Affymetrix combines many probes to form a probeset measurement, for instance.';


--
-- Name: elementresult; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE elementresult (
    elementresult_id integer NOT NULL,
    element_id integer NOT NULL,
    quantification_id integer NOT NULL,
    signal double precision NOT NULL
);


--
-- Name: TABLE elementresult; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE elementresult IS 'An element on an array produces a measurement when hybridized to a biomaterial (traceable through quantification_id). This is the base data from which tables that actually contain data inherit.';


--
-- Name: elementresult_relationship; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE elementresult_relationship (
    elementresult_relationship_id integer NOT NULL,
    subject_id integer NOT NULL,
    type_id integer NOT NULL,
    object_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER elementresult_relationship_rank_trigger BEFORE INSERT OR UPDATE ON elementresult_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.elementresult_relationship_rank_trigger_func();


--
-- Name: TABLE elementresult_relationship; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE elementresult_relationship IS 'Sometimes we want to combine measurements from multiple elements to get a composite value. Affymetrix combines many probes to form a probeset measurement, for instance.';


--
-- Name: environment; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE environment (
    environment_id integer NOT NULL,
    uniquename text NOT NULL,
    description text
);


--
-- Name: TABLE environment; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE environment IS 'The environmental component of a phenotype description.';


--
-- Name: environment_cvterm; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE environment_cvterm (
    environment_cvterm_id integer NOT NULL,
    environment_id integer NOT NULL,
    cvterm_id integer NOT NULL
);


--
-- Name: experiment; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE experiment (
    experiment_id integer NOT NULL,
    uniquename character varying(255) NOT NULL,
    description text
);


--
-- Name: experiment_applied_protocol; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE experiment_applied_protocol (
    experiment_applied_protocol_id integer NOT NULL,
    experiment_id integer NOT NULL,
    first_applied_protocol_id integer NOT NULL
);


--
-- Name: experiment_prop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE experiment_prop (
    experiment_prop_id integer NOT NULL,
    experiment_id integer NOT NULL,
    name character varying(255) NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    value text,
    type_id integer NOT NULL,
    dbxref_id integer
);
CREATE TRIGGER experiment_prop_rank_trigger BEFORE INSERT OR UPDATE ON experiment_prop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.experiment_prop_rank_trigger_func();


--
-- Name: expression; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE expression (
    expression_id integer NOT NULL,
    uniquename text NOT NULL,
    md5checksum character(32),
    description text
);


--
-- Name: TABLE expression; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE expression IS 'The expression table is essentially a bridge table.';


--
-- Name: expression_cvterm; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE expression_cvterm (
    expression_cvterm_id integer NOT NULL,
    expression_id integer NOT NULL,
    cvterm_id integer NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    cvterm_type_id integer NOT NULL
);
CREATE TRIGGER expression_cvterm_rank_trigger BEFORE INSERT OR UPDATE ON expression_cvterm
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.expression_cvterm_rank_trigger_func();


--
-- Name: expression_cvtermprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE expression_cvtermprop (
    expression_cvtermprop_id integer NOT NULL,
    expression_cvterm_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER expression_cvtermprop_rank_trigger BEFORE INSERT OR UPDATE ON expression_cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.expression_cvtermprop_rank_trigger_func();


--
-- Name: TABLE expression_cvtermprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE expression_cvtermprop IS 'Extensible properties for
expression to cvterm associations. Examples: qualifiers.';


--
-- Name: COLUMN expression_cvtermprop.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN expression_cvtermprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. For example, cvterms may come from the FlyBase miscellaneous cv.';


--
-- Name: COLUMN expression_cvtermprop.value; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN expression_cvtermprop.value IS 'The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.';


--
-- Name: COLUMN expression_cvtermprop.rank; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN expression_cvtermprop.rank IS 'Property-Value
ordering. Any expression_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used.';


--
-- Name: expression_image; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE expression_image (
    expression_image_id integer NOT NULL,
    expression_id integer NOT NULL,
    eimage_id integer NOT NULL
);


--
-- Name: expression_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE expression_pub (
    expression_pub_id integer NOT NULL,
    expression_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: expressionprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE expressionprop (
    expressionprop_id integer NOT NULL,
    expression_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER expressionprop_rank_trigger BEFORE INSERT OR UPDATE ON expressionprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.expressionprop_rank_trigger_func();


--
-- Name: feature; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature (
    feature_id integer NOT NULL,
    dbxref_id integer,
    organism_id integer NOT NULL,
    name character varying(255),
    uniquename text NOT NULL,
    residues text,
    seqlen integer,
    md5checksum character(32),
    type_id integer NOT NULL,
    is_analysis boolean DEFAULT false NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL,
    timeaccessioned timestamp without time zone DEFAULT now() NOT NULL,
    timelastmodified timestamp without time zone DEFAULT now() NOT NULL
);
CREATE TRIGGER feature_timeaccessioned_trigger BEFORE INSERT OR UPDATE ON feature
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_timeaccessioned_trigger_func();
CREATE TRIGGER feature_is_obsolete_trigger BEFORE INSERT OR UPDATE ON feature
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_is_obsolete_trigger_func();
CREATE TRIGGER feature_is_analysis_trigger BEFORE INSERT OR UPDATE ON feature
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_is_analysis_trigger_func();
CREATE TRIGGER feature_timelastmodified_trigger BEFORE INSERT OR UPDATE ON feature
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_timelastmodified_trigger_func();


--
-- Name: TABLE feature; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature IS 'A feature is a biological sequence or a
section of a biological sequence, or a collection of such
sections. Examples include genes, exons, transcripts, regulatory
regions, polypeptides, protein domains, chromosome sequences, sequence
variations, cross-genome match regions such as hits and HSPs and so
on; see the Sequence Ontology for more.';


--
-- Name: COLUMN feature.dbxref_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.dbxref_id IS 'An optional primary public stable
identifier for this feature. Secondary identifiers and external
dbxrefs go in the table feature_dbxref.';


--
-- Name: COLUMN feature.organism_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.organism_id IS 'The organism to which this feature
belongs. This column is mandatory.';


--
-- Name: COLUMN feature.name; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.name IS 'The optional human-readable common name for
a feature, for display purposes.';


--
-- Name: COLUMN feature.uniquename; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.uniquename IS 'The unique name for a feature; may
not be necessarily be particularly human-readable, although this is
preferred. This name must be unique for this type of feature within
this organism.';


--
-- Name: COLUMN feature.residues; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.residues IS 'A sequence of alphabetic characters
representing biological residues (nucleic acids, amino acids). This
column does not need to be manifested for all features; it is optional
for features such as exons where the residues can be derived from the
featureloc. It is recommended that the value for this column be
manifested for features which may may non-contiguous sublocations (e.g.
transcripts), since derivation at query time is non-trivial. For
expressed sequence, the DNA sequence should be used rather than the
RNA sequence.';


--
-- Name: COLUMN feature.seqlen; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.seqlen IS 'The length of the residue feature. See
column:residues. This column is partially redundant with the residues
column, and also with featureloc. This column is required because the
location may be unknown and the residue sequence may not be
manifested, yet it may be desirable to store and query the length of
the feature. The seqlen should always be manifested where the length
of the sequence is known.';


--
-- Name: COLUMN feature.md5checksum; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.md5checksum IS 'The 32-character checksum of the sequence,
calculated using the MD5 algorithm. This is practically guaranteed to
be unique for any feature. This column thus acts as a unique
identifier on the mathematical sequence.';


--
-- Name: COLUMN feature.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.type_id IS 'A required reference to a table:cvterm
giving the feature type. This will typically be a Sequence Ontology
identifier. This column is thus used to subclass the feature table.';


--
-- Name: COLUMN feature.is_analysis; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.is_analysis IS 'Boolean indicating whether this
feature is annotated or the result of an automated analysis. Analysis
results also use the companalysis module. Note that the dividing line
between analysis and annotation may be fuzzy, this should be determined on
a per-project basis in a consistent manner. One requirement is that
there should only be one non-analysis version of each wild-type gene
feature in a genome, whereas the same gene feature can be predicted
multiple times in different analyses.';


--
-- Name: COLUMN feature.is_obsolete; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.is_obsolete IS 'Boolean indicating whether this
feature has been obsoleted. Some chado instances may choose to simply
remove the feature altogether, others may choose to keep an obsolete
row in the table.';


--
-- Name: COLUMN feature.timeaccessioned; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.timeaccessioned IS 'For handling object
accession or modification timestamps (as opposed to database auditing data,
handled elsewhere). The expectation is that these fields would be
available to software interacting with chado.';


--
-- Name: COLUMN feature.timelastmodified; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature.timelastmodified IS 'For handling object
accession or modification timestamps (as opposed to database auditing data,
handled elsewhere). The expectation is that these fields would be
available to software interacting with chado.';


--
-- Name: f_type; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW f_type AS
    SELECT f.feature_id, f.name, f.dbxref_id, c.name AS type, f.residues, f.seqlen, f.md5checksum, f.type_id, f.timeaccessioned, f.timelastmodified FROM feature f, cvterm c WHERE (f.type_id = c.cvterm_id);


--
-- Name: f_loc; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW f_loc AS
    SELECT f.feature_id, f.name, f.dbxref_id, fl.nbeg, fl.nend, fl.strand FROM dfeatureloc fl, f_type f WHERE (f.feature_id = fl.feature_id);


--
-- Name: feature_contains; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW feature_contains AS
    SELECT x.feature_id AS subject_id, y.feature_id AS object_id FROM featureloc x, featureloc y WHERE ((x.srcfeature_id = y.srcfeature_id) AND ((y.fmin >= x.fmin) AND (y.fmin <= x.fmax)));


--
-- Name: VIEW feature_contains; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW feature_contains IS 'subject intervals contains (or is
same as) object interval. transitive,reflexive';


--
-- Name: feature_cvterm; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_cvterm (
    feature_cvterm_id integer NOT NULL,
    feature_id integer NOT NULL,
    cvterm_id integer NOT NULL,
    pub_id integer NOT NULL,
    is_not boolean DEFAULT false NOT NULL
);
CREATE TRIGGER feature_cvterm_is_not_trigger BEFORE INSERT OR UPDATE ON feature_cvterm
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_cvterm_is_not_trigger_func();


--
-- Name: TABLE feature_cvterm; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_cvterm IS 'Associate a term from a cv with a feature, for example, GO annotation.';


--
-- Name: COLUMN feature_cvterm.pub_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_cvterm.pub_id IS 'Provenance for the annotation. Each annotation should have a single primary publication (which may be of the appropriate type for computational analyses) where more details can be found. Additional provenance dbxrefs can be attached using feature_cvterm_dbxref.';


--
-- Name: COLUMN feature_cvterm.is_not; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_cvterm.is_not IS 'If this is set to true, then this annotation is interpreted as a NEGATIVE annotation - i.e. the feature does NOT have the specified function, process, component, part, etc. See GO docs for more details.';


--
-- Name: feature_cvterm_dbxref; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_cvterm_dbxref (
    feature_cvterm_dbxref_id integer NOT NULL,
    feature_cvterm_id integer NOT NULL,
    dbxref_id integer NOT NULL
);


--
-- Name: TABLE feature_cvterm_dbxref; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_cvterm_dbxref IS 'Additional dbxrefs for an association. Rows in the feature_cvterm table may be backed up by dbxrefs. For example, a feature_cvterm association that was inferred via a protein-protein interaction may be backed by by refering to the dbxref for the alternate protein. Corresponds to the WITH column in a GO gene association file (but can also be used for other analagous associations). See http://www.geneontology.org/doc/GO.annotation.shtml#file for more details.';


--
-- Name: feature_cvterm_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_cvterm_pub (
    feature_cvterm_pub_id integer NOT NULL,
    feature_cvterm_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE feature_cvterm_pub; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_cvterm_pub IS 'Secondary pubs for an
association. Each feature_cvterm association is supported by a single
primary publication. Additional secondary pubs can be added using this
linking table (in a GO gene association file, these corresponding to
any IDs after the pipe symbol in the publications column.';


--
-- Name: feature_cvtermprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_cvtermprop (
    feature_cvtermprop_id integer NOT NULL,
    feature_cvterm_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER feature_cvtermprop_rank_trigger BEFORE INSERT OR UPDATE ON feature_cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_cvtermprop_rank_trigger_func();


--
-- Name: TABLE feature_cvtermprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_cvtermprop IS 'Extensible properties for
feature to cvterm associations. Examples: GO evidence codes;
qualifiers; metadata such as the date on which the entry was curated
and the source of the association. See the featureprop table for
meanings of type_id, value and rank.';


--
-- Name: COLUMN feature_cvtermprop.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_cvtermprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. cvterms may come from the OBO evidence code cv.';


--
-- Name: COLUMN feature_cvtermprop.value; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_cvtermprop.value IS 'The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.';


--
-- Name: COLUMN feature_cvtermprop.rank; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_cvtermprop.rank IS 'Property-Value
ordering. Any feature_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used.';


--
-- Name: feature_dbxref; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_dbxref (
    feature_dbxref_id integer NOT NULL,
    feature_id integer NOT NULL,
    dbxref_id integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL
);
CREATE TRIGGER feature_dbxref_is_current_trigger BEFORE INSERT OR UPDATE ON feature_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_dbxref_is_current_trigger_func();


--
-- Name: TABLE feature_dbxref; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_dbxref IS 'Links a feature to dbxrefs. This is for secondary identifiers; primary identifiers should use feature.dbxref_id.';


--
-- Name: COLUMN feature_dbxref.is_current; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_dbxref.is_current IS 'The is_current boolean indicates whether the linked dbxref is the  current -official- dbxref for the linked feature.';


--
-- Name: feature_difference; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW feature_difference AS
    SELECT x.feature_id AS subject_id, y.feature_id AS object_id, x.strand AS srcfeature_id, x.srcfeature_id AS fmin, x.fmin AS fmax, y.fmin AS strand FROM featureloc x, featureloc y WHERE ((x.srcfeature_id = y.srcfeature_id) AND ((x.fmin < y.fmin) AND (x.fmax >= y.fmax))) UNION SELECT x.feature_id AS subject_id, y.feature_id AS object_id, x.strand AS srcfeature_id, x.srcfeature_id AS fmin, y.fmax, x.fmax AS strand FROM featureloc x, featureloc y WHERE ((x.srcfeature_id = y.srcfeature_id) AND ((x.fmax > y.fmax) AND (x.fmin <= y.fmin)));


--
-- Name: VIEW feature_difference; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW feature_difference IS 'size of gap between two features. must be abutting or disjoint';


--
-- Name: feature_disjoint; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW feature_disjoint AS
    SELECT x.feature_id AS subject_id, y.feature_id AS object_id FROM featureloc x, featureloc y WHERE ((x.srcfeature_id = y.srcfeature_id) AND ((x.fmax < y.fmin) AND (x.fmin > y.fmax)));


--
-- Name: VIEW feature_disjoint; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW feature_disjoint IS 'featurelocs do not meet. symmetric';


--
-- Name: feature_distance; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW feature_distance AS
    SELECT x.feature_id AS subject_id, y.feature_id AS object_id, x.srcfeature_id, x.strand AS subject_strand, y.strand AS object_strand, CASE WHEN (x.fmax <= y.fmin) THEN (x.fmax - y.fmin) ELSE (y.fmax - x.fmin) END AS distance FROM featureloc x, featureloc y WHERE ((x.srcfeature_id = y.srcfeature_id) AND ((x.fmax <= y.fmin) OR (x.fmin >= y.fmax)));


--
-- Name: feature_expression; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_expression (
    feature_expression_id integer NOT NULL,
    expression_id integer NOT NULL,
    feature_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: feature_expressionprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_expressionprop (
    feature_expressionprop_id integer NOT NULL,
    feature_expression_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER feature_expressionprop_rank_trigger BEFORE INSERT OR UPDATE ON feature_expressionprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_expressionprop_rank_trigger_func();


--
-- Name: TABLE feature_expressionprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_expressionprop IS 'Extensible properties for
feature_expression (comments, for example). Modeled on feature_cvtermprop.';


--
-- Name: feature_genotype; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_genotype (
    feature_genotype_id integer NOT NULL,
    feature_id integer NOT NULL,
    genotype_id integer NOT NULL,
    chromosome_id integer,
    rank integer NOT NULL,
    cgroup integer NOT NULL,
    cvterm_id integer NOT NULL
);


--
-- Name: COLUMN feature_genotype.chromosome_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_genotype.chromosome_id IS 'A feature of SO type "chromosome".';


--
-- Name: COLUMN feature_genotype.rank; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_genotype.rank IS 'rank can be used for
n-ploid organisms or to preserve order.';


--
-- Name: COLUMN feature_genotype.cgroup; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_genotype.cgroup IS 'Spatially distinguishable
group. group can be used for distinguishing the chromosomal groups,
for example (RNAi products and so on can be treated as different
groups, as they do not fall on a particular chromosome).';


--
-- Name: feature_intersection; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW feature_intersection AS
    SELECT x.feature_id AS subject_id, y.feature_id AS object_id, x.srcfeature_id, x.strand AS subject_strand, y.strand AS object_strand, CASE WHEN (x.fmin < y.fmin) THEN y.fmin ELSE x.fmin END AS fmin, CASE WHEN (x.fmax > y.fmax) THEN y.fmax ELSE x.fmax END AS fmax FROM featureloc x, featureloc y WHERE ((x.srcfeature_id = y.srcfeature_id) AND ((x.fmax >= y.fmin) AND (x.fmin <= y.fmax)));


--
-- Name: VIEW feature_intersection; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW feature_intersection IS 'set-intersection on interval defined by featureloc. featurelocs must meet';


--
-- Name: feature_meets; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW feature_meets AS
    SELECT x.feature_id AS subject_id, y.feature_id AS object_id FROM featureloc x, featureloc y WHERE ((x.srcfeature_id = y.srcfeature_id) AND ((x.fmax >= y.fmin) AND (x.fmin <= y.fmax)));


--
-- Name: VIEW feature_meets; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW feature_meets IS 'intervals have at least one
interbase point in common (ie overlap OR abut). symmetric,reflexive';


--
-- Name: feature_meets_on_same_strand; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW feature_meets_on_same_strand AS
    SELECT x.feature_id AS subject_id, y.feature_id AS object_id FROM featureloc x, featureloc y WHERE (((x.srcfeature_id = y.srcfeature_id) AND (x.strand = y.strand)) AND ((x.fmax >= y.fmin) AND (x.fmin <= y.fmax)));


--
-- Name: VIEW feature_meets_on_same_strand; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW feature_meets_on_same_strand IS 'as feature_meets, but
featurelocs must be on the same strand. symmetric,reflexive';


--
-- Name: feature_phenotype; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_phenotype (
    feature_phenotype_id integer NOT NULL,
    feature_id integer NOT NULL,
    phenotype_id integer NOT NULL
);


--
-- Name: feature_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_pub (
    feature_pub_id integer NOT NULL,
    feature_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE feature_pub; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_pub IS 'Provenance. Linking table between features and publications that mention them.';


--
-- Name: feature_pubprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_pubprop (
    feature_pubprop_id integer NOT NULL,
    feature_pub_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER feature_pubprop_rank_trigger BEFORE INSERT OR UPDATE ON feature_pubprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_pubprop_rank_trigger_func();


--
-- Name: TABLE feature_pubprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_pubprop IS 'Property or attribute of a feature_pub link.';


--
-- Name: feature_relationship; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_relationship (
    feature_relationship_id integer NOT NULL,
    subject_id integer NOT NULL,
    object_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER feature_relationship_rank_trigger BEFORE INSERT OR UPDATE ON feature_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_relationship_rank_trigger_func();


--
-- Name: TABLE feature_relationship; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_relationship IS 'Features can be arranged in
graphs, e.g. "exon part_of transcript part_of gene"; If type is
thought of as a verb, the each arc or edge makes a statement
[Subject Verb Object]. The object can also be thought of as parent
(containing feature), and subject as child (contained feature or
subfeature). We include the relationship rank/order, because even
though most of the time we can order things implicitly by sequence
coordinates, we can not always do this - e.g. transpliced genes. It is also
useful for quickly getting implicit introns.';


--
-- Name: COLUMN feature_relationship.subject_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_relationship.subject_id IS 'The subject of the subj-predicate-obj sentence. This is typically the subfeature.';


--
-- Name: COLUMN feature_relationship.object_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_relationship.object_id IS 'The object of the subj-predicate-obj sentence. This is typically the container feature.';


--
-- Name: COLUMN feature_relationship.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_relationship.type_id IS 'Relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed. The most common relationship type is OBO_REL:part_of. Valid relationship types are constrained by the Sequence Ontology.';


--
-- Name: COLUMN feature_relationship.value; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_relationship.value IS 'Additional notes or comments.';


--
-- Name: COLUMN feature_relationship.rank; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_relationship.rank IS 'The ordering of subject features with respect to the object feature may be important (for example, exon ordering on a transcript - not always derivable if you take trans spliced genes into consideration). Rank is used to order these; starts from zero.';


--
-- Name: feature_relationship_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_relationship_pub (
    feature_relationship_pub_id integer NOT NULL,
    feature_relationship_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE feature_relationship_pub; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_relationship_pub IS 'Provenance. Attach optional evidence to a feature_relationship in the form of a publication.';


--
-- Name: feature_relationshipprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_relationshipprop (
    feature_relationshipprop_id integer NOT NULL,
    feature_relationship_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER feature_relationshipprop_rank_trigger BEFORE INSERT OR UPDATE ON feature_relationshipprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_relationshipprop_rank_trigger_func();


--
-- Name: TABLE feature_relationshipprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_relationshipprop IS 'Extensible properties
for feature_relationships. Analagous structure to featureprop. This
table is largely optional and not used with a high frequency. Typical
scenarios may be if one wishes to attach additional data to a
feature_relationship - for example to say that the
feature_relationship is only true in certain contexts.';


--
-- Name: COLUMN feature_relationshipprop.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_relationshipprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. Currently there is no standard ontology for
feature_relationship property types.';


--
-- Name: COLUMN feature_relationshipprop.value; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_relationshipprop.value IS 'The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.';


--
-- Name: COLUMN feature_relationshipprop.rank; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_relationshipprop.rank IS 'Property-Value
ordering. Any feature_relationship can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used.';


--
-- Name: feature_relationshipprop_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_relationshipprop_pub (
    feature_relationshipprop_pub_id integer NOT NULL,
    feature_relationshipprop_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE feature_relationshipprop_pub; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_relationshipprop_pub IS 'Provenance for feature_relationshipprop.';


--
-- Name: feature_synonym; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE feature_synonym (
    feature_synonym_id integer NOT NULL,
    synonym_id integer NOT NULL,
    feature_id integer NOT NULL,
    pub_id integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    is_internal boolean DEFAULT false NOT NULL
);
CREATE TRIGGER feature_synonym_is_current_trigger BEFORE INSERT OR UPDATE ON feature_synonym
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_synonym_is_current_trigger_func();
CREATE TRIGGER feature_synonym_is_internal_trigger BEFORE INSERT OR UPDATE ON feature_synonym
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_synonym_is_internal_trigger_func();


--
-- Name: TABLE feature_synonym; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE feature_synonym IS 'Linking table between feature and synonym.';


--
-- Name: COLUMN feature_synonym.pub_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_synonym.pub_id IS 'The pub_id link is for relating the usage of a given synonym to the publication in which it was used.';


--
-- Name: COLUMN feature_synonym.is_current; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_synonym.is_current IS 'The is_current boolean indicates whether the linked synonym is the  current -official- symbol for the linked feature.';


--
-- Name: COLUMN feature_synonym.is_internal; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN feature_synonym.is_internal IS 'Typically a synonym exists so that somebody querying the db with an obsolete name can find the object theyre looking for (under its current name.  If the synonym has been used publicly and deliberately (e.g. in a paper), it may also be listed in reports as a synonym. If the synonym was not used deliberately (e.g. there was a typo which went public), then the is_internal boolean may be set to -true- so that it is known that the synonym is -internal- and should be queryable but should not be listed in reports as a valid synonym.';


--
-- Name: feature_union; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW feature_union AS
    SELECT x.feature_id AS subject_id, y.feature_id AS object_id, x.srcfeature_id, x.strand AS subject_strand, y.strand AS object_strand, CASE WHEN (x.fmin < y.fmin) THEN x.fmin ELSE y.fmin END AS fmin, CASE WHEN (x.fmax > y.fmax) THEN x.fmax ELSE y.fmax END AS fmax FROM featureloc x, featureloc y WHERE ((x.srcfeature_id = y.srcfeature_id) AND ((x.fmax >= y.fmin) AND (x.fmin <= y.fmax)));


--
-- Name: VIEW feature_union; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW feature_union IS 'set-union on interval defined by featureloc. featurelocs must meet';


--
-- Name: featureloc_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE featureloc_pub (
    featureloc_pub_id integer NOT NULL,
    featureloc_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE featureloc_pub; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE featureloc_pub IS 'Provenance of featureloc. Linking table between featurelocs and publications that mention them.';


--
-- Name: featuremap; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE featuremap (
    featuremap_id integer NOT NULL,
    name character varying(255),
    description text,
    unittype_id integer
);


--
-- Name: featuremap_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE featuremap_pub (
    featuremap_pub_id integer NOT NULL,
    featuremap_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: featurepos; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE featurepos (
    featurepos_id integer NOT NULL,
    featuremap_id integer NOT NULL,
    feature_id integer NOT NULL,
    map_feature_id integer NOT NULL,
    mappos double precision NOT NULL
);


--
-- Name: COLUMN featurepos.map_feature_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featurepos.map_feature_id IS 'map_feature_id
links to the feature (map) upon which the feature is being localized.';


--
-- Name: featureprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE featureprop (
    featureprop_id integer NOT NULL,
    feature_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER featureprop_rank_trigger BEFORE INSERT OR UPDATE ON featureprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featureprop_rank_trigger_func();


--
-- Name: TABLE featureprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE featureprop IS 'A feature can have any number of slot-value property tags attached to it. This is an alternative to hardcoding a list of columns in the relational schema, and is completely extensible.';


--
-- Name: COLUMN featureprop.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureprop.type_id IS 'The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. Certain property types will only apply to certain feature
types (e.g. the anticodon property will only apply to tRNA features) ;
the types here come from the sequence feature property ontology.';


--
-- Name: COLUMN featureprop.value; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureprop.value IS 'The value of the property, represented as text. Numeric values are converted to their text representation. This is less efficient than using native database types, but is easier to query.';


--
-- Name: COLUMN featureprop.rank; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featureprop.rank IS 'Property-Value ordering. Any
feature can have multiple values for any particular property type -
these are ordered in a list using rank, counting from zero. For
properties that are single-valued rather than multi-valued, the
default 0 value should be used';


--
-- Name: featureprop_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE featureprop_pub (
    featureprop_pub_id integer NOT NULL,
    featureprop_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE featureprop_pub; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE featureprop_pub IS 'Provenance. Any featureprop assignment can optionally be supported by a publication.';


--
-- Name: featurerange; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE featurerange (
    featurerange_id integer NOT NULL,
    featuremap_id integer NOT NULL,
    feature_id integer NOT NULL,
    leftstartf_id integer NOT NULL,
    leftendf_id integer,
    rightstartf_id integer,
    rightendf_id integer NOT NULL,
    rangestr character varying(255)
);


--
-- Name: TABLE featurerange; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE featurerange IS 'In cases where the start and end of a mapped feature is a range, leftendf and rightstartf are populated. leftstartf_id, leftendf_id, rightstartf_id, rightendf_id are the ids of features with respect to which the feature is being mapped. These may be cytological bands.';


--
-- Name: COLUMN featurerange.featuremap_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN featurerange.featuremap_id IS 'featuremap_id is the id of the feature being mapped.';


--
-- Name: featureset_meets; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW featureset_meets AS
    SELECT x.object_id AS subject_id, y.object_id FROM ((feature_meets r JOIN feature_relationship x ON ((r.subject_id = x.subject_id))) JOIN feature_relationship y ON ((r.object_id = y.subject_id)));


--
-- Name: fnr_type; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW fnr_type AS
    SELECT f.feature_id, f.name, f.dbxref_id, c.name AS type, f.residues, f.seqlen, f.md5checksum, f.type_id, f.timeaccessioned, f.timelastmodified FROM (feature f LEFT JOIN analysisfeature af ON ((f.feature_id = af.feature_id))), cvterm c WHERE ((f.type_id = c.cvterm_id) AND (af.feature_id IS NULL));


--
-- Name: fp_key; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW fp_key AS
    SELECT fp.feature_id, c.name AS pkey, fp.value FROM featureprop fp, cvterm c WHERE (fp.featureprop_id = c.cvterm_id);


--
-- Name: genotype; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE genotype (
    genotype_id integer NOT NULL,
    name text,
    uniquename text NOT NULL,
    description character varying(255)
);


--
-- Name: TABLE genotype; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE genotype IS 'Genetic context. A genotype is defined by a collection of features, mutations, balancers, deficiencies, haplotype blocks, or engineered constructs.';


--
-- Name: COLUMN genotype.name; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN genotype.name IS 'Optional alternative name for a genotype, 
for display purposes.';


--
-- Name: COLUMN genotype.uniquename; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN genotype.uniquename IS 'The unique name for a genotype; 
typically derived from the features making up the genotype.';


--
-- Name: pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE pub (
    pub_id integer NOT NULL,
    title text,
    volumetitle text,
    volume character varying(255),
    series_name character varying(255),
    issue character varying(255),
    pyear character varying(255),
    pages character varying(255),
    miniref character varying(255),
    uniquename text NOT NULL,
    type_id integer NOT NULL,
    is_obsolete boolean DEFAULT false,
    publisher character varying(255),
    pubplace character varying(255)
);
CREATE TRIGGER pub_is_obsolete_trigger BEFORE INSERT OR UPDATE ON pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.pub_is_obsolete_trigger_func();


--
-- Name: TABLE pub; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE pub IS 'A documented provenance artefact - publications,
documents, personal communication.';


--
-- Name: COLUMN pub.title; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN pub.title IS 'Descriptive general heading.';


--
-- Name: COLUMN pub.volumetitle; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN pub.volumetitle IS 'Title of part if one of a series.';


--
-- Name: COLUMN pub.series_name; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN pub.series_name IS 'Full name of (journal) series.';


--
-- Name: COLUMN pub.pages; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN pub.pages IS 'Page number range[s], e.g. 457--459, viii + 664pp, lv--lvii.';


--
-- Name: COLUMN pub.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN pub.type_id IS 'The type of the publication (book, journal, poem, graffiti, etc). Uses pub cv.';


--
-- Name: synonym; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE synonym (
    synonym_id integer NOT NULL,
    name character varying(255) NOT NULL,
    type_id integer NOT NULL,
    synonym_sgml character varying(255) NOT NULL
);


--
-- Name: TABLE synonym; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE synonym IS 'A synonym for a feature. One feature can have multiple synonyms, and the same synonym can apply to multiple features.';


--
-- Name: COLUMN synonym.name; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN synonym.name IS 'The synonym itself. Should be human-readable machine-searchable ascii text.';


--
-- Name: COLUMN synonym.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN synonym.type_id IS 'Types would be symbol and fullname for now.';


--
-- Name: COLUMN synonym.synonym_sgml; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN synonym.synonym_sgml IS 'The fully specified synonym, with any non-ascii characters encoded in SGML.';


--
-- Name: gff3atts; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW gff3atts AS
    (((((((((SELECT fs.feature_id, 'Ontology_term' AS type, CASE WHEN ((db.name)::text ~~ '%Gene Ontology%'::text) THEN (('GO:'::text || (dbx.accession)::text))::character varying WHEN ((db.name)::text ~~ 'Sequence Ontology%'::text) THEN (('SO:'::text || (dbx.accession)::text))::character varying ELSE ((((db.name)::text || ':'::text) || (dbx.accession)::text))::character varying END AS attribute FROM cvterm s, dbxref dbx, feature_cvterm fs, db WHERE (((fs.cvterm_id = s.cvterm_id) AND (s.dbxref_id = dbx.dbxref_id)) AND (db.db_id = dbx.db_id)) UNION ALL SELECT fs.feature_id, 'Dbxref' AS type, (((d.name)::text || ':'::text) || (s.accession)::text) AS attribute FROM dbxref s, feature_dbxref fs, db d WHERE (((fs.dbxref_id = s.dbxref_id) AND (s.db_id = d.db_id)) AND ((d.name)::text <> 'GFF_source'::text))) UNION ALL SELECT f.feature_id, 'Alias' AS type, s.name AS attribute FROM synonym s, feature_synonym fs, feature f WHERE ((((fs.synonym_id = s.synonym_id) AND (f.feature_id = fs.feature_id)) AND ((f.name)::text <> (s.name)::text)) AND (f.uniquename <> (s.name)::text))) UNION ALL SELECT fp.feature_id, cv.name AS type, fp.value AS attribute FROM featureprop fp, cvterm cv WHERE (fp.type_id = cv.cvterm_id)) UNION ALL SELECT fs.feature_id, 'pub' AS type, (((s.series_name)::text || ':'::text) || s.title) AS attribute FROM pub s, feature_pub fs WHERE (fs.pub_id = s.pub_id)) UNION ALL SELECT fr.subject_id AS feature_id, 'Parent' AS type, parent.uniquename AS attribute FROM feature_relationship fr, feature parent WHERE ((fr.object_id = parent.feature_id) AND (fr.type_id = (SELECT cvterm.cvterm_id FROM cvterm WHERE ((cvterm.name)::text = 'part_of'::text))))) UNION ALL SELECT fr.subject_id AS feature_id, 'Derived_from' AS type, parent.uniquename AS attribute FROM feature_relationship fr, feature parent WHERE ((fr.object_id = parent.feature_id) AND (fr.type_id = (SELECT cvterm.cvterm_id FROM cvterm WHERE ((cvterm.name)::text = 'derives_from'::text))))) UNION ALL SELECT fl.feature_id, 'Target' AS type, (((((((target.name)::text || ' '::text) || ((fl.fmin + 1))::text) || ' '::text) || (fl.fmax)::text) || ' '::text) || (fl.strand)::text) AS attribute FROM featureloc fl, feature target WHERE ((fl.srcfeature_id = target.feature_id) AND (fl.rank <> 0))) UNION ALL SELECT feature.feature_id, 'ID' AS type, feature.uniquename AS attribute FROM feature WHERE (NOT (feature.type_id IN (SELECT cvterm.cvterm_id FROM cvterm WHERE ((cvterm.name)::text = 'CDS'::text))))) UNION ALL SELECT feature.feature_id, 'chado_feature_id' AS type, (feature.feature_id)::character varying AS attribute FROM feature) UNION ALL SELECT feature.feature_id, 'Name' AS type, feature.name AS attribute FROM feature;


--
-- Name: gff3view; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW gff3view AS
    SELECT f.feature_id, sf.name AS ref, dbx.accession AS source, cv.name AS type, (fl.fmin + 1) AS fstart, fl.fmax AS fend, af.significance AS score, fl.strand, fl.phase, f.seqlen, f.name, f.organism_id FROM ((((((feature f LEFT JOIN featureloc fl ON ((f.feature_id = fl.feature_id))) LEFT JOIN feature sf ON ((fl.srcfeature_id = sf.feature_id))) LEFT JOIN feature_dbxref fd ON ((f.feature_id = fd.feature_id))) LEFT JOIN dbxref dbx ON (((dbx.dbxref_id = fd.dbxref_id) AND (dbx.db_id IN (SELECT db.db_id FROM db WHERE ((db.name)::text = 'GFF_source'::text)))))) LEFT JOIN cvterm cv ON ((f.type_id = cv.cvterm_id))) LEFT JOIN analysisfeature af ON ((f.feature_id = af.feature_id)));


--
-- Name: gff_sort_tmp; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE gff_sort_tmp (
    refseq character varying(4000),
    id character varying(4000),
    parent character varying(4000),
    gffline character varying(4000),
    row_id integer NOT NULL
);


--
-- Name: gffatts; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW gffatts AS
    (((SELECT fs.feature_id, 'cvterm' AS type, s.name AS attribute FROM cvterm s, feature_cvterm fs WHERE (fs.cvterm_id = s.cvterm_id) UNION ALL SELECT fs.feature_id, 'dbxref' AS type, (((d.name)::text || ':'::text) || (s.accession)::text) AS attribute FROM dbxref s, feature_dbxref fs, db d WHERE ((fs.dbxref_id = s.dbxref_id) AND (s.db_id = d.db_id))) UNION ALL SELECT fs.feature_id, 'synonym' AS type, s.name AS attribute FROM synonym s, feature_synonym fs WHERE (fs.synonym_id = s.synonym_id)) UNION ALL SELECT fp.feature_id, cv.name AS type, fp.value AS attribute FROM featureprop fp, cvterm cv WHERE (fp.type_id = cv.cvterm_id)) UNION ALL SELECT fs.feature_id, 'pub' AS type, (((s.series_name)::text || ':'::text) || s.title) AS attribute FROM pub s, feature_pub fs WHERE (fs.pub_id = s.pub_id);


--
-- Name: intron_combined_view; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW intron_combined_view AS
    SELECT x1.feature_id AS exon1_id, x2.feature_id AS exon2_id, CASE WHEN (l1.strand = (-1)) THEN l2.fmax ELSE l1.fmax END AS fmin, CASE WHEN (l1.strand = (-1)) THEN l1.fmin ELSE l2.fmin END AS fmax, l1.strand, l1.srcfeature_id, r1.rank AS intron_rank, r1.object_id AS transcript_id FROM ((((((cvterm JOIN feature x1 ON ((x1.type_id = cvterm.cvterm_id))) JOIN feature_relationship r1 ON ((x1.feature_id = r1.subject_id))) JOIN featureloc l1 ON ((x1.feature_id = l1.feature_id))) JOIN feature x2 ON ((x2.type_id = cvterm.cvterm_id))) JOIN feature_relationship r2 ON ((x2.feature_id = r2.subject_id))) JOIN featureloc l2 ON ((x2.feature_id = l2.feature_id))) WHERE ((((((((cvterm.name)::text = 'exon'::text) AND ((r2.rank - r1.rank) = 1)) AND (r1.object_id = r2.object_id)) AND (l1.strand = l2.strand)) AND (l1.srcfeature_id = l2.srcfeature_id)) AND (l1.locgroup = 0)) AND (l2.locgroup = 0));


--
-- Name: intronloc_view; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW intronloc_view AS
    SELECT DISTINCT intron_combined_view.exon1_id, intron_combined_view.exon2_id, intron_combined_view.fmin, intron_combined_view.fmax, intron_combined_view.strand, intron_combined_view.srcfeature_id FROM intron_combined_view ORDER BY intron_combined_view.exon1_id, intron_combined_view.exon2_id, intron_combined_view.fmin, intron_combined_view.fmax, intron_combined_view.strand, intron_combined_view.srcfeature_id;


--
-- Name: library; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE library (
    library_id integer NOT NULL,
    organism_id integer NOT NULL,
    name character varying(255),
    uniquename text NOT NULL,
    type_id integer NOT NULL
);


--
-- Name: COLUMN library.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN library.type_id IS 'The type_id foreign key links
to a controlled vocabulary of library types. Examples of this would be: "cDNA_library" or "genomic_library"';


--
-- Name: library_cvterm; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE library_cvterm (
    library_cvterm_id integer NOT NULL,
    library_id integer NOT NULL,
    cvterm_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE library_cvterm; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE library_cvterm IS 'The table library_cvterm links a library to controlled vocabularies which describe the library.  For instance, there might be a link to the anatomy cv for "head" or "testes" for a head or testes library.';


--
-- Name: library_feature; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE library_feature (
    library_feature_id integer NOT NULL,
    library_id integer NOT NULL,
    feature_id integer NOT NULL
);


--
-- Name: TABLE library_feature; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE library_feature IS 'library_feature links a library to the clones which are contained in the library.  Examples of such linked features might be "cDNA_clone" or  "genomic_clone".';


--
-- Name: library_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE library_pub (
    library_pub_id integer NOT NULL,
    library_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: library_synonym; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE library_synonym (
    library_synonym_id integer NOT NULL,
    synonym_id integer NOT NULL,
    library_id integer NOT NULL,
    pub_id integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    is_internal boolean DEFAULT false NOT NULL
);
CREATE TRIGGER library_synonym_is_current_trigger BEFORE INSERT OR UPDATE ON library_synonym
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.library_synonym_is_current_trigger_func();
CREATE TRIGGER library_synonym_is_internal_trigger BEFORE INSERT OR UPDATE ON library_synonym
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.library_synonym_is_internal_trigger_func();


--
-- Name: COLUMN library_synonym.pub_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN library_synonym.pub_id IS 'The pub_id link is for
relating the usage of a given synonym to the publication in which it was used.';


--
-- Name: COLUMN library_synonym.is_current; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN library_synonym.is_current IS 'The is_current bit indicates whether the linked synonym is the current -official- symbol for the linked library.';


--
-- Name: COLUMN library_synonym.is_internal; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN library_synonym.is_internal IS 'Typically a synonym
exists so that somebody querying the database with an obsolete name
can find the object they are looking for under its current name.  If
the synonym has been used publicly and deliberately (e.g. in a paper), it my also be listed in reports as a synonym.   If the synonym was not used deliberately (e.g., there was a typo which went public), then the is_internal bit may be set to "true" so that it is known that the synonym is "internal" and should be queryable but should not be listed in reports as a valid synonym.';


--
-- Name: libraryprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE libraryprop (
    libraryprop_id integer NOT NULL,
    library_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER libraryprop_rank_trigger BEFORE INSERT OR UPDATE ON libraryprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.libraryprop_rank_trigger_func();


--
-- Name: magedocumentation; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE magedocumentation (
    magedocumentation_id integer NOT NULL,
    mageml_id integer NOT NULL,
    tableinfo_id integer NOT NULL,
    row_id integer NOT NULL,
    mageidentifier text NOT NULL
);


--
-- Name: mageml; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE mageml (
    mageml_id integer NOT NULL,
    mage_package text NOT NULL,
    mage_ml text NOT NULL
);


--
-- Name: TABLE mageml; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE mageml IS 'This table is for storing extra bits of MAGEml in a denormalized form. More normalization would require many more tables.';


--
-- Name: organism; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE organism (
    organism_id integer NOT NULL,
    abbreviation character varying(255),
    genus character varying(255) NOT NULL,
    species character varying(255) NOT NULL,
    common_name character varying(255),
    comment text
);


--
-- Name: TABLE organism; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE organism IS 'The organismal taxonomic
classification. Note that phylogenies are represented using the
phylogeny module, and taxonomies can be represented using the cvterm
module or the phylogeny module.';


--
-- Name: COLUMN organism.species; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN organism.species IS 'A type of organism is always
uniquely identified by genus and species. When mapping from the NCBI
taxonomy names.dmp file, this column must be used where it
is present, as the common_name column is not always unique (e.g. environmental
samples). If a particular strain or subspecies is to be represented,
this is appended onto the species name. Follows standard NCBI taxonomy
pattern.';


--
-- Name: organism_dbxref; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE organism_dbxref (
    organism_dbxref_id integer NOT NULL,
    organism_id integer NOT NULL,
    dbxref_id integer NOT NULL
);


--
-- Name: organismprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE organismprop (
    organismprop_id integer NOT NULL,
    organism_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER organismprop_rank_trigger BEFORE INSERT OR UPDATE ON organismprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.organismprop_rank_trigger_func();


--
-- Name: TABLE organismprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE organismprop IS 'Tag-value properties - follows standard chado model.';


--
-- Name: phendesc; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phendesc (
    phendesc_id integer NOT NULL,
    genotype_id integer NOT NULL,
    environment_id integer NOT NULL,
    description text NOT NULL,
    type_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE phendesc; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE phendesc IS 'A summary of a _set_ of phenotypic statements for any one gcontext made in any one publication.';


--
-- Name: phenotype; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phenotype (
    phenotype_id integer NOT NULL,
    uniquename text NOT NULL,
    observable_id integer,
    attr_id integer,
    value text,
    cvalue_id integer,
    assay_id integer
);


--
-- Name: TABLE phenotype; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE phenotype IS 'A phenotypic statement, or a single
atomic phenotypic observation, is a controlled sentence describing
observable effects of non-wild type function. E.g. Obs=eye, attribute=color, cvalue=red.';


--
-- Name: COLUMN phenotype.observable_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN phenotype.observable_id IS 'The entity: e.g. anatomy_part, biological_process.';


--
-- Name: COLUMN phenotype.attr_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN phenotype.attr_id IS 'Phenotypic attribute (quality, property, attribute, character) - drawn from PATO.';


--
-- Name: COLUMN phenotype.value; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN phenotype.value IS 'Value of attribute - unconstrained free text. Used only if cvalue_id is not appropriate.';


--
-- Name: COLUMN phenotype.cvalue_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN phenotype.cvalue_id IS 'Phenotype attribute value (state).';


--
-- Name: COLUMN phenotype.assay_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN phenotype.assay_id IS 'Evidence type.';


--
-- Name: phenotype_comparison; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phenotype_comparison (
    phenotype_comparison_id integer NOT NULL,
    genotype1_id integer NOT NULL,
    environment1_id integer NOT NULL,
    genotype2_id integer NOT NULL,
    environment2_id integer NOT NULL,
    phenotype1_id integer NOT NULL,
    phenotype2_id integer,
    type_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE phenotype_comparison; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE phenotype_comparison IS 'Comparison of phenotypes e.g., genotype1/environment1/phenotype1 "non-suppressible" with respect to genotype2/environment2/phenotype2.';


--
-- Name: phenotype_cvterm; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phenotype_cvterm (
    phenotype_cvterm_id integer NOT NULL,
    phenotype_id integer NOT NULL,
    cvterm_id integer NOT NULL
);


--
-- Name: phenstatement; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phenstatement (
    phenstatement_id integer NOT NULL,
    genotype_id integer NOT NULL,
    environment_id integer NOT NULL,
    phenotype_id integer NOT NULL,
    type_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE phenstatement; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE phenstatement IS 'Phenotypes are things like "larval lethal".  Phenstatements are things like "dpp-1 is recessive larval lethal". So essentially phenstatement is a linking table expressing the relationship between genotype, environment, and phenotype.';


--
-- Name: phylonode; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phylonode (
    phylonode_id integer NOT NULL,
    phylotree_id integer NOT NULL,
    parent_phylonode_id integer,
    left_idx integer NOT NULL,
    right_idx integer NOT NULL,
    type_id integer,
    feature_id integer,
    label character varying(255),
    distance double precision
);


--
-- Name: TABLE phylonode; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE phylonode IS 'This is the most pervasive
       element in the phylogeny module, cataloging the "phylonodes" of
       tree graphs. Edges are implied by the parent_phylonode_id
       reflexive closure. For all nodes in a nested set implementation the left and right index will be *between* the parents left and right indexes.';


--
-- Name: COLUMN phylonode.parent_phylonode_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN phylonode.parent_phylonode_id IS 'Root phylonode can have null parent_phylonode_id value.';


--
-- Name: COLUMN phylonode.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN phylonode.type_id IS 'Type: e.g. root, interior, leaf.';


--
-- Name: COLUMN phylonode.feature_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN phylonode.feature_id IS 'Phylonodes can have optional features attached to them e.g. a protein or nucleotide sequence usually attached to a leaf of the phylotree for non-leaf nodes, the feature may be a feature that is an instance of SO:match; this feature is the alignment of all leaf features beneath it.';


--
-- Name: phylonode_dbxref; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phylonode_dbxref (
    phylonode_dbxref_id integer NOT NULL,
    phylonode_id integer NOT NULL,
    dbxref_id integer NOT NULL
);


--
-- Name: TABLE phylonode_dbxref; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE phylonode_dbxref IS 'For example, for orthology, paralogy group identifiers; could also be used for NCBI taxonomy; for sequences, refer to phylonode_feature, feature associated dbxrefs.';


--
-- Name: phylonode_organism; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phylonode_organism (
    phylonode_organism_id integer NOT NULL,
    phylonode_id integer NOT NULL,
    organism_id integer NOT NULL
);


--
-- Name: TABLE phylonode_organism; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE phylonode_organism IS 'This linking table should only be used for nodes in taxonomy trees; it provides a mapping between the node and an organism. One node can have zero or one organisms, one organism can have zero or more nodes (although typically it should only have one in the standard NCBI taxonomy tree).';


--
-- Name: COLUMN phylonode_organism.phylonode_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN phylonode_organism.phylonode_id IS 'One phylonode cannot refer to >1 organism.';


--
-- Name: phylonode_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phylonode_pub (
    phylonode_pub_id integer NOT NULL,
    phylonode_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: phylonode_relationship; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phylonode_relationship (
    phylonode_relationship_id integer NOT NULL,
    subject_id integer NOT NULL,
    object_id integer NOT NULL,
    type_id integer NOT NULL,
    rank integer,
    phylotree_id integer NOT NULL
);


--
-- Name: TABLE phylonode_relationship; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE phylonode_relationship IS 'This is for 
relationships that are not strictly hierarchical; for example,
horizontal gene transfer. Most phylogenetic trees are strictly
hierarchical, nevertheless it is here for completeness.';


--
-- Name: phylonodeprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phylonodeprop (
    phylonodeprop_id integer NOT NULL,
    phylonode_id integer NOT NULL,
    type_id integer NOT NULL,
    value text DEFAULT ''::text NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER phylonodeprop_value_trigger BEFORE INSERT OR UPDATE ON phylonodeprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phylonodeprop_value_trigger_func();
CREATE TRIGGER phylonodeprop_rank_trigger BEFORE INSERT OR UPDATE ON phylonodeprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phylonodeprop_rank_trigger_func();


--
-- Name: COLUMN phylonodeprop.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN phylonodeprop.type_id IS 'type_id could designate phylonode hierarchy relationships, for example: species taxonomy (kingdom, order, family, genus, species), "ortholog/paralog", "fold/superfold", etc.';


--
-- Name: phylotree; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phylotree (
    phylotree_id integer NOT NULL,
    dbxref_id integer NOT NULL,
    name character varying(255),
    type_id integer,
    analysis_id integer,
    comment text
);


--
-- Name: TABLE phylotree; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE phylotree IS 'Global anchor for phylogenetic tree.';


--
-- Name: COLUMN phylotree.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN phylotree.type_id IS 'Type: protein, nucleotide, taxonomy, for example. The type should be any SO type, or "taxonomy".';


--
-- Name: phylotree_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE phylotree_pub (
    phylotree_pub_id integer NOT NULL,
    phylotree_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE phylotree_pub; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE phylotree_pub IS 'Tracks citations global to the tree e.g. multiple sequence alignment supporting tree construction.';


--
-- Name: project; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE project (
    project_id integer NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL
);


--
-- Name: protocol; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE protocol (
    protocol_id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    dbxref_id integer,
    version integer NOT NULL
);


--
-- Name: protocol_attribute; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE protocol_attribute (
    protocol_attribute_id integer NOT NULL,
    protocol_id integer NOT NULL,
    attribute_id integer NOT NULL
);


--
-- Name: protocolparam; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE protocolparam (
    protocolparam_id integer NOT NULL,
    protocol_id integer NOT NULL,
    name text NOT NULL,
    datatype_id integer,
    unittype_id integer,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER protocolparam_rank_trigger BEFORE INSERT OR UPDATE ON protocolparam
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.protocolparam_rank_trigger_func();


--
-- Name: TABLE protocolparam; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE protocolparam IS 'Parameters related to a
protocol. For example, if the protocol is a soak, this might include attributes of bath temperature and duration.';


--
-- Name: pub_dbxref; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE pub_dbxref (
    pub_dbxref_id integer NOT NULL,
    pub_id integer NOT NULL,
    dbxref_id integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL
);
CREATE TRIGGER pub_dbxref_is_current_trigger BEFORE INSERT OR UPDATE ON pub_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.pub_dbxref_is_current_trigger_func();


--
-- Name: TABLE pub_dbxref; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE pub_dbxref IS 'Handle links to repositories,
e.g. Pubmed, Biosis, zoorec, OCLC, Medline, ISSN, coden...';


--
-- Name: pub_relationship; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE pub_relationship (
    pub_relationship_id integer NOT NULL,
    subject_id integer NOT NULL,
    object_id integer NOT NULL,
    type_id integer NOT NULL
);


--
-- Name: TABLE pub_relationship; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE pub_relationship IS 'Handle relationships between
publications, e.g. when one publication makes others obsolete, when one
publication contains errata with respect to other publication(s), or
when one publication also appears in another pub.';


--
-- Name: pubauthor; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE pubauthor (
    pubauthor_id integer NOT NULL,
    pub_id integer NOT NULL,
    rank integer NOT NULL,
    editor boolean DEFAULT false,
    surname character varying(100) NOT NULL,
    givennames character varying(100),
    suffix character varying(100)
);
CREATE TRIGGER pubauthor_editor_trigger BEFORE INSERT OR UPDATE ON pubauthor
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.pubauthor_editor_trigger_func();


--
-- Name: TABLE pubauthor; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE pubauthor IS 'An author for a publication. Note the denormalisation (hence lack of _ in table name) - this is deliberate as it is in general too hard to assign IDs to authors.';


--
-- Name: COLUMN pubauthor.rank; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN pubauthor.rank IS 'Order of author in author list for this pub - order is important.';


--
-- Name: COLUMN pubauthor.editor; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN pubauthor.editor IS 'Indicates whether the author is an editor for linked publication. Note: this is a boolean field but does not follow the normal chado convention for naming booleans.';


--
-- Name: COLUMN pubauthor.givennames; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN pubauthor.givennames IS 'First name, initials';


--
-- Name: COLUMN pubauthor.suffix; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN pubauthor.suffix IS 'Jr., Sr., etc';


--
-- Name: pubprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE pubprop (
    pubprop_id integer NOT NULL,
    pub_id integer NOT NULL,
    type_id integer NOT NULL,
    value text NOT NULL,
    rank integer
);


--
-- Name: TABLE pubprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE pubprop IS 'Property-value pairs for a pub. Follows standard chado pattern.';


--
-- Name: quantification; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE quantification (
    quantification_id integer NOT NULL,
    acquisition_id integer NOT NULL,
    operator_id integer,
    protocol_id integer,
    analysis_id integer NOT NULL,
    quantificationdate timestamp without time zone DEFAULT now(),
    name text,
    uri text
);
CREATE TRIGGER quantification_quantificationdate_trigger BEFORE INSERT OR UPDATE ON quantification
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.quantification_quantificationdate_trigger_func();


--
-- Name: TABLE quantification; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE quantification IS 'Quantification is the transformation of an image acquisition to numeric data. This typically involves statistical procedures.';


--
-- Name: quantification_relationship; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE quantification_relationship (
    quantification_relationship_id integer NOT NULL,
    subject_id integer NOT NULL,
    type_id integer NOT NULL,
    object_id integer NOT NULL
);


--
-- Name: TABLE quantification_relationship; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE quantification_relationship IS 'There may be multiple rounds of quantification, this allows us to keep an audit trail of what values went where.';


--
-- Name: quantificationprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE quantificationprop (
    quantificationprop_id integer NOT NULL,
    quantification_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER quantificationprop_rank_trigger BEFORE INSERT OR UPDATE ON quantificationprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.quantificationprop_rank_trigger_func();


--
-- Name: TABLE quantificationprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE quantificationprop IS 'Extra quantification properties that are not accounted for in quantification.';


--
-- Name: stats_paths_to_root; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW stats_paths_to_root AS
    SELECT cvtermpath.subject_id AS cvterm_id, count(DISTINCT cvtermpath.cvtermpath_id) AS total_paths, avg(cvtermpath.pathdistance) AS avg_distance, min(cvtermpath.pathdistance) AS min_distance, max(cvtermpath.pathdistance) AS max_distance FROM (cvtermpath JOIN cv_root ON ((cvtermpath.object_id = cv_root.root_cvterm_id))) GROUP BY cvtermpath.subject_id;


--
-- Name: VIEW stats_paths_to_root; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW stats_paths_to_root IS 'per-cvterm statistics on its
placement in the DAG relative to the root. There may be multiple paths
from any term to the root. This gives the total number of paths, and
the average minimum and maximum distances. Here distance is defined by
cvtermpath.pathdistance';


--
-- Name: stock; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stock (
    stock_id integer NOT NULL,
    dbxref_id integer,
    organism_id integer NOT NULL,
    name character varying(255),
    uniquename text NOT NULL,
    description text,
    type_id integer NOT NULL,
    is_obsolete boolean DEFAULT false NOT NULL
);
CREATE TRIGGER stock_rank_trigger BEFORE INSERT OR UPDATE ON stock
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stock_rank_trigger_func();


--
-- Name: TABLE stock; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE stock IS 'Any stock can be globally identified by the
combination of organism, uniquename and stock type. A stock is the physical entities, either living or preserved, held by collections. Stocks belong to a collection; they have IDs, type, organism, description and may have a genotype.';


--
-- Name: COLUMN stock.dbxref_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stock.dbxref_id IS 'The dbxref_id is an optional primary stable identifier for this stock. Secondary indentifiers and external dbxrefs go in table: stock_dbxref.';


--
-- Name: COLUMN stock.organism_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stock.organism_id IS 'The organism_id is the organism to which the stock belongs. This column is mandatory.';


--
-- Name: COLUMN stock.name; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stock.name IS 'The name is a human-readable local name for a stock.';


--
-- Name: COLUMN stock.description; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stock.description IS 'The description is the genetic description provided in the stock list.';


--
-- Name: COLUMN stock.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stock.type_id IS 'The type_id foreign key links to a controlled vocabulary of stock types. The would include living stock, genomic DNA, preserved specimen. Secondary cvterms for stocks would go in stock_cvterm.';


--
-- Name: stock_cvterm; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stock_cvterm (
    stock_cvterm_id integer NOT NULL,
    stock_id integer NOT NULL,
    cvterm_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE stock_cvterm; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE stock_cvterm IS 'stock_cvterm links a stock to cvterms. This is for secondary cvterms; primary cvterms should use stock.type_id.';


--
-- Name: stock_dbxref; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stock_dbxref (
    stock_dbxref_id integer NOT NULL,
    stock_id integer NOT NULL,
    dbxref_id integer NOT NULL,
    is_current boolean DEFAULT true NOT NULL
);
CREATE TRIGGER stock_dbxref_is_current_trigger BEFORE INSERT OR UPDATE ON stock_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stock_dbxref_is_current_trigger_func();


--
-- Name: TABLE stock_dbxref; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE stock_dbxref IS 'stock_dbxref links a stock to dbxrefs. This is for secondary identifiers; primary identifiers should use stock.dbxref_id.';


--
-- Name: COLUMN stock_dbxref.is_current; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stock_dbxref.is_current IS 'The is_current boolean indicates whether the linked dbxref is the current -official- dbxref for the linked stock.';


--
-- Name: stock_genotype; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stock_genotype (
    stock_genotype_id integer NOT NULL,
    stock_id integer NOT NULL,
    genotype_id integer NOT NULL
);


--
-- Name: TABLE stock_genotype; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE stock_genotype IS 'Simple table linking a stock to
a genotype. Features with genotypes can be linked to stocks thru feature_genotype -> genotype -> stock_genotype -> stock.';


--
-- Name: stock_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stock_pub (
    stock_pub_id integer NOT NULL,
    stock_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE stock_pub; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE stock_pub IS 'Provenance. Linking table between stocks and, for example, a stocklist computer file.';


--
-- Name: stock_relationship; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stock_relationship (
    stock_relationship_id integer NOT NULL,
    subject_id integer NOT NULL,
    object_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER stock_relationship_rank_trigger BEFORE INSERT OR UPDATE ON stock_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stock_relationship_rank_trigger_func();


--
-- Name: COLUMN stock_relationship.subject_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stock_relationship.subject_id IS 'stock_relationship.subject_id is the subject of the subj-predicate-obj sentence. This is typically the substock.';


--
-- Name: COLUMN stock_relationship.object_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stock_relationship.object_id IS 'stock_relationship.object_id is the object of the subj-predicate-obj sentence. This is typically the container stock.';


--
-- Name: COLUMN stock_relationship.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stock_relationship.type_id IS 'stock_relationship.type_id is relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed.';


--
-- Name: COLUMN stock_relationship.value; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stock_relationship.value IS 'stock_relationship.value is for additional notes or comments.';


--
-- Name: COLUMN stock_relationship.rank; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stock_relationship.rank IS 'stock_relationship.rank is the ordering of subject stocks with respect to the object stock may be important where rank is used to order these; starts from zero.';


--
-- Name: stock_relationship_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stock_relationship_pub (
    stock_relationship_pub_id integer NOT NULL,
    stock_relationship_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE stock_relationship_pub; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE stock_relationship_pub IS 'Provenance. Attach optional evidence to a stock_relationship in the form of a publication.';


--
-- Name: stockcollection; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stockcollection (
    stockcollection_id integer NOT NULL,
    type_id integer NOT NULL,
    contact_id integer,
    name character varying(255),
    uniquename text NOT NULL
);


--
-- Name: TABLE stockcollection; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE stockcollection IS 'The lab or stock center distributing the stocks in their collection.';


--
-- Name: COLUMN stockcollection.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stockcollection.type_id IS 'type_id is the collection type cv.';


--
-- Name: COLUMN stockcollection.contact_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stockcollection.contact_id IS 'contact_id links to the contact information for the collection.';


--
-- Name: COLUMN stockcollection.name; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stockcollection.name IS 'name is the collection.';


--
-- Name: COLUMN stockcollection.uniquename; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stockcollection.uniquename IS 'uniqename is the value of the collection cv.';


--
-- Name: stockcollection_stock; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stockcollection_stock (
    stockcollection_stock_id integer NOT NULL,
    stockcollection_id integer NOT NULL,
    stock_id integer NOT NULL
);


--
-- Name: TABLE stockcollection_stock; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE stockcollection_stock IS 'stockcollection_stock links
a stock collection to the stocks which are contained in the collection.';


--
-- Name: stockcollectionprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stockcollectionprop (
    stockcollectionprop_id integer NOT NULL,
    stockcollection_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER stockcollectionprop_rank_trigger BEFORE INSERT OR UPDATE ON stockcollectionprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stockcollectionprop_rank_trigger_func();


--
-- Name: TABLE stockcollectionprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE stockcollectionprop IS 'The table stockcollectionprop
contains the value of the stock collection such as website/email URLs;
the value of the stock collection order URLs.';


--
-- Name: COLUMN stockcollectionprop.type_id; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON COLUMN stockcollectionprop.type_id IS 'The cv for the type_id is "stockcollection property type".';


--
-- Name: stockprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stockprop (
    stockprop_id integer NOT NULL,
    stock_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER stockprop_rank_trigger BEFORE INSERT OR UPDATE ON stockprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stockprop_rank_trigger_func();


--
-- Name: TABLE stockprop; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE stockprop IS 'A stock can have any number of
slot-value property tags attached to it. This is an alternative to
hardcoding a list of columns in the relational schema, and is
completely extensible. There is a unique constraint, stockprop_c1, for
the combination of stock_id, rank, and type_id. Multivalued property-value pairs must be differentiated by rank.';


--
-- Name: stockprop_pub; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE stockprop_pub (
    stockprop_pub_id integer NOT NULL,
    stockprop_id integer NOT NULL,
    pub_id integer NOT NULL
);


--
-- Name: TABLE stockprop_pub; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE stockprop_pub IS 'Provenance. Any stockprop assignment can optionally be supported by a publication.';


--
-- Name: study; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE study (
    study_id integer NOT NULL,
    contact_id integer NOT NULL,
    pub_id integer,
    dbxref_id integer,
    name text NOT NULL,
    description text
);


--
-- Name: study_assay; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE study_assay (
    study_assay_id integer NOT NULL,
    study_id integer NOT NULL,
    assay_id integer NOT NULL
);


--
-- Name: studydesign; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE studydesign (
    studydesign_id integer NOT NULL,
    study_id integer NOT NULL,
    description text
);


--
-- Name: studydesignprop; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE studydesignprop (
    studydesignprop_id integer NOT NULL,
    studydesign_id integer NOT NULL,
    type_id integer NOT NULL,
    value text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER studydesignprop_rank_trigger BEFORE INSERT OR UPDATE ON studydesignprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.studydesignprop_rank_trigger_func();


--
-- Name: studyfactor; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE studyfactor (
    studyfactor_id integer NOT NULL,
    studydesign_id integer NOT NULL,
    type_id integer,
    name text NOT NULL,
    description text
);


--
-- Name: studyfactorvalue; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE studyfactorvalue (
    studyfactorvalue_id integer NOT NULL,
    studyfactor_id integer NOT NULL,
    assay_id integer NOT NULL,
    factorvalue text,
    name text,
    rank integer DEFAULT 0 NOT NULL
);
CREATE TRIGGER studyfactorvalue_rank_trigger BEFORE INSERT OR UPDATE ON studyfactorvalue
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.studyfactorvalue_rank_trigger_func();


--
-- Name: tableinfo; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE tableinfo (
    tableinfo_id integer NOT NULL,
    name character varying(30) NOT NULL,
    primary_key_column character varying(30),
    is_view integer DEFAULT 0 NOT NULL,
    view_on_table_id integer,
    superclass_table_id integer,
    is_updateable integer DEFAULT 1 NOT NULL,
    modification_date date DEFAULT now() NOT NULL
);
CREATE TRIGGER tableinfo_is_updateable_trigger BEFORE INSERT OR UPDATE ON tableinfo
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.tableinfo_is_updateable_trigger_func();
CREATE TRIGGER tableinfo_is_view_trigger BEFORE INSERT OR UPDATE ON tableinfo
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.tableinfo_is_view_trigger_func();
CREATE TRIGGER tableinfo_modification_date_trigger BEFORE INSERT OR UPDATE ON tableinfo
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.tableinfo_modification_date_trigger_func();


--
-- Name: treatment; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE treatment (
    treatment_id integer NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    biomaterial_id integer NOT NULL,
    type_id integer NOT NULL,
    protocol_id integer,
    name text
);
CREATE TRIGGER treatment_rank_trigger BEFORE INSERT OR UPDATE ON treatment
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.treatment_rank_trigger_func();


--
-- Name: TABLE treatment; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON TABLE treatment IS 'A biomaterial may undergo multiple
treatments. Examples of treatments: apoxia, fluorophore and biotin labeling.';


--
-- Name: type_feature_count; Type: VIEW; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE VIEW type_feature_count AS
    SELECT t.name AS type, count(*) AS num_features FROM (cvterm t JOIN feature ON ((feature.type_id = t.cvterm_id))) GROUP BY t.name;


--
-- Name: VIEW type_feature_count; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON VIEW type_feature_count IS 'per-feature-type feature counts';


--
-- Name: wiggle_data; Type: TABLE; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE TABLE wiggle_data (
    wiggle_data_id integer NOT NULL,
    type character(8) DEFAULT 'wiggle_0'::bpchar NOT NULL,
    name character varying(255) DEFAULT 'User Track'::character varying NOT NULL,
    description character varying(255) DEFAULT 'User Supplied Track'::character varying,
    visibility character(5) DEFAULT 'hide'::bpchar NOT NULL,
    color wiggle.color DEFAULT wiggle.color(255, 255, 255) NOT NULL,
    altcolor wiggle.color DEFAULT wiggle.color(128, 128, 128) NOT NULL,
    priority integer DEFAULT 100 NOT NULL,
    autoscale boolean DEFAULT true NOT NULL,
    griddefault boolean DEFAULT false NOT NULL,
    maxheightpixels wiggle.maxheightbounds DEFAULT wiggle.maxheightbounds(128, 128, 11) NOT NULL,
    graphtype character(6) DEFAULT 'bar'::bpchar NOT NULL,
    viewlimits wiggle.range DEFAULT wiggle.range(0, 0) NOT NULL,
    ylinemark double precision DEFAULT 0.0 NOT NULL,
    ylineonoff boolean DEFAULT false,
    windowingfunction character(7) DEFAULT 'maximum'::bpchar NOT NULL,
    smoothingwindow integer DEFAULT 1 NOT NULL,
    data text DEFAULT ''::text NOT NULL,
    CONSTRAINT wiggle_data_altcolor_check CHECK ((altcolor OPERATOR(wiggle.=) wiggle.color(altcolor))),
    CONSTRAINT wiggle_data_color_check CHECK ((color OPERATOR(wiggle.=) wiggle.color(color))),
    CONSTRAINT wiggle_data_graphtype_check CHECK (((graphtype = 'bar'::bpchar) OR (graphtype = 'points'::bpchar))),
    CONSTRAINT wiggle_data_smoothingwindow_check CHECK (((smoothingwindow >= 1) AND (smoothingwindow <= 16))),
    CONSTRAINT wiggle_data_type_check CHECK ((type = 'wiggle_0'::bpchar)),
    CONSTRAINT wiggle_data_visibility_check CHECK ((((visibility = 'full'::bpchar) OR (visibility = 'dense'::bpchar)) OR (visibility = 'hide'::bpchar))),
    CONSTRAINT wiggle_data_windowingfunction_check CHECK ((((windowingfunction = 'maximum'::bpchar) OR (windowingfunction = 'mean'::bpchar)) OR (windowingfunction = 'minimum'::bpchar)))
);
CREATE TRIGGER wiggle_data_data_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_data_trigger_func();
CREATE TRIGGER wiggle_data_smoothingwindow_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_smoothingwindow_trigger_func();
CREATE TRIGGER wiggle_data_windowingfunction_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_windowingfunction_trigger_func();
CREATE TRIGGER wiggle_data_ylineonoff_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_ylineonoff_trigger_func();
CREATE TRIGGER wiggle_data_ylinemark_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_ylinemark_trigger_func();
CREATE TRIGGER wiggle_data_viewlimits_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_viewlimits_trigger_func();
CREATE TRIGGER wiggle_data_graphtype_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_graphtype_trigger_func();
CREATE TRIGGER wiggle_data_maxheightpixels_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_maxheightpixels_trigger_func();
CREATE TRIGGER wiggle_data_griddefault_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_griddefault_trigger_func();
CREATE TRIGGER wiggle_data_autoscale_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_autoscale_trigger_func();
CREATE TRIGGER wiggle_data_priority_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_priority_trigger_func();
CREATE TRIGGER wiggle_data_altcolor_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_altcolor_trigger_func();
CREATE TRIGGER wiggle_data_color_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_color_trigger_func();
CREATE TRIGGER wiggle_data_visibility_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_visibility_trigger_func();
CREATE TRIGGER wiggle_data_description_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_description_trigger_func();
CREATE TRIGGER wiggle_data_name_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_name_trigger_func();
CREATE TRIGGER wiggle_data_type_trigger BEFORE INSERT OR UPDATE ON wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_type_trigger_func();

--
-- Name: acquisition_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE acquisition ALTER COLUMN acquisition_id SET DEFAULT nextval('generic_chado.acquisition_acquisition_id_seq'::regclass);


--
-- Name: acquisition_relationship_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE acquisition_relationship ALTER COLUMN acquisition_relationship_id SET DEFAULT nextval('generic_chado.acquisition_relationship_acquisition_relationship_id_seq'::regclass);


--
-- Name: acquisitionprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE acquisitionprop ALTER COLUMN acquisitionprop_id SET DEFAULT nextval('generic_chado.acquisitionprop_acquisitionprop_id_seq'::regclass);


--
-- Name: analysis_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE analysis ALTER COLUMN analysis_id SET DEFAULT nextval('generic_chado.analysis_analysis_id_seq'::regclass);


--
-- Name: analysisfeature_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE analysisfeature ALTER COLUMN analysisfeature_id SET DEFAULT nextval('generic_chado.analysisfeature_analysisfeature_id_seq'::regclass);


--
-- Name: analysisprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE analysisprop ALTER COLUMN analysisprop_id SET DEFAULT nextval('generic_chado.analysisprop_analysisprop_id_seq'::regclass);


--
-- Name: applied_protocol_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE applied_protocol ALTER COLUMN applied_protocol_id SET DEFAULT nextval('generic_chado.applied_protocol_applied_protocol_id_seq'::regclass);


--
-- Name: applied_protocol_data_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE applied_protocol_data ALTER COLUMN applied_protocol_data_id SET DEFAULT nextval('generic_chado.applied_protocol_data_applied_protocol_data_id_seq'::regclass);


--
-- Name: arraydesign_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE arraydesign ALTER COLUMN arraydesign_id SET DEFAULT nextval('generic_chado.arraydesign_arraydesign_id_seq'::regclass);


--
-- Name: arraydesignprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE arraydesignprop ALTER COLUMN arraydesignprop_id SET DEFAULT nextval('generic_chado.arraydesignprop_arraydesignprop_id_seq'::regclass);


--
-- Name: assay_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE assay ALTER COLUMN assay_id SET DEFAULT nextval('generic_chado.assay_assay_id_seq'::regclass);


--
-- Name: assay_biomaterial_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE assay_biomaterial ALTER COLUMN assay_biomaterial_id SET DEFAULT nextval('generic_chado.assay_biomaterial_assay_biomaterial_id_seq'::regclass);


--
-- Name: assay_project_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE assay_project ALTER COLUMN assay_project_id SET DEFAULT nextval('generic_chado.assay_project_assay_project_id_seq'::regclass);


--
-- Name: assayprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE assayprop ALTER COLUMN assayprop_id SET DEFAULT nextval('generic_chado.assayprop_assayprop_id_seq'::regclass);


--
-- Name: attribute_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE attribute ALTER COLUMN attribute_id SET DEFAULT nextval('generic_chado.attribute_attribute_id_seq'::regclass);


--
-- Name: attribute_organism_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE attribute_organism ALTER COLUMN attribute_organism_id SET DEFAULT nextval('generic_chado.attribute_organism_attribute_organism_id_seq'::regclass);


--
-- Name: biomaterial_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE biomaterial ALTER COLUMN biomaterial_id SET DEFAULT nextval('generic_chado.biomaterial_biomaterial_id_seq'::regclass);


--
-- Name: biomaterial_dbxref_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE biomaterial_dbxref ALTER COLUMN biomaterial_dbxref_id SET DEFAULT nextval('generic_chado.biomaterial_dbxref_biomaterial_dbxref_id_seq'::regclass);


--
-- Name: biomaterial_relationship_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE biomaterial_relationship ALTER COLUMN biomaterial_relationship_id SET DEFAULT nextval('generic_chado.biomaterial_relationship_biomaterial_relationship_id_seq'::regclass);


--
-- Name: biomaterial_treatment_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE biomaterial_treatment ALTER COLUMN biomaterial_treatment_id SET DEFAULT nextval('generic_chado.biomaterial_treatment_biomaterial_treatment_id_seq'::regclass);


--
-- Name: biomaterialprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE biomaterialprop ALTER COLUMN biomaterialprop_id SET DEFAULT nextval('generic_chado.biomaterialprop_biomaterialprop_id_seq'::regclass);


--
-- Name: channel_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE channel ALTER COLUMN channel_id SET DEFAULT nextval('generic_chado.channel_channel_id_seq'::regclass);


--
-- Name: contact_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE contact ALTER COLUMN contact_id SET DEFAULT nextval('generic_chado.contact_contact_id_seq'::regclass);


--
-- Name: contact_relationship_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE contact_relationship ALTER COLUMN contact_relationship_id SET DEFAULT nextval('generic_chado.contact_relationship_contact_relationship_id_seq'::regclass);


--
-- Name: contactprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE contactprop ALTER COLUMN contactprop_id SET DEFAULT nextval('generic_chado.contactprop_contactprop_id_seq'::regclass);


--
-- Name: control_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE control ALTER COLUMN control_id SET DEFAULT nextval('generic_chado.control_control_id_seq'::regclass);


--
-- Name: cv_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE cv ALTER COLUMN cv_id SET DEFAULT nextval('generic_chado.cv_cv_id_seq'::regclass);


--
-- Name: cvterm_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE cvterm ALTER COLUMN cvterm_id SET DEFAULT nextval('generic_chado.cvterm_cvterm_id_seq'::regclass);


--
-- Name: cvterm_dbxref_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE cvterm_dbxref ALTER COLUMN cvterm_dbxref_id SET DEFAULT nextval('generic_chado.cvterm_dbxref_cvterm_dbxref_id_seq'::regclass);


--
-- Name: cvterm_relationship_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE cvterm_relationship ALTER COLUMN cvterm_relationship_id SET DEFAULT nextval('generic_chado.cvterm_relationship_cvterm_relationship_id_seq'::regclass);


--
-- Name: cvtermpath_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE cvtermpath ALTER COLUMN cvtermpath_id SET DEFAULT nextval('generic_chado.cvtermpath_cvtermpath_id_seq'::regclass);


--
-- Name: cvtermprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE cvtermprop ALTER COLUMN cvtermprop_id SET DEFAULT nextval('generic_chado.cvtermprop_cvtermprop_id_seq'::regclass);


--
-- Name: cvtermsynonym_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE cvtermsynonym ALTER COLUMN cvtermsynonym_id SET DEFAULT nextval('generic_chado.cvtermsynonym_cvtermsynonym_id_seq'::regclass);


--
-- Name: data_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE data ALTER COLUMN data_id SET DEFAULT nextval('generic_chado.data_data_id_seq'::regclass);


--
-- Name: data_attribute_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE data_attribute ALTER COLUMN data_attribute_id SET DEFAULT nextval('generic_chado.data_attribute_data_attribute_id_seq'::regclass);


--
-- Name: data_feature_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE data_feature ALTER COLUMN data_feature_id SET DEFAULT nextval('generic_chado.data_feature_data_feature_id_seq'::regclass);


--
-- Name: data_organism_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE data_organism ALTER COLUMN data_organism_id SET DEFAULT nextval('generic_chado.data_organism_data_organism_id_seq'::regclass);


--
-- Name: data_wiggle_data_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE data_wiggle_data ALTER COLUMN data_wiggle_data_id SET DEFAULT nextval('generic_chado.data_wiggle_data_data_wiggle_data_id_seq'::regclass);


--
-- Name: db_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE db ALTER COLUMN db_id SET DEFAULT nextval('generic_chado.db_db_id_seq'::regclass);


--
-- Name: dbxref_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE dbxref ALTER COLUMN dbxref_id SET DEFAULT nextval('generic_chado.dbxref_dbxref_id_seq'::regclass);


--
-- Name: dbxrefprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE dbxrefprop ALTER COLUMN dbxrefprop_id SET DEFAULT nextval('generic_chado.dbxrefprop_dbxrefprop_id_seq'::regclass);


--
-- Name: eimage_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE eimage ALTER COLUMN eimage_id SET DEFAULT nextval('generic_chado.eimage_eimage_id_seq'::regclass);


--
-- Name: element_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE element ALTER COLUMN element_id SET DEFAULT nextval('generic_chado.element_element_id_seq'::regclass);


--
-- Name: element_relationship_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE element_relationship ALTER COLUMN element_relationship_id SET DEFAULT nextval('generic_chado.element_relationship_element_relationship_id_seq'::regclass);


--
-- Name: elementresult_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE elementresult ALTER COLUMN elementresult_id SET DEFAULT nextval('generic_chado.elementresult_elementresult_id_seq'::regclass);


--
-- Name: elementresult_relationship_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE elementresult_relationship ALTER COLUMN elementresult_relationship_id SET DEFAULT nextval('generic_chado.elementresult_relationship_elementresult_relationship_id_seq'::regclass);


--
-- Name: environment_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE environment ALTER COLUMN environment_id SET DEFAULT nextval('generic_chado.environment_environment_id_seq'::regclass);


--
-- Name: environment_cvterm_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE environment_cvterm ALTER COLUMN environment_cvterm_id SET DEFAULT nextval('generic_chado.environment_cvterm_environment_cvterm_id_seq'::regclass);


--
-- Name: experiment_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE experiment ALTER COLUMN experiment_id SET DEFAULT nextval('generic_chado.experiment_experiment_id_seq'::regclass);


--
-- Name: experiment_applied_protocol_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE experiment_applied_protocol ALTER COLUMN experiment_applied_protocol_id SET DEFAULT nextval('generic_chado.experiment_applied_protocol_experiment_applied_protocol_id_seq'::regclass);


--
-- Name: experiment_prop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE experiment_prop ALTER COLUMN experiment_prop_id SET DEFAULT nextval('generic_chado.experiment_prop_experiment_prop_id_seq'::regclass);


--
-- Name: expression_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE expression ALTER COLUMN expression_id SET DEFAULT nextval('generic_chado.expression_expression_id_seq'::regclass);


--
-- Name: expression_cvterm_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE expression_cvterm ALTER COLUMN expression_cvterm_id SET DEFAULT nextval('generic_chado.expression_cvterm_expression_cvterm_id_seq'::regclass);


--
-- Name: expression_cvtermprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE expression_cvtermprop ALTER COLUMN expression_cvtermprop_id SET DEFAULT nextval('generic_chado.expression_cvtermprop_expression_cvtermprop_id_seq'::regclass);


--
-- Name: expression_image_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE expression_image ALTER COLUMN expression_image_id SET DEFAULT nextval('generic_chado.expression_image_expression_image_id_seq'::regclass);


--
-- Name: expression_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE expression_pub ALTER COLUMN expression_pub_id SET DEFAULT nextval('generic_chado.expression_pub_expression_pub_id_seq'::regclass);


--
-- Name: expressionprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE expressionprop ALTER COLUMN expressionprop_id SET DEFAULT nextval('generic_chado.expressionprop_expressionprop_id_seq'::regclass);


--
-- Name: feature_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature ALTER COLUMN feature_id SET DEFAULT nextval('generic_chado.feature_feature_id_seq'::regclass);


--
-- Name: feature_cvterm_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_cvterm ALTER COLUMN feature_cvterm_id SET DEFAULT nextval('generic_chado.feature_cvterm_feature_cvterm_id_seq'::regclass);


--
-- Name: feature_cvterm_dbxref_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_cvterm_dbxref ALTER COLUMN feature_cvterm_dbxref_id SET DEFAULT nextval('generic_chado.feature_cvterm_dbxref_feature_cvterm_dbxref_id_seq'::regclass);


--
-- Name: feature_cvterm_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_cvterm_pub ALTER COLUMN feature_cvterm_pub_id SET DEFAULT nextval('generic_chado.feature_cvterm_pub_feature_cvterm_pub_id_seq'::regclass);


--
-- Name: feature_cvtermprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_cvtermprop ALTER COLUMN feature_cvtermprop_id SET DEFAULT nextval('generic_chado.feature_cvtermprop_feature_cvtermprop_id_seq'::regclass);


--
-- Name: feature_dbxref_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_dbxref ALTER COLUMN feature_dbxref_id SET DEFAULT nextval('generic_chado.feature_dbxref_feature_dbxref_id_seq'::regclass);


--
-- Name: feature_expression_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_expression ALTER COLUMN feature_expression_id SET DEFAULT nextval('generic_chado.feature_expression_feature_expression_id_seq'::regclass);


--
-- Name: feature_expressionprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_expressionprop ALTER COLUMN feature_expressionprop_id SET DEFAULT nextval('generic_chado.feature_expressionprop_feature_expressionprop_id_seq'::regclass);


--
-- Name: feature_genotype_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_genotype ALTER COLUMN feature_genotype_id SET DEFAULT nextval('generic_chado.feature_genotype_feature_genotype_id_seq'::regclass);


--
-- Name: feature_phenotype_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_phenotype ALTER COLUMN feature_phenotype_id SET DEFAULT nextval('generic_chado.feature_phenotype_feature_phenotype_id_seq'::regclass);


--
-- Name: feature_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_pub ALTER COLUMN feature_pub_id SET DEFAULT nextval('generic_chado.feature_pub_feature_pub_id_seq'::regclass);


--
-- Name: feature_pubprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_pubprop ALTER COLUMN feature_pubprop_id SET DEFAULT nextval('generic_chado.feature_pubprop_feature_pubprop_id_seq'::regclass);


--
-- Name: feature_relationship_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_relationship ALTER COLUMN feature_relationship_id SET DEFAULT nextval('generic_chado.feature_relationship_feature_relationship_id_seq'::regclass);


--
-- Name: feature_relationship_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_relationship_pub ALTER COLUMN feature_relationship_pub_id SET DEFAULT nextval('generic_chado.feature_relationship_pub_feature_relationship_pub_id_seq'::regclass);


--
-- Name: feature_relationshipprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_relationshipprop ALTER COLUMN feature_relationshipprop_id SET DEFAULT nextval('generic_chado.feature_relationshipprop_feature_relationshipprop_id_seq'::regclass);


--
-- Name: feature_relationshipprop_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_relationshipprop_pub ALTER COLUMN feature_relationshipprop_pub_id SET DEFAULT nextval('generic_chado.feature_relationshipprop_pub_feature_relationshipprop_pub_i_seq'::regclass);


--
-- Name: feature_synonym_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE feature_synonym ALTER COLUMN feature_synonym_id SET DEFAULT nextval('generic_chado.feature_synonym_feature_synonym_id_seq'::regclass);


--
-- Name: featureloc_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE featureloc ALTER COLUMN featureloc_id SET DEFAULT nextval('generic_chado.featureloc_featureloc_id_seq'::regclass);


--
-- Name: featureloc_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE featureloc_pub ALTER COLUMN featureloc_pub_id SET DEFAULT nextval('generic_chado.featureloc_pub_featureloc_pub_id_seq'::regclass);


--
-- Name: featuremap_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE featuremap ALTER COLUMN featuremap_id SET DEFAULT nextval('generic_chado.featuremap_featuremap_id_seq'::regclass);


--
-- Name: featuremap_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE featuremap_pub ALTER COLUMN featuremap_pub_id SET DEFAULT nextval('generic_chado.featuremap_pub_featuremap_pub_id_seq'::regclass);


--
-- Name: featurepos_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE featurepos ALTER COLUMN featurepos_id SET DEFAULT nextval('generic_chado.featurepos_featurepos_id_seq'::regclass);


--
-- Name: featuremap_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE featurepos ALTER COLUMN featuremap_id SET DEFAULT nextval('generic_chado.featurepos_featuremap_id_seq'::regclass);


--
-- Name: featureprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE featureprop ALTER COLUMN featureprop_id SET DEFAULT nextval('generic_chado.featureprop_featureprop_id_seq'::regclass);


--
-- Name: featureprop_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE featureprop_pub ALTER COLUMN featureprop_pub_id SET DEFAULT nextval('generic_chado.featureprop_pub_featureprop_pub_id_seq'::regclass);


--
-- Name: featurerange_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE featurerange ALTER COLUMN featurerange_id SET DEFAULT nextval('generic_chado.featurerange_featurerange_id_seq'::regclass);


--
-- Name: genotype_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE genotype ALTER COLUMN genotype_id SET DEFAULT nextval('generic_chado.genotype_genotype_id_seq'::regclass);


--
-- Name: row_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE gff_sort_tmp ALTER COLUMN row_id SET DEFAULT nextval('generic_chado.gff_sort_tmp_row_id_seq'::regclass);


--
-- Name: library_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE library ALTER COLUMN library_id SET DEFAULT nextval('generic_chado.library_library_id_seq'::regclass);


--
-- Name: library_cvterm_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE library_cvterm ALTER COLUMN library_cvterm_id SET DEFAULT nextval('generic_chado.library_cvterm_library_cvterm_id_seq'::regclass);


--
-- Name: library_feature_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE library_feature ALTER COLUMN library_feature_id SET DEFAULT nextval('generic_chado.library_feature_library_feature_id_seq'::regclass);


--
-- Name: library_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE library_pub ALTER COLUMN library_pub_id SET DEFAULT nextval('generic_chado.library_pub_library_pub_id_seq'::regclass);


--
-- Name: library_synonym_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE library_synonym ALTER COLUMN library_synonym_id SET DEFAULT nextval('generic_chado.library_synonym_library_synonym_id_seq'::regclass);


--
-- Name: libraryprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE libraryprop ALTER COLUMN libraryprop_id SET DEFAULT nextval('generic_chado.libraryprop_libraryprop_id_seq'::regclass);


--
-- Name: magedocumentation_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE magedocumentation ALTER COLUMN magedocumentation_id SET DEFAULT nextval('generic_chado.magedocumentation_magedocumentation_id_seq'::regclass);


--
-- Name: mageml_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE mageml ALTER COLUMN mageml_id SET DEFAULT nextval('generic_chado.mageml_mageml_id_seq'::regclass);


--
-- Name: organism_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE organism ALTER COLUMN organism_id SET DEFAULT nextval('generic_chado.organism_organism_id_seq'::regclass);


--
-- Name: organism_dbxref_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE organism_dbxref ALTER COLUMN organism_dbxref_id SET DEFAULT nextval('generic_chado.organism_dbxref_organism_dbxref_id_seq'::regclass);


--
-- Name: organismprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE organismprop ALTER COLUMN organismprop_id SET DEFAULT nextval('generic_chado.organismprop_organismprop_id_seq'::regclass);


--
-- Name: phendesc_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phendesc ALTER COLUMN phendesc_id SET DEFAULT nextval('generic_chado.phendesc_phendesc_id_seq'::regclass);


--
-- Name: phenotype_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phenotype ALTER COLUMN phenotype_id SET DEFAULT nextval('generic_chado.phenotype_phenotype_id_seq'::regclass);


--
-- Name: phenotype_comparison_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phenotype_comparison ALTER COLUMN phenotype_comparison_id SET DEFAULT nextval('generic_chado.phenotype_comparison_phenotype_comparison_id_seq'::regclass);


--
-- Name: phenotype_cvterm_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phenotype_cvterm ALTER COLUMN phenotype_cvterm_id SET DEFAULT nextval('generic_chado.phenotype_cvterm_phenotype_cvterm_id_seq'::regclass);


--
-- Name: phenstatement_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phenstatement ALTER COLUMN phenstatement_id SET DEFAULT nextval('generic_chado.phenstatement_phenstatement_id_seq'::regclass);


--
-- Name: phylonode_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phylonode ALTER COLUMN phylonode_id SET DEFAULT nextval('generic_chado.phylonode_phylonode_id_seq'::regclass);


--
-- Name: phylonode_dbxref_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phylonode_dbxref ALTER COLUMN phylonode_dbxref_id SET DEFAULT nextval('generic_chado.phylonode_dbxref_phylonode_dbxref_id_seq'::regclass);


--
-- Name: phylonode_organism_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phylonode_organism ALTER COLUMN phylonode_organism_id SET DEFAULT nextval('generic_chado.phylonode_organism_phylonode_organism_id_seq'::regclass);


--
-- Name: phylonode_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phylonode_pub ALTER COLUMN phylonode_pub_id SET DEFAULT nextval('generic_chado.phylonode_pub_phylonode_pub_id_seq'::regclass);


--
-- Name: phylonode_relationship_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phylonode_relationship ALTER COLUMN phylonode_relationship_id SET DEFAULT nextval('generic_chado.phylonode_relationship_phylonode_relationship_id_seq'::regclass);


--
-- Name: phylonodeprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phylonodeprop ALTER COLUMN phylonodeprop_id SET DEFAULT nextval('generic_chado.phylonodeprop_phylonodeprop_id_seq'::regclass);


--
-- Name: phylotree_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phylotree ALTER COLUMN phylotree_id SET DEFAULT nextval('generic_chado.phylotree_phylotree_id_seq'::regclass);


--
-- Name: phylotree_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE phylotree_pub ALTER COLUMN phylotree_pub_id SET DEFAULT nextval('generic_chado.phylotree_pub_phylotree_pub_id_seq'::regclass);


--
-- Name: project_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE project ALTER COLUMN project_id SET DEFAULT nextval('generic_chado.project_project_id_seq'::regclass);


--
-- Name: protocol_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE protocol ALTER COLUMN protocol_id SET DEFAULT nextval('generic_chado.protocol_protocol_id_seq'::regclass);


--
-- Name: protocol_attribute_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE protocol_attribute ALTER COLUMN protocol_attribute_id SET DEFAULT nextval('generic_chado.protocol_attribute_protocol_attribute_id_seq'::regclass);


--
-- Name: protocolparam_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE protocolparam ALTER COLUMN protocolparam_id SET DEFAULT nextval('generic_chado.protocolparam_protocolparam_id_seq'::regclass);


--
-- Name: pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE pub ALTER COLUMN pub_id SET DEFAULT nextval('generic_chado.pub_pub_id_seq'::regclass);


--
-- Name: pub_dbxref_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE pub_dbxref ALTER COLUMN pub_dbxref_id SET DEFAULT nextval('generic_chado.pub_dbxref_pub_dbxref_id_seq'::regclass);


--
-- Name: pub_relationship_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE pub_relationship ALTER COLUMN pub_relationship_id SET DEFAULT nextval('generic_chado.pub_relationship_pub_relationship_id_seq'::regclass);


--
-- Name: pubauthor_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE pubauthor ALTER COLUMN pubauthor_id SET DEFAULT nextval('generic_chado.pubauthor_pubauthor_id_seq'::regclass);


--
-- Name: pubprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE pubprop ALTER COLUMN pubprop_id SET DEFAULT nextval('generic_chado.pubprop_pubprop_id_seq'::regclass);


--
-- Name: quantification_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE quantification ALTER COLUMN quantification_id SET DEFAULT nextval('generic_chado.quantification_quantification_id_seq'::regclass);


--
-- Name: quantification_relationship_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE quantification_relationship ALTER COLUMN quantification_relationship_id SET DEFAULT nextval('generic_chado.quantification_relationship_quantification_relationship_id_seq'::regclass);


--
-- Name: quantificationprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE quantificationprop ALTER COLUMN quantificationprop_id SET DEFAULT nextval('generic_chado.quantificationprop_quantificationprop_id_seq'::regclass);


--
-- Name: stock_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stock ALTER COLUMN stock_id SET DEFAULT nextval('generic_chado.stock_stock_id_seq'::regclass);


--
-- Name: stock_cvterm_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stock_cvterm ALTER COLUMN stock_cvterm_id SET DEFAULT nextval('generic_chado.stock_cvterm_stock_cvterm_id_seq'::regclass);


--
-- Name: stock_dbxref_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stock_dbxref ALTER COLUMN stock_dbxref_id SET DEFAULT nextval('generic_chado.stock_dbxref_stock_dbxref_id_seq'::regclass);


--
-- Name: stock_genotype_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stock_genotype ALTER COLUMN stock_genotype_id SET DEFAULT nextval('generic_chado.stock_genotype_stock_genotype_id_seq'::regclass);


--
-- Name: stock_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stock_pub ALTER COLUMN stock_pub_id SET DEFAULT nextval('generic_chado.stock_pub_stock_pub_id_seq'::regclass);


--
-- Name: stock_relationship_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stock_relationship ALTER COLUMN stock_relationship_id SET DEFAULT nextval('generic_chado.stock_relationship_stock_relationship_id_seq'::regclass);


--
-- Name: stock_relationship_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stock_relationship_pub ALTER COLUMN stock_relationship_pub_id SET DEFAULT nextval('generic_chado.stock_relationship_pub_stock_relationship_pub_id_seq'::regclass);


--
-- Name: stockcollection_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stockcollection ALTER COLUMN stockcollection_id SET DEFAULT nextval('generic_chado.stockcollection_stockcollection_id_seq'::regclass);


--
-- Name: stockcollection_stock_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stockcollection_stock ALTER COLUMN stockcollection_stock_id SET DEFAULT nextval('generic_chado.stockcollection_stock_stockcollection_stock_id_seq'::regclass);


--
-- Name: stockcollectionprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stockcollectionprop ALTER COLUMN stockcollectionprop_id SET DEFAULT nextval('generic_chado.stockcollectionprop_stockcollectionprop_id_seq'::regclass);


--
-- Name: stockprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stockprop ALTER COLUMN stockprop_id SET DEFAULT nextval('generic_chado.stockprop_stockprop_id_seq'::regclass);


--
-- Name: stockprop_pub_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE stockprop_pub ALTER COLUMN stockprop_pub_id SET DEFAULT nextval('generic_chado.stockprop_pub_stockprop_pub_id_seq'::regclass);


--
-- Name: study_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE study ALTER COLUMN study_id SET DEFAULT nextval('generic_chado.study_study_id_seq'::regclass);


--
-- Name: study_assay_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE study_assay ALTER COLUMN study_assay_id SET DEFAULT nextval('generic_chado.study_assay_study_assay_id_seq'::regclass);


--
-- Name: studydesign_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE studydesign ALTER COLUMN studydesign_id SET DEFAULT nextval('generic_chado.studydesign_studydesign_id_seq'::regclass);


--
-- Name: studydesignprop_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE studydesignprop ALTER COLUMN studydesignprop_id SET DEFAULT nextval('generic_chado.studydesignprop_studydesignprop_id_seq'::regclass);


--
-- Name: studyfactor_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE studyfactor ALTER COLUMN studyfactor_id SET DEFAULT nextval('generic_chado.studyfactor_studyfactor_id_seq'::regclass);


--
-- Name: studyfactorvalue_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE studyfactorvalue ALTER COLUMN studyfactorvalue_id SET DEFAULT nextval('generic_chado.studyfactorvalue_studyfactorvalue_id_seq'::regclass);


--
-- Name: synonym_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE synonym ALTER COLUMN synonym_id SET DEFAULT nextval('generic_chado.synonym_synonym_id_seq'::regclass);


--
-- Name: tableinfo_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE tableinfo ALTER COLUMN tableinfo_id SET DEFAULT nextval('generic_chado.tableinfo_tableinfo_id_seq'::regclass);


--
-- Name: treatment_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE treatment ALTER COLUMN treatment_id SET DEFAULT nextval('generic_chado.treatment_treatment_id_seq'::regclass);


--
-- Name: wiggle_data_id; Type: DEFAULT; Schema: $temporary_chado_schema_name$; Owner: -
--

-- ALTER TABLE wiggle_data ALTER COLUMN wiggle_data_id SET DEFAULT nextval('generic_chado.wiggle_data_wiggle_data_id_seq'::regclass);


--
-- Name: acquisition_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY acquisition
    ADD CONSTRAINT acquisition_c1 UNIQUE (name);

CREATE FUNCTION $temporary_chado_schema_name$_data.acquisition_assay_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT assay_id FROM $temporary_chado_schema_name$_data.assay WHERE assay_id = NEW.assay_id LIMIT 1) IS NULL) THEN
      INSERT INTO assay (SELECT * FROM public.assay WHERE public.assay.assay_id = NEW.assay_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.acquisition_channel_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT channel_id FROM $temporary_chado_schema_name$_data.channel WHERE channel_id = NEW.channel_id LIMIT 1) IS NULL) THEN
      INSERT INTO channel (SELECT * FROM public.channel WHERE public.channel.channel_id = NEW.channel_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.acquisition_relationship_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT acquisition_id FROM $temporary_chado_schema_name$_data.acquisition WHERE acquisition_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO acquisition (SELECT * FROM public.acquisition WHERE public.acquisition.acquisition_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.acquisition_relationship_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT acquisition_id FROM $temporary_chado_schema_name$_data.acquisition WHERE acquisition_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO acquisition (SELECT * FROM public.acquisition WHERE public.acquisition.acquisition_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.acquisition_relationship_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.acquisitionprop_acquisition_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT acquisition_id FROM $temporary_chado_schema_name$_data.acquisition WHERE acquisition_id = NEW.acquisition_id LIMIT 1) IS NULL) THEN
      INSERT INTO acquisition (SELECT * FROM public.acquisition WHERE public.acquisition.acquisition_id = NEW.acquisition_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.acquisitionprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.analysisfeature_analysis_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT analysis_id FROM $temporary_chado_schema_name$_data.analysis WHERE analysis_id = NEW.analysis_id LIMIT 1) IS NULL) THEN
      INSERT INTO analysis (SELECT * FROM public.analysis WHERE public.analysis.analysis_id = NEW.analysis_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.analysisfeature_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.analysisprop_analysis_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT analysis_id FROM $temporary_chado_schema_name$_data.analysis WHERE analysis_id = NEW.analysis_id LIMIT 1) IS NULL) THEN
      INSERT INTO analysis (SELECT * FROM public.analysis WHERE public.analysis.analysis_id = NEW.analysis_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.analysisprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.applied_protocol_data_applied_protocol_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT applied_protocol_id FROM $temporary_chado_schema_name$_data.applied_protocol WHERE applied_protocol_id = NEW.applied_protocol_id LIMIT 1) IS NULL) THEN
      INSERT INTO applied_protocol (SELECT * FROM public.applied_protocol WHERE public.applied_protocol.applied_protocol_id = NEW.applied_protocol_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.applied_protocol_data_data_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT data_id FROM $temporary_chado_schema_name$_data.data WHERE data_id = NEW.data_id LIMIT 1) IS NULL) THEN
      INSERT INTO data (SELECT * FROM public.data WHERE public.data.data_id = NEW.data_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.applied_protocol_protocol_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT protocol_id FROM $temporary_chado_schema_name$_data.protocol WHERE protocol_id = NEW.protocol_id LIMIT 1) IS NULL) THEN
      INSERT INTO protocol (SELECT * FROM public.protocol WHERE public.protocol.protocol_id = NEW.protocol_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.arraydesign_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.arraydesign_manufacturer_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT contact_id FROM $temporary_chado_schema_name$_data.contact WHERE contact_id = NEW.manufacturer_id LIMIT 1) IS NULL) THEN
      INSERT INTO contact (SELECT * FROM public.contact WHERE public.contact.contact_id = NEW.manufacturer_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.arraydesign_platformtype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.platformtype_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.platformtype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.arraydesign_substratetype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.substratetype_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.substratetype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.arraydesignprop_arraydesign_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT arraydesign_id FROM $temporary_chado_schema_name$_data.arraydesign WHERE arraydesign_id = NEW.arraydesign_id LIMIT 1) IS NULL) THEN
      INSERT INTO arraydesign (SELECT * FROM public.arraydesign WHERE public.arraydesign.arraydesign_id = NEW.arraydesign_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.arraydesignprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.assay_arraydesign_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT arraydesign_id FROM $temporary_chado_schema_name$_data.arraydesign WHERE arraydesign_id = NEW.arraydesign_id LIMIT 1) IS NULL) THEN
      INSERT INTO arraydesign (SELECT * FROM public.arraydesign WHERE public.arraydesign.arraydesign_id = NEW.arraydesign_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.assay_biomaterial_assay_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT assay_id FROM $temporary_chado_schema_name$_data.assay WHERE assay_id = NEW.assay_id LIMIT 1) IS NULL) THEN
      INSERT INTO assay (SELECT * FROM public.assay WHERE public.assay.assay_id = NEW.assay_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.assay_biomaterial_biomaterial_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT biomaterial_id FROM $temporary_chado_schema_name$_data.biomaterial WHERE biomaterial_id = NEW.biomaterial_id LIMIT 1) IS NULL) THEN
      INSERT INTO biomaterial (SELECT * FROM public.biomaterial WHERE public.biomaterial.biomaterial_id = NEW.biomaterial_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.assay_biomaterial_channel_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT channel_id FROM $temporary_chado_schema_name$_data.channel WHERE channel_id = NEW.channel_id LIMIT 1) IS NULL) THEN
      INSERT INTO channel (SELECT * FROM public.channel WHERE public.channel.channel_id = NEW.channel_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.assay_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.assay_operator_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT contact_id FROM $temporary_chado_schema_name$_data.contact WHERE contact_id = NEW.operator_id LIMIT 1) IS NULL) THEN
      INSERT INTO contact (SELECT * FROM public.contact WHERE public.contact.contact_id = NEW.operator_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.assay_project_assay_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT assay_id FROM $temporary_chado_schema_name$_data.assay WHERE assay_id = NEW.assay_id LIMIT 1) IS NULL) THEN
      INSERT INTO assay (SELECT * FROM public.assay WHERE public.assay.assay_id = NEW.assay_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.assay_project_project_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT project_id FROM $temporary_chado_schema_name$_data.project WHERE project_id = NEW.project_id LIMIT 1) IS NULL) THEN
      INSERT INTO project (SELECT * FROM public.project WHERE public.project.project_id = NEW.project_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.assayprop_assay_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT assay_id FROM $temporary_chado_schema_name$_data.assay WHERE assay_id = NEW.assay_id LIMIT 1) IS NULL) THEN
      INSERT INTO assay (SELECT * FROM public.assay WHERE public.assay.assay_id = NEW.assay_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.assayprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.attribute_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.attribute_organism_attribute_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT attribute_id FROM $temporary_chado_schema_name$_data.attribute WHERE attribute_id = NEW.attribute_id LIMIT 1) IS NULL) THEN
      INSERT INTO attribute (SELECT * FROM public.attribute WHERE public.attribute.attribute_id = NEW.attribute_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.attribute_organism_organism_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT organism_id FROM $temporary_chado_schema_name$_data.organism WHERE organism_id = NEW.organism_id LIMIT 1) IS NULL) THEN
      INSERT INTO organism (SELECT * FROM public.organism WHERE public.organism.organism_id = NEW.organism_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.attribute_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterial_biosourceprovider_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT contact_id FROM $temporary_chado_schema_name$_data.contact WHERE contact_id = NEW.biosourceprovider_id LIMIT 1) IS NULL) THEN
      INSERT INTO contact (SELECT * FROM public.contact WHERE public.contact.contact_id = NEW.biosourceprovider_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterial_dbxref_biomaterial_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT biomaterial_id FROM $temporary_chado_schema_name$_data.biomaterial WHERE biomaterial_id = NEW.biomaterial_id LIMIT 1) IS NULL) THEN
      INSERT INTO biomaterial (SELECT * FROM public.biomaterial WHERE public.biomaterial.biomaterial_id = NEW.biomaterial_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterial_dbxref_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterial_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterial_relationship_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT biomaterial_id FROM $temporary_chado_schema_name$_data.biomaterial WHERE biomaterial_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO biomaterial (SELECT * FROM public.biomaterial WHERE public.biomaterial.biomaterial_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterial_relationship_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT biomaterial_id FROM $temporary_chado_schema_name$_data.biomaterial WHERE biomaterial_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO biomaterial (SELECT * FROM public.biomaterial WHERE public.biomaterial.biomaterial_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterial_relationship_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterial_taxon_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT organism_id FROM $temporary_chado_schema_name$_data.organism WHERE organism_id = NEW.taxon_id LIMIT 1) IS NULL) THEN
      INSERT INTO organism (SELECT * FROM public.organism WHERE public.organism.organism_id = NEW.taxon_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterial_treatment_biomaterial_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT biomaterial_id FROM $temporary_chado_schema_name$_data.biomaterial WHERE biomaterial_id = NEW.biomaterial_id LIMIT 1) IS NULL) THEN
      INSERT INTO biomaterial (SELECT * FROM public.biomaterial WHERE public.biomaterial.biomaterial_id = NEW.biomaterial_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterial_treatment_treatment_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT treatment_id FROM $temporary_chado_schema_name$_data.treatment WHERE treatment_id = NEW.treatment_id LIMIT 1) IS NULL) THEN
      INSERT INTO treatment (SELECT * FROM public.treatment WHERE public.treatment.treatment_id = NEW.treatment_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterial_treatment_unittype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.unittype_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.unittype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterialprop_biomaterial_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT biomaterial_id FROM $temporary_chado_schema_name$_data.biomaterial WHERE biomaterial_id = NEW.biomaterial_id LIMIT 1) IS NULL) THEN
      INSERT INTO biomaterial (SELECT * FROM public.biomaterial WHERE public.biomaterial.biomaterial_id = NEW.biomaterial_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.biomaterialprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.contact_relationship_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT contact_id FROM $temporary_chado_schema_name$_data.contact WHERE contact_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO contact (SELECT * FROM public.contact WHERE public.contact.contact_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.contact_relationship_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT contact_id FROM $temporary_chado_schema_name$_data.contact WHERE contact_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO contact (SELECT * FROM public.contact WHERE public.contact.contact_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.contact_relationship_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.contact_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.contactprop_contact_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT contact_id FROM $temporary_chado_schema_name$_data.contact WHERE contact_id = NEW.contact_id LIMIT 1) IS NULL) THEN
      INSERT INTO contact (SELECT * FROM public.contact WHERE public.contact.contact_id = NEW.contact_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.contactprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.control_assay_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT assay_id FROM $temporary_chado_schema_name$_data.assay WHERE assay_id = NEW.assay_id LIMIT 1) IS NULL) THEN
      INSERT INTO assay (SELECT * FROM public.assay WHERE public.assay.assay_id = NEW.assay_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.control_tableinfo_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT tableinfo_id FROM $temporary_chado_schema_name$_data.tableinfo WHERE tableinfo_id = NEW.tableinfo_id LIMIT 1) IS NULL) THEN
      INSERT INTO tableinfo (SELECT * FROM public.tableinfo WHERE public.tableinfo.tableinfo_id = NEW.tableinfo_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.control_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvterm_cv_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cv_id FROM $temporary_chado_schema_name$_data.cv WHERE cv_id = NEW.cv_id LIMIT 1) IS NULL) THEN
      INSERT INTO cv (SELECT * FROM public.cv WHERE public.cv.cv_id = NEW.cv_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvterm_dbxref_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvterm_dbxref_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvterm_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvterm_relationship_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvterm_relationship_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvterm_relationship_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvtermpath_cv_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cv_id FROM $temporary_chado_schema_name$_data.cv WHERE cv_id = NEW.cv_id LIMIT 1) IS NULL) THEN
      INSERT INTO cv (SELECT * FROM public.cv WHERE public.cv.cv_id = NEW.cv_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvtermpath_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvtermpath_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvtermpath_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvtermprop_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvtermprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvtermsynonym_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.cvtermsynonym_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.data_attribute_attribute_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT attribute_id FROM $temporary_chado_schema_name$_data.attribute WHERE attribute_id = NEW.attribute_id LIMIT 1) IS NULL) THEN
      INSERT INTO attribute (SELECT * FROM public.attribute WHERE public.attribute.attribute_id = NEW.attribute_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.data_attribute_data_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT data_id FROM $temporary_chado_schema_name$_data.data WHERE data_id = NEW.data_id LIMIT 1) IS NULL) THEN
      INSERT INTO data (SELECT * FROM public.data WHERE public.data.data_id = NEW.data_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.data_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.data_feature_data_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT data_id FROM $temporary_chado_schema_name$_data.data WHERE data_id = NEW.data_id LIMIT 1) IS NULL) THEN
      INSERT INTO data (SELECT * FROM public.data WHERE public.data.data_id = NEW.data_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.data_feature_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.data_organism_data_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT data_id FROM $temporary_chado_schema_name$_data.data WHERE data_id = NEW.data_id LIMIT 1) IS NULL) THEN
      INSERT INTO data (SELECT * FROM public.data WHERE public.data.data_id = NEW.data_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.data_organism_organism_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT organism_id FROM $temporary_chado_schema_name$_data.organism WHERE organism_id = NEW.organism_id LIMIT 1) IS NULL) THEN
      INSERT INTO organism (SELECT * FROM public.organism WHERE public.organism.organism_id = NEW.organism_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.data_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.data_wiggle_data_data_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT data_id FROM $temporary_chado_schema_name$_data.data WHERE data_id = NEW.data_id LIMIT 1) IS NULL) THEN
      INSERT INTO data (SELECT * FROM public.data WHERE public.data.data_id = NEW.data_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.data_wiggle_data_wiggle_data_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT wiggle_data_id FROM $temporary_chado_schema_name$_data.wiggle_data WHERE wiggle_data_id = NEW.wiggle_data_id LIMIT 1) IS NULL) THEN
      INSERT INTO wiggle_data (SELECT * FROM public.wiggle_data WHERE public.wiggle_data.wiggle_data_id = NEW.wiggle_data_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.dbxref_db_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT db_id FROM $temporary_chado_schema_name$_data.db WHERE db_id = NEW.db_id LIMIT 1) IS NULL) THEN
      INSERT INTO db (SELECT * FROM public.db WHERE public.db.db_id = NEW.db_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.dbxrefprop_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.dbxrefprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.element_arraydesign_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT arraydesign_id FROM $temporary_chado_schema_name$_data.arraydesign WHERE arraydesign_id = NEW.arraydesign_id LIMIT 1) IS NULL) THEN
      INSERT INTO arraydesign (SELECT * FROM public.arraydesign WHERE public.arraydesign.arraydesign_id = NEW.arraydesign_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.element_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.element_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.element_relationship_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT element_id FROM $temporary_chado_schema_name$_data.element WHERE element_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO element (SELECT * FROM public.element WHERE public.element.element_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.element_relationship_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT element_id FROM $temporary_chado_schema_name$_data.element WHERE element_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO element (SELECT * FROM public.element WHERE public.element.element_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.element_relationship_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.element_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.elementresult_element_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT element_id FROM $temporary_chado_schema_name$_data.element WHERE element_id = NEW.element_id LIMIT 1) IS NULL) THEN
      INSERT INTO element (SELECT * FROM public.element WHERE public.element.element_id = NEW.element_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.elementresult_quantification_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT quantification_id FROM $temporary_chado_schema_name$_data.quantification WHERE quantification_id = NEW.quantification_id LIMIT 1) IS NULL) THEN
      INSERT INTO quantification (SELECT * FROM public.quantification WHERE public.quantification.quantification_id = NEW.quantification_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.elementresult_relationship_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT elementresult_id FROM $temporary_chado_schema_name$_data.elementresult WHERE elementresult_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO elementresult (SELECT * FROM public.elementresult WHERE public.elementresult.elementresult_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.elementresult_relationship_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT elementresult_id FROM $temporary_chado_schema_name$_data.elementresult WHERE elementresult_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO elementresult (SELECT * FROM public.elementresult WHERE public.elementresult.elementresult_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.elementresult_relationship_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.environment_cvterm_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.environment_cvterm_environment_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT environment_id FROM $temporary_chado_schema_name$_data.environment WHERE environment_id = NEW.environment_id LIMIT 1) IS NULL) THEN
      INSERT INTO environment (SELECT * FROM public.environment WHERE public.environment.environment_id = NEW.environment_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.experiment_applied_protocol_experiment_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT experiment_id FROM $temporary_chado_schema_name$_data.experiment WHERE experiment_id = NEW.experiment_id LIMIT 1) IS NULL) THEN
      INSERT INTO experiment (SELECT * FROM public.experiment WHERE public.experiment.experiment_id = NEW.experiment_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.experiment_applied_protocol_first_applied_protocol_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT applied_protocol_id FROM $temporary_chado_schema_name$_data.applied_protocol WHERE applied_protocol_id = NEW.first_applied_protocol_id LIMIT 1) IS NULL) THEN
      INSERT INTO applied_protocol (SELECT * FROM public.applied_protocol WHERE public.applied_protocol.applied_protocol_id = NEW.first_applied_protocol_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.experiment_prop_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.experiment_prop_experiment_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT experiment_id FROM $temporary_chado_schema_name$_data.experiment WHERE experiment_id = NEW.experiment_id LIMIT 1) IS NULL) THEN
      INSERT INTO experiment (SELECT * FROM public.experiment WHERE public.experiment.experiment_id = NEW.experiment_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.experiment_prop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.expression_cvterm_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.expression_cvterm_cvterm_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvterm_type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvterm_type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.expression_cvterm_expression_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT expression_id FROM $temporary_chado_schema_name$_data.expression WHERE expression_id = NEW.expression_id LIMIT 1) IS NULL) THEN
      INSERT INTO expression (SELECT * FROM public.expression WHERE public.expression.expression_id = NEW.expression_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.expression_cvtermprop_expression_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT expression_cvterm_id FROM $temporary_chado_schema_name$_data.expression_cvterm WHERE expression_cvterm_id = NEW.expression_cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO expression_cvterm (SELECT * FROM public.expression_cvterm WHERE public.expression_cvterm.expression_cvterm_id = NEW.expression_cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.expression_cvtermprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.expression_image_eimage_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT eimage_id FROM $temporary_chado_schema_name$_data.eimage WHERE eimage_id = NEW.eimage_id LIMIT 1) IS NULL) THEN
      INSERT INTO eimage (SELECT * FROM public.eimage WHERE public.eimage.eimage_id = NEW.eimage_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.expression_image_expression_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT expression_id FROM $temporary_chado_schema_name$_data.expression WHERE expression_id = NEW.expression_id LIMIT 1) IS NULL) THEN
      INSERT INTO expression (SELECT * FROM public.expression WHERE public.expression.expression_id = NEW.expression_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.expression_pub_expression_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT expression_id FROM $temporary_chado_schema_name$_data.expression WHERE expression_id = NEW.expression_id LIMIT 1) IS NULL) THEN
      INSERT INTO expression (SELECT * FROM public.expression WHERE public.expression.expression_id = NEW.expression_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.expression_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.expressionprop_expression_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT expression_id FROM $temporary_chado_schema_name$_data.expression WHERE expression_id = NEW.expression_id LIMIT 1) IS NULL) THEN
      INSERT INTO expression (SELECT * FROM public.expression WHERE public.expression.expression_id = NEW.expression_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.expressionprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_cvterm_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_cvterm_dbxref_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_cvterm_dbxref_feature_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_cvterm_id FROM $temporary_chado_schema_name$_data.feature_cvterm WHERE feature_cvterm_id = NEW.feature_cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature_cvterm (SELECT * FROM public.feature_cvterm WHERE public.feature_cvterm.feature_cvterm_id = NEW.feature_cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_cvterm_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_cvterm_pub_feature_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_cvterm_id FROM $temporary_chado_schema_name$_data.feature_cvterm WHERE feature_cvterm_id = NEW.feature_cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature_cvterm (SELECT * FROM public.feature_cvterm WHERE public.feature_cvterm.feature_cvterm_id = NEW.feature_cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_cvterm_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_cvterm_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_cvtermprop_feature_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_cvterm_id FROM $temporary_chado_schema_name$_data.feature_cvterm WHERE feature_cvterm_id = NEW.feature_cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature_cvterm (SELECT * FROM public.feature_cvterm WHERE public.feature_cvterm.feature_cvterm_id = NEW.feature_cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_cvtermprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_dbxref_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_dbxref_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_expression_expression_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT expression_id FROM $temporary_chado_schema_name$_data.expression WHERE expression_id = NEW.expression_id LIMIT 1) IS NULL) THEN
      INSERT INTO expression (SELECT * FROM public.expression WHERE public.expression.expression_id = NEW.expression_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_expression_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_expression_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_expressionprop_feature_expression_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_expression_id FROM $temporary_chado_schema_name$_data.feature_expression WHERE feature_expression_id = NEW.feature_expression_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature_expression (SELECT * FROM public.feature_expression WHERE public.feature_expression.feature_expression_id = NEW.feature_expression_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_expressionprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_genotype_chromosome_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.chromosome_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.chromosome_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_genotype_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_genotype_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_genotype_genotype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT genotype_id FROM $temporary_chado_schema_name$_data.genotype WHERE genotype_id = NEW.genotype_id LIMIT 1) IS NULL) THEN
      INSERT INTO genotype (SELECT * FROM public.genotype WHERE public.genotype.genotype_id = NEW.genotype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_organism_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT organism_id FROM $temporary_chado_schema_name$_data.organism WHERE organism_id = NEW.organism_id LIMIT 1) IS NULL) THEN
      INSERT INTO organism (SELECT * FROM public.organism WHERE public.organism.organism_id = NEW.organism_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_phenotype_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_phenotype_phenotype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phenotype_id FROM $temporary_chado_schema_name$_data.phenotype WHERE phenotype_id = NEW.phenotype_id LIMIT 1) IS NULL) THEN
      INSERT INTO phenotype (SELECT * FROM public.phenotype WHERE public.phenotype.phenotype_id = NEW.phenotype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_pub_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_pubprop_feature_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_pub_id FROM $temporary_chado_schema_name$_data.feature_pub WHERE feature_pub_id = NEW.feature_pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature_pub (SELECT * FROM public.feature_pub WHERE public.feature_pub.feature_pub_id = NEW.feature_pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_pubprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_relationship_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_relationship_pub_feature_relationship_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_relationship_id FROM $temporary_chado_schema_name$_data.feature_relationship WHERE feature_relationship_id = NEW.feature_relationship_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature_relationship (SELECT * FROM public.feature_relationship WHERE public.feature_relationship.feature_relationship_id = NEW.feature_relationship_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_relationship_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_relationship_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_relationship_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_relationshipprop_feature_relationship_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_relationship_id FROM $temporary_chado_schema_name$_data.feature_relationship WHERE feature_relationship_id = NEW.feature_relationship_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature_relationship (SELECT * FROM public.feature_relationship WHERE public.feature_relationship.feature_relationship_id = NEW.feature_relationship_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_relationshipprop_pub_feature_relationshipprop_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_relationshipprop_id FROM $temporary_chado_schema_name$_data.feature_relationshipprop WHERE feature_relationshipprop_id = NEW.feature_relationshipprop_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature_relationshipprop (SELECT * FROM public.feature_relationshipprop WHERE public.feature_relationshipprop.feature_relationshipprop_id = NEW.feature_relationshipprop_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_relationshipprop_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_relationshipprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_synonym_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_synonym_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_synonym_synonym_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT synonym_id FROM $temporary_chado_schema_name$_data.synonym WHERE synonym_id = NEW.synonym_id LIMIT 1) IS NULL) THEN
      INSERT INTO synonym (SELECT * FROM public.synonym WHERE public.synonym.synonym_id = NEW.synonym_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.feature_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featureloc_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featureloc_pub_featureloc_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT featureloc_id FROM $temporary_chado_schema_name$_data.featureloc WHERE featureloc_id = NEW.featureloc_id LIMIT 1) IS NULL) THEN
      INSERT INTO featureloc (SELECT * FROM public.featureloc WHERE public.featureloc.featureloc_id = NEW.featureloc_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featureloc_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featureloc_srcfeature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.srcfeature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.srcfeature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featuremap_pub_featuremap_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT featuremap_id FROM $temporary_chado_schema_name$_data.featuremap WHERE featuremap_id = NEW.featuremap_id LIMIT 1) IS NULL) THEN
      INSERT INTO featuremap (SELECT * FROM public.featuremap WHERE public.featuremap.featuremap_id = NEW.featuremap_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featuremap_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featuremap_unittype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.unittype_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.unittype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featurepos_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featurepos_featuremap_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT featuremap_id FROM $temporary_chado_schema_name$_data.featuremap WHERE featuremap_id = NEW.featuremap_id LIMIT 1) IS NULL) THEN
      INSERT INTO featuremap (SELECT * FROM public.featuremap WHERE public.featuremap.featuremap_id = NEW.featuremap_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featurepos_map_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.map_feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.map_feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featureprop_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featureprop_pub_featureprop_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT featureprop_id FROM $temporary_chado_schema_name$_data.featureprop WHERE featureprop_id = NEW.featureprop_id LIMIT 1) IS NULL) THEN
      INSERT INTO featureprop (SELECT * FROM public.featureprop WHERE public.featureprop.featureprop_id = NEW.featureprop_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featureprop_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featureprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featurerange_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featurerange_featuremap_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT featuremap_id FROM $temporary_chado_schema_name$_data.featuremap WHERE featuremap_id = NEW.featuremap_id LIMIT 1) IS NULL) THEN
      INSERT INTO featuremap (SELECT * FROM public.featuremap WHERE public.featuremap.featuremap_id = NEW.featuremap_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featurerange_leftendf_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.leftendf_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.leftendf_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featurerange_leftstartf_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.leftstartf_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.leftstartf_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featurerange_rightendf_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.rightendf_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.rightendf_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.featurerange_rightstartf_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.rightstartf_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.rightstartf_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_cvterm_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_cvterm_library_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT library_id FROM $temporary_chado_schema_name$_data.library WHERE library_id = NEW.library_id LIMIT 1) IS NULL) THEN
      INSERT INTO library (SELECT * FROM public.library WHERE public.library.library_id = NEW.library_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_cvterm_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_feature_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_feature_library_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT library_id FROM $temporary_chado_schema_name$_data.library WHERE library_id = NEW.library_id LIMIT 1) IS NULL) THEN
      INSERT INTO library (SELECT * FROM public.library WHERE public.library.library_id = NEW.library_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_organism_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT organism_id FROM $temporary_chado_schema_name$_data.organism WHERE organism_id = NEW.organism_id LIMIT 1) IS NULL) THEN
      INSERT INTO organism (SELECT * FROM public.organism WHERE public.organism.organism_id = NEW.organism_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_pub_library_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT library_id FROM $temporary_chado_schema_name$_data.library WHERE library_id = NEW.library_id LIMIT 1) IS NULL) THEN
      INSERT INTO library (SELECT * FROM public.library WHERE public.library.library_id = NEW.library_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_synonym_library_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT library_id FROM $temporary_chado_schema_name$_data.library WHERE library_id = NEW.library_id LIMIT 1) IS NULL) THEN
      INSERT INTO library (SELECT * FROM public.library WHERE public.library.library_id = NEW.library_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_synonym_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_synonym_synonym_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT synonym_id FROM $temporary_chado_schema_name$_data.synonym WHERE synonym_id = NEW.synonym_id LIMIT 1) IS NULL) THEN
      INSERT INTO synonym (SELECT * FROM public.synonym WHERE public.synonym.synonym_id = NEW.synonym_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.library_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.libraryprop_library_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT library_id FROM $temporary_chado_schema_name$_data.library WHERE library_id = NEW.library_id LIMIT 1) IS NULL) THEN
      INSERT INTO library (SELECT * FROM public.library WHERE public.library.library_id = NEW.library_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.libraryprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.magedocumentation_mageml_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT mageml_id FROM $temporary_chado_schema_name$_data.mageml WHERE mageml_id = NEW.mageml_id LIMIT 1) IS NULL) THEN
      INSERT INTO mageml (SELECT * FROM public.mageml WHERE public.mageml.mageml_id = NEW.mageml_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.magedocumentation_tableinfo_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT tableinfo_id FROM $temporary_chado_schema_name$_data.tableinfo WHERE tableinfo_id = NEW.tableinfo_id LIMIT 1) IS NULL) THEN
      INSERT INTO tableinfo (SELECT * FROM public.tableinfo WHERE public.tableinfo.tableinfo_id = NEW.tableinfo_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.organism_dbxref_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.organism_dbxref_organism_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT organism_id FROM $temporary_chado_schema_name$_data.organism WHERE organism_id = NEW.organism_id LIMIT 1) IS NULL) THEN
      INSERT INTO organism (SELECT * FROM public.organism WHERE public.organism.organism_id = NEW.organism_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.organismprop_organism_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT organism_id FROM $temporary_chado_schema_name$_data.organism WHERE organism_id = NEW.organism_id LIMIT 1) IS NULL) THEN
      INSERT INTO organism (SELECT * FROM public.organism WHERE public.organism.organism_id = NEW.organism_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.organismprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phendesc_environment_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT environment_id FROM $temporary_chado_schema_name$_data.environment WHERE environment_id = NEW.environment_id LIMIT 1) IS NULL) THEN
      INSERT INTO environment (SELECT * FROM public.environment WHERE public.environment.environment_id = NEW.environment_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phendesc_genotype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT genotype_id FROM $temporary_chado_schema_name$_data.genotype WHERE genotype_id = NEW.genotype_id LIMIT 1) IS NULL) THEN
      INSERT INTO genotype (SELECT * FROM public.genotype WHERE public.genotype.genotype_id = NEW.genotype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phendesc_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phendesc_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_assay_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.assay_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.assay_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_attr_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.attr_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.attr_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_comparison_environment1_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT environment_id FROM $temporary_chado_schema_name$_data.environment WHERE environment_id = NEW.environment1_id LIMIT 1) IS NULL) THEN
      INSERT INTO environment (SELECT * FROM public.environment WHERE public.environment.environment_id = NEW.environment1_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_comparison_environment2_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT environment_id FROM $temporary_chado_schema_name$_data.environment WHERE environment_id = NEW.environment2_id LIMIT 1) IS NULL) THEN
      INSERT INTO environment (SELECT * FROM public.environment WHERE public.environment.environment_id = NEW.environment2_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_comparison_genotype1_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT genotype_id FROM $temporary_chado_schema_name$_data.genotype WHERE genotype_id = NEW.genotype1_id LIMIT 1) IS NULL) THEN
      INSERT INTO genotype (SELECT * FROM public.genotype WHERE public.genotype.genotype_id = NEW.genotype1_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_comparison_genotype2_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT genotype_id FROM $temporary_chado_schema_name$_data.genotype WHERE genotype_id = NEW.genotype2_id LIMIT 1) IS NULL) THEN
      INSERT INTO genotype (SELECT * FROM public.genotype WHERE public.genotype.genotype_id = NEW.genotype2_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_comparison_phenotype1_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phenotype_id FROM $temporary_chado_schema_name$_data.phenotype WHERE phenotype_id = NEW.phenotype1_id LIMIT 1) IS NULL) THEN
      INSERT INTO phenotype (SELECT * FROM public.phenotype WHERE public.phenotype.phenotype_id = NEW.phenotype1_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_comparison_phenotype2_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phenotype_id FROM $temporary_chado_schema_name$_data.phenotype WHERE phenotype_id = NEW.phenotype2_id LIMIT 1) IS NULL) THEN
      INSERT INTO phenotype (SELECT * FROM public.phenotype WHERE public.phenotype.phenotype_id = NEW.phenotype2_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_comparison_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_comparison_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_cvalue_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvalue_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvalue_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_cvterm_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_cvterm_phenotype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phenotype_id FROM $temporary_chado_schema_name$_data.phenotype WHERE phenotype_id = NEW.phenotype_id LIMIT 1) IS NULL) THEN
      INSERT INTO phenotype (SELECT * FROM public.phenotype WHERE public.phenotype.phenotype_id = NEW.phenotype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenotype_observable_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.observable_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.observable_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenstatement_environment_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT environment_id FROM $temporary_chado_schema_name$_data.environment WHERE environment_id = NEW.environment_id LIMIT 1) IS NULL) THEN
      INSERT INTO environment (SELECT * FROM public.environment WHERE public.environment.environment_id = NEW.environment_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenstatement_genotype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT genotype_id FROM $temporary_chado_schema_name$_data.genotype WHERE genotype_id = NEW.genotype_id LIMIT 1) IS NULL) THEN
      INSERT INTO genotype (SELECT * FROM public.genotype WHERE public.genotype.genotype_id = NEW.genotype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenstatement_phenotype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phenotype_id FROM $temporary_chado_schema_name$_data.phenotype WHERE phenotype_id = NEW.phenotype_id LIMIT 1) IS NULL) THEN
      INSERT INTO phenotype (SELECT * FROM public.phenotype WHERE public.phenotype.phenotype_id = NEW.phenotype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenstatement_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phenstatement_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_dbxref_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_dbxref_phylonode_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phylonode_id FROM $temporary_chado_schema_name$_data.phylonode WHERE phylonode_id = NEW.phylonode_id LIMIT 1) IS NULL) THEN
      INSERT INTO phylonode (SELECT * FROM public.phylonode WHERE public.phylonode.phylonode_id = NEW.phylonode_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_feature_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT feature_id FROM $temporary_chado_schema_name$_data.feature WHERE feature_id = NEW.feature_id LIMIT 1) IS NULL) THEN
      INSERT INTO feature (SELECT * FROM public.feature WHERE public.feature.feature_id = NEW.feature_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_organism_organism_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT organism_id FROM $temporary_chado_schema_name$_data.organism WHERE organism_id = NEW.organism_id LIMIT 1) IS NULL) THEN
      INSERT INTO organism (SELECT * FROM public.organism WHERE public.organism.organism_id = NEW.organism_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_organism_phylonode_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phylonode_id FROM $temporary_chado_schema_name$_data.phylonode WHERE phylonode_id = NEW.phylonode_id LIMIT 1) IS NULL) THEN
      INSERT INTO phylonode (SELECT * FROM public.phylonode WHERE public.phylonode.phylonode_id = NEW.phylonode_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_parent_phylonode_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phylonode_id FROM $temporary_chado_schema_name$_data.phylonode WHERE phylonode_id = NEW.parent_phylonode_id LIMIT 1) IS NULL) THEN
      INSERT INTO phylonode (SELECT * FROM public.phylonode WHERE public.phylonode.phylonode_id = NEW.parent_phylonode_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_phylotree_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phylotree_id FROM $temporary_chado_schema_name$_data.phylotree WHERE phylotree_id = NEW.phylotree_id LIMIT 1) IS NULL) THEN
      INSERT INTO phylotree (SELECT * FROM public.phylotree WHERE public.phylotree.phylotree_id = NEW.phylotree_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_pub_phylonode_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phylonode_id FROM $temporary_chado_schema_name$_data.phylonode WHERE phylonode_id = NEW.phylonode_id LIMIT 1) IS NULL) THEN
      INSERT INTO phylonode (SELECT * FROM public.phylonode WHERE public.phylonode.phylonode_id = NEW.phylonode_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_relationship_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phylonode_id FROM $temporary_chado_schema_name$_data.phylonode WHERE phylonode_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO phylonode (SELECT * FROM public.phylonode WHERE public.phylonode.phylonode_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_relationship_phylotree_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phylotree_id FROM $temporary_chado_schema_name$_data.phylotree WHERE phylotree_id = NEW.phylotree_id LIMIT 1) IS NULL) THEN
      INSERT INTO phylotree (SELECT * FROM public.phylotree WHERE public.phylotree.phylotree_id = NEW.phylotree_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_relationship_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phylonode_id FROM $temporary_chado_schema_name$_data.phylonode WHERE phylonode_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO phylonode (SELECT * FROM public.phylonode WHERE public.phylonode.phylonode_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_relationship_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonode_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonodeprop_phylonode_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phylonode_id FROM $temporary_chado_schema_name$_data.phylonode WHERE phylonode_id = NEW.phylonode_id LIMIT 1) IS NULL) THEN
      INSERT INTO phylonode (SELECT * FROM public.phylonode WHERE public.phylonode.phylonode_id = NEW.phylonode_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylonodeprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylotree_analysis_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT analysis_id FROM $temporary_chado_schema_name$_data.analysis WHERE analysis_id = NEW.analysis_id LIMIT 1) IS NULL) THEN
      INSERT INTO analysis (SELECT * FROM public.analysis WHERE public.analysis.analysis_id = NEW.analysis_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylotree_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylotree_pub_phylotree_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT phylotree_id FROM $temporary_chado_schema_name$_data.phylotree WHERE phylotree_id = NEW.phylotree_id LIMIT 1) IS NULL) THEN
      INSERT INTO phylotree (SELECT * FROM public.phylotree WHERE public.phylotree.phylotree_id = NEW.phylotree_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylotree_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.phylotree_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.protocol_attribute_attribute_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT attribute_id FROM $temporary_chado_schema_name$_data.attribute WHERE attribute_id = NEW.attribute_id LIMIT 1) IS NULL) THEN
      INSERT INTO attribute (SELECT * FROM public.attribute WHERE public.attribute.attribute_id = NEW.attribute_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.protocol_attribute_protocol_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT protocol_id FROM $temporary_chado_schema_name$_data.protocol WHERE protocol_id = NEW.protocol_id LIMIT 1) IS NULL) THEN
      INSERT INTO protocol (SELECT * FROM public.protocol WHERE public.protocol.protocol_id = NEW.protocol_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.protocol_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.protocolparam_datatype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.datatype_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.datatype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.protocolparam_unittype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.unittype_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.unittype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.pub_dbxref_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.pub_dbxref_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.pub_relationship_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.pub_relationship_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.pub_relationship_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.pub_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.pubauthor_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.pubprop_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.pubprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.quantification_acquisition_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT acquisition_id FROM $temporary_chado_schema_name$_data.acquisition WHERE acquisition_id = NEW.acquisition_id LIMIT 1) IS NULL) THEN
      INSERT INTO acquisition (SELECT * FROM public.acquisition WHERE public.acquisition.acquisition_id = NEW.acquisition_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.quantification_analysis_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT analysis_id FROM $temporary_chado_schema_name$_data.analysis WHERE analysis_id = NEW.analysis_id LIMIT 1) IS NULL) THEN
      INSERT INTO analysis (SELECT * FROM public.analysis WHERE public.analysis.analysis_id = NEW.analysis_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.quantification_operator_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT contact_id FROM $temporary_chado_schema_name$_data.contact WHERE contact_id = NEW.operator_id LIMIT 1) IS NULL) THEN
      INSERT INTO contact (SELECT * FROM public.contact WHERE public.contact.contact_id = NEW.operator_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.quantification_relationship_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT quantification_id FROM $temporary_chado_schema_name$_data.quantification WHERE quantification_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO quantification (SELECT * FROM public.quantification WHERE public.quantification.quantification_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.quantification_relationship_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT quantification_id FROM $temporary_chado_schema_name$_data.quantification WHERE quantification_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO quantification (SELECT * FROM public.quantification WHERE public.quantification.quantification_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.quantification_relationship_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.quantificationprop_quantification_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT quantification_id FROM $temporary_chado_schema_name$_data.quantification WHERE quantification_id = NEW.quantification_id LIMIT 1) IS NULL) THEN
      INSERT INTO quantification (SELECT * FROM public.quantification WHERE public.quantification.quantification_id = NEW.quantification_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.quantificationprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_cvterm_cvterm_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.cvterm_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.cvterm_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_cvterm_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_cvterm_stock_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stock_id FROM $temporary_chado_schema_name$_data.stock WHERE stock_id = NEW.stock_id LIMIT 1) IS NULL) THEN
      INSERT INTO stock (SELECT * FROM public.stock WHERE public.stock.stock_id = NEW.stock_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_dbxref_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_dbxref_stock_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stock_id FROM $temporary_chado_schema_name$_data.stock WHERE stock_id = NEW.stock_id LIMIT 1) IS NULL) THEN
      INSERT INTO stock (SELECT * FROM public.stock WHERE public.stock.stock_id = NEW.stock_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_genotype_genotype_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT genotype_id FROM $temporary_chado_schema_name$_data.genotype WHERE genotype_id = NEW.genotype_id LIMIT 1) IS NULL) THEN
      INSERT INTO genotype (SELECT * FROM public.genotype WHERE public.genotype.genotype_id = NEW.genotype_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_genotype_stock_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stock_id FROM $temporary_chado_schema_name$_data.stock WHERE stock_id = NEW.stock_id LIMIT 1) IS NULL) THEN
      INSERT INTO stock (SELECT * FROM public.stock WHERE public.stock.stock_id = NEW.stock_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_organism_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT organism_id FROM $temporary_chado_schema_name$_data.organism WHERE organism_id = NEW.organism_id LIMIT 1) IS NULL) THEN
      INSERT INTO organism (SELECT * FROM public.organism WHERE public.organism.organism_id = NEW.organism_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_pub_stock_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stock_id FROM $temporary_chado_schema_name$_data.stock WHERE stock_id = NEW.stock_id LIMIT 1) IS NULL) THEN
      INSERT INTO stock (SELECT * FROM public.stock WHERE public.stock.stock_id = NEW.stock_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_relationship_object_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stock_id FROM $temporary_chado_schema_name$_data.stock WHERE stock_id = NEW.object_id LIMIT 1) IS NULL) THEN
      INSERT INTO stock (SELECT * FROM public.stock WHERE public.stock.stock_id = NEW.object_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_relationship_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_relationship_pub_stock_relationship_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stock_relationship_id FROM $temporary_chado_schema_name$_data.stock_relationship WHERE stock_relationship_id = NEW.stock_relationship_id LIMIT 1) IS NULL) THEN
      INSERT INTO stock_relationship (SELECT * FROM public.stock_relationship WHERE public.stock_relationship.stock_relationship_id = NEW.stock_relationship_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_relationship_subject_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stock_id FROM $temporary_chado_schema_name$_data.stock WHERE stock_id = NEW.subject_id LIMIT 1) IS NULL) THEN
      INSERT INTO stock (SELECT * FROM public.stock WHERE public.stock.stock_id = NEW.subject_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_relationship_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stock_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stockcollection_contact_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT contact_id FROM $temporary_chado_schema_name$_data.contact WHERE contact_id = NEW.contact_id LIMIT 1) IS NULL) THEN
      INSERT INTO contact (SELECT * FROM public.contact WHERE public.contact.contact_id = NEW.contact_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stockcollection_stock_stock_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stock_id FROM $temporary_chado_schema_name$_data.stock WHERE stock_id = NEW.stock_id LIMIT 1) IS NULL) THEN
      INSERT INTO stock (SELECT * FROM public.stock WHERE public.stock.stock_id = NEW.stock_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stockcollection_stock_stockcollection_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stockcollection_id FROM $temporary_chado_schema_name$_data.stockcollection WHERE stockcollection_id = NEW.stockcollection_id LIMIT 1) IS NULL) THEN
      INSERT INTO stockcollection (SELECT * FROM public.stockcollection WHERE public.stockcollection.stockcollection_id = NEW.stockcollection_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stockcollection_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stockcollectionprop_stockcollection_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stockcollection_id FROM $temporary_chado_schema_name$_data.stockcollection WHERE stockcollection_id = NEW.stockcollection_id LIMIT 1) IS NULL) THEN
      INSERT INTO stockcollection (SELECT * FROM public.stockcollection WHERE public.stockcollection.stockcollection_id = NEW.stockcollection_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stockcollectionprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stockprop_pub_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stockprop_pub_stockprop_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stockprop_id FROM $temporary_chado_schema_name$_data.stockprop WHERE stockprop_id = NEW.stockprop_id LIMIT 1) IS NULL) THEN
      INSERT INTO stockprop (SELECT * FROM public.stockprop WHERE public.stockprop.stockprop_id = NEW.stockprop_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stockprop_stock_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT stock_id FROM $temporary_chado_schema_name$_data.stock WHERE stock_id = NEW.stock_id LIMIT 1) IS NULL) THEN
      INSERT INTO stock (SELECT * FROM public.stock WHERE public.stock.stock_id = NEW.stock_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.stockprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.study_assay_assay_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT assay_id FROM $temporary_chado_schema_name$_data.assay WHERE assay_id = NEW.assay_id LIMIT 1) IS NULL) THEN
      INSERT INTO assay (SELECT * FROM public.assay WHERE public.assay.assay_id = NEW.assay_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.study_assay_study_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT study_id FROM $temporary_chado_schema_name$_data.study WHERE study_id = NEW.study_id LIMIT 1) IS NULL) THEN
      INSERT INTO study (SELECT * FROM public.study WHERE public.study.study_id = NEW.study_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.study_contact_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT contact_id FROM $temporary_chado_schema_name$_data.contact WHERE contact_id = NEW.contact_id LIMIT 1) IS NULL) THEN
      INSERT INTO contact (SELECT * FROM public.contact WHERE public.contact.contact_id = NEW.contact_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.study_dbxref_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT dbxref_id FROM $temporary_chado_schema_name$_data.dbxref WHERE dbxref_id = NEW.dbxref_id LIMIT 1) IS NULL) THEN
      INSERT INTO dbxref (SELECT * FROM public.dbxref WHERE public.dbxref.dbxref_id = NEW.dbxref_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.study_pub_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT pub_id FROM $temporary_chado_schema_name$_data.pub WHERE pub_id = NEW.pub_id LIMIT 1) IS NULL) THEN
      INSERT INTO pub (SELECT * FROM public.pub WHERE public.pub.pub_id = NEW.pub_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.studydesign_study_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT study_id FROM $temporary_chado_schema_name$_data.study WHERE study_id = NEW.study_id LIMIT 1) IS NULL) THEN
      INSERT INTO study (SELECT * FROM public.study WHERE public.study.study_id = NEW.study_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.studydesignprop_studydesign_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT studydesign_id FROM $temporary_chado_schema_name$_data.studydesign WHERE studydesign_id = NEW.studydesign_id LIMIT 1) IS NULL) THEN
      INSERT INTO studydesign (SELECT * FROM public.studydesign WHERE public.studydesign.studydesign_id = NEW.studydesign_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.studydesignprop_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.studyfactor_studydesign_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT studydesign_id FROM $temporary_chado_schema_name$_data.studydesign WHERE studydesign_id = NEW.studydesign_id LIMIT 1) IS NULL) THEN
      INSERT INTO studydesign (SELECT * FROM public.studydesign WHERE public.studydesign.studydesign_id = NEW.studydesign_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.studyfactor_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.studyfactorvalue_assay_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT assay_id FROM $temporary_chado_schema_name$_data.assay WHERE assay_id = NEW.assay_id LIMIT 1) IS NULL) THEN
      INSERT INTO assay (SELECT * FROM public.assay WHERE public.assay.assay_id = NEW.assay_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.studyfactorvalue_studyfactor_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT studyfactor_id FROM $temporary_chado_schema_name$_data.studyfactor WHERE studyfactor_id = NEW.studyfactor_id LIMIT 1) IS NULL) THEN
      INSERT INTO studyfactor (SELECT * FROM public.studyfactor WHERE public.studyfactor.studyfactor_id = NEW.studyfactor_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.synonym_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.treatment_biomaterial_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT biomaterial_id FROM $temporary_chado_schema_name$_data.biomaterial WHERE biomaterial_id = NEW.biomaterial_id LIMIT 1) IS NULL) THEN
      INSERT INTO biomaterial (SELECT * FROM public.biomaterial WHERE public.biomaterial.biomaterial_id = NEW.biomaterial_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;

CREATE FUNCTION $temporary_chado_schema_name$_data.treatment_type_id_trigger_func() RETURNS TRIGGER AS $$
  BEGIN
    IF ((SELECT cvterm_id FROM $temporary_chado_schema_name$_data.cvterm WHERE cvterm_id = NEW.type_id LIMIT 1) IS NULL) THEN
      INSERT INTO cvterm (SELECT * FROM public.cvterm WHERE public.cvterm.cvterm_id = NEW.type_id);
    END IF;
    RETURN NEW;
  END
$$ LANGUAGE plpgsql;


--
-- Name: acquisition_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY acquisition
    ADD CONSTRAINT acquisition_pkey PRIMARY KEY (acquisition_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.acquisition AS SELECT * FROM $temporary_chado_schema_name$_data.acquisition UNION SELECT * FROM public.acquisition;
CREATE TRIGGER acquisition_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.acquisition
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.acquisition_pkey_trigger_func();
CREATE RULE acquisition_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.acquisition DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.acquisition VALUES(NEW.*)
  RETURNING acquisition.*;
CREATE RULE acquisition_update AS
  ON UPDATE TO $temporary_chado_schema_name$.acquisition DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.acquisition SET 
    acquisition_id = NEW.acquisition_id,
    assay_id = NEW.assay_id,
    protocol_id = NEW.protocol_id,
    channel_id = NEW.channel_id,
    acquisitiondate = NEW.acquisitiondate,
    name = NEW.name,
    uri = NEW.uri
  WHERE acquisition_id = NEW.acquisition_id
  RETURNING acquisition.*;


--
-- Name: acquisition_relationship_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY acquisition_relationship
    ADD CONSTRAINT acquisition_relationship_c1 UNIQUE (subject_id, object_id, type_id, rank);


--
-- Name: acquisition_relationship_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY acquisition_relationship
    ADD CONSTRAINT acquisition_relationship_pkey PRIMARY KEY (acquisition_relationship_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.acquisition_relationship AS SELECT * FROM $temporary_chado_schema_name$_data.acquisition_relationship UNION SELECT * FROM public.acquisition_relationship;
CREATE TRIGGER acquisition_relationship_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.acquisition_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.acquisition_relationship_pkey_trigger_func();
CREATE RULE acquisition_relationship_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.acquisition_relationship DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.acquisition_relationship VALUES(NEW.*)
  RETURNING acquisition_relationship.*;
CREATE RULE acquisition_relationship_update AS
  ON UPDATE TO $temporary_chado_schema_name$.acquisition_relationship DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.acquisition_relationship SET 
    acquisition_relationship_id = NEW.acquisition_relationship_id,
    subject_id = NEW.subject_id,
    type_id = NEW.type_id,
    object_id = NEW.object_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE acquisition_relationship_id = NEW.acquisition_relationship_id
  RETURNING acquisition_relationship.*;


--
-- Name: acquisitionprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY acquisitionprop
    ADD CONSTRAINT acquisitionprop_c1 UNIQUE (acquisition_id, type_id, rank);


--
-- Name: acquisitionprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY acquisitionprop
    ADD CONSTRAINT acquisitionprop_pkey PRIMARY KEY (acquisitionprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.acquisitionprop AS SELECT * FROM $temporary_chado_schema_name$_data.acquisitionprop UNION SELECT * FROM public.acquisitionprop;
CREATE TRIGGER acquisitionprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.acquisitionprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.acquisitionprop_pkey_trigger_func();
CREATE RULE acquisitionprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.acquisitionprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.acquisitionprop VALUES(NEW.*)
  RETURNING acquisitionprop.*;
CREATE RULE acquisitionprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.acquisitionprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.acquisitionprop SET 
    acquisitionprop_id = NEW.acquisitionprop_id,
    acquisition_id = NEW.acquisition_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE acquisitionprop_id = NEW.acquisitionprop_id
  RETURNING acquisitionprop.*;


--
-- Name: analysis_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY analysis
    ADD CONSTRAINT analysis_c1 UNIQUE (program, programversion, sourcename);


--
-- Name: analysis_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY analysis
    ADD CONSTRAINT analysis_pkey PRIMARY KEY (analysis_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.analysis AS SELECT * FROM $temporary_chado_schema_name$_data.analysis UNION SELECT * FROM public.analysis;
CREATE TRIGGER analysis_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.analysis
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.analysis_pkey_trigger_func();
CREATE RULE analysis_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.analysis DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.analysis VALUES(NEW.*)
  RETURNING analysis.*;
CREATE RULE analysis_update AS
  ON UPDATE TO $temporary_chado_schema_name$.analysis DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.analysis SET 
    analysis_id = NEW.analysis_id,
    name = NEW.name,
    description = NEW.description,
    program = NEW.program,
    programversion = NEW.programversion,
    algorithm = NEW.algorithm,
    sourcename = NEW.sourcename,
    sourceversion = NEW.sourceversion,
    sourceuri = NEW.sourceuri,
    timeexecuted = NEW.timeexecuted
  WHERE analysis_id = NEW.analysis_id
  RETURNING analysis.*;


--
-- Name: analysisfeature_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY analysisfeature
    ADD CONSTRAINT analysisfeature_c1 UNIQUE (feature_id, analysis_id);


--
-- Name: analysisfeature_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY analysisfeature
    ADD CONSTRAINT analysisfeature_pkey PRIMARY KEY (analysisfeature_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.analysisfeature AS SELECT * FROM $temporary_chado_schema_name$_data.analysisfeature UNION SELECT * FROM public.analysisfeature;
CREATE TRIGGER analysisfeature_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.analysisfeature
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.analysisfeature_pkey_trigger_func();
CREATE RULE analysisfeature_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.analysisfeature DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.analysisfeature VALUES(NEW.*)
  RETURNING analysisfeature.*;
CREATE RULE analysisfeature_update AS
  ON UPDATE TO $temporary_chado_schema_name$.analysisfeature DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.analysisfeature SET 
    analysisfeature_id = NEW.analysisfeature_id,
    feature_id = NEW.feature_id,
    analysis_id = NEW.analysis_id,
    rawscore = NEW.rawscore,
    normscore = NEW.normscore,
    significance = NEW.significance,
    identity = NEW.identity
  WHERE analysisfeature_id = NEW.analysisfeature_id
  RETURNING analysisfeature.*;


--
-- Name: analysisprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY analysisprop
    ADD CONSTRAINT analysisprop_c1 UNIQUE (analysis_id, type_id, value);


--
-- Name: analysisprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY analysisprop
    ADD CONSTRAINT analysisprop_pkey PRIMARY KEY (analysisprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.analysisprop AS SELECT * FROM $temporary_chado_schema_name$_data.analysisprop UNION SELECT * FROM public.analysisprop;
CREATE TRIGGER analysisprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.analysisprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.analysisprop_pkey_trigger_func();
CREATE RULE analysisprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.analysisprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.analysisprop VALUES(NEW.*)
  RETURNING analysisprop.*;
CREATE RULE analysisprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.analysisprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.analysisprop SET 
    analysisprop_id = NEW.analysisprop_id,
    analysis_id = NEW.analysis_id,
    type_id = NEW.type_id,
    value = NEW.value
  WHERE analysisprop_id = NEW.analysisprop_id
  RETURNING analysisprop.*;


--
-- Name: applied_protocol_applied_protocol_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY applied_protocol
    ADD CONSTRAINT applied_protocol_applied_protocol_id_key UNIQUE (applied_protocol_id, protocol_id);


--
-- Name: applied_protocol_data_applied_protocol_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY applied_protocol_data
    ADD CONSTRAINT applied_protocol_data_applied_protocol_id_key UNIQUE (applied_protocol_id, data_id, direction);


--
-- Name: applied_protocol_data_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY applied_protocol_data
    ADD CONSTRAINT applied_protocol_data_pkey PRIMARY KEY (applied_protocol_data_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.applied_protocol_data AS SELECT * FROM $temporary_chado_schema_name$_data.applied_protocol_data UNION SELECT * FROM public.applied_protocol_data;
CREATE TRIGGER applied_protocol_data_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.applied_protocol_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.applied_protocol_data_pkey_trigger_func();
CREATE RULE applied_protocol_data_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.applied_protocol_data DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.applied_protocol_data VALUES(NEW.*)
  RETURNING applied_protocol_data.*;
CREATE RULE applied_protocol_data_update AS
  ON UPDATE TO $temporary_chado_schema_name$.applied_protocol_data DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.applied_protocol_data SET 
    applied_protocol_data_id = NEW.applied_protocol_data_id,
    applied_protocol_id = NEW.applied_protocol_id,
    data_id = NEW.data_id,
    direction = NEW.direction
  WHERE applied_protocol_data_id = NEW.applied_protocol_data_id
  RETURNING applied_protocol_data.*;


--
-- Name: applied_protocol_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY applied_protocol
    ADD CONSTRAINT applied_protocol_pkey PRIMARY KEY (applied_protocol_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.applied_protocol AS SELECT * FROM $temporary_chado_schema_name$_data.applied_protocol UNION SELECT * FROM public.applied_protocol;
CREATE TRIGGER applied_protocol_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.applied_protocol
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.applied_protocol_pkey_trigger_func();
CREATE RULE applied_protocol_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.applied_protocol DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.applied_protocol VALUES(NEW.*)
  RETURNING applied_protocol.*;
CREATE RULE applied_protocol_update AS
  ON UPDATE TO $temporary_chado_schema_name$.applied_protocol DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.applied_protocol SET 
    applied_protocol_id = NEW.applied_protocol_id,
    protocol_id = NEW.protocol_id
  WHERE applied_protocol_id = NEW.applied_protocol_id
  RETURNING applied_protocol.*;


--
-- Name: arraydesign_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY arraydesign
    ADD CONSTRAINT arraydesign_c1 UNIQUE (name);


--
-- Name: arraydesign_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY arraydesign
    ADD CONSTRAINT arraydesign_pkey PRIMARY KEY (arraydesign_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.arraydesign AS SELECT * FROM $temporary_chado_schema_name$_data.arraydesign UNION SELECT * FROM public.arraydesign;
CREATE TRIGGER arraydesign_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.arraydesign
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.arraydesign_pkey_trigger_func();
CREATE RULE arraydesign_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.arraydesign DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.arraydesign VALUES(NEW.*)
  RETURNING arraydesign.*;
CREATE RULE arraydesign_update AS
  ON UPDATE TO $temporary_chado_schema_name$.arraydesign DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.arraydesign SET 
    arraydesign_id = NEW.arraydesign_id,
    manufacturer_id = NEW.manufacturer_id,
    platformtype_id = NEW.platformtype_id,
    substratetype_id = NEW.substratetype_id,
    protocol_id = NEW.protocol_id,
    dbxref_id = NEW.dbxref_id,
    name = NEW.name,
    version = NEW.version,
    description = NEW.description,
    array_dimensions = NEW.array_dimensions,
    element_dimensions = NEW.element_dimensions,
    num_of_elements = NEW.num_of_elements,
    num_array_columns = NEW.num_array_columns,
    num_array_rows = NEW.num_array_rows,
    num_grid_columns = NEW.num_grid_columns,
    num_grid_rows = NEW.num_grid_rows,
    num_sub_columns = NEW.num_sub_columns,
    num_sub_rows = NEW.num_sub_rows
  WHERE arraydesign_id = NEW.arraydesign_id
  RETURNING arraydesign.*;


--
-- Name: arraydesignprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY arraydesignprop
    ADD CONSTRAINT arraydesignprop_c1 UNIQUE (arraydesign_id, type_id, rank);


--
-- Name: arraydesignprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY arraydesignprop
    ADD CONSTRAINT arraydesignprop_pkey PRIMARY KEY (arraydesignprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.arraydesignprop AS SELECT * FROM $temporary_chado_schema_name$_data.arraydesignprop UNION SELECT * FROM public.arraydesignprop;
CREATE TRIGGER arraydesignprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.arraydesignprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.arraydesignprop_pkey_trigger_func();
CREATE RULE arraydesignprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.arraydesignprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.arraydesignprop VALUES(NEW.*)
  RETURNING arraydesignprop.*;
CREATE RULE arraydesignprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.arraydesignprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.arraydesignprop SET 
    arraydesignprop_id = NEW.arraydesignprop_id,
    arraydesign_id = NEW.arraydesign_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE arraydesignprop_id = NEW.arraydesignprop_id
  RETURNING arraydesignprop.*;


--
-- Name: assay_biomaterial_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assay_biomaterial
    ADD CONSTRAINT assay_biomaterial_c1 UNIQUE (assay_id, biomaterial_id, channel_id, rank);


--
-- Name: assay_biomaterial_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assay_biomaterial
    ADD CONSTRAINT assay_biomaterial_pkey PRIMARY KEY (assay_biomaterial_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.assay_biomaterial AS SELECT * FROM $temporary_chado_schema_name$_data.assay_biomaterial UNION SELECT * FROM public.assay_biomaterial;
CREATE TRIGGER assay_biomaterial_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.assay_biomaterial
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.assay_biomaterial_pkey_trigger_func();
CREATE RULE assay_biomaterial_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.assay_biomaterial DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.assay_biomaterial VALUES(NEW.*)
  RETURNING assay_biomaterial.*;
CREATE RULE assay_biomaterial_update AS
  ON UPDATE TO $temporary_chado_schema_name$.assay_biomaterial DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.assay_biomaterial SET 
    assay_biomaterial_id = NEW.assay_biomaterial_id,
    assay_id = NEW.assay_id,
    biomaterial_id = NEW.biomaterial_id,
    channel_id = NEW.channel_id,
    rank = NEW.rank
  WHERE assay_biomaterial_id = NEW.assay_biomaterial_id
  RETURNING assay_biomaterial.*;


--
-- Name: assay_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assay
    ADD CONSTRAINT assay_c1 UNIQUE (name);


--
-- Name: assay_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assay
    ADD CONSTRAINT assay_pkey PRIMARY KEY (assay_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.assay AS SELECT * FROM $temporary_chado_schema_name$_data.assay UNION SELECT * FROM public.assay;
CREATE TRIGGER assay_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.assay
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.assay_pkey_trigger_func();
CREATE RULE assay_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.assay DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.assay VALUES(NEW.*)
  RETURNING assay.*;
CREATE RULE assay_update AS
  ON UPDATE TO $temporary_chado_schema_name$.assay DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.assay SET 
    assay_id = NEW.assay_id,
    arraydesign_id = NEW.arraydesign_id,
    protocol_id = NEW.protocol_id,
    assaydate = NEW.assaydate,
    arrayidentifier = NEW.arrayidentifier,
    arraybatchidentifier = NEW.arraybatchidentifier,
    operator_id = NEW.operator_id,
    dbxref_id = NEW.dbxref_id,
    name = NEW.name,
    description = NEW.description
  WHERE assay_id = NEW.assay_id
  RETURNING assay.*;


--
-- Name: assay_project_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assay_project
    ADD CONSTRAINT assay_project_c1 UNIQUE (assay_id, project_id);


--
-- Name: assay_project_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assay_project
    ADD CONSTRAINT assay_project_pkey PRIMARY KEY (assay_project_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.assay_project AS SELECT * FROM $temporary_chado_schema_name$_data.assay_project UNION SELECT * FROM public.assay_project;
CREATE TRIGGER assay_project_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.assay_project
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.assay_project_pkey_trigger_func();
CREATE RULE assay_project_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.assay_project DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.assay_project VALUES(NEW.*)
  RETURNING assay_project.*;
CREATE RULE assay_project_update AS
  ON UPDATE TO $temporary_chado_schema_name$.assay_project DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.assay_project SET 
    assay_project_id = NEW.assay_project_id,
    assay_id = NEW.assay_id,
    project_id = NEW.project_id
  WHERE assay_project_id = NEW.assay_project_id
  RETURNING assay_project.*;


--
-- Name: assayprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assayprop
    ADD CONSTRAINT assayprop_c1 UNIQUE (assay_id, type_id, rank);


--
-- Name: assayprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assayprop
    ADD CONSTRAINT assayprop_pkey PRIMARY KEY (assayprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.assayprop AS SELECT * FROM $temporary_chado_schema_name$_data.assayprop UNION SELECT * FROM public.assayprop;
CREATE TRIGGER assayprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.assayprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.assayprop_pkey_trigger_func();
CREATE RULE assayprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.assayprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.assayprop VALUES(NEW.*)
  RETURNING assayprop.*;
CREATE RULE assayprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.assayprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.assayprop SET 
    assayprop_id = NEW.assayprop_id,
    assay_id = NEW.assay_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE assayprop_id = NEW.assayprop_id
  RETURNING assayprop.*;


--
-- Name: attribute_name_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY attribute
    ADD CONSTRAINT attribute_name_key UNIQUE (name, heading, rank, value, type_id);


--
-- Name: attribute_organism_organism_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY attribute_organism
    ADD CONSTRAINT attribute_organism_organism_id_key UNIQUE (organism_id, attribute_id);


--
-- Name: attribute_organism_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY attribute_organism
    ADD CONSTRAINT attribute_organism_pkey PRIMARY KEY (attribute_organism_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.attribute_organism AS SELECT * FROM $temporary_chado_schema_name$_data.attribute_organism UNION SELECT * FROM public.attribute_organism;
CREATE TRIGGER attribute_organism_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.attribute_organism
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.attribute_organism_pkey_trigger_func();
CREATE RULE attribute_organism_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.attribute_organism DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.attribute_organism VALUES(NEW.*)
  RETURNING attribute_organism.*;
CREATE RULE attribute_organism_update AS
  ON UPDATE TO $temporary_chado_schema_name$.attribute_organism DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.attribute_organism SET 
    attribute_organism_id = NEW.attribute_organism_id,
    organism_id = NEW.organism_id,
    attribute_id = NEW.attribute_id
  WHERE attribute_organism_id = NEW.attribute_organism_id
  RETURNING attribute_organism.*;


--
-- Name: attribute_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY attribute
    ADD CONSTRAINT attribute_pkey PRIMARY KEY (attribute_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.attribute AS SELECT * FROM $temporary_chado_schema_name$_data.attribute UNION SELECT * FROM public.attribute;
CREATE TRIGGER attribute_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.attribute
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.attribute_pkey_trigger_func();
CREATE RULE attribute_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.attribute DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.attribute VALUES(NEW.*)
  RETURNING attribute.*;
CREATE RULE attribute_update AS
  ON UPDATE TO $temporary_chado_schema_name$.attribute DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.attribute SET 
    attribute_id = NEW.attribute_id,
    name = NEW.name,
    heading = NEW.heading,
    rank = NEW.rank,
    value = NEW.value,
    type_id = NEW.type_id,
    dbxref_id = NEW.dbxref_id
  WHERE attribute_id = NEW.attribute_id
  RETURNING attribute.*;


--
-- Name: biomaterial_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY biomaterial
    ADD CONSTRAINT biomaterial_c1 UNIQUE (name);


--
-- Name: biomaterial_dbxref_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY biomaterial_dbxref
    ADD CONSTRAINT biomaterial_dbxref_c1 UNIQUE (biomaterial_id, dbxref_id);


--
-- Name: biomaterial_dbxref_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY biomaterial_dbxref
    ADD CONSTRAINT biomaterial_dbxref_pkey PRIMARY KEY (biomaterial_dbxref_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.biomaterial_dbxref AS SELECT * FROM $temporary_chado_schema_name$_data.biomaterial_dbxref UNION SELECT * FROM public.biomaterial_dbxref;
CREATE TRIGGER biomaterial_dbxref_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.biomaterial_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.biomaterial_dbxref_pkey_trigger_func();
CREATE RULE biomaterial_dbxref_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.biomaterial_dbxref DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.biomaterial_dbxref VALUES(NEW.*)
  RETURNING biomaterial_dbxref.*;
CREATE RULE biomaterial_dbxref_update AS
  ON UPDATE TO $temporary_chado_schema_name$.biomaterial_dbxref DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.biomaterial_dbxref SET 
    biomaterial_dbxref_id = NEW.biomaterial_dbxref_id,
    biomaterial_id = NEW.biomaterial_id,
    dbxref_id = NEW.dbxref_id
  WHERE biomaterial_dbxref_id = NEW.biomaterial_dbxref_id
  RETURNING biomaterial_dbxref.*;


--
-- Name: biomaterial_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY biomaterial
    ADD CONSTRAINT biomaterial_pkey PRIMARY KEY (biomaterial_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.biomaterial AS SELECT * FROM $temporary_chado_schema_name$_data.biomaterial UNION SELECT * FROM public.biomaterial;
CREATE TRIGGER biomaterial_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.biomaterial
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.biomaterial_pkey_trigger_func();
CREATE RULE biomaterial_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.biomaterial DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.biomaterial VALUES(NEW.*)
  RETURNING biomaterial.*;
CREATE RULE biomaterial_update AS
  ON UPDATE TO $temporary_chado_schema_name$.biomaterial DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.biomaterial SET 
    biomaterial_id = NEW.biomaterial_id,
    taxon_id = NEW.taxon_id,
    biosourceprovider_id = NEW.biosourceprovider_id,
    dbxref_id = NEW.dbxref_id,
    name = NEW.name,
    description = NEW.description
  WHERE biomaterial_id = NEW.biomaterial_id
  RETURNING biomaterial.*;


--
-- Name: biomaterial_relationship_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY biomaterial_relationship
    ADD CONSTRAINT biomaterial_relationship_c1 UNIQUE (subject_id, object_id, type_id);


--
-- Name: biomaterial_relationship_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY biomaterial_relationship
    ADD CONSTRAINT biomaterial_relationship_pkey PRIMARY KEY (biomaterial_relationship_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.biomaterial_relationship AS SELECT * FROM $temporary_chado_schema_name$_data.biomaterial_relationship UNION SELECT * FROM public.biomaterial_relationship;
CREATE TRIGGER biomaterial_relationship_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.biomaterial_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.biomaterial_relationship_pkey_trigger_func();
CREATE RULE biomaterial_relationship_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.biomaterial_relationship DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.biomaterial_relationship VALUES(NEW.*)
  RETURNING biomaterial_relationship.*;
CREATE RULE biomaterial_relationship_update AS
  ON UPDATE TO $temporary_chado_schema_name$.biomaterial_relationship DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.biomaterial_relationship SET 
    biomaterial_relationship_id = NEW.biomaterial_relationship_id,
    subject_id = NEW.subject_id,
    type_id = NEW.type_id,
    object_id = NEW.object_id
  WHERE biomaterial_relationship_id = NEW.biomaterial_relationship_id
  RETURNING biomaterial_relationship.*;


--
-- Name: biomaterial_treatment_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY biomaterial_treatment
    ADD CONSTRAINT biomaterial_treatment_c1 UNIQUE (biomaterial_id, treatment_id);


--
-- Name: biomaterial_treatment_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY biomaterial_treatment
    ADD CONSTRAINT biomaterial_treatment_pkey PRIMARY KEY (biomaterial_treatment_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.biomaterial_treatment AS SELECT * FROM $temporary_chado_schema_name$_data.biomaterial_treatment UNION SELECT * FROM public.biomaterial_treatment;
CREATE TRIGGER biomaterial_treatment_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.biomaterial_treatment
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.biomaterial_treatment_pkey_trigger_func();
CREATE RULE biomaterial_treatment_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.biomaterial_treatment DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.biomaterial_treatment VALUES(NEW.*)
  RETURNING biomaterial_treatment.*;
CREATE RULE biomaterial_treatment_update AS
  ON UPDATE TO $temporary_chado_schema_name$.biomaterial_treatment DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.biomaterial_treatment SET 
    biomaterial_treatment_id = NEW.biomaterial_treatment_id,
    biomaterial_id = NEW.biomaterial_id,
    treatment_id = NEW.treatment_id,
    unittype_id = NEW.unittype_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE biomaterial_treatment_id = NEW.biomaterial_treatment_id
  RETURNING biomaterial_treatment.*;


--
-- Name: biomaterialprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY biomaterialprop
    ADD CONSTRAINT biomaterialprop_c1 UNIQUE (biomaterial_id, type_id, rank);


--
-- Name: biomaterialprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY biomaterialprop
    ADD CONSTRAINT biomaterialprop_pkey PRIMARY KEY (biomaterialprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.biomaterialprop AS SELECT * FROM $temporary_chado_schema_name$_data.biomaterialprop UNION SELECT * FROM public.biomaterialprop;
CREATE TRIGGER biomaterialprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.biomaterialprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.biomaterialprop_pkey_trigger_func();
CREATE RULE biomaterialprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.biomaterialprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.biomaterialprop VALUES(NEW.*)
  RETURNING biomaterialprop.*;
CREATE RULE biomaterialprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.biomaterialprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.biomaterialprop SET 
    biomaterialprop_id = NEW.biomaterialprop_id,
    biomaterial_id = NEW.biomaterial_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE biomaterialprop_id = NEW.biomaterialprop_id
  RETURNING biomaterialprop.*;


--
-- Name: channel_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY channel
    ADD CONSTRAINT channel_c1 UNIQUE (name);


--
-- Name: channel_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY channel
    ADD CONSTRAINT channel_pkey PRIMARY KEY (channel_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.channel AS SELECT * FROM $temporary_chado_schema_name$_data.channel UNION SELECT * FROM public.channel;
CREATE TRIGGER channel_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.channel
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.channel_pkey_trigger_func();
CREATE RULE channel_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.channel DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.channel VALUES(NEW.*)
  RETURNING channel.*;
CREATE RULE channel_update AS
  ON UPDATE TO $temporary_chado_schema_name$.channel DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.channel SET 
    channel_id = NEW.channel_id,
    name = NEW.name,
    definition = NEW.definition
  WHERE channel_id = NEW.channel_id
  RETURNING channel.*;


--
-- Name: contact_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contact
    ADD CONSTRAINT contact_c1 UNIQUE (name);


--
-- Name: contact_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contact
    ADD CONSTRAINT contact_pkey PRIMARY KEY (contact_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.contact AS SELECT * FROM $temporary_chado_schema_name$_data.contact UNION SELECT * FROM public.contact;
CREATE TRIGGER contact_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.contact
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.contact_pkey_trigger_func();
CREATE RULE contact_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.contact DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.contact VALUES(NEW.*)
  RETURNING contact.*;
CREATE RULE contact_update AS
  ON UPDATE TO $temporary_chado_schema_name$.contact DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.contact SET 
    contact_id = NEW.contact_id,
    type_id = NEW.type_id,
    name = NEW.name,
    description = NEW.description
  WHERE contact_id = NEW.contact_id
  RETURNING contact.*;


--
-- Name: contact_relationship_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contact_relationship
    ADD CONSTRAINT contact_relationship_c1 UNIQUE (subject_id, object_id, type_id);


--
-- Name: contact_relationship_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contact_relationship
    ADD CONSTRAINT contact_relationship_pkey PRIMARY KEY (contact_relationship_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.contact_relationship AS SELECT * FROM $temporary_chado_schema_name$_data.contact_relationship UNION SELECT * FROM public.contact_relationship;
CREATE TRIGGER contact_relationship_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.contact_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.contact_relationship_pkey_trigger_func();
CREATE RULE contact_relationship_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.contact_relationship DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.contact_relationship VALUES(NEW.*)
  RETURNING contact_relationship.*;
CREATE RULE contact_relationship_update AS
  ON UPDATE TO $temporary_chado_schema_name$.contact_relationship DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.contact_relationship SET 
    contact_relationship_id = NEW.contact_relationship_id,
    type_id = NEW.type_id,
    subject_id = NEW.subject_id,
    object_id = NEW.object_id
  WHERE contact_relationship_id = NEW.contact_relationship_id
  RETURNING contact_relationship.*;


--
-- Name: contactprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contactprop
    ADD CONSTRAINT contactprop_c1 UNIQUE (contact_id, type_id, value);


--
-- Name: contactprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contactprop
    ADD CONSTRAINT contactprop_pkey PRIMARY KEY (contactprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.contactprop AS SELECT * FROM $temporary_chado_schema_name$_data.contactprop UNION SELECT * FROM public.contactprop;
CREATE TRIGGER contactprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.contactprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.contactprop_pkey_trigger_func();
CREATE RULE contactprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.contactprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.contactprop VALUES(NEW.*)
  RETURNING contactprop.*;
CREATE RULE contactprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.contactprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.contactprop SET 
    contactprop_id = NEW.contactprop_id,
    contact_id = NEW.contact_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE contactprop_id = NEW.contactprop_id
  RETURNING contactprop.*;


--
-- Name: control_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY control
    ADD CONSTRAINT control_pkey PRIMARY KEY (control_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.control AS SELECT * FROM $temporary_chado_schema_name$_data.control UNION SELECT * FROM public.control;
CREATE TRIGGER control_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.control
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.control_pkey_trigger_func();
CREATE RULE control_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.control DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.control VALUES(NEW.*)
  RETURNING control.*;
CREATE RULE control_update AS
  ON UPDATE TO $temporary_chado_schema_name$.control DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.control SET 
    control_id = NEW.control_id,
    type_id = NEW.type_id,
    assay_id = NEW.assay_id,
    tableinfo_id = NEW.tableinfo_id,
    row_id = NEW.row_id,
    name = NEW.name,
    value = NEW.value,
    rank = NEW.rank
  WHERE control_id = NEW.control_id
  RETURNING control.*;


--
-- Name: cv_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cv
    ADD CONSTRAINT cv_c1 UNIQUE (name);


--
-- Name: cv_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cv
    ADD CONSTRAINT cv_pkey PRIMARY KEY (cv_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.cv AS SELECT * FROM $temporary_chado_schema_name$_data.cv UNION SELECT * FROM public.cv;
CREATE TRIGGER cv_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.cv
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cv_pkey_trigger_func();
CREATE RULE cv_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.cv DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.cv VALUES(NEW.*)
  RETURNING cv.*;
CREATE RULE cv_update AS
  ON UPDATE TO $temporary_chado_schema_name$.cv DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.cv SET 
    cv_id = NEW.cv_id,
    name = NEW.name,
    definition = NEW.definition
  WHERE cv_id = NEW.cv_id
  RETURNING cv.*;


--
-- Name: cvterm_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvterm
    ADD CONSTRAINT cvterm_c1 UNIQUE (name, cv_id, is_obsolete);


--
-- Name: cvterm_c2; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvterm
    ADD CONSTRAINT cvterm_c2 UNIQUE (dbxref_id);


--
-- Name: cvterm_dbxref_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvterm_dbxref
    ADD CONSTRAINT cvterm_dbxref_c1 UNIQUE (cvterm_id, dbxref_id);


--
-- Name: cvterm_dbxref_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvterm_dbxref
    ADD CONSTRAINT cvterm_dbxref_pkey PRIMARY KEY (cvterm_dbxref_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.cvterm_dbxref AS SELECT * FROM $temporary_chado_schema_name$_data.cvterm_dbxref UNION SELECT * FROM public.cvterm_dbxref;
CREATE TRIGGER cvterm_dbxref_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.cvterm_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cvterm_dbxref_pkey_trigger_func();
CREATE RULE cvterm_dbxref_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.cvterm_dbxref DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.cvterm_dbxref VALUES(NEW.*)
  RETURNING cvterm_dbxref.*;
CREATE RULE cvterm_dbxref_update AS
  ON UPDATE TO $temporary_chado_schema_name$.cvterm_dbxref DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.cvterm_dbxref SET 
    cvterm_dbxref_id = NEW.cvterm_dbxref_id,
    cvterm_id = NEW.cvterm_id,
    dbxref_id = NEW.dbxref_id,
    is_for_definition = NEW.is_for_definition
  WHERE cvterm_dbxref_id = NEW.cvterm_dbxref_id
  RETURNING cvterm_dbxref.*;


--
-- Name: cvterm_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvterm
    ADD CONSTRAINT cvterm_pkey PRIMARY KEY (cvterm_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.cvterm AS SELECT * FROM $temporary_chado_schema_name$_data.cvterm UNION SELECT * FROM public.cvterm;
CREATE TRIGGER cvterm_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.cvterm
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cvterm_pkey_trigger_func();
CREATE RULE cvterm_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.cvterm DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.cvterm VALUES(NEW.*)
  RETURNING cvterm.*;
CREATE RULE cvterm_update AS
  ON UPDATE TO $temporary_chado_schema_name$.cvterm DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.cvterm SET 
    cvterm_id = NEW.cvterm_id,
    cv_id = NEW.cv_id,
    name = NEW.name,
    definition = NEW.definition,
    dbxref_id = NEW.dbxref_id,
    is_obsolete = NEW.is_obsolete,
    is_relationshiptype = NEW.is_relationshiptype
  WHERE cvterm_id = NEW.cvterm_id
  RETURNING cvterm.*;


--
-- Name: cvterm_relationship_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvterm_relationship
    ADD CONSTRAINT cvterm_relationship_c1 UNIQUE (subject_id, object_id, type_id);


--
-- Name: cvterm_relationship_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvterm_relationship
    ADD CONSTRAINT cvterm_relationship_pkey PRIMARY KEY (cvterm_relationship_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.cvterm_relationship AS SELECT * FROM $temporary_chado_schema_name$_data.cvterm_relationship UNION SELECT * FROM public.cvterm_relationship;
CREATE TRIGGER cvterm_relationship_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.cvterm_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cvterm_relationship_pkey_trigger_func();
CREATE RULE cvterm_relationship_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.cvterm_relationship DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.cvterm_relationship VALUES(NEW.*)
  RETURNING cvterm_relationship.*;
CREATE RULE cvterm_relationship_update AS
  ON UPDATE TO $temporary_chado_schema_name$.cvterm_relationship DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.cvterm_relationship SET 
    cvterm_relationship_id = NEW.cvterm_relationship_id,
    type_id = NEW.type_id,
    subject_id = NEW.subject_id,
    object_id = NEW.object_id
  WHERE cvterm_relationship_id = NEW.cvterm_relationship_id
  RETURNING cvterm_relationship.*;


--
-- Name: cvtermpath_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvtermpath
    ADD CONSTRAINT cvtermpath_c1 UNIQUE (subject_id, object_id, type_id, pathdistance);


--
-- Name: cvtermpath_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvtermpath
    ADD CONSTRAINT cvtermpath_pkey PRIMARY KEY (cvtermpath_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.cvtermpath AS SELECT * FROM $temporary_chado_schema_name$_data.cvtermpath UNION SELECT * FROM public.cvtermpath;
CREATE TRIGGER cvtermpath_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.cvtermpath
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cvtermpath_pkey_trigger_func();
CREATE RULE cvtermpath_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.cvtermpath DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.cvtermpath VALUES(NEW.*)
  RETURNING cvtermpath.*;
CREATE RULE cvtermpath_update AS
  ON UPDATE TO $temporary_chado_schema_name$.cvtermpath DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.cvtermpath SET 
    cvtermpath_id = NEW.cvtermpath_id,
    type_id = NEW.type_id,
    subject_id = NEW.subject_id,
    object_id = NEW.object_id,
    cv_id = NEW.cv_id,
    pathdistance = NEW.pathdistance
  WHERE cvtermpath_id = NEW.cvtermpath_id
  RETURNING cvtermpath.*;


--
-- Name: cvtermprop_cvterm_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvtermprop
    ADD CONSTRAINT cvtermprop_cvterm_id_key UNIQUE (cvterm_id, type_id, value, rank);


--
-- Name: cvtermprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvtermprop
    ADD CONSTRAINT cvtermprop_pkey PRIMARY KEY (cvtermprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.cvtermprop AS SELECT * FROM $temporary_chado_schema_name$_data.cvtermprop UNION SELECT * FROM public.cvtermprop;
CREATE TRIGGER cvtermprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cvtermprop_pkey_trigger_func();
CREATE RULE cvtermprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.cvtermprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.cvtermprop VALUES(NEW.*)
  RETURNING cvtermprop.*;
CREATE RULE cvtermprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.cvtermprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.cvtermprop SET 
    cvtermprop_id = NEW.cvtermprop_id,
    cvterm_id = NEW.cvterm_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE cvtermprop_id = NEW.cvtermprop_id
  RETURNING cvtermprop.*;


--
-- Name: cvtermsynonym_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvtermsynonym
    ADD CONSTRAINT cvtermsynonym_c1 UNIQUE (cvterm_id, synonym);


--
-- Name: cvtermsynonym_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cvtermsynonym
    ADD CONSTRAINT cvtermsynonym_pkey PRIMARY KEY (cvtermsynonym_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.cvtermsynonym AS SELECT * FROM $temporary_chado_schema_name$_data.cvtermsynonym UNION SELECT * FROM public.cvtermsynonym;
CREATE TRIGGER cvtermsynonym_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.cvtermsynonym
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.cvtermsynonym_pkey_trigger_func();
CREATE RULE cvtermsynonym_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.cvtermsynonym DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.cvtermsynonym VALUES(NEW.*)
  RETURNING cvtermsynonym.*;
CREATE RULE cvtermsynonym_update AS
  ON UPDATE TO $temporary_chado_schema_name$.cvtermsynonym DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.cvtermsynonym SET 
    cvtermsynonym_id = NEW.cvtermsynonym_id,
    cvterm_id = NEW.cvterm_id,
    synonym = NEW.synonym,
    type_id = NEW.type_id
  WHERE cvtermsynonym_id = NEW.cvtermsynonym_id
  RETURNING cvtermsynonym.*;


--
-- Name: data_attribute_data_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_attribute
    ADD CONSTRAINT data_attribute_data_id_key UNIQUE (data_id, attribute_id);


--
-- Name: data_attribute_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_attribute
    ADD CONSTRAINT data_attribute_pkey PRIMARY KEY (data_attribute_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.data_attribute AS SELECT * FROM $temporary_chado_schema_name$_data.data_attribute UNION SELECT * FROM public.data_attribute;
CREATE TRIGGER data_attribute_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.data_attribute
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.data_attribute_pkey_trigger_func();
CREATE RULE data_attribute_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.data_attribute DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.data_attribute VALUES(NEW.*)
  RETURNING data_attribute.*;
CREATE RULE data_attribute_update AS
  ON UPDATE TO $temporary_chado_schema_name$.data_attribute DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.data_attribute SET 
    data_attribute_id = NEW.data_attribute_id,
    data_id = NEW.data_id,
    attribute_id = NEW.attribute_id
  WHERE data_attribute_id = NEW.data_attribute_id
  RETURNING data_attribute.*;


--
-- Name: data_feature_feature_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_feature
    ADD CONSTRAINT data_feature_feature_id_key UNIQUE (feature_id, data_id);


--
-- Name: data_feature_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_feature
    ADD CONSTRAINT data_feature_pkey PRIMARY KEY (data_feature_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.data_feature AS SELECT * FROM $temporary_chado_schema_name$_data.data_feature UNION SELECT * FROM public.data_feature;
CREATE TRIGGER data_feature_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.data_feature
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.data_feature_pkey_trigger_func();
CREATE RULE data_feature_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.data_feature DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.data_feature VALUES(NEW.*)
  RETURNING data_feature.*;
CREATE RULE data_feature_update AS
  ON UPDATE TO $temporary_chado_schema_name$.data_feature DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.data_feature SET 
    data_feature_id = NEW.data_feature_id,
    feature_id = NEW.feature_id,
    data_id = NEW.data_id
  WHERE data_feature_id = NEW.data_feature_id
  RETURNING data_feature.*;


--
-- Name: data_organism_organism_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_organism
    ADD CONSTRAINT data_organism_organism_id_key UNIQUE (organism_id, data_id);


--
-- Name: data_organism_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_organism
    ADD CONSTRAINT data_organism_pkey PRIMARY KEY (data_organism_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.data_organism AS SELECT * FROM $temporary_chado_schema_name$_data.data_organism UNION SELECT * FROM public.data_organism;
CREATE TRIGGER data_organism_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.data_organism
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.data_organism_pkey_trigger_func();
CREATE RULE data_organism_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.data_organism DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.data_organism VALUES(NEW.*)
  RETURNING data_organism.*;
CREATE RULE data_organism_update AS
  ON UPDATE TO $temporary_chado_schema_name$.data_organism DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.data_organism SET 
    data_organism_id = NEW.data_organism_id,
    organism_id = NEW.organism_id,
    data_id = NEW.data_id
  WHERE data_organism_id = NEW.data_organism_id
  RETURNING data_organism.*;


--
-- Name: data_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data
    ADD CONSTRAINT data_pkey PRIMARY KEY (data_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.data AS SELECT * FROM $temporary_chado_schema_name$_data.data UNION SELECT * FROM public.data;
CREATE TRIGGER data_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.data_pkey_trigger_func();
CREATE RULE data_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.data DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.data VALUES(NEW.*)
  RETURNING data.*;
CREATE RULE data_update AS
  ON UPDATE TO $temporary_chado_schema_name$.data DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.data SET 
    data_id = NEW.data_id,
    name = NEW.name,
    heading = NEW.heading,
    value = NEW.value,
    type_id = NEW.type_id,
    dbxref_id = NEW.dbxref_id
  WHERE data_id = NEW.data_id
  RETURNING data.*;


--
-- Name: data_wiggle_data_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_wiggle_data
    ADD CONSTRAINT data_wiggle_data_pkey PRIMARY KEY (data_wiggle_data_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.data_wiggle_data AS SELECT * FROM $temporary_chado_schema_name$_data.data_wiggle_data UNION SELECT * FROM public.data_wiggle_data;
CREATE TRIGGER data_wiggle_data_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.data_wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.data_wiggle_data_pkey_trigger_func();
CREATE RULE data_wiggle_data_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.data_wiggle_data DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.data_wiggle_data VALUES(NEW.*)
  RETURNING data_wiggle_data.*;
CREATE RULE data_wiggle_data_update AS
  ON UPDATE TO $temporary_chado_schema_name$.data_wiggle_data DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.data_wiggle_data SET 
    data_wiggle_data_id = NEW.data_wiggle_data_id,
    wiggle_data_id = NEW.wiggle_data_id,
    data_id = NEW.data_id
  WHERE data_wiggle_data_id = NEW.data_wiggle_data_id
  RETURNING data_wiggle_data.*;


--
-- Name: data_wiggle_data_wiggle_data_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_wiggle_data
    ADD CONSTRAINT data_wiggle_data_wiggle_data_id_key UNIQUE (wiggle_data_id, data_id);


--
-- Name: db_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY db
    ADD CONSTRAINT db_c1 UNIQUE (name);


--
-- Name: db_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY db
    ADD CONSTRAINT db_pkey PRIMARY KEY (db_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.db AS SELECT * FROM $temporary_chado_schema_name$_data.db UNION SELECT * FROM public.db;
CREATE TRIGGER db_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.db
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.db_pkey_trigger_func();
CREATE RULE db_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.db DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.db VALUES(NEW.*)
  RETURNING db.*;
CREATE RULE db_update AS
  ON UPDATE TO $temporary_chado_schema_name$.db DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.db SET 
    db_id = NEW.db_id,
    name = NEW.name,
    description = NEW.description,
    urlprefix = NEW.urlprefix,
    url = NEW.url
  WHERE db_id = NEW.db_id
  RETURNING db.*;


--
-- Name: dbxref_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dbxref
    ADD CONSTRAINT dbxref_c1 UNIQUE (db_id, accession, version);


--
-- Name: dbxref_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dbxref
    ADD CONSTRAINT dbxref_pkey PRIMARY KEY (dbxref_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.dbxref AS SELECT * FROM $temporary_chado_schema_name$_data.dbxref UNION SELECT * FROM public.dbxref;
CREATE TRIGGER dbxref_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.dbxref_pkey_trigger_func();
CREATE RULE dbxref_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.dbxref DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.dbxref VALUES(NEW.*)
  RETURNING dbxref.*;
CREATE RULE dbxref_update AS
  ON UPDATE TO $temporary_chado_schema_name$.dbxref DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.dbxref SET 
    dbxref_id = NEW.dbxref_id,
    db_id = NEW.db_id,
    accession = NEW.accession,
    version = NEW.version,
    description = NEW.description
  WHERE dbxref_id = NEW.dbxref_id
  RETURNING dbxref.*;


--
-- Name: dbxrefprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dbxrefprop
    ADD CONSTRAINT dbxrefprop_c1 UNIQUE (dbxref_id, type_id, rank);


--
-- Name: dbxrefprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dbxrefprop
    ADD CONSTRAINT dbxrefprop_pkey PRIMARY KEY (dbxrefprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.dbxrefprop AS SELECT * FROM $temporary_chado_schema_name$_data.dbxrefprop UNION SELECT * FROM public.dbxrefprop;
CREATE TRIGGER dbxrefprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.dbxrefprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.dbxrefprop_pkey_trigger_func();
CREATE RULE dbxrefprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.dbxrefprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.dbxrefprop VALUES(NEW.*)
  RETURNING dbxrefprop.*;
CREATE RULE dbxrefprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.dbxrefprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.dbxrefprop SET 
    dbxrefprop_id = NEW.dbxrefprop_id,
    dbxref_id = NEW.dbxref_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE dbxrefprop_id = NEW.dbxrefprop_id
  RETURNING dbxrefprop.*;


--
-- Name: eimage_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY eimage
    ADD CONSTRAINT eimage_pkey PRIMARY KEY (eimage_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.eimage AS SELECT * FROM $temporary_chado_schema_name$_data.eimage UNION SELECT * FROM public.eimage;
CREATE TRIGGER eimage_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.eimage
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.eimage_pkey_trigger_func();
CREATE RULE eimage_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.eimage DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.eimage VALUES(NEW.*)
  RETURNING eimage.*;
CREATE RULE eimage_update AS
  ON UPDATE TO $temporary_chado_schema_name$.eimage DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.eimage SET 
    eimage_id = NEW.eimage_id,
    eimage_data = NEW.eimage_data,
    eimage_type = NEW.eimage_type,
    image_uri = NEW.image_uri
  WHERE eimage_id = NEW.eimage_id
  RETURNING eimage.*;


--
-- Name: element_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY element
    ADD CONSTRAINT element_c1 UNIQUE (feature_id, arraydesign_id);


--
-- Name: element_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY element
    ADD CONSTRAINT element_pkey PRIMARY KEY (element_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.element AS SELECT * FROM $temporary_chado_schema_name$_data.element UNION SELECT * FROM public.element;
CREATE TRIGGER element_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.element
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.element_pkey_trigger_func();
CREATE RULE element_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.element DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.element VALUES(NEW.*)
  RETURNING element.*;
CREATE RULE element_update AS
  ON UPDATE TO $temporary_chado_schema_name$.element DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.element SET 
    element_id = NEW.element_id,
    feature_id = NEW.feature_id,
    arraydesign_id = NEW.arraydesign_id,
    type_id = NEW.type_id,
    dbxref_id = NEW.dbxref_id
  WHERE element_id = NEW.element_id
  RETURNING element.*;


--
-- Name: element_relationship_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY element_relationship
    ADD CONSTRAINT element_relationship_c1 UNIQUE (subject_id, object_id, type_id, rank);


--
-- Name: element_relationship_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY element_relationship
    ADD CONSTRAINT element_relationship_pkey PRIMARY KEY (element_relationship_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.element_relationship AS SELECT * FROM $temporary_chado_schema_name$_data.element_relationship UNION SELECT * FROM public.element_relationship;
CREATE TRIGGER element_relationship_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.element_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.element_relationship_pkey_trigger_func();
CREATE RULE element_relationship_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.element_relationship DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.element_relationship VALUES(NEW.*)
  RETURNING element_relationship.*;
CREATE RULE element_relationship_update AS
  ON UPDATE TO $temporary_chado_schema_name$.element_relationship DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.element_relationship SET 
    element_relationship_id = NEW.element_relationship_id,
    subject_id = NEW.subject_id,
    type_id = NEW.type_id,
    object_id = NEW.object_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE element_relationship_id = NEW.element_relationship_id
  RETURNING element_relationship.*;


--
-- Name: elementresult_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY elementresult
    ADD CONSTRAINT elementresult_c1 UNIQUE (element_id, quantification_id);


--
-- Name: elementresult_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY elementresult
    ADD CONSTRAINT elementresult_pkey PRIMARY KEY (elementresult_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.elementresult AS SELECT * FROM $temporary_chado_schema_name$_data.elementresult UNION SELECT * FROM public.elementresult;
CREATE TRIGGER elementresult_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.elementresult
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.elementresult_pkey_trigger_func();
CREATE RULE elementresult_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.elementresult DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.elementresult VALUES(NEW.*)
  RETURNING elementresult.*;
CREATE RULE elementresult_update AS
  ON UPDATE TO $temporary_chado_schema_name$.elementresult DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.elementresult SET 
    elementresult_id = NEW.elementresult_id,
    element_id = NEW.element_id,
    quantification_id = NEW.quantification_id,
    signal = NEW.signal
  WHERE elementresult_id = NEW.elementresult_id
  RETURNING elementresult.*;


--
-- Name: elementresult_relationship_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY elementresult_relationship
    ADD CONSTRAINT elementresult_relationship_c1 UNIQUE (subject_id, object_id, type_id, rank);


--
-- Name: elementresult_relationship_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY elementresult_relationship
    ADD CONSTRAINT elementresult_relationship_pkey PRIMARY KEY (elementresult_relationship_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.elementresult_relationship AS SELECT * FROM $temporary_chado_schema_name$_data.elementresult_relationship UNION SELECT * FROM public.elementresult_relationship;
CREATE TRIGGER elementresult_relationship_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.elementresult_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.elementresult_relationship_pkey_trigger_func();
CREATE RULE elementresult_relationship_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.elementresult_relationship DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.elementresult_relationship VALUES(NEW.*)
  RETURNING elementresult_relationship.*;
CREATE RULE elementresult_relationship_update AS
  ON UPDATE TO $temporary_chado_schema_name$.elementresult_relationship DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.elementresult_relationship SET 
    elementresult_relationship_id = NEW.elementresult_relationship_id,
    subject_id = NEW.subject_id,
    type_id = NEW.type_id,
    object_id = NEW.object_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE elementresult_relationship_id = NEW.elementresult_relationship_id
  RETURNING elementresult_relationship.*;


--
-- Name: environment_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY environment
    ADD CONSTRAINT environment_c1 UNIQUE (uniquename);


--
-- Name: environment_cvterm_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY environment_cvterm
    ADD CONSTRAINT environment_cvterm_c1 UNIQUE (environment_id, cvterm_id);


--
-- Name: environment_cvterm_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY environment_cvterm
    ADD CONSTRAINT environment_cvterm_pkey PRIMARY KEY (environment_cvterm_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.environment_cvterm AS SELECT * FROM $temporary_chado_schema_name$_data.environment_cvterm UNION SELECT * FROM public.environment_cvterm;
CREATE TRIGGER environment_cvterm_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.environment_cvterm
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.environment_cvterm_pkey_trigger_func();
CREATE RULE environment_cvterm_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.environment_cvterm DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.environment_cvterm VALUES(NEW.*)
  RETURNING environment_cvterm.*;
CREATE RULE environment_cvterm_update AS
  ON UPDATE TO $temporary_chado_schema_name$.environment_cvterm DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.environment_cvterm SET 
    environment_cvterm_id = NEW.environment_cvterm_id,
    environment_id = NEW.environment_id,
    cvterm_id = NEW.cvterm_id
  WHERE environment_cvterm_id = NEW.environment_cvterm_id
  RETURNING environment_cvterm.*;


--
-- Name: environment_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY environment
    ADD CONSTRAINT environment_pkey PRIMARY KEY (environment_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.environment AS SELECT * FROM $temporary_chado_schema_name$_data.environment UNION SELECT * FROM public.environment;
CREATE TRIGGER environment_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.environment
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.environment_pkey_trigger_func();
CREATE RULE environment_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.environment DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.environment VALUES(NEW.*)
  RETURNING environment.*;
CREATE RULE environment_update AS
  ON UPDATE TO $temporary_chado_schema_name$.environment DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.environment SET 
    environment_id = NEW.environment_id,
    uniquename = NEW.uniquename,
    description = NEW.description
  WHERE environment_id = NEW.environment_id
  RETURNING environment.*;


--
-- Name: experiment_applied_protocol_experiment_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY experiment_applied_protocol
    ADD CONSTRAINT experiment_applied_protocol_experiment_id_key UNIQUE (experiment_id, first_applied_protocol_id);


--
-- Name: experiment_applied_protocol_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY experiment_applied_protocol
    ADD CONSTRAINT experiment_applied_protocol_pkey PRIMARY KEY (experiment_applied_protocol_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.experiment_applied_protocol AS SELECT * FROM $temporary_chado_schema_name$_data.experiment_applied_protocol UNION SELECT * FROM public.experiment_applied_protocol;
CREATE TRIGGER experiment_applied_protocol_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.experiment_applied_protocol
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.experiment_applied_protocol_pkey_trigger_func();
CREATE RULE experiment_applied_protocol_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.experiment_applied_protocol DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.experiment_applied_protocol VALUES(NEW.*)
  RETURNING experiment_applied_protocol.*;
CREATE RULE experiment_applied_protocol_update AS
  ON UPDATE TO $temporary_chado_schema_name$.experiment_applied_protocol DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.experiment_applied_protocol SET 
    experiment_applied_protocol_id = NEW.experiment_applied_protocol_id,
    experiment_id = NEW.experiment_id,
    first_applied_protocol_id = NEW.first_applied_protocol_id
  WHERE experiment_applied_protocol_id = NEW.experiment_applied_protocol_id
  RETURNING experiment_applied_protocol.*;


--
-- Name: experiment_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY experiment
    ADD CONSTRAINT experiment_pkey PRIMARY KEY (experiment_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.experiment AS SELECT * FROM $temporary_chado_schema_name$_data.experiment UNION SELECT * FROM public.experiment;
CREATE TRIGGER experiment_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.experiment
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.experiment_pkey_trigger_func();
CREATE RULE experiment_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.experiment DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.experiment VALUES(NEW.*)
  RETURNING experiment.*;
CREATE RULE experiment_update AS
  ON UPDATE TO $temporary_chado_schema_name$.experiment DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.experiment SET 
    experiment_id = NEW.experiment_id,
    uniquename = NEW.uniquename,
    description = NEW.description
  WHERE experiment_id = NEW.experiment_id
  RETURNING experiment.*;


--
-- Name: experiment_prop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY experiment_prop
    ADD CONSTRAINT experiment_prop_pkey PRIMARY KEY (experiment_prop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.experiment_prop AS SELECT * FROM $temporary_chado_schema_name$_data.experiment_prop UNION SELECT * FROM public.experiment_prop;
CREATE TRIGGER experiment_prop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.experiment_prop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.experiment_prop_pkey_trigger_func();
CREATE RULE experiment_prop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.experiment_prop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.experiment_prop VALUES(NEW.*)
  RETURNING experiment_prop.*;
CREATE RULE experiment_prop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.experiment_prop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.experiment_prop SET 
    experiment_prop_id = NEW.experiment_prop_id,
    experiment_id = NEW.experiment_id,
    name = NEW.name,
    rank = NEW.rank,
    value = NEW.value,
    type_id = NEW.type_id,
    dbxref_id = NEW.dbxref_id
  WHERE experiment_prop_id = NEW.experiment_prop_id
  RETURNING experiment_prop.*;


--
-- Name: experiment_uniquename_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY experiment
    ADD CONSTRAINT experiment_uniquename_key UNIQUE (uniquename);


--
-- Name: expression_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expression
    ADD CONSTRAINT expression_c1 UNIQUE (uniquename);


--
-- Name: expression_cvterm_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expression_cvterm
    ADD CONSTRAINT expression_cvterm_c1 UNIQUE (expression_id, cvterm_id, cvterm_type_id);


--
-- Name: expression_cvterm_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expression_cvterm
    ADD CONSTRAINT expression_cvterm_pkey PRIMARY KEY (expression_cvterm_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.expression_cvterm AS SELECT * FROM $temporary_chado_schema_name$_data.expression_cvterm UNION SELECT * FROM public.expression_cvterm;
CREATE TRIGGER expression_cvterm_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.expression_cvterm
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.expression_cvterm_pkey_trigger_func();
CREATE RULE expression_cvterm_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.expression_cvterm DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.expression_cvterm VALUES(NEW.*)
  RETURNING expression_cvterm.*;
CREATE RULE expression_cvterm_update AS
  ON UPDATE TO $temporary_chado_schema_name$.expression_cvterm DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.expression_cvterm SET 
    expression_cvterm_id = NEW.expression_cvterm_id,
    expression_id = NEW.expression_id,
    cvterm_id = NEW.cvterm_id,
    rank = NEW.rank,
    cvterm_type_id = NEW.cvterm_type_id
  WHERE expression_cvterm_id = NEW.expression_cvterm_id
  RETURNING expression_cvterm.*;


--
-- Name: expression_cvtermprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expression_cvtermprop
    ADD CONSTRAINT expression_cvtermprop_c1 UNIQUE (expression_cvterm_id, type_id, rank);


--
-- Name: expression_cvtermprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expression_cvtermprop
    ADD CONSTRAINT expression_cvtermprop_pkey PRIMARY KEY (expression_cvtermprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.expression_cvtermprop AS SELECT * FROM $temporary_chado_schema_name$_data.expression_cvtermprop UNION SELECT * FROM public.expression_cvtermprop;
CREATE TRIGGER expression_cvtermprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.expression_cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.expression_cvtermprop_pkey_trigger_func();
CREATE RULE expression_cvtermprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.expression_cvtermprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.expression_cvtermprop VALUES(NEW.*)
  RETURNING expression_cvtermprop.*;
CREATE RULE expression_cvtermprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.expression_cvtermprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.expression_cvtermprop SET 
    expression_cvtermprop_id = NEW.expression_cvtermprop_id,
    expression_cvterm_id = NEW.expression_cvterm_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE expression_cvtermprop_id = NEW.expression_cvtermprop_id
  RETURNING expression_cvtermprop.*;


--
-- Name: expression_image_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expression_image
    ADD CONSTRAINT expression_image_c1 UNIQUE (expression_id, eimage_id);


--
-- Name: expression_image_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expression_image
    ADD CONSTRAINT expression_image_pkey PRIMARY KEY (expression_image_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.expression_image AS SELECT * FROM $temporary_chado_schema_name$_data.expression_image UNION SELECT * FROM public.expression_image;
CREATE TRIGGER expression_image_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.expression_image
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.expression_image_pkey_trigger_func();
CREATE RULE expression_image_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.expression_image DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.expression_image VALUES(NEW.*)
  RETURNING expression_image.*;
CREATE RULE expression_image_update AS
  ON UPDATE TO $temporary_chado_schema_name$.expression_image DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.expression_image SET 
    expression_image_id = NEW.expression_image_id,
    expression_id = NEW.expression_id,
    eimage_id = NEW.eimage_id
  WHERE expression_image_id = NEW.expression_image_id
  RETURNING expression_image.*;


--
-- Name: expression_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expression
    ADD CONSTRAINT expression_pkey PRIMARY KEY (expression_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.expression AS SELECT * FROM $temporary_chado_schema_name$_data.expression UNION SELECT * FROM public.expression;
CREATE TRIGGER expression_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.expression
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.expression_pkey_trigger_func();
CREATE RULE expression_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.expression DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.expression VALUES(NEW.*)
  RETURNING expression.*;
CREATE RULE expression_update AS
  ON UPDATE TO $temporary_chado_schema_name$.expression DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.expression SET 
    expression_id = NEW.expression_id,
    uniquename = NEW.uniquename,
    md5checksum = NEW.md5checksum,
    description = NEW.description
  WHERE expression_id = NEW.expression_id
  RETURNING expression.*;


--
-- Name: expression_pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expression_pub
    ADD CONSTRAINT expression_pub_c1 UNIQUE (expression_id, pub_id);


--
-- Name: expression_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expression_pub
    ADD CONSTRAINT expression_pub_pkey PRIMARY KEY (expression_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.expression_pub AS SELECT * FROM $temporary_chado_schema_name$_data.expression_pub UNION SELECT * FROM public.expression_pub;
CREATE TRIGGER expression_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.expression_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.expression_pub_pkey_trigger_func();
CREATE RULE expression_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.expression_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.expression_pub VALUES(NEW.*)
  RETURNING expression_pub.*;
CREATE RULE expression_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.expression_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.expression_pub SET 
    expression_pub_id = NEW.expression_pub_id,
    expression_id = NEW.expression_id,
    pub_id = NEW.pub_id
  WHERE expression_pub_id = NEW.expression_pub_id
  RETURNING expression_pub.*;


--
-- Name: expressionprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expressionprop
    ADD CONSTRAINT expressionprop_c1 UNIQUE (expression_id, type_id, rank);


--
-- Name: expressionprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY expressionprop
    ADD CONSTRAINT expressionprop_pkey PRIMARY KEY (expressionprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.expressionprop AS SELECT * FROM $temporary_chado_schema_name$_data.expressionprop UNION SELECT * FROM public.expressionprop;
CREATE TRIGGER expressionprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.expressionprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.expressionprop_pkey_trigger_func();
CREATE RULE expressionprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.expressionprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.expressionprop VALUES(NEW.*)
  RETURNING expressionprop.*;
CREATE RULE expressionprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.expressionprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.expressionprop SET 
    expressionprop_id = NEW.expressionprop_id,
    expression_id = NEW.expression_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE expressionprop_id = NEW.expressionprop_id
  RETURNING expressionprop.*;


--
-- Name: feature_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature
    ADD CONSTRAINT feature_c1 UNIQUE (organism_id, uniquename, type_id);


--
-- Name: feature_cvterm_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_cvterm
    ADD CONSTRAINT feature_cvterm_c1 UNIQUE (feature_id, cvterm_id, pub_id);


--
-- Name: feature_cvterm_dbxref_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_cvterm_dbxref
    ADD CONSTRAINT feature_cvterm_dbxref_c1 UNIQUE (feature_cvterm_id, dbxref_id);


--
-- Name: feature_cvterm_dbxref_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_cvterm_dbxref
    ADD CONSTRAINT feature_cvterm_dbxref_pkey PRIMARY KEY (feature_cvterm_dbxref_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_cvterm_dbxref AS SELECT * FROM $temporary_chado_schema_name$_data.feature_cvterm_dbxref UNION SELECT * FROM public.feature_cvterm_dbxref;
CREATE TRIGGER feature_cvterm_dbxref_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_cvterm_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_cvterm_dbxref_pkey_trigger_func();
CREATE RULE feature_cvterm_dbxref_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_cvterm_dbxref DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_cvterm_dbxref VALUES(NEW.*)
  RETURNING feature_cvterm_dbxref.*;
CREATE RULE feature_cvterm_dbxref_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_cvterm_dbxref DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_cvterm_dbxref SET 
    feature_cvterm_dbxref_id = NEW.feature_cvterm_dbxref_id,
    feature_cvterm_id = NEW.feature_cvterm_id,
    dbxref_id = NEW.dbxref_id
  WHERE feature_cvterm_dbxref_id = NEW.feature_cvterm_dbxref_id
  RETURNING feature_cvterm_dbxref.*;


--
-- Name: feature_cvterm_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_cvterm
    ADD CONSTRAINT feature_cvterm_pkey PRIMARY KEY (feature_cvterm_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_cvterm AS SELECT * FROM $temporary_chado_schema_name$_data.feature_cvterm UNION SELECT * FROM public.feature_cvterm;
CREATE TRIGGER feature_cvterm_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_cvterm
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_cvterm_pkey_trigger_func();
CREATE RULE feature_cvterm_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_cvterm DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_cvterm VALUES(NEW.*)
  RETURNING feature_cvterm.*;
CREATE RULE feature_cvterm_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_cvterm DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_cvterm SET 
    feature_cvterm_id = NEW.feature_cvterm_id,
    feature_id = NEW.feature_id,
    cvterm_id = NEW.cvterm_id,
    pub_id = NEW.pub_id,
    is_not = NEW.is_not
  WHERE feature_cvterm_id = NEW.feature_cvterm_id
  RETURNING feature_cvterm.*;


--
-- Name: feature_cvterm_pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_cvterm_pub
    ADD CONSTRAINT feature_cvterm_pub_c1 UNIQUE (feature_cvterm_id, pub_id);


--
-- Name: feature_cvterm_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_cvterm_pub
    ADD CONSTRAINT feature_cvterm_pub_pkey PRIMARY KEY (feature_cvterm_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_cvterm_pub AS SELECT * FROM $temporary_chado_schema_name$_data.feature_cvterm_pub UNION SELECT * FROM public.feature_cvterm_pub;
CREATE TRIGGER feature_cvterm_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_cvterm_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_cvterm_pub_pkey_trigger_func();
CREATE RULE feature_cvterm_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_cvterm_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_cvterm_pub VALUES(NEW.*)
  RETURNING feature_cvterm_pub.*;
CREATE RULE feature_cvterm_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_cvterm_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_cvterm_pub SET 
    feature_cvterm_pub_id = NEW.feature_cvterm_pub_id,
    feature_cvterm_id = NEW.feature_cvterm_id,
    pub_id = NEW.pub_id
  WHERE feature_cvterm_pub_id = NEW.feature_cvterm_pub_id
  RETURNING feature_cvterm_pub.*;


--
-- Name: feature_cvtermprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_cvtermprop
    ADD CONSTRAINT feature_cvtermprop_c1 UNIQUE (feature_cvterm_id, type_id, rank);


--
-- Name: feature_cvtermprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_cvtermprop
    ADD CONSTRAINT feature_cvtermprop_pkey PRIMARY KEY (feature_cvtermprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_cvtermprop AS SELECT * FROM $temporary_chado_schema_name$_data.feature_cvtermprop UNION SELECT * FROM public.feature_cvtermprop;
CREATE TRIGGER feature_cvtermprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_cvtermprop_pkey_trigger_func();
CREATE RULE feature_cvtermprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_cvtermprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_cvtermprop VALUES(NEW.*)
  RETURNING feature_cvtermprop.*;
CREATE RULE feature_cvtermprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_cvtermprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_cvtermprop SET 
    feature_cvtermprop_id = NEW.feature_cvtermprop_id,
    feature_cvterm_id = NEW.feature_cvterm_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE feature_cvtermprop_id = NEW.feature_cvtermprop_id
  RETURNING feature_cvtermprop.*;


--
-- Name: feature_dbxref_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_dbxref
    ADD CONSTRAINT feature_dbxref_c1 UNIQUE (feature_id, dbxref_id);


--
-- Name: feature_dbxref_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_dbxref
    ADD CONSTRAINT feature_dbxref_pkey PRIMARY KEY (feature_dbxref_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_dbxref AS SELECT * FROM $temporary_chado_schema_name$_data.feature_dbxref UNION SELECT * FROM public.feature_dbxref;
CREATE TRIGGER feature_dbxref_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_dbxref_pkey_trigger_func();
CREATE RULE feature_dbxref_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_dbxref DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_dbxref VALUES(NEW.*)
  RETURNING feature_dbxref.*;
CREATE RULE feature_dbxref_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_dbxref DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_dbxref SET 
    feature_dbxref_id = NEW.feature_dbxref_id,
    feature_id = NEW.feature_id,
    dbxref_id = NEW.dbxref_id,
    is_current = NEW.is_current
  WHERE feature_dbxref_id = NEW.feature_dbxref_id
  RETURNING feature_dbxref.*;


--
-- Name: feature_expression_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_expression
    ADD CONSTRAINT feature_expression_c1 UNIQUE (expression_id, feature_id, pub_id);


--
-- Name: feature_expression_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_expression
    ADD CONSTRAINT feature_expression_pkey PRIMARY KEY (feature_expression_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_expression AS SELECT * FROM $temporary_chado_schema_name$_data.feature_expression UNION SELECT * FROM public.feature_expression;
CREATE TRIGGER feature_expression_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_expression
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_expression_pkey_trigger_func();
CREATE RULE feature_expression_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_expression DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_expression VALUES(NEW.*)
  RETURNING feature_expression.*;
CREATE RULE feature_expression_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_expression DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_expression SET 
    feature_expression_id = NEW.feature_expression_id,
    expression_id = NEW.expression_id,
    feature_id = NEW.feature_id,
    pub_id = NEW.pub_id
  WHERE feature_expression_id = NEW.feature_expression_id
  RETURNING feature_expression.*;


--
-- Name: feature_expressionprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_expressionprop
    ADD CONSTRAINT feature_expressionprop_c1 UNIQUE (feature_expression_id, type_id, rank);


--
-- Name: feature_expressionprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_expressionprop
    ADD CONSTRAINT feature_expressionprop_pkey PRIMARY KEY (feature_expressionprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_expressionprop AS SELECT * FROM $temporary_chado_schema_name$_data.feature_expressionprop UNION SELECT * FROM public.feature_expressionprop;
CREATE TRIGGER feature_expressionprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_expressionprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_expressionprop_pkey_trigger_func();
CREATE RULE feature_expressionprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_expressionprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_expressionprop VALUES(NEW.*)
  RETURNING feature_expressionprop.*;
CREATE RULE feature_expressionprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_expressionprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_expressionprop SET 
    feature_expressionprop_id = NEW.feature_expressionprop_id,
    feature_expression_id = NEW.feature_expression_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE feature_expressionprop_id = NEW.feature_expressionprop_id
  RETURNING feature_expressionprop.*;


--
-- Name: feature_genotype_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_genotype
    ADD CONSTRAINT feature_genotype_c1 UNIQUE (feature_id, genotype_id, cvterm_id, chromosome_id, rank, cgroup);


--
-- Name: feature_genotype_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_genotype
    ADD CONSTRAINT feature_genotype_pkey PRIMARY KEY (feature_genotype_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_genotype AS SELECT * FROM $temporary_chado_schema_name$_data.feature_genotype UNION SELECT * FROM public.feature_genotype;
CREATE TRIGGER feature_genotype_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_genotype
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_genotype_pkey_trigger_func();
CREATE RULE feature_genotype_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_genotype DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_genotype VALUES(NEW.*)
  RETURNING feature_genotype.*;
CREATE RULE feature_genotype_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_genotype DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_genotype SET 
    feature_genotype_id = NEW.feature_genotype_id,
    feature_id = NEW.feature_id,
    genotype_id = NEW.genotype_id,
    chromosome_id = NEW.chromosome_id,
    rank = NEW.rank,
    cgroup = NEW.cgroup,
    cvterm_id = NEW.cvterm_id
  WHERE feature_genotype_id = NEW.feature_genotype_id
  RETURNING feature_genotype.*;


--
-- Name: feature_phenotype_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_phenotype
    ADD CONSTRAINT feature_phenotype_c1 UNIQUE (feature_id, phenotype_id);


--
-- Name: feature_phenotype_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_phenotype
    ADD CONSTRAINT feature_phenotype_pkey PRIMARY KEY (feature_phenotype_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_phenotype AS SELECT * FROM $temporary_chado_schema_name$_data.feature_phenotype UNION SELECT * FROM public.feature_phenotype;
CREATE TRIGGER feature_phenotype_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_phenotype
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_phenotype_pkey_trigger_func();
CREATE RULE feature_phenotype_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_phenotype DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_phenotype VALUES(NEW.*)
  RETURNING feature_phenotype.*;
CREATE RULE feature_phenotype_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_phenotype DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_phenotype SET 
    feature_phenotype_id = NEW.feature_phenotype_id,
    feature_id = NEW.feature_id,
    phenotype_id = NEW.phenotype_id
  WHERE feature_phenotype_id = NEW.feature_phenotype_id
  RETURNING feature_phenotype.*;


--
-- Name: feature_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature
    ADD CONSTRAINT feature_pkey PRIMARY KEY (feature_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature AS SELECT * FROM $temporary_chado_schema_name$_data.feature UNION SELECT * FROM public.feature;
CREATE TRIGGER feature_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_pkey_trigger_func();
CREATE RULE feature_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature VALUES(NEW.*)
  RETURNING feature.*;
CREATE RULE feature_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature SET 
    feature_id = NEW.feature_id,
    dbxref_id = NEW.dbxref_id,
    organism_id = NEW.organism_id,
    name = NEW.name,
    uniquename = NEW.uniquename,
    residues = NEW.residues,
    seqlen = NEW.seqlen,
    md5checksum = NEW.md5checksum,
    type_id = NEW.type_id,
    is_analysis = NEW.is_analysis,
    is_obsolete = NEW.is_obsolete,
    timeaccessioned = NEW.timeaccessioned,
    timelastmodified = NEW.timelastmodified
  WHERE feature_id = NEW.feature_id
  RETURNING feature.*;


--
-- Name: feature_pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_pub
    ADD CONSTRAINT feature_pub_c1 UNIQUE (feature_id, pub_id);


--
-- Name: feature_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_pub
    ADD CONSTRAINT feature_pub_pkey PRIMARY KEY (feature_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_pub AS SELECT * FROM $temporary_chado_schema_name$_data.feature_pub UNION SELECT * FROM public.feature_pub;
CREATE TRIGGER feature_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_pub_pkey_trigger_func();
CREATE RULE feature_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_pub VALUES(NEW.*)
  RETURNING feature_pub.*;
CREATE RULE feature_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_pub SET 
    feature_pub_id = NEW.feature_pub_id,
    feature_id = NEW.feature_id,
    pub_id = NEW.pub_id
  WHERE feature_pub_id = NEW.feature_pub_id
  RETURNING feature_pub.*;


--
-- Name: feature_pubprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_pubprop
    ADD CONSTRAINT feature_pubprop_c1 UNIQUE (feature_pub_id, type_id, rank);


--
-- Name: feature_pubprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_pubprop
    ADD CONSTRAINT feature_pubprop_pkey PRIMARY KEY (feature_pubprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_pubprop AS SELECT * FROM $temporary_chado_schema_name$_data.feature_pubprop UNION SELECT * FROM public.feature_pubprop;
CREATE TRIGGER feature_pubprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_pubprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_pubprop_pkey_trigger_func();
CREATE RULE feature_pubprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_pubprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_pubprop VALUES(NEW.*)
  RETURNING feature_pubprop.*;
CREATE RULE feature_pubprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_pubprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_pubprop SET 
    feature_pubprop_id = NEW.feature_pubprop_id,
    feature_pub_id = NEW.feature_pub_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE feature_pubprop_id = NEW.feature_pubprop_id
  RETURNING feature_pubprop.*;


--
-- Name: feature_relationship_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_relationship
    ADD CONSTRAINT feature_relationship_c1 UNIQUE (subject_id, object_id, type_id, rank);


--
-- Name: feature_relationship_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_relationship
    ADD CONSTRAINT feature_relationship_pkey PRIMARY KEY (feature_relationship_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_relationship AS SELECT * FROM $temporary_chado_schema_name$_data.feature_relationship UNION SELECT * FROM public.feature_relationship;
CREATE TRIGGER feature_relationship_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_relationship_pkey_trigger_func();
CREATE RULE feature_relationship_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_relationship DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_relationship VALUES(NEW.*)
  RETURNING feature_relationship.*;
CREATE RULE feature_relationship_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_relationship DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_relationship SET 
    feature_relationship_id = NEW.feature_relationship_id,
    subject_id = NEW.subject_id,
    object_id = NEW.object_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE feature_relationship_id = NEW.feature_relationship_id
  RETURNING feature_relationship.*;


--
-- Name: feature_relationship_pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_relationship_pub
    ADD CONSTRAINT feature_relationship_pub_c1 UNIQUE (feature_relationship_id, pub_id);


--
-- Name: feature_relationship_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_relationship_pub
    ADD CONSTRAINT feature_relationship_pub_pkey PRIMARY KEY (feature_relationship_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_relationship_pub AS SELECT * FROM $temporary_chado_schema_name$_data.feature_relationship_pub UNION SELECT * FROM public.feature_relationship_pub;
CREATE TRIGGER feature_relationship_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_relationship_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_relationship_pub_pkey_trigger_func();
CREATE RULE feature_relationship_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_relationship_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_relationship_pub VALUES(NEW.*)
  RETURNING feature_relationship_pub.*;
CREATE RULE feature_relationship_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_relationship_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_relationship_pub SET 
    feature_relationship_pub_id = NEW.feature_relationship_pub_id,
    feature_relationship_id = NEW.feature_relationship_id,
    pub_id = NEW.pub_id
  WHERE feature_relationship_pub_id = NEW.feature_relationship_pub_id
  RETURNING feature_relationship_pub.*;


--
-- Name: feature_relationshipprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_relationshipprop
    ADD CONSTRAINT feature_relationshipprop_c1 UNIQUE (feature_relationship_id, type_id, rank);


--
-- Name: feature_relationshipprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_relationshipprop
    ADD CONSTRAINT feature_relationshipprop_pkey PRIMARY KEY (feature_relationshipprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_relationshipprop AS SELECT * FROM $temporary_chado_schema_name$_data.feature_relationshipprop UNION SELECT * FROM public.feature_relationshipprop;
CREATE TRIGGER feature_relationshipprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_relationshipprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_relationshipprop_pkey_trigger_func();
CREATE RULE feature_relationshipprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_relationshipprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_relationshipprop VALUES(NEW.*)
  RETURNING feature_relationshipprop.*;
CREATE RULE feature_relationshipprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_relationshipprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_relationshipprop SET 
    feature_relationshipprop_id = NEW.feature_relationshipprop_id,
    feature_relationship_id = NEW.feature_relationship_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE feature_relationshipprop_id = NEW.feature_relationshipprop_id
  RETURNING feature_relationshipprop.*;


--
-- Name: feature_relationshipprop_pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_relationshipprop_pub
    ADD CONSTRAINT feature_relationshipprop_pub_c1 UNIQUE (feature_relationshipprop_id, pub_id);


--
-- Name: feature_relationshipprop_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_relationshipprop_pub
    ADD CONSTRAINT feature_relationshipprop_pub_pkey PRIMARY KEY (feature_relationshipprop_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_relationshipprop_pub AS SELECT * FROM $temporary_chado_schema_name$_data.feature_relationshipprop_pub UNION SELECT * FROM public.feature_relationshipprop_pub;
CREATE TRIGGER feature_relationshipprop_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_relationshipprop_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_relationshipprop_pub_pkey_trigger_func();
CREATE RULE feature_relationshipprop_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_relationshipprop_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_relationshipprop_pub VALUES(NEW.*)
  RETURNING feature_relationshipprop_pub.*;
CREATE RULE feature_relationshipprop_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_relationshipprop_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_relationshipprop_pub SET 
    feature_relationshipprop_pub_id = NEW.feature_relationshipprop_pub_id,
    feature_relationshipprop_id = NEW.feature_relationshipprop_id,
    pub_id = NEW.pub_id
  WHERE feature_relationshipprop_pub_id = NEW.feature_relationshipprop_pub_id
  RETURNING feature_relationshipprop_pub.*;


--
-- Name: feature_synonym_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_synonym
    ADD CONSTRAINT feature_synonym_c1 UNIQUE (synonym_id, feature_id, pub_id);


--
-- Name: feature_synonym_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feature_synonym
    ADD CONSTRAINT feature_synonym_pkey PRIMARY KEY (feature_synonym_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.feature_synonym AS SELECT * FROM $temporary_chado_schema_name$_data.feature_synonym UNION SELECT * FROM public.feature_synonym;
CREATE TRIGGER feature_synonym_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.feature_synonym
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.feature_synonym_pkey_trigger_func();
CREATE RULE feature_synonym_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.feature_synonym DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.feature_synonym VALUES(NEW.*)
  RETURNING feature_synonym.*;
CREATE RULE feature_synonym_update AS
  ON UPDATE TO $temporary_chado_schema_name$.feature_synonym DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.feature_synonym SET 
    feature_synonym_id = NEW.feature_synonym_id,
    synonym_id = NEW.synonym_id,
    feature_id = NEW.feature_id,
    pub_id = NEW.pub_id,
    is_current = NEW.is_current,
    is_internal = NEW.is_internal
  WHERE feature_synonym_id = NEW.feature_synonym_id
  RETURNING feature_synonym.*;


--
-- Name: featureloc_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featureloc
    ADD CONSTRAINT featureloc_c1 UNIQUE (feature_id, locgroup, rank);


--
-- Name: featureloc_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featureloc
    ADD CONSTRAINT featureloc_pkey PRIMARY KEY (featureloc_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.featureloc AS SELECT * FROM $temporary_chado_schema_name$_data.featureloc UNION SELECT * FROM public.featureloc;
CREATE TRIGGER featureloc_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.featureloc
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featureloc_pkey_trigger_func();
CREATE RULE featureloc_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.featureloc DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.featureloc VALUES(NEW.*)
  RETURNING featureloc.*;
CREATE RULE featureloc_update AS
  ON UPDATE TO $temporary_chado_schema_name$.featureloc DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.featureloc SET 
    featureloc_id = NEW.featureloc_id,
    feature_id = NEW.feature_id,
    srcfeature_id = NEW.srcfeature_id,
    fmin = NEW.fmin,
    is_fmin_partial = NEW.is_fmin_partial,
    fmax = NEW.fmax,
    is_fmax_partial = NEW.is_fmax_partial,
    strand = NEW.strand,
    phase = NEW.phase,
    residue_info = NEW.residue_info,
    locgroup = NEW.locgroup,
    rank = NEW.rank
  WHERE featureloc_id = NEW.featureloc_id
  RETURNING featureloc.*;


--
-- Name: featureloc_pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featureloc_pub
    ADD CONSTRAINT featureloc_pub_c1 UNIQUE (featureloc_id, pub_id);


--
-- Name: featureloc_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featureloc_pub
    ADD CONSTRAINT featureloc_pub_pkey PRIMARY KEY (featureloc_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.featureloc_pub AS SELECT * FROM $temporary_chado_schema_name$_data.featureloc_pub UNION SELECT * FROM public.featureloc_pub;
CREATE TRIGGER featureloc_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.featureloc_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featureloc_pub_pkey_trigger_func();
CREATE RULE featureloc_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.featureloc_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.featureloc_pub VALUES(NEW.*)
  RETURNING featureloc_pub.*;
CREATE RULE featureloc_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.featureloc_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.featureloc_pub SET 
    featureloc_pub_id = NEW.featureloc_pub_id,
    featureloc_id = NEW.featureloc_id,
    pub_id = NEW.pub_id
  WHERE featureloc_pub_id = NEW.featureloc_pub_id
  RETURNING featureloc_pub.*;


--
-- Name: featuremap_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featuremap
    ADD CONSTRAINT featuremap_c1 UNIQUE (name);


--
-- Name: featuremap_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featuremap
    ADD CONSTRAINT featuremap_pkey PRIMARY KEY (featuremap_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.featuremap AS SELECT * FROM $temporary_chado_schema_name$_data.featuremap UNION SELECT * FROM public.featuremap;
CREATE TRIGGER featuremap_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.featuremap
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featuremap_pkey_trigger_func();
CREATE RULE featuremap_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.featuremap DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.featuremap VALUES(NEW.*)
  RETURNING featuremap.*;
CREATE RULE featuremap_update AS
  ON UPDATE TO $temporary_chado_schema_name$.featuremap DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.featuremap SET 
    featuremap_id = NEW.featuremap_id,
    name = NEW.name,
    description = NEW.description,
    unittype_id = NEW.unittype_id
  WHERE featuremap_id = NEW.featuremap_id
  RETURNING featuremap.*;


--
-- Name: featuremap_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featuremap_pub
    ADD CONSTRAINT featuremap_pub_pkey PRIMARY KEY (featuremap_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.featuremap_pub AS SELECT * FROM $temporary_chado_schema_name$_data.featuremap_pub UNION SELECT * FROM public.featuremap_pub;
CREATE TRIGGER featuremap_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.featuremap_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featuremap_pub_pkey_trigger_func();
CREATE RULE featuremap_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.featuremap_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.featuremap_pub VALUES(NEW.*)
  RETURNING featuremap_pub.*;
CREATE RULE featuremap_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.featuremap_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.featuremap_pub SET 
    featuremap_pub_id = NEW.featuremap_pub_id,
    featuremap_id = NEW.featuremap_id,
    pub_id = NEW.pub_id
  WHERE featuremap_pub_id = NEW.featuremap_pub_id
  RETURNING featuremap_pub.*;


--
-- Name: featurepos_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featurepos
    ADD CONSTRAINT featurepos_pkey PRIMARY KEY (featurepos_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.featurepos AS SELECT * FROM $temporary_chado_schema_name$_data.featurepos UNION SELECT * FROM public.featurepos;
CREATE TRIGGER featurepos_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.featurepos
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featurepos_pkey_trigger_func();
CREATE RULE featurepos_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.featurepos DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.featurepos VALUES(NEW.*)
  RETURNING featurepos.*;
CREATE RULE featurepos_update AS
  ON UPDATE TO $temporary_chado_schema_name$.featurepos DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.featurepos SET 
    featurepos_id = NEW.featurepos_id,
    featuremap_id = NEW.featuremap_id,
    feature_id = NEW.feature_id,
    map_feature_id = NEW.map_feature_id,
    mappos = NEW.mappos
  WHERE featurepos_id = NEW.featurepos_id
  RETURNING featurepos.*;


--
-- Name: featureprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featureprop
    ADD CONSTRAINT featureprop_c1 UNIQUE (feature_id, type_id, rank);


--
-- Name: featureprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featureprop
    ADD CONSTRAINT featureprop_pkey PRIMARY KEY (featureprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.featureprop AS SELECT * FROM $temporary_chado_schema_name$_data.featureprop UNION SELECT * FROM public.featureprop;
CREATE TRIGGER featureprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.featureprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featureprop_pkey_trigger_func();
CREATE RULE featureprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.featureprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.featureprop VALUES(NEW.*)
  RETURNING featureprop.*;
CREATE RULE featureprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.featureprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.featureprop SET 
    featureprop_id = NEW.featureprop_id,
    feature_id = NEW.feature_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE featureprop_id = NEW.featureprop_id
  RETURNING featureprop.*;


--
-- Name: featureprop_pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featureprop_pub
    ADD CONSTRAINT featureprop_pub_c1 UNIQUE (featureprop_id, pub_id);


--
-- Name: featureprop_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featureprop_pub
    ADD CONSTRAINT featureprop_pub_pkey PRIMARY KEY (featureprop_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.featureprop_pub AS SELECT * FROM $temporary_chado_schema_name$_data.featureprop_pub UNION SELECT * FROM public.featureprop_pub;
CREATE TRIGGER featureprop_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.featureprop_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featureprop_pub_pkey_trigger_func();
CREATE RULE featureprop_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.featureprop_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.featureprop_pub VALUES(NEW.*)
  RETURNING featureprop_pub.*;
CREATE RULE featureprop_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.featureprop_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.featureprop_pub SET 
    featureprop_pub_id = NEW.featureprop_pub_id,
    featureprop_id = NEW.featureprop_id,
    pub_id = NEW.pub_id
  WHERE featureprop_pub_id = NEW.featureprop_pub_id
  RETURNING featureprop_pub.*;


--
-- Name: featurerange_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY featurerange
    ADD CONSTRAINT featurerange_pkey PRIMARY KEY (featurerange_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.featurerange AS SELECT * FROM $temporary_chado_schema_name$_data.featurerange UNION SELECT * FROM public.featurerange;
CREATE TRIGGER featurerange_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.featurerange
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.featurerange_pkey_trigger_func();
CREATE RULE featurerange_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.featurerange DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.featurerange VALUES(NEW.*)
  RETURNING featurerange.*;
CREATE RULE featurerange_update AS
  ON UPDATE TO $temporary_chado_schema_name$.featurerange DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.featurerange SET 
    featurerange_id = NEW.featurerange_id,
    featuremap_id = NEW.featuremap_id,
    feature_id = NEW.feature_id,
    leftstartf_id = NEW.leftstartf_id,
    leftendf_id = NEW.leftendf_id,
    rightstartf_id = NEW.rightstartf_id,
    rightendf_id = NEW.rightendf_id,
    rangestr = NEW.rangestr
  WHERE featurerange_id = NEW.featurerange_id
  RETURNING featurerange.*;


--
-- Name: genotype_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY genotype
    ADD CONSTRAINT genotype_c1 UNIQUE (uniquename);


--
-- Name: genotype_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY genotype
    ADD CONSTRAINT genotype_pkey PRIMARY KEY (genotype_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.genotype AS SELECT * FROM $temporary_chado_schema_name$_data.genotype UNION SELECT * FROM public.genotype;
CREATE TRIGGER genotype_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.genotype
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.genotype_pkey_trigger_func();
CREATE RULE genotype_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.genotype DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.genotype VALUES(NEW.*)
  RETURNING genotype.*;
CREATE RULE genotype_update AS
  ON UPDATE TO $temporary_chado_schema_name$.genotype DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.genotype SET 
    genotype_id = NEW.genotype_id,
    name = NEW.name,
    uniquename = NEW.uniquename,
    description = NEW.description
  WHERE genotype_id = NEW.genotype_id
  RETURNING genotype.*;


--
-- Name: gff_sort_tmp_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gff_sort_tmp
    ADD CONSTRAINT gff_sort_tmp_pkey PRIMARY KEY (row_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.gff_sort_tmp AS SELECT * FROM $temporary_chado_schema_name$_data.gff_sort_tmp UNION SELECT * FROM public.gff_sort_tmp;
CREATE TRIGGER gff_sort_tmp_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.gff_sort_tmp
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.gff_sort_tmp_pkey_trigger_func();
CREATE RULE gff_sort_tmp_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.gff_sort_tmp DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.gff_sort_tmp VALUES(NEW.*)
  RETURNING gff_sort_tmp.*;
CREATE RULE gff_sort_tmp_update AS
  ON UPDATE TO $temporary_chado_schema_name$.gff_sort_tmp DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.gff_sort_tmp SET 
    refseq = NEW.refseq,
    id = NEW.id,
    parent = NEW.parent,
    gffline = NEW.gffline,
    row_id = NEW.row_id
  WHERE row_id = NEW.row_id
  RETURNING gff_sort_tmp.*;


--
-- Name: library_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY library
    ADD CONSTRAINT library_c1 UNIQUE (organism_id, uniquename, type_id);


--
-- Name: library_cvterm_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY library_cvterm
    ADD CONSTRAINT library_cvterm_c1 UNIQUE (library_id, cvterm_id, pub_id);


--
-- Name: library_cvterm_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY library_cvterm
    ADD CONSTRAINT library_cvterm_pkey PRIMARY KEY (library_cvterm_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.library_cvterm AS SELECT * FROM $temporary_chado_schema_name$_data.library_cvterm UNION SELECT * FROM public.library_cvterm;
CREATE TRIGGER library_cvterm_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.library_cvterm
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.library_cvterm_pkey_trigger_func();
CREATE RULE library_cvterm_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.library_cvterm DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.library_cvterm VALUES(NEW.*)
  RETURNING library_cvterm.*;
CREATE RULE library_cvterm_update AS
  ON UPDATE TO $temporary_chado_schema_name$.library_cvterm DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.library_cvterm SET 
    library_cvterm_id = NEW.library_cvterm_id,
    library_id = NEW.library_id,
    cvterm_id = NEW.cvterm_id,
    pub_id = NEW.pub_id
  WHERE library_cvterm_id = NEW.library_cvterm_id
  RETURNING library_cvterm.*;


--
-- Name: library_feature_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY library_feature
    ADD CONSTRAINT library_feature_c1 UNIQUE (library_id, feature_id);


--
-- Name: library_feature_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY library_feature
    ADD CONSTRAINT library_feature_pkey PRIMARY KEY (library_feature_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.library_feature AS SELECT * FROM $temporary_chado_schema_name$_data.library_feature UNION SELECT * FROM public.library_feature;
CREATE TRIGGER library_feature_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.library_feature
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.library_feature_pkey_trigger_func();
CREATE RULE library_feature_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.library_feature DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.library_feature VALUES(NEW.*)
  RETURNING library_feature.*;
CREATE RULE library_feature_update AS
  ON UPDATE TO $temporary_chado_schema_name$.library_feature DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.library_feature SET 
    library_feature_id = NEW.library_feature_id,
    library_id = NEW.library_id,
    feature_id = NEW.feature_id
  WHERE library_feature_id = NEW.library_feature_id
  RETURNING library_feature.*;


--
-- Name: library_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY library
    ADD CONSTRAINT library_pkey PRIMARY KEY (library_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.library AS SELECT * FROM $temporary_chado_schema_name$_data.library UNION SELECT * FROM public.library;
CREATE TRIGGER library_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.library
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.library_pkey_trigger_func();
CREATE RULE library_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.library DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.library VALUES(NEW.*)
  RETURNING library.*;
CREATE RULE library_update AS
  ON UPDATE TO $temporary_chado_schema_name$.library DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.library SET 
    library_id = NEW.library_id,
    organism_id = NEW.organism_id,
    name = NEW.name,
    uniquename = NEW.uniquename,
    type_id = NEW.type_id
  WHERE library_id = NEW.library_id
  RETURNING library.*;


--
-- Name: library_pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY library_pub
    ADD CONSTRAINT library_pub_c1 UNIQUE (library_id, pub_id);


--
-- Name: library_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY library_pub
    ADD CONSTRAINT library_pub_pkey PRIMARY KEY (library_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.library_pub AS SELECT * FROM $temporary_chado_schema_name$_data.library_pub UNION SELECT * FROM public.library_pub;
CREATE TRIGGER library_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.library_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.library_pub_pkey_trigger_func();
CREATE RULE library_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.library_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.library_pub VALUES(NEW.*)
  RETURNING library_pub.*;
CREATE RULE library_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.library_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.library_pub SET 
    library_pub_id = NEW.library_pub_id,
    library_id = NEW.library_id,
    pub_id = NEW.pub_id
  WHERE library_pub_id = NEW.library_pub_id
  RETURNING library_pub.*;


--
-- Name: library_synonym_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY library_synonym
    ADD CONSTRAINT library_synonym_c1 UNIQUE (synonym_id, library_id, pub_id);


--
-- Name: library_synonym_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY library_synonym
    ADD CONSTRAINT library_synonym_pkey PRIMARY KEY (library_synonym_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.library_synonym AS SELECT * FROM $temporary_chado_schema_name$_data.library_synonym UNION SELECT * FROM public.library_synonym;
CREATE TRIGGER library_synonym_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.library_synonym
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.library_synonym_pkey_trigger_func();
CREATE RULE library_synonym_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.library_synonym DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.library_synonym VALUES(NEW.*)
  RETURNING library_synonym.*;
CREATE RULE library_synonym_update AS
  ON UPDATE TO $temporary_chado_schema_name$.library_synonym DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.library_synonym SET 
    library_synonym_id = NEW.library_synonym_id,
    synonym_id = NEW.synonym_id,
    library_id = NEW.library_id,
    pub_id = NEW.pub_id,
    is_current = NEW.is_current,
    is_internal = NEW.is_internal
  WHERE library_synonym_id = NEW.library_synonym_id
  RETURNING library_synonym.*;


--
-- Name: libraryprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY libraryprop
    ADD CONSTRAINT libraryprop_c1 UNIQUE (library_id, type_id, rank);


--
-- Name: libraryprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY libraryprop
    ADD CONSTRAINT libraryprop_pkey PRIMARY KEY (libraryprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.libraryprop AS SELECT * FROM $temporary_chado_schema_name$_data.libraryprop UNION SELECT * FROM public.libraryprop;
CREATE TRIGGER libraryprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.libraryprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.libraryprop_pkey_trigger_func();
CREATE RULE libraryprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.libraryprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.libraryprop VALUES(NEW.*)
  RETURNING libraryprop.*;
CREATE RULE libraryprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.libraryprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.libraryprop SET 
    libraryprop_id = NEW.libraryprop_id,
    library_id = NEW.library_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE libraryprop_id = NEW.libraryprop_id
  RETURNING libraryprop.*;


--
-- Name: magedocumentation_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY magedocumentation
    ADD CONSTRAINT magedocumentation_pkey PRIMARY KEY (magedocumentation_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.magedocumentation AS SELECT * FROM $temporary_chado_schema_name$_data.magedocumentation UNION SELECT * FROM public.magedocumentation;
CREATE TRIGGER magedocumentation_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.magedocumentation
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.magedocumentation_pkey_trigger_func();
CREATE RULE magedocumentation_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.magedocumentation DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.magedocumentation VALUES(NEW.*)
  RETURNING magedocumentation.*;
CREATE RULE magedocumentation_update AS
  ON UPDATE TO $temporary_chado_schema_name$.magedocumentation DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.magedocumentation SET 
    magedocumentation_id = NEW.magedocumentation_id,
    mageml_id = NEW.mageml_id,
    tableinfo_id = NEW.tableinfo_id,
    row_id = NEW.row_id,
    mageidentifier = NEW.mageidentifier
  WHERE magedocumentation_id = NEW.magedocumentation_id
  RETURNING magedocumentation.*;


--
-- Name: mageml_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mageml
    ADD CONSTRAINT mageml_pkey PRIMARY KEY (mageml_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.mageml AS SELECT * FROM $temporary_chado_schema_name$_data.mageml UNION SELECT * FROM public.mageml;
CREATE TRIGGER mageml_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.mageml
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.mageml_pkey_trigger_func();
CREATE RULE mageml_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.mageml DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.mageml VALUES(NEW.*)
  RETURNING mageml.*;
CREATE RULE mageml_update AS
  ON UPDATE TO $temporary_chado_schema_name$.mageml DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.mageml SET 
    mageml_id = NEW.mageml_id,
    mage_package = NEW.mage_package,
    mage_ml = NEW.mage_ml
  WHERE mageml_id = NEW.mageml_id
  RETURNING mageml.*;


--
-- Name: organism_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organism
    ADD CONSTRAINT organism_c1 UNIQUE (genus, species);


--
-- Name: organism_dbxref_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organism_dbxref
    ADD CONSTRAINT organism_dbxref_c1 UNIQUE (organism_id, dbxref_id);


--
-- Name: organism_dbxref_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organism_dbxref
    ADD CONSTRAINT organism_dbxref_pkey PRIMARY KEY (organism_dbxref_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.organism_dbxref AS SELECT * FROM $temporary_chado_schema_name$_data.organism_dbxref UNION SELECT * FROM public.organism_dbxref;
CREATE TRIGGER organism_dbxref_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.organism_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.organism_dbxref_pkey_trigger_func();
CREATE RULE organism_dbxref_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.organism_dbxref DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.organism_dbxref VALUES(NEW.*)
  RETURNING organism_dbxref.*;
CREATE RULE organism_dbxref_update AS
  ON UPDATE TO $temporary_chado_schema_name$.organism_dbxref DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.organism_dbxref SET 
    organism_dbxref_id = NEW.organism_dbxref_id,
    organism_id = NEW.organism_id,
    dbxref_id = NEW.dbxref_id
  WHERE organism_dbxref_id = NEW.organism_dbxref_id
  RETURNING organism_dbxref.*;


--
-- Name: organism_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organism
    ADD CONSTRAINT organism_pkey PRIMARY KEY (organism_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.organism AS SELECT * FROM $temporary_chado_schema_name$_data.organism UNION SELECT * FROM public.organism;
CREATE TRIGGER organism_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.organism
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.organism_pkey_trigger_func();
CREATE RULE organism_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.organism DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.organism VALUES(NEW.*)
  RETURNING organism.*;
CREATE RULE organism_update AS
  ON UPDATE TO $temporary_chado_schema_name$.organism DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.organism SET 
    organism_id = NEW.organism_id,
    abbreviation = NEW.abbreviation,
    genus = NEW.genus,
    species = NEW.species,
    common_name = NEW.common_name,
    comment = NEW.comment
  WHERE organism_id = NEW.organism_id
  RETURNING organism.*;


--
-- Name: organismprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organismprop
    ADD CONSTRAINT organismprop_c1 UNIQUE (organism_id, type_id, rank);


--
-- Name: organismprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organismprop
    ADD CONSTRAINT organismprop_pkey PRIMARY KEY (organismprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.organismprop AS SELECT * FROM $temporary_chado_schema_name$_data.organismprop UNION SELECT * FROM public.organismprop;
CREATE TRIGGER organismprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.organismprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.organismprop_pkey_trigger_func();
CREATE RULE organismprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.organismprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.organismprop VALUES(NEW.*)
  RETURNING organismprop.*;
CREATE RULE organismprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.organismprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.organismprop SET 
    organismprop_id = NEW.organismprop_id,
    organism_id = NEW.organism_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE organismprop_id = NEW.organismprop_id
  RETURNING organismprop.*;


--
-- Name: phendesc_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phendesc
    ADD CONSTRAINT phendesc_c1 UNIQUE (genotype_id, environment_id, type_id, pub_id);


--
-- Name: phendesc_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phendesc
    ADD CONSTRAINT phendesc_pkey PRIMARY KEY (phendesc_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phendesc AS SELECT * FROM $temporary_chado_schema_name$_data.phendesc UNION SELECT * FROM public.phendesc;
CREATE TRIGGER phendesc_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phendesc
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phendesc_pkey_trigger_func();
CREATE RULE phendesc_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phendesc DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phendesc VALUES(NEW.*)
  RETURNING phendesc.*;
CREATE RULE phendesc_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phendesc DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phendesc SET 
    phendesc_id = NEW.phendesc_id,
    genotype_id = NEW.genotype_id,
    environment_id = NEW.environment_id,
    description = NEW.description,
    type_id = NEW.type_id,
    pub_id = NEW.pub_id
  WHERE phendesc_id = NEW.phendesc_id
  RETURNING phendesc.*;


--
-- Name: phenotype_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenotype
    ADD CONSTRAINT phenotype_c1 UNIQUE (uniquename);


--
-- Name: phenotype_comparison_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenotype_comparison
    ADD CONSTRAINT phenotype_comparison_c1 UNIQUE (genotype1_id, environment1_id, genotype2_id, environment2_id, phenotype1_id, type_id, pub_id);


--
-- Name: phenotype_comparison_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenotype_comparison
    ADD CONSTRAINT phenotype_comparison_pkey PRIMARY KEY (phenotype_comparison_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phenotype_comparison AS SELECT * FROM $temporary_chado_schema_name$_data.phenotype_comparison UNION SELECT * FROM public.phenotype_comparison;
CREATE TRIGGER phenotype_comparison_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phenotype_comparison
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phenotype_comparison_pkey_trigger_func();
CREATE RULE phenotype_comparison_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phenotype_comparison DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phenotype_comparison VALUES(NEW.*)
  RETURNING phenotype_comparison.*;
CREATE RULE phenotype_comparison_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phenotype_comparison DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phenotype_comparison SET 
    phenotype_comparison_id = NEW.phenotype_comparison_id,
    genotype1_id = NEW.genotype1_id,
    environment1_id = NEW.environment1_id,
    genotype2_id = NEW.genotype2_id,
    environment2_id = NEW.environment2_id,
    phenotype1_id = NEW.phenotype1_id,
    phenotype2_id = NEW.phenotype2_id,
    type_id = NEW.type_id,
    pub_id = NEW.pub_id
  WHERE phenotype_comparison_id = NEW.phenotype_comparison_id
  RETURNING phenotype_comparison.*;


--
-- Name: phenotype_cvterm_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenotype_cvterm
    ADD CONSTRAINT phenotype_cvterm_c1 UNIQUE (phenotype_id, cvterm_id);


--
-- Name: phenotype_cvterm_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenotype_cvterm
    ADD CONSTRAINT phenotype_cvterm_pkey PRIMARY KEY (phenotype_cvterm_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phenotype_cvterm AS SELECT * FROM $temporary_chado_schema_name$_data.phenotype_cvterm UNION SELECT * FROM public.phenotype_cvterm;
CREATE TRIGGER phenotype_cvterm_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phenotype_cvterm
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phenotype_cvterm_pkey_trigger_func();
CREATE RULE phenotype_cvterm_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phenotype_cvterm DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phenotype_cvterm VALUES(NEW.*)
  RETURNING phenotype_cvterm.*;
CREATE RULE phenotype_cvterm_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phenotype_cvterm DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phenotype_cvterm SET 
    phenotype_cvterm_id = NEW.phenotype_cvterm_id,
    phenotype_id = NEW.phenotype_id,
    cvterm_id = NEW.cvterm_id
  WHERE phenotype_cvterm_id = NEW.phenotype_cvterm_id
  RETURNING phenotype_cvterm.*;


--
-- Name: phenotype_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenotype
    ADD CONSTRAINT phenotype_pkey PRIMARY KEY (phenotype_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phenotype AS SELECT * FROM $temporary_chado_schema_name$_data.phenotype UNION SELECT * FROM public.phenotype;
CREATE TRIGGER phenotype_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phenotype
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phenotype_pkey_trigger_func();
CREATE RULE phenotype_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phenotype DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phenotype VALUES(NEW.*)
  RETURNING phenotype.*;
CREATE RULE phenotype_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phenotype DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phenotype SET 
    phenotype_id = NEW.phenotype_id,
    uniquename = NEW.uniquename,
    observable_id = NEW.observable_id,
    attr_id = NEW.attr_id,
    value = NEW.value,
    cvalue_id = NEW.cvalue_id,
    assay_id = NEW.assay_id
  WHERE phenotype_id = NEW.phenotype_id
  RETURNING phenotype.*;


--
-- Name: phenstatement_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenstatement
    ADD CONSTRAINT phenstatement_c1 UNIQUE (genotype_id, phenotype_id, environment_id, type_id, pub_id);


--
-- Name: phenstatement_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenstatement
    ADD CONSTRAINT phenstatement_pkey PRIMARY KEY (phenstatement_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phenstatement AS SELECT * FROM $temporary_chado_schema_name$_data.phenstatement UNION SELECT * FROM public.phenstatement;
CREATE TRIGGER phenstatement_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phenstatement
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phenstatement_pkey_trigger_func();
CREATE RULE phenstatement_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phenstatement DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phenstatement VALUES(NEW.*)
  RETURNING phenstatement.*;
CREATE RULE phenstatement_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phenstatement DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phenstatement SET 
    phenstatement_id = NEW.phenstatement_id,
    genotype_id = NEW.genotype_id,
    environment_id = NEW.environment_id,
    phenotype_id = NEW.phenotype_id,
    type_id = NEW.type_id,
    pub_id = NEW.pub_id
  WHERE phenstatement_id = NEW.phenstatement_id
  RETURNING phenstatement.*;


--
-- Name: phylonode_dbxref_phylonode_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonode_dbxref
    ADD CONSTRAINT phylonode_dbxref_phylonode_id_key UNIQUE (phylonode_id, dbxref_id);


--
-- Name: phylonode_dbxref_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonode_dbxref
    ADD CONSTRAINT phylonode_dbxref_pkey PRIMARY KEY (phylonode_dbxref_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phylonode_dbxref AS SELECT * FROM $temporary_chado_schema_name$_data.phylonode_dbxref UNION SELECT * FROM public.phylonode_dbxref;
CREATE TRIGGER phylonode_dbxref_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phylonode_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phylonode_dbxref_pkey_trigger_func();
CREATE RULE phylonode_dbxref_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phylonode_dbxref DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phylonode_dbxref VALUES(NEW.*)
  RETURNING phylonode_dbxref.*;
CREATE RULE phylonode_dbxref_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phylonode_dbxref DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phylonode_dbxref SET 
    phylonode_dbxref_id = NEW.phylonode_dbxref_id,
    phylonode_id = NEW.phylonode_id,
    dbxref_id = NEW.dbxref_id
  WHERE phylonode_dbxref_id = NEW.phylonode_dbxref_id
  RETURNING phylonode_dbxref.*;


--
-- Name: phylonode_organism_phylonode_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonode_organism
    ADD CONSTRAINT phylonode_organism_phylonode_id_key UNIQUE (phylonode_id);


--
-- Name: phylonode_organism_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonode_organism
    ADD CONSTRAINT phylonode_organism_pkey PRIMARY KEY (phylonode_organism_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phylonode_organism AS SELECT * FROM $temporary_chado_schema_name$_data.phylonode_organism UNION SELECT * FROM public.phylonode_organism;
CREATE TRIGGER phylonode_organism_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phylonode_organism
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phylonode_organism_pkey_trigger_func();
CREATE RULE phylonode_organism_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phylonode_organism DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phylonode_organism VALUES(NEW.*)
  RETURNING phylonode_organism.*;
CREATE RULE phylonode_organism_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phylonode_organism DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phylonode_organism SET 
    phylonode_organism_id = NEW.phylonode_organism_id,
    phylonode_id = NEW.phylonode_id,
    organism_id = NEW.organism_id
  WHERE phylonode_organism_id = NEW.phylonode_organism_id
  RETURNING phylonode_organism.*;


--
-- Name: phylonode_phylotree_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonode
    ADD CONSTRAINT phylonode_phylotree_id_key UNIQUE (phylotree_id, left_idx);


--
-- Name: phylonode_phylotree_id_key1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonode
    ADD CONSTRAINT phylonode_phylotree_id_key1 UNIQUE (phylotree_id, right_idx);


--
-- Name: phylonode_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonode
    ADD CONSTRAINT phylonode_pkey PRIMARY KEY (phylonode_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phylonode AS SELECT * FROM $temporary_chado_schema_name$_data.phylonode UNION SELECT * FROM public.phylonode;
CREATE TRIGGER phylonode_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phylonode
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phylonode_pkey_trigger_func();
CREATE RULE phylonode_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phylonode DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phylonode VALUES(NEW.*)
  RETURNING phylonode.*;
CREATE RULE phylonode_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phylonode DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phylonode SET 
    phylonode_id = NEW.phylonode_id,
    phylotree_id = NEW.phylotree_id,
    parent_phylonode_id = NEW.parent_phylonode_id,
    left_idx = NEW.left_idx,
    right_idx = NEW.right_idx,
    type_id = NEW.type_id,
    feature_id = NEW.feature_id,
    label = NEW.label,
    distance = NEW.distance
  WHERE phylonode_id = NEW.phylonode_id
  RETURNING phylonode.*;


--
-- Name: phylonode_pub_phylonode_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonode_pub
    ADD CONSTRAINT phylonode_pub_phylonode_id_key UNIQUE (phylonode_id, pub_id);


--
-- Name: phylonode_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonode_pub
    ADD CONSTRAINT phylonode_pub_pkey PRIMARY KEY (phylonode_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phylonode_pub AS SELECT * FROM $temporary_chado_schema_name$_data.phylonode_pub UNION SELECT * FROM public.phylonode_pub;
CREATE TRIGGER phylonode_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phylonode_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phylonode_pub_pkey_trigger_func();
CREATE RULE phylonode_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phylonode_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phylonode_pub VALUES(NEW.*)
  RETURNING phylonode_pub.*;
CREATE RULE phylonode_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phylonode_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phylonode_pub SET 
    phylonode_pub_id = NEW.phylonode_pub_id,
    phylonode_id = NEW.phylonode_id,
    pub_id = NEW.pub_id
  WHERE phylonode_pub_id = NEW.phylonode_pub_id
  RETURNING phylonode_pub.*;


--
-- Name: phylonode_relationship_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonode_relationship
    ADD CONSTRAINT phylonode_relationship_pkey PRIMARY KEY (phylonode_relationship_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phylonode_relationship AS SELECT * FROM $temporary_chado_schema_name$_data.phylonode_relationship UNION SELECT * FROM public.phylonode_relationship;
CREATE TRIGGER phylonode_relationship_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phylonode_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phylonode_relationship_pkey_trigger_func();
CREATE RULE phylonode_relationship_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phylonode_relationship DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phylonode_relationship VALUES(NEW.*)
  RETURNING phylonode_relationship.*;
CREATE RULE phylonode_relationship_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phylonode_relationship DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phylonode_relationship SET 
    phylonode_relationship_id = NEW.phylonode_relationship_id,
    subject_id = NEW.subject_id,
    object_id = NEW.object_id,
    type_id = NEW.type_id,
    rank = NEW.rank,
    phylotree_id = NEW.phylotree_id
  WHERE phylonode_relationship_id = NEW.phylonode_relationship_id
  RETURNING phylonode_relationship.*;


--
-- Name: phylonode_relationship_subject_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonode_relationship
    ADD CONSTRAINT phylonode_relationship_subject_id_key UNIQUE (subject_id, object_id, type_id);


--
-- Name: phylonodeprop_phylonode_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonodeprop
    ADD CONSTRAINT phylonodeprop_phylonode_id_key UNIQUE (phylonode_id, type_id, value, rank);


--
-- Name: phylonodeprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylonodeprop
    ADD CONSTRAINT phylonodeprop_pkey PRIMARY KEY (phylonodeprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phylonodeprop AS SELECT * FROM $temporary_chado_schema_name$_data.phylonodeprop UNION SELECT * FROM public.phylonodeprop;
CREATE TRIGGER phylonodeprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phylonodeprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phylonodeprop_pkey_trigger_func();
CREATE RULE phylonodeprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phylonodeprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phylonodeprop VALUES(NEW.*)
  RETURNING phylonodeprop.*;
CREATE RULE phylonodeprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phylonodeprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phylonodeprop SET 
    phylonodeprop_id = NEW.phylonodeprop_id,
    phylonode_id = NEW.phylonode_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE phylonodeprop_id = NEW.phylonodeprop_id
  RETURNING phylonodeprop.*;


--
-- Name: phylotree_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylotree
    ADD CONSTRAINT phylotree_pkey PRIMARY KEY (phylotree_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phylotree AS SELECT * FROM $temporary_chado_schema_name$_data.phylotree UNION SELECT * FROM public.phylotree;
CREATE TRIGGER phylotree_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phylotree
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phylotree_pkey_trigger_func();
CREATE RULE phylotree_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phylotree DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phylotree VALUES(NEW.*)
  RETURNING phylotree.*;
CREATE RULE phylotree_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phylotree DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phylotree SET 
    phylotree_id = NEW.phylotree_id,
    dbxref_id = NEW.dbxref_id,
    name = NEW.name,
    type_id = NEW.type_id,
    analysis_id = NEW.analysis_id,
    comment = NEW.comment
  WHERE phylotree_id = NEW.phylotree_id
  RETURNING phylotree.*;


--
-- Name: phylotree_pub_phylotree_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylotree_pub
    ADD CONSTRAINT phylotree_pub_phylotree_id_key UNIQUE (phylotree_id, pub_id);


--
-- Name: phylotree_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phylotree_pub
    ADD CONSTRAINT phylotree_pub_pkey PRIMARY KEY (phylotree_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.phylotree_pub AS SELECT * FROM $temporary_chado_schema_name$_data.phylotree_pub UNION SELECT * FROM public.phylotree_pub;
CREATE TRIGGER phylotree_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.phylotree_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.phylotree_pub_pkey_trigger_func();
CREATE RULE phylotree_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.phylotree_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.phylotree_pub VALUES(NEW.*)
  RETURNING phylotree_pub.*;
CREATE RULE phylotree_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.phylotree_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.phylotree_pub SET 
    phylotree_pub_id = NEW.phylotree_pub_id,
    phylotree_id = NEW.phylotree_id,
    pub_id = NEW.pub_id
  WHERE phylotree_pub_id = NEW.phylotree_pub_id
  RETURNING phylotree_pub.*;


--
-- Name: project_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_c1 UNIQUE (name);


--
-- Name: project_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_pkey PRIMARY KEY (project_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.project AS SELECT * FROM $temporary_chado_schema_name$_data.project UNION SELECT * FROM public.project;
CREATE TRIGGER project_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.project
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.project_pkey_trigger_func();
CREATE RULE project_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.project DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.project VALUES(NEW.*)
  RETURNING project.*;
CREATE RULE project_update AS
  ON UPDATE TO $temporary_chado_schema_name$.project DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.project SET 
    project_id = NEW.project_id,
    name = NEW.name,
    description = NEW.description
  WHERE project_id = NEW.project_id
  RETURNING project.*;


--
-- Name: protocol_attribute_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocol_attribute
    ADD CONSTRAINT protocol_attribute_pkey PRIMARY KEY (protocol_attribute_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.protocol_attribute AS SELECT * FROM $temporary_chado_schema_name$_data.protocol_attribute UNION SELECT * FROM public.protocol_attribute;
CREATE TRIGGER protocol_attribute_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.protocol_attribute
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.protocol_attribute_pkey_trigger_func();
CREATE RULE protocol_attribute_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.protocol_attribute DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.protocol_attribute VALUES(NEW.*)
  RETURNING protocol_attribute.*;
CREATE RULE protocol_attribute_update AS
  ON UPDATE TO $temporary_chado_schema_name$.protocol_attribute DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.protocol_attribute SET 
    protocol_attribute_id = NEW.protocol_attribute_id,
    protocol_id = NEW.protocol_id,
    attribute_id = NEW.attribute_id
  WHERE protocol_attribute_id = NEW.protocol_attribute_id
  RETURNING protocol_attribute.*;


--
-- Name: protocol_attribute_protocol_id_key; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocol_attribute
    ADD CONSTRAINT protocol_attribute_protocol_id_key UNIQUE (protocol_id, attribute_id);


--
-- Name: protocol_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocol
    ADD CONSTRAINT protocol_pkey PRIMARY KEY (protocol_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.protocol AS SELECT * FROM $temporary_chado_schema_name$_data.protocol UNION SELECT * FROM public.protocol;
CREATE TRIGGER protocol_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.protocol
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.protocol_pkey_trigger_func();
CREATE RULE protocol_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.protocol DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.protocol VALUES(NEW.*)
  RETURNING protocol.*;
CREATE RULE protocol_update AS
  ON UPDATE TO $temporary_chado_schema_name$.protocol DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.protocol SET 
    protocol_id = NEW.protocol_id,
    name = NEW.name,
    description = NEW.description,
    dbxref_id = NEW.dbxref_id,
    version = NEW.version
  WHERE protocol_id = NEW.protocol_id
  RETURNING protocol.*;


--
-- Name: protocolparam_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocolparam
    ADD CONSTRAINT protocolparam_pkey PRIMARY KEY (protocolparam_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.protocolparam AS SELECT * FROM $temporary_chado_schema_name$_data.protocolparam UNION SELECT * FROM public.protocolparam;
CREATE TRIGGER protocolparam_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.protocolparam
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.protocolparam_pkey_trigger_func();
CREATE RULE protocolparam_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.protocolparam DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.protocolparam VALUES(NEW.*)
  RETURNING protocolparam.*;
CREATE RULE protocolparam_update AS
  ON UPDATE TO $temporary_chado_schema_name$.protocolparam DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.protocolparam SET 
    protocolparam_id = NEW.protocolparam_id,
    protocol_id = NEW.protocol_id,
    name = NEW.name,
    datatype_id = NEW.datatype_id,
    unittype_id = NEW.unittype_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE protocolparam_id = NEW.protocolparam_id
  RETURNING protocolparam.*;


--
-- Name: pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pub
    ADD CONSTRAINT pub_c1 UNIQUE (uniquename);


--
-- Name: pub_dbxref_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pub_dbxref
    ADD CONSTRAINT pub_dbxref_c1 UNIQUE (pub_id, dbxref_id);


--
-- Name: pub_dbxref_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pub_dbxref
    ADD CONSTRAINT pub_dbxref_pkey PRIMARY KEY (pub_dbxref_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.pub_dbxref AS SELECT * FROM $temporary_chado_schema_name$_data.pub_dbxref UNION SELECT * FROM public.pub_dbxref;
CREATE TRIGGER pub_dbxref_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.pub_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.pub_dbxref_pkey_trigger_func();
CREATE RULE pub_dbxref_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.pub_dbxref DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.pub_dbxref VALUES(NEW.*)
  RETURNING pub_dbxref.*;
CREATE RULE pub_dbxref_update AS
  ON UPDATE TO $temporary_chado_schema_name$.pub_dbxref DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.pub_dbxref SET 
    pub_dbxref_id = NEW.pub_dbxref_id,
    pub_id = NEW.pub_id,
    dbxref_id = NEW.dbxref_id,
    is_current = NEW.is_current
  WHERE pub_dbxref_id = NEW.pub_dbxref_id
  RETURNING pub_dbxref.*;


--
-- Name: pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pub
    ADD CONSTRAINT pub_pkey PRIMARY KEY (pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.pub AS SELECT * FROM $temporary_chado_schema_name$_data.pub UNION SELECT * FROM public.pub;
CREATE TRIGGER pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.pub_pkey_trigger_func();
CREATE RULE pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.pub VALUES(NEW.*)
  RETURNING pub.*;
CREATE RULE pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.pub SET 
    pub_id = NEW.pub_id,
    title = NEW.title,
    volumetitle = NEW.volumetitle,
    volume = NEW.volume,
    series_name = NEW.series_name,
    issue = NEW.issue,
    pyear = NEW.pyear,
    pages = NEW.pages,
    miniref = NEW.miniref,
    uniquename = NEW.uniquename,
    type_id = NEW.type_id,
    is_obsolete = NEW.is_obsolete,
    publisher = NEW.publisher,
    pubplace = NEW.pubplace
  WHERE pub_id = NEW.pub_id
  RETURNING pub.*;


--
-- Name: pub_relationship_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pub_relationship
    ADD CONSTRAINT pub_relationship_c1 UNIQUE (subject_id, object_id, type_id);


--
-- Name: pub_relationship_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pub_relationship
    ADD CONSTRAINT pub_relationship_pkey PRIMARY KEY (pub_relationship_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.pub_relationship AS SELECT * FROM $temporary_chado_schema_name$_data.pub_relationship UNION SELECT * FROM public.pub_relationship;
CREATE TRIGGER pub_relationship_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.pub_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.pub_relationship_pkey_trigger_func();
CREATE RULE pub_relationship_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.pub_relationship DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.pub_relationship VALUES(NEW.*)
  RETURNING pub_relationship.*;
CREATE RULE pub_relationship_update AS
  ON UPDATE TO $temporary_chado_schema_name$.pub_relationship DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.pub_relationship SET 
    pub_relationship_id = NEW.pub_relationship_id,
    subject_id = NEW.subject_id,
    object_id = NEW.object_id,
    type_id = NEW.type_id
  WHERE pub_relationship_id = NEW.pub_relationship_id
  RETURNING pub_relationship.*;


--
-- Name: pubauthor_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pubauthor
    ADD CONSTRAINT pubauthor_c1 UNIQUE (pub_id, rank);


--
-- Name: pubauthor_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pubauthor
    ADD CONSTRAINT pubauthor_pkey PRIMARY KEY (pubauthor_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.pubauthor AS SELECT * FROM $temporary_chado_schema_name$_data.pubauthor UNION SELECT * FROM public.pubauthor;
CREATE TRIGGER pubauthor_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.pubauthor
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.pubauthor_pkey_trigger_func();
CREATE RULE pubauthor_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.pubauthor DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.pubauthor VALUES(NEW.*)
  RETURNING pubauthor.*;
CREATE RULE pubauthor_update AS
  ON UPDATE TO $temporary_chado_schema_name$.pubauthor DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.pubauthor SET 
    pubauthor_id = NEW.pubauthor_id,
    pub_id = NEW.pub_id,
    rank = NEW.rank,
    editor = NEW.editor,
    surname = NEW.surname,
    givennames = NEW.givennames,
    suffix = NEW.suffix
  WHERE pubauthor_id = NEW.pubauthor_id
  RETURNING pubauthor.*;


--
-- Name: pubprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pubprop
    ADD CONSTRAINT pubprop_c1 UNIQUE (pub_id, type_id, rank);


--
-- Name: pubprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pubprop
    ADD CONSTRAINT pubprop_pkey PRIMARY KEY (pubprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.pubprop AS SELECT * FROM $temporary_chado_schema_name$_data.pubprop UNION SELECT * FROM public.pubprop;
CREATE TRIGGER pubprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.pubprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.pubprop_pkey_trigger_func();
CREATE RULE pubprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.pubprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.pubprop VALUES(NEW.*)
  RETURNING pubprop.*;
CREATE RULE pubprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.pubprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.pubprop SET 
    pubprop_id = NEW.pubprop_id,
    pub_id = NEW.pub_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE pubprop_id = NEW.pubprop_id
  RETURNING pubprop.*;


--
-- Name: quantification_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY quantification
    ADD CONSTRAINT quantification_c1 UNIQUE (name, analysis_id);


--
-- Name: quantification_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY quantification
    ADD CONSTRAINT quantification_pkey PRIMARY KEY (quantification_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.quantification AS SELECT * FROM $temporary_chado_schema_name$_data.quantification UNION SELECT * FROM public.quantification;
CREATE TRIGGER quantification_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.quantification
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.quantification_pkey_trigger_func();
CREATE RULE quantification_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.quantification DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.quantification VALUES(NEW.*)
  RETURNING quantification.*;
CREATE RULE quantification_update AS
  ON UPDATE TO $temporary_chado_schema_name$.quantification DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.quantification SET 
    quantification_id = NEW.quantification_id,
    acquisition_id = NEW.acquisition_id,
    operator_id = NEW.operator_id,
    protocol_id = NEW.protocol_id,
    analysis_id = NEW.analysis_id,
    quantificationdate = NEW.quantificationdate,
    name = NEW.name,
    uri = NEW.uri
  WHERE quantification_id = NEW.quantification_id
  RETURNING quantification.*;


--
-- Name: quantification_relationship_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY quantification_relationship
    ADD CONSTRAINT quantification_relationship_c1 UNIQUE (subject_id, object_id, type_id);


--
-- Name: quantification_relationship_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY quantification_relationship
    ADD CONSTRAINT quantification_relationship_pkey PRIMARY KEY (quantification_relationship_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.quantification_relationship AS SELECT * FROM $temporary_chado_schema_name$_data.quantification_relationship UNION SELECT * FROM public.quantification_relationship;
CREATE TRIGGER quantification_relationship_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.quantification_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.quantification_relationship_pkey_trigger_func();
CREATE RULE quantification_relationship_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.quantification_relationship DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.quantification_relationship VALUES(NEW.*)
  RETURNING quantification_relationship.*;
CREATE RULE quantification_relationship_update AS
  ON UPDATE TO $temporary_chado_schema_name$.quantification_relationship DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.quantification_relationship SET 
    quantification_relationship_id = NEW.quantification_relationship_id,
    subject_id = NEW.subject_id,
    type_id = NEW.type_id,
    object_id = NEW.object_id
  WHERE quantification_relationship_id = NEW.quantification_relationship_id
  RETURNING quantification_relationship.*;


--
-- Name: quantificationprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY quantificationprop
    ADD CONSTRAINT quantificationprop_c1 UNIQUE (quantification_id, type_id, rank);


--
-- Name: quantificationprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY quantificationprop
    ADD CONSTRAINT quantificationprop_pkey PRIMARY KEY (quantificationprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.quantificationprop AS SELECT * FROM $temporary_chado_schema_name$_data.quantificationprop UNION SELECT * FROM public.quantificationprop;
CREATE TRIGGER quantificationprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.quantificationprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.quantificationprop_pkey_trigger_func();
CREATE RULE quantificationprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.quantificationprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.quantificationprop VALUES(NEW.*)
  RETURNING quantificationprop.*;
CREATE RULE quantificationprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.quantificationprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.quantificationprop SET 
    quantificationprop_id = NEW.quantificationprop_id,
    quantification_id = NEW.quantification_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE quantificationprop_id = NEW.quantificationprop_id
  RETURNING quantificationprop.*;


--
-- Name: stock_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock
    ADD CONSTRAINT stock_c1 UNIQUE (organism_id, uniquename, type_id);


--
-- Name: stock_cvterm_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_cvterm
    ADD CONSTRAINT stock_cvterm_c1 UNIQUE (stock_id, cvterm_id, pub_id);


--
-- Name: stock_cvterm_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_cvterm
    ADD CONSTRAINT stock_cvterm_pkey PRIMARY KEY (stock_cvterm_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stock_cvterm AS SELECT * FROM $temporary_chado_schema_name$_data.stock_cvterm UNION SELECT * FROM public.stock_cvterm;
CREATE TRIGGER stock_cvterm_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stock_cvterm
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stock_cvterm_pkey_trigger_func();
CREATE RULE stock_cvterm_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stock_cvterm DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stock_cvterm VALUES(NEW.*)
  RETURNING stock_cvterm.*;
CREATE RULE stock_cvterm_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stock_cvterm DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stock_cvterm SET 
    stock_cvterm_id = NEW.stock_cvterm_id,
    stock_id = NEW.stock_id,
    cvterm_id = NEW.cvterm_id,
    pub_id = NEW.pub_id
  WHERE stock_cvterm_id = NEW.stock_cvterm_id
  RETURNING stock_cvterm.*;


--
-- Name: stock_dbxref_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_dbxref
    ADD CONSTRAINT stock_dbxref_c1 UNIQUE (stock_id, dbxref_id);


--
-- Name: stock_dbxref_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_dbxref
    ADD CONSTRAINT stock_dbxref_pkey PRIMARY KEY (stock_dbxref_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stock_dbxref AS SELECT * FROM $temporary_chado_schema_name$_data.stock_dbxref UNION SELECT * FROM public.stock_dbxref;
CREATE TRIGGER stock_dbxref_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stock_dbxref
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stock_dbxref_pkey_trigger_func();
CREATE RULE stock_dbxref_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stock_dbxref DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stock_dbxref VALUES(NEW.*)
  RETURNING stock_dbxref.*;
CREATE RULE stock_dbxref_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stock_dbxref DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stock_dbxref SET 
    stock_dbxref_id = NEW.stock_dbxref_id,
    stock_id = NEW.stock_id,
    dbxref_id = NEW.dbxref_id,
    is_current = NEW.is_current
  WHERE stock_dbxref_id = NEW.stock_dbxref_id
  RETURNING stock_dbxref.*;


--
-- Name: stock_genotype_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_genotype
    ADD CONSTRAINT stock_genotype_c1 UNIQUE (stock_id, genotype_id);


--
-- Name: stock_genotype_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_genotype
    ADD CONSTRAINT stock_genotype_pkey PRIMARY KEY (stock_genotype_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stock_genotype AS SELECT * FROM $temporary_chado_schema_name$_data.stock_genotype UNION SELECT * FROM public.stock_genotype;
CREATE TRIGGER stock_genotype_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stock_genotype
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stock_genotype_pkey_trigger_func();
CREATE RULE stock_genotype_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stock_genotype DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stock_genotype VALUES(NEW.*)
  RETURNING stock_genotype.*;
CREATE RULE stock_genotype_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stock_genotype DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stock_genotype SET 
    stock_genotype_id = NEW.stock_genotype_id,
    stock_id = NEW.stock_id,
    genotype_id = NEW.genotype_id
  WHERE stock_genotype_id = NEW.stock_genotype_id
  RETURNING stock_genotype.*;


--
-- Name: stock_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock
    ADD CONSTRAINT stock_pkey PRIMARY KEY (stock_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stock AS SELECT * FROM $temporary_chado_schema_name$_data.stock UNION SELECT * FROM public.stock;
CREATE TRIGGER stock_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stock
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stock_pkey_trigger_func();
CREATE RULE stock_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stock DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stock VALUES(NEW.*)
  RETURNING stock.*;
CREATE RULE stock_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stock DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stock SET 
    stock_id = NEW.stock_id,
    dbxref_id = NEW.dbxref_id,
    organism_id = NEW.organism_id,
    name = NEW.name,
    uniquename = NEW.uniquename,
    description = NEW.description,
    type_id = NEW.type_id,
    is_obsolete = NEW.is_obsolete
  WHERE stock_id = NEW.stock_id
  RETURNING stock.*;


--
-- Name: stock_pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_pub
    ADD CONSTRAINT stock_pub_c1 UNIQUE (stock_id, pub_id);


--
-- Name: stock_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_pub
    ADD CONSTRAINT stock_pub_pkey PRIMARY KEY (stock_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stock_pub AS SELECT * FROM $temporary_chado_schema_name$_data.stock_pub UNION SELECT * FROM public.stock_pub;
CREATE TRIGGER stock_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stock_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stock_pub_pkey_trigger_func();
CREATE RULE stock_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stock_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stock_pub VALUES(NEW.*)
  RETURNING stock_pub.*;
CREATE RULE stock_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stock_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stock_pub SET 
    stock_pub_id = NEW.stock_pub_id,
    stock_id = NEW.stock_id,
    pub_id = NEW.pub_id
  WHERE stock_pub_id = NEW.stock_pub_id
  RETURNING stock_pub.*;


--
-- Name: stock_relationship_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_relationship
    ADD CONSTRAINT stock_relationship_c1 UNIQUE (subject_id, object_id, type_id, rank);


--
-- Name: stock_relationship_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_relationship
    ADD CONSTRAINT stock_relationship_pkey PRIMARY KEY (stock_relationship_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stock_relationship AS SELECT * FROM $temporary_chado_schema_name$_data.stock_relationship UNION SELECT * FROM public.stock_relationship;
CREATE TRIGGER stock_relationship_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stock_relationship
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stock_relationship_pkey_trigger_func();
CREATE RULE stock_relationship_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stock_relationship DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stock_relationship VALUES(NEW.*)
  RETURNING stock_relationship.*;
CREATE RULE stock_relationship_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stock_relationship DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stock_relationship SET 
    stock_relationship_id = NEW.stock_relationship_id,
    subject_id = NEW.subject_id,
    object_id = NEW.object_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE stock_relationship_id = NEW.stock_relationship_id
  RETURNING stock_relationship.*;


--
-- Name: stock_relationship_pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_relationship_pub
    ADD CONSTRAINT stock_relationship_pub_c1 UNIQUE (stock_relationship_id, pub_id);


--
-- Name: stock_relationship_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stock_relationship_pub
    ADD CONSTRAINT stock_relationship_pub_pkey PRIMARY KEY (stock_relationship_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stock_relationship_pub AS SELECT * FROM $temporary_chado_schema_name$_data.stock_relationship_pub UNION SELECT * FROM public.stock_relationship_pub;
CREATE TRIGGER stock_relationship_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stock_relationship_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stock_relationship_pub_pkey_trigger_func();
CREATE RULE stock_relationship_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stock_relationship_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stock_relationship_pub VALUES(NEW.*)
  RETURNING stock_relationship_pub.*;
CREATE RULE stock_relationship_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stock_relationship_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stock_relationship_pub SET 
    stock_relationship_pub_id = NEW.stock_relationship_pub_id,
    stock_relationship_id = NEW.stock_relationship_id,
    pub_id = NEW.pub_id
  WHERE stock_relationship_pub_id = NEW.stock_relationship_pub_id
  RETURNING stock_relationship_pub.*;


--
-- Name: stockcollection_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stockcollection
    ADD CONSTRAINT stockcollection_c1 UNIQUE (uniquename, type_id);


--
-- Name: stockcollection_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stockcollection
    ADD CONSTRAINT stockcollection_pkey PRIMARY KEY (stockcollection_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stockcollection AS SELECT * FROM $temporary_chado_schema_name$_data.stockcollection UNION SELECT * FROM public.stockcollection;
CREATE TRIGGER stockcollection_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stockcollection
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stockcollection_pkey_trigger_func();
CREATE RULE stockcollection_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stockcollection DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stockcollection VALUES(NEW.*)
  RETURNING stockcollection.*;
CREATE RULE stockcollection_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stockcollection DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stockcollection SET 
    stockcollection_id = NEW.stockcollection_id,
    type_id = NEW.type_id,
    contact_id = NEW.contact_id,
    name = NEW.name,
    uniquename = NEW.uniquename
  WHERE stockcollection_id = NEW.stockcollection_id
  RETURNING stockcollection.*;


--
-- Name: stockcollection_stock_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stockcollection_stock
    ADD CONSTRAINT stockcollection_stock_c1 UNIQUE (stockcollection_id, stock_id);


--
-- Name: stockcollection_stock_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stockcollection_stock
    ADD CONSTRAINT stockcollection_stock_pkey PRIMARY KEY (stockcollection_stock_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stockcollection_stock AS SELECT * FROM $temporary_chado_schema_name$_data.stockcollection_stock UNION SELECT * FROM public.stockcollection_stock;
CREATE TRIGGER stockcollection_stock_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stockcollection_stock
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stockcollection_stock_pkey_trigger_func();
CREATE RULE stockcollection_stock_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stockcollection_stock DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stockcollection_stock VALUES(NEW.*)
  RETURNING stockcollection_stock.*;
CREATE RULE stockcollection_stock_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stockcollection_stock DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stockcollection_stock SET 
    stockcollection_stock_id = NEW.stockcollection_stock_id,
    stockcollection_id = NEW.stockcollection_id,
    stock_id = NEW.stock_id
  WHERE stockcollection_stock_id = NEW.stockcollection_stock_id
  RETURNING stockcollection_stock.*;


--
-- Name: stockcollectionprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stockcollectionprop
    ADD CONSTRAINT stockcollectionprop_c1 UNIQUE (stockcollection_id, type_id, rank);


--
-- Name: stockcollectionprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stockcollectionprop
    ADD CONSTRAINT stockcollectionprop_pkey PRIMARY KEY (stockcollectionprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stockcollectionprop AS SELECT * FROM $temporary_chado_schema_name$_data.stockcollectionprop UNION SELECT * FROM public.stockcollectionprop;
CREATE TRIGGER stockcollectionprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stockcollectionprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stockcollectionprop_pkey_trigger_func();
CREATE RULE stockcollectionprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stockcollectionprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stockcollectionprop VALUES(NEW.*)
  RETURNING stockcollectionprop.*;
CREATE RULE stockcollectionprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stockcollectionprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stockcollectionprop SET 
    stockcollectionprop_id = NEW.stockcollectionprop_id,
    stockcollection_id = NEW.stockcollection_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE stockcollectionprop_id = NEW.stockcollectionprop_id
  RETURNING stockcollectionprop.*;


--
-- Name: stockprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stockprop
    ADD CONSTRAINT stockprop_c1 UNIQUE (stock_id, type_id, rank);


--
-- Name: stockprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stockprop
    ADD CONSTRAINT stockprop_pkey PRIMARY KEY (stockprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stockprop AS SELECT * FROM $temporary_chado_schema_name$_data.stockprop UNION SELECT * FROM public.stockprop;
CREATE TRIGGER stockprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stockprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stockprop_pkey_trigger_func();
CREATE RULE stockprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stockprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stockprop VALUES(NEW.*)
  RETURNING stockprop.*;
CREATE RULE stockprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stockprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stockprop SET 
    stockprop_id = NEW.stockprop_id,
    stock_id = NEW.stock_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE stockprop_id = NEW.stockprop_id
  RETURNING stockprop.*;


--
-- Name: stockprop_pub_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stockprop_pub
    ADD CONSTRAINT stockprop_pub_c1 UNIQUE (stockprop_id, pub_id);


--
-- Name: stockprop_pub_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stockprop_pub
    ADD CONSTRAINT stockprop_pub_pkey PRIMARY KEY (stockprop_pub_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.stockprop_pub AS SELECT * FROM $temporary_chado_schema_name$_data.stockprop_pub UNION SELECT * FROM public.stockprop_pub;
CREATE TRIGGER stockprop_pub_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.stockprop_pub
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.stockprop_pub_pkey_trigger_func();
CREATE RULE stockprop_pub_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.stockprop_pub DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.stockprop_pub VALUES(NEW.*)
  RETURNING stockprop_pub.*;
CREATE RULE stockprop_pub_update AS
  ON UPDATE TO $temporary_chado_schema_name$.stockprop_pub DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.stockprop_pub SET 
    stockprop_pub_id = NEW.stockprop_pub_id,
    stockprop_id = NEW.stockprop_id,
    pub_id = NEW.pub_id
  WHERE stockprop_pub_id = NEW.stockprop_pub_id
  RETURNING stockprop_pub.*;


--
-- Name: study_assay_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY study_assay
    ADD CONSTRAINT study_assay_c1 UNIQUE (study_id, assay_id);


--
-- Name: study_assay_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY study_assay
    ADD CONSTRAINT study_assay_pkey PRIMARY KEY (study_assay_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.study_assay AS SELECT * FROM $temporary_chado_schema_name$_data.study_assay UNION SELECT * FROM public.study_assay;
CREATE TRIGGER study_assay_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.study_assay
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.study_assay_pkey_trigger_func();
CREATE RULE study_assay_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.study_assay DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.study_assay VALUES(NEW.*)
  RETURNING study_assay.*;
CREATE RULE study_assay_update AS
  ON UPDATE TO $temporary_chado_schema_name$.study_assay DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.study_assay SET 
    study_assay_id = NEW.study_assay_id,
    study_id = NEW.study_id,
    assay_id = NEW.assay_id
  WHERE study_assay_id = NEW.study_assay_id
  RETURNING study_assay.*;


--
-- Name: study_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY study
    ADD CONSTRAINT study_c1 UNIQUE (name);


--
-- Name: study_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY study
    ADD CONSTRAINT study_pkey PRIMARY KEY (study_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.study AS SELECT * FROM $temporary_chado_schema_name$_data.study UNION SELECT * FROM public.study;
CREATE TRIGGER study_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.study
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.study_pkey_trigger_func();
CREATE RULE study_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.study DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.study VALUES(NEW.*)
  RETURNING study.*;
CREATE RULE study_update AS
  ON UPDATE TO $temporary_chado_schema_name$.study DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.study SET 
    study_id = NEW.study_id,
    contact_id = NEW.contact_id,
    pub_id = NEW.pub_id,
    dbxref_id = NEW.dbxref_id,
    name = NEW.name,
    description = NEW.description
  WHERE study_id = NEW.study_id
  RETURNING study.*;


--
-- Name: studydesign_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY studydesign
    ADD CONSTRAINT studydesign_pkey PRIMARY KEY (studydesign_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.studydesign AS SELECT * FROM $temporary_chado_schema_name$_data.studydesign UNION SELECT * FROM public.studydesign;
CREATE TRIGGER studydesign_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.studydesign
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.studydesign_pkey_trigger_func();
CREATE RULE studydesign_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.studydesign DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.studydesign VALUES(NEW.*)
  RETURNING studydesign.*;
CREATE RULE studydesign_update AS
  ON UPDATE TO $temporary_chado_schema_name$.studydesign DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.studydesign SET 
    studydesign_id = NEW.studydesign_id,
    study_id = NEW.study_id,
    description = NEW.description
  WHERE studydesign_id = NEW.studydesign_id
  RETURNING studydesign.*;


--
-- Name: studydesignprop_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY studydesignprop
    ADD CONSTRAINT studydesignprop_c1 UNIQUE (studydesign_id, type_id, rank);


--
-- Name: studydesignprop_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY studydesignprop
    ADD CONSTRAINT studydesignprop_pkey PRIMARY KEY (studydesignprop_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.studydesignprop AS SELECT * FROM $temporary_chado_schema_name$_data.studydesignprop UNION SELECT * FROM public.studydesignprop;
CREATE TRIGGER studydesignprop_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.studydesignprop
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.studydesignprop_pkey_trigger_func();
CREATE RULE studydesignprop_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.studydesignprop DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.studydesignprop VALUES(NEW.*)
  RETURNING studydesignprop.*;
CREATE RULE studydesignprop_update AS
  ON UPDATE TO $temporary_chado_schema_name$.studydesignprop DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.studydesignprop SET 
    studydesignprop_id = NEW.studydesignprop_id,
    studydesign_id = NEW.studydesign_id,
    type_id = NEW.type_id,
    value = NEW.value,
    rank = NEW.rank
  WHERE studydesignprop_id = NEW.studydesignprop_id
  RETURNING studydesignprop.*;


--
-- Name: studyfactor_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY studyfactor
    ADD CONSTRAINT studyfactor_pkey PRIMARY KEY (studyfactor_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.studyfactor AS SELECT * FROM $temporary_chado_schema_name$_data.studyfactor UNION SELECT * FROM public.studyfactor;
CREATE TRIGGER studyfactor_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.studyfactor
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.studyfactor_pkey_trigger_func();
CREATE RULE studyfactor_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.studyfactor DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.studyfactor VALUES(NEW.*)
  RETURNING studyfactor.*;
CREATE RULE studyfactor_update AS
  ON UPDATE TO $temporary_chado_schema_name$.studyfactor DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.studyfactor SET 
    studyfactor_id = NEW.studyfactor_id,
    studydesign_id = NEW.studydesign_id,
    type_id = NEW.type_id,
    name = NEW.name,
    description = NEW.description
  WHERE studyfactor_id = NEW.studyfactor_id
  RETURNING studyfactor.*;


--
-- Name: studyfactorvalue_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY studyfactorvalue
    ADD CONSTRAINT studyfactorvalue_pkey PRIMARY KEY (studyfactorvalue_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.studyfactorvalue AS SELECT * FROM $temporary_chado_schema_name$_data.studyfactorvalue UNION SELECT * FROM public.studyfactorvalue;
CREATE TRIGGER studyfactorvalue_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.studyfactorvalue
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.studyfactorvalue_pkey_trigger_func();
CREATE RULE studyfactorvalue_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.studyfactorvalue DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.studyfactorvalue VALUES(NEW.*)
  RETURNING studyfactorvalue.*;
CREATE RULE studyfactorvalue_update AS
  ON UPDATE TO $temporary_chado_schema_name$.studyfactorvalue DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.studyfactorvalue SET 
    studyfactorvalue_id = NEW.studyfactorvalue_id,
    studyfactor_id = NEW.studyfactor_id,
    assay_id = NEW.assay_id,
    factorvalue = NEW.factorvalue,
    name = NEW.name,
    rank = NEW.rank
  WHERE studyfactorvalue_id = NEW.studyfactorvalue_id
  RETURNING studyfactorvalue.*;


--
-- Name: synonym_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY synonym
    ADD CONSTRAINT synonym_c1 UNIQUE (name, type_id);


--
-- Name: synonym_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY synonym
    ADD CONSTRAINT synonym_pkey PRIMARY KEY (synonym_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.synonym AS SELECT * FROM $temporary_chado_schema_name$_data.synonym UNION SELECT * FROM public.synonym;
CREATE TRIGGER synonym_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.synonym
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.synonym_pkey_trigger_func();
CREATE RULE synonym_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.synonym DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.synonym VALUES(NEW.*)
  RETURNING synonym.*;
CREATE RULE synonym_update AS
  ON UPDATE TO $temporary_chado_schema_name$.synonym DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.synonym SET 
    synonym_id = NEW.synonym_id,
    name = NEW.name,
    type_id = NEW.type_id,
    synonym_sgml = NEW.synonym_sgml
  WHERE synonym_id = NEW.synonym_id
  RETURNING synonym.*;


--
-- Name: tableinfo_c1; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tableinfo
    ADD CONSTRAINT tableinfo_c1 UNIQUE (name);


--
-- Name: tableinfo_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tableinfo
    ADD CONSTRAINT tableinfo_pkey PRIMARY KEY (tableinfo_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.tableinfo AS SELECT * FROM $temporary_chado_schema_name$_data.tableinfo UNION SELECT * FROM public.tableinfo;
CREATE TRIGGER tableinfo_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.tableinfo
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.tableinfo_pkey_trigger_func();
CREATE RULE tableinfo_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.tableinfo DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.tableinfo VALUES(NEW.*)
  RETURNING tableinfo.*;
CREATE RULE tableinfo_update AS
  ON UPDATE TO $temporary_chado_schema_name$.tableinfo DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.tableinfo SET 
    tableinfo_id = NEW.tableinfo_id,
    name = NEW.name,
    primary_key_column = NEW.primary_key_column,
    is_view = NEW.is_view,
    view_on_table_id = NEW.view_on_table_id,
    superclass_table_id = NEW.superclass_table_id,
    is_updateable = NEW.is_updateable,
    modification_date = NEW.modification_date
  WHERE tableinfo_id = NEW.tableinfo_id
  RETURNING tableinfo.*;


--
-- Name: treatment_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY treatment
    ADD CONSTRAINT treatment_pkey PRIMARY KEY (treatment_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.treatment AS SELECT * FROM $temporary_chado_schema_name$_data.treatment UNION SELECT * FROM public.treatment;
CREATE TRIGGER treatment_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.treatment
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.treatment_pkey_trigger_func();
CREATE RULE treatment_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.treatment DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.treatment VALUES(NEW.*)
  RETURNING treatment.*;
CREATE RULE treatment_update AS
  ON UPDATE TO $temporary_chado_schema_name$.treatment DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.treatment SET 
    treatment_id = NEW.treatment_id,
    rank = NEW.rank,
    biomaterial_id = NEW.biomaterial_id,
    type_id = NEW.type_id,
    protocol_id = NEW.protocol_id,
    name = NEW.name
  WHERE treatment_id = NEW.treatment_id
  RETURNING treatment.*;


--
-- Name: wiggle_data_pkey; Type: CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

ALTER TABLE ONLY wiggle_data
    ADD CONSTRAINT wiggle_data_pkey PRIMARY KEY (wiggle_data_id);
CREATE OR REPLACE VIEW $temporary_chado_schema_name$.wiggle_data AS SELECT * FROM $temporary_chado_schema_name$_data.wiggle_data UNION SELECT * FROM public.wiggle_data;
CREATE TRIGGER wiggle_data_pkey_trigger BEFORE INSERT OR UPDATE ON $temporary_chado_schema_name$_data.wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE meta_chado.wiggle_data_pkey_trigger_func();
CREATE RULE wiggle_data_insert AS 
  ON INSERT TO $temporary_chado_schema_name$.wiggle_data DO INSTEAD
  INSERT INTO $temporary_chado_schema_name$_data.wiggle_data VALUES(NEW.*)
  RETURNING wiggle_data.*;
CREATE RULE wiggle_data_update AS
  ON UPDATE TO $temporary_chado_schema_name$.wiggle_data DO INSTEAD
  UPDATE $temporary_chado_schema_name$_data.wiggle_data SET 
    wiggle_data_id = NEW.wiggle_data_id,
    type = NEW.type,
    name = NEW.name,
    description = NEW.description,
    visibility = NEW.visibility,
    color = NEW.color,
    altcolor = NEW.altcolor,
    priority = NEW.priority,
    autoscale = NEW.autoscale,
    griddefault = NEW.griddefault,
    maxheightpixels = NEW.maxheightpixels,
    graphtype = NEW.graphtype,
    viewlimits = NEW.viewlimits,
    ylinemark = NEW.ylinemark,
    ylineonoff = NEW.ylineonoff,
    windowingfunction = NEW.windowingfunction,
    smoothingwindow = NEW.smoothingwindow,
    data = NEW.data
  WHERE wiggle_data_id = NEW.wiggle_data_id
  RETURNING wiggle_data.*;


--
-- Name: acquisition_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX acquisition_idx1 ON acquisition USING btree (assay_id);


--
-- Name: acquisition_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX acquisition_idx2 ON acquisition USING btree (protocol_id);


--
-- Name: acquisition_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX acquisition_idx3 ON acquisition USING btree (channel_id);


--
-- Name: acquisition_relationship_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX acquisition_relationship_idx1 ON acquisition_relationship USING btree (subject_id);


--
-- Name: acquisition_relationship_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX acquisition_relationship_idx2 ON acquisition_relationship USING btree (type_id);


--
-- Name: acquisition_relationship_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX acquisition_relationship_idx3 ON acquisition_relationship USING btree (object_id);


--
-- Name: acquisitionprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX acquisitionprop_idx1 ON acquisitionprop USING btree (acquisition_id);


--
-- Name: acquisitionprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX acquisitionprop_idx2 ON acquisitionprop USING btree (type_id);


--
-- Name: analysisfeature_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX analysisfeature_idx1 ON analysisfeature USING btree (feature_id);


--
-- Name: analysisfeature_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX analysisfeature_idx2 ON analysisfeature USING btree (analysis_id);


--
-- Name: analysisprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX analysisprop_idx1 ON analysisprop USING btree (analysis_id);


--
-- Name: analysisprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX analysisprop_idx2 ON analysisprop USING btree (type_id);


--
-- Name: apd_on_d; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX apd_on_d ON applied_protocol_data USING btree (applied_protocol_id, direction);


--
-- Name: arraydesign_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX arraydesign_idx1 ON arraydesign USING btree (manufacturer_id);


--
-- Name: arraydesign_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX arraydesign_idx2 ON arraydesign USING btree (platformtype_id);


--
-- Name: arraydesign_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX arraydesign_idx3 ON arraydesign USING btree (substratetype_id);


--
-- Name: arraydesign_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX arraydesign_idx4 ON arraydesign USING btree (protocol_id);


--
-- Name: arraydesign_idx5; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX arraydesign_idx5 ON arraydesign USING btree (dbxref_id);


--
-- Name: arraydesignprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX arraydesignprop_idx1 ON arraydesignprop USING btree (arraydesign_id);


--
-- Name: arraydesignprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX arraydesignprop_idx2 ON arraydesignprop USING btree (type_id);


--
-- Name: assay_biomaterial_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX assay_biomaterial_idx1 ON assay_biomaterial USING btree (assay_id);


--
-- Name: assay_biomaterial_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX assay_biomaterial_idx2 ON assay_biomaterial USING btree (biomaterial_id);


--
-- Name: assay_biomaterial_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX assay_biomaterial_idx3 ON assay_biomaterial USING btree (channel_id);


--
-- Name: assay_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX assay_idx1 ON assay USING btree (arraydesign_id);


--
-- Name: assay_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX assay_idx2 ON assay USING btree (protocol_id);


--
-- Name: assay_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX assay_idx3 ON assay USING btree (operator_id);


--
-- Name: assay_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX assay_idx4 ON assay USING btree (dbxref_id);


--
-- Name: assay_project_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX assay_project_idx1 ON assay_project USING btree (assay_id);


--
-- Name: assay_project_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX assay_project_idx2 ON assay_project USING btree (project_id);


--
-- Name: assayprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX assayprop_idx1 ON assayprop USING btree (assay_id);


--
-- Name: assayprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX assayprop_idx2 ON assayprop USING btree (type_id);


--
-- Name: binloc_boxrange; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX binloc_boxrange ON featureloc USING gist (generic_chado.boxrange(fmin, fmax));


--
-- Name: binloc_boxrange_src; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX binloc_boxrange_src ON featureloc USING gist (generic_chado.boxrange(srcfeature_id, fmin, fmax));


--
-- Name: biomaterial_dbxref_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterial_dbxref_idx1 ON biomaterial_dbxref USING btree (biomaterial_id);


--
-- Name: biomaterial_dbxref_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterial_dbxref_idx2 ON biomaterial_dbxref USING btree (dbxref_id);


--
-- Name: biomaterial_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterial_idx1 ON biomaterial USING btree (taxon_id);


--
-- Name: biomaterial_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterial_idx2 ON biomaterial USING btree (biosourceprovider_id);


--
-- Name: biomaterial_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterial_idx3 ON biomaterial USING btree (dbxref_id);


--
-- Name: biomaterial_relationship_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterial_relationship_idx1 ON biomaterial_relationship USING btree (subject_id);


--
-- Name: biomaterial_relationship_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterial_relationship_idx2 ON biomaterial_relationship USING btree (object_id);


--
-- Name: biomaterial_relationship_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterial_relationship_idx3 ON biomaterial_relationship USING btree (type_id);


--
-- Name: biomaterial_treatment_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterial_treatment_idx1 ON biomaterial_treatment USING btree (biomaterial_id);


--
-- Name: biomaterial_treatment_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterial_treatment_idx2 ON biomaterial_treatment USING btree (treatment_id);


--
-- Name: biomaterial_treatment_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterial_treatment_idx3 ON biomaterial_treatment USING btree (unittype_id);


--
-- Name: biomaterialprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterialprop_idx1 ON biomaterialprop USING btree (biomaterial_id);


--
-- Name: biomaterialprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX biomaterialprop_idx2 ON biomaterialprop USING btree (type_id);


--
-- Name: contact_relationship_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX contact_relationship_idx1 ON contact_relationship USING btree (type_id);


--
-- Name: contact_relationship_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX contact_relationship_idx2 ON contact_relationship USING btree (subject_id);


--
-- Name: contact_relationship_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX contact_relationship_idx3 ON contact_relationship USING btree (object_id);


--
-- Name: control_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX control_idx1 ON control USING btree (type_id);


--
-- Name: control_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX control_idx2 ON control USING btree (assay_id);


--
-- Name: control_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX control_idx3 ON control USING btree (tableinfo_id);


--
-- Name: control_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX control_idx4 ON control USING btree (row_id);


--
-- Name: INDEX cvterm_c1; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON INDEX cvterm_c1 IS 'A name can mean different things in
different contexts; for example "chromosome" in SO and GO. A name
should be unique within an ontology or cv. A name may exist twice in a
cv, in both obsolete and non-obsolete forms - these will be for
different cvterms with different OBO identifiers; so GO documentation
for more details on obsoletion. Note that occasionally multiple
obsolete terms with the same name will exist in the same cv. If this
is a possibility for the ontology under consideration (e.g. GO) then the
ID should be appended to the name to ensure uniqueness.';


--
-- Name: INDEX cvterm_c2; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON INDEX cvterm_c2 IS 'The OBO identifier is globally unique.';


--
-- Name: cvterm_dbxref_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvterm_dbxref_idx1 ON cvterm_dbxref USING btree (cvterm_id);


--
-- Name: cvterm_dbxref_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvterm_dbxref_idx2 ON cvterm_dbxref USING btree (dbxref_id);


--
-- Name: cvterm_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvterm_idx1 ON cvterm USING btree (cv_id);


--
-- Name: cvterm_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvterm_idx2 ON cvterm USING btree (name);


--
-- Name: cvterm_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvterm_idx3 ON cvterm USING btree (dbxref_id);


--
-- Name: cvterm_relationship_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvterm_relationship_idx1 ON cvterm_relationship USING btree (type_id);


--
-- Name: cvterm_relationship_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvterm_relationship_idx2 ON cvterm_relationship USING btree (subject_id);


--
-- Name: cvterm_relationship_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvterm_relationship_idx3 ON cvterm_relationship USING btree (object_id);


--
-- Name: cvtermpath_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvtermpath_idx1 ON cvtermpath USING btree (type_id);


--
-- Name: cvtermpath_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvtermpath_idx2 ON cvtermpath USING btree (subject_id);


--
-- Name: cvtermpath_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvtermpath_idx3 ON cvtermpath USING btree (object_id);


--
-- Name: cvtermpath_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvtermpath_idx4 ON cvtermpath USING btree (cv_id);


--
-- Name: cvtermprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvtermprop_idx1 ON cvtermprop USING btree (cvterm_id);


--
-- Name: cvtermprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvtermprop_idx2 ON cvtermprop USING btree (type_id);


--
-- Name: cvtermsynonym_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX cvtermsynonym_idx1 ON cvtermsynonym USING btree (cvterm_id);


--
-- Name: data_feature_data_id; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX data_feature_data_id ON data_feature USING btree (data_id);


--
-- Name: data_feature_data_id_idx; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX data_feature_data_id_idx ON data_feature USING btree (data_id);


--
-- Name: dbxref_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX dbxref_idx1 ON dbxref USING btree (db_id);


--
-- Name: dbxref_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX dbxref_idx2 ON dbxref USING btree (accession);


--
-- Name: dbxref_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX dbxref_idx3 ON dbxref USING btree (version);


--
-- Name: dbxrefprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX dbxrefprop_idx1 ON dbxrefprop USING btree (dbxref_id);


--
-- Name: dbxrefprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX dbxrefprop_idx2 ON dbxrefprop USING btree (type_id);


--
-- Name: element_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX element_idx1 ON element USING btree (feature_id);


--
-- Name: element_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX element_idx2 ON element USING btree (arraydesign_id);


--
-- Name: element_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX element_idx3 ON element USING btree (type_id);


--
-- Name: element_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX element_idx4 ON element USING btree (dbxref_id);


--
-- Name: element_relationship_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX element_relationship_idx1 ON element_relationship USING btree (subject_id);


--
-- Name: element_relationship_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX element_relationship_idx2 ON element_relationship USING btree (type_id);


--
-- Name: element_relationship_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX element_relationship_idx3 ON element_relationship USING btree (object_id);


--
-- Name: element_relationship_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX element_relationship_idx4 ON element_relationship USING btree (value);


--
-- Name: elementresult_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX elementresult_idx1 ON elementresult USING btree (element_id);


--
-- Name: elementresult_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX elementresult_idx2 ON elementresult USING btree (quantification_id);


--
-- Name: elementresult_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX elementresult_idx3 ON elementresult USING btree (signal);


--
-- Name: elementresult_relationship_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX elementresult_relationship_idx1 ON elementresult_relationship USING btree (subject_id);


--
-- Name: elementresult_relationship_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX elementresult_relationship_idx2 ON elementresult_relationship USING btree (type_id);


--
-- Name: elementresult_relationship_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX elementresult_relationship_idx3 ON elementresult_relationship USING btree (object_id);


--
-- Name: elementresult_relationship_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX elementresult_relationship_idx4 ON elementresult_relationship USING btree (value);


--
-- Name: environment_cvterm_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX environment_cvterm_idx1 ON environment_cvterm USING btree (environment_id);


--
-- Name: environment_cvterm_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX environment_cvterm_idx2 ON environment_cvterm USING btree (cvterm_id);


--
-- Name: environment_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX environment_idx1 ON environment USING btree (uniquename);


--
-- Name: expression_cvterm_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX expression_cvterm_idx1 ON expression_cvterm USING btree (expression_id);


--
-- Name: expression_cvterm_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX expression_cvterm_idx2 ON expression_cvterm USING btree (cvterm_id);


--
-- Name: expression_cvterm_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX expression_cvterm_idx3 ON expression_cvterm USING btree (cvterm_type_id);


--
-- Name: expression_cvtermprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX expression_cvtermprop_idx1 ON expression_cvtermprop USING btree (expression_cvterm_id);


--
-- Name: expression_cvtermprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX expression_cvtermprop_idx2 ON expression_cvtermprop USING btree (type_id);


--
-- Name: expression_image_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX expression_image_idx1 ON expression_image USING btree (expression_id);


--
-- Name: expression_image_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX expression_image_idx2 ON expression_image USING btree (eimage_id);


--
-- Name: expression_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX expression_pub_idx1 ON expression_pub USING btree (expression_id);


--
-- Name: expression_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX expression_pub_idx2 ON expression_pub USING btree (pub_id);


--
-- Name: expressionprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX expressionprop_idx1 ON expressionprop USING btree (expression_id);


--
-- Name: expressionprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX expressionprop_idx2 ON expressionprop USING btree (type_id);


--
-- Name: feature_cvterm_dbxref_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_cvterm_dbxref_idx1 ON feature_cvterm_dbxref USING btree (feature_cvterm_id);


--
-- Name: feature_cvterm_dbxref_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_cvterm_dbxref_idx2 ON feature_cvterm_dbxref USING btree (dbxref_id);


--
-- Name: feature_cvterm_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_cvterm_idx1 ON feature_cvterm USING btree (feature_id);


--
-- Name: feature_cvterm_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_cvterm_idx2 ON feature_cvterm USING btree (cvterm_id);


--
-- Name: feature_cvterm_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_cvterm_idx3 ON feature_cvterm USING btree (pub_id);


--
-- Name: feature_cvterm_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_cvterm_pub_idx1 ON feature_cvterm_pub USING btree (feature_cvterm_id);


--
-- Name: feature_cvterm_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_cvterm_pub_idx2 ON feature_cvterm_pub USING btree (pub_id);


--
-- Name: feature_cvtermprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_cvtermprop_idx1 ON feature_cvtermprop USING btree (feature_cvterm_id);


--
-- Name: feature_cvtermprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_cvtermprop_idx2 ON feature_cvtermprop USING btree (type_id);


--
-- Name: feature_dbxref_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_dbxref_idx1 ON feature_dbxref USING btree (feature_id);


--
-- Name: feature_dbxref_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_dbxref_idx2 ON feature_dbxref USING btree (dbxref_id);


--
-- Name: feature_expression_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_expression_idx1 ON feature_expression USING btree (expression_id);


--
-- Name: feature_expression_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_expression_idx2 ON feature_expression USING btree (feature_id);


--
-- Name: feature_expression_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_expression_idx3 ON feature_expression USING btree (pub_id);


--
-- Name: feature_expressionprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_expressionprop_idx1 ON feature_expressionprop USING btree (feature_expression_id);


--
-- Name: feature_expressionprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_expressionprop_idx2 ON feature_expressionprop USING btree (type_id);


--
-- Name: feature_genotype_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_genotype_idx1 ON feature_genotype USING btree (feature_id);


--
-- Name: feature_genotype_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_genotype_idx2 ON feature_genotype USING btree (genotype_id);


--
-- Name: feature_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_idx1 ON feature USING btree (dbxref_id);


--
-- Name: feature_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_idx2 ON feature USING btree (organism_id);


--
-- Name: feature_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_idx3 ON feature USING btree (type_id);


--
-- Name: feature_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_idx4 ON feature USING btree (uniquename);


--
-- Name: feature_idx5; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_idx5 ON feature USING btree (lower((name)::text));


--
-- Name: feature_name_ind1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_name_ind1 ON feature USING btree (name);


--
-- Name: feature_phenotype_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_phenotype_idx1 ON feature_phenotype USING btree (feature_id);


--
-- Name: feature_phenotype_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_phenotype_idx2 ON feature_phenotype USING btree (phenotype_id);


--
-- Name: feature_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_pub_idx1 ON feature_pub USING btree (feature_id);


--
-- Name: feature_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_pub_idx2 ON feature_pub USING btree (pub_id);


--
-- Name: feature_pubprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_pubprop_idx1 ON feature_pubprop USING btree (feature_pub_id);


--
-- Name: feature_relationship_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_relationship_idx1 ON feature_relationship USING btree (subject_id);


--
-- Name: feature_relationship_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_relationship_idx2 ON feature_relationship USING btree (object_id);


--
-- Name: feature_relationship_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_relationship_idx3 ON feature_relationship USING btree (type_id);


--
-- Name: feature_relationship_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_relationship_pub_idx1 ON feature_relationship_pub USING btree (feature_relationship_id);


--
-- Name: feature_relationship_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_relationship_pub_idx2 ON feature_relationship_pub USING btree (pub_id);


--
-- Name: feature_relationshipprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_relationshipprop_idx1 ON feature_relationshipprop USING btree (feature_relationship_id);


--
-- Name: feature_relationshipprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_relationshipprop_idx2 ON feature_relationshipprop USING btree (type_id);


--
-- Name: feature_relationshipprop_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_relationshipprop_pub_idx1 ON feature_relationshipprop_pub USING btree (feature_relationshipprop_id);


--
-- Name: feature_relationshipprop_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_relationshipprop_pub_idx2 ON feature_relationshipprop_pub USING btree (pub_id);


--
-- Name: feature_synonym_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_synonym_idx1 ON feature_synonym USING btree (synonym_id);


--
-- Name: feature_synonym_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_synonym_idx2 ON feature_synonym USING btree (feature_id);


--
-- Name: feature_synonym_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX feature_synonym_idx3 ON feature_synonym USING btree (pub_id);


--
-- Name: featureloc_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featureloc_idx1 ON featureloc USING btree (feature_id);


--
-- Name: featureloc_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featureloc_idx2 ON featureloc USING btree (srcfeature_id);


--
-- Name: featureloc_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featureloc_idx3 ON featureloc USING btree (srcfeature_id, fmin, fmax);


--
-- Name: featureloc_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featureloc_pub_idx1 ON featureloc_pub USING btree (featureloc_id);


--
-- Name: featureloc_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featureloc_pub_idx2 ON featureloc_pub USING btree (pub_id);


--
-- Name: featuremap_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featuremap_pub_idx1 ON featuremap_pub USING btree (featuremap_id);


--
-- Name: featuremap_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featuremap_pub_idx2 ON featuremap_pub USING btree (pub_id);


--
-- Name: featurepos_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featurepos_idx1 ON featurepos USING btree (featuremap_id);


--
-- Name: featurepos_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featurepos_idx2 ON featurepos USING btree (feature_id);


--
-- Name: featurepos_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featurepos_idx3 ON featurepos USING btree (map_feature_id);


--
-- Name: INDEX featureprop_c1; Type: COMMENT; Schema: $temporary_chado_schema_name$; Owner: -
--

COMMENT ON INDEX featureprop_c1 IS 'For any one feature, multivalued
property-value pairs must be differentiated by rank.';


--
-- Name: featureprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featureprop_idx1 ON featureprop USING btree (feature_id);


--
-- Name: featureprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featureprop_idx2 ON featureprop USING btree (type_id);


--
-- Name: featureprop_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featureprop_pub_idx1 ON featureprop_pub USING btree (featureprop_id);


--
-- Name: featureprop_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featureprop_pub_idx2 ON featureprop_pub USING btree (pub_id);


--
-- Name: featurerange_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featurerange_idx1 ON featurerange USING btree (featuremap_id);


--
-- Name: featurerange_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featurerange_idx2 ON featurerange USING btree (feature_id);


--
-- Name: featurerange_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featurerange_idx3 ON featurerange USING btree (leftstartf_id);


--
-- Name: featurerange_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featurerange_idx4 ON featurerange USING btree (leftendf_id);


--
-- Name: featurerange_idx5; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featurerange_idx5 ON featurerange USING btree (rightstartf_id);


--
-- Name: featurerange_idx6; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX featurerange_idx6 ON featurerange USING btree (rightendf_id);


--
-- Name: first_applied_protocol_id_idx; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX first_applied_protocol_id_idx ON experiment_applied_protocol USING btree (first_applied_protocol_id);


--
-- Name: genotype_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX genotype_idx1 ON genotype USING btree (uniquename);


--
-- Name: genotype_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX genotype_idx2 ON genotype USING btree (name);


--
-- Name: gff_sort_tmp_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX gff_sort_tmp_idx1 ON gff_sort_tmp USING btree (refseq);


--
-- Name: gff_sort_tmp_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX gff_sort_tmp_idx2 ON gff_sort_tmp USING btree (id);


--
-- Name: gff_sort_tmp_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX gff_sort_tmp_idx3 ON gff_sort_tmp USING btree (parent);


--
-- Name: library_cvterm_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_cvterm_idx1 ON library_cvterm USING btree (library_id);


--
-- Name: library_cvterm_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_cvterm_idx2 ON library_cvterm USING btree (cvterm_id);


--
-- Name: library_cvterm_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_cvterm_idx3 ON library_cvterm USING btree (pub_id);


--
-- Name: library_feature_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_feature_idx1 ON library_feature USING btree (library_id);


--
-- Name: library_feature_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_feature_idx2 ON library_feature USING btree (feature_id);


--
-- Name: library_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_idx1 ON library USING btree (organism_id);


--
-- Name: library_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_idx2 ON library USING btree (type_id);


--
-- Name: library_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_idx3 ON library USING btree (uniquename);


--
-- Name: library_name_ind1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_name_ind1 ON library USING btree (name);


--
-- Name: library_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_pub_idx1 ON library_pub USING btree (library_id);


--
-- Name: library_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_pub_idx2 ON library_pub USING btree (pub_id);


--
-- Name: library_synonym_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_synonym_idx1 ON library_synonym USING btree (synonym_id);


--
-- Name: library_synonym_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_synonym_idx2 ON library_synonym USING btree (library_id);


--
-- Name: library_synonym_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX library_synonym_idx3 ON library_synonym USING btree (pub_id);


--
-- Name: libraryprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX libraryprop_idx1 ON libraryprop USING btree (library_id);


--
-- Name: libraryprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX libraryprop_idx2 ON libraryprop USING btree (type_id);


--
-- Name: magedocumentation_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX magedocumentation_idx1 ON magedocumentation USING btree (mageml_id);


--
-- Name: magedocumentation_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX magedocumentation_idx2 ON magedocumentation USING btree (tableinfo_id);


--
-- Name: magedocumentation_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX magedocumentation_idx3 ON magedocumentation USING btree (row_id);


--
-- Name: organism_dbxref_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX organism_dbxref_idx1 ON organism_dbxref USING btree (organism_id);


--
-- Name: organism_dbxref_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX organism_dbxref_idx2 ON organism_dbxref USING btree (dbxref_id);


--
-- Name: organismprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX organismprop_idx1 ON organismprop USING btree (organism_id);


--
-- Name: organismprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX organismprop_idx2 ON organismprop USING btree (type_id);


--
-- Name: phendesc_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phendesc_idx1 ON phendesc USING btree (genotype_id);


--
-- Name: phendesc_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phendesc_idx2 ON phendesc USING btree (environment_id);


--
-- Name: phendesc_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phendesc_idx3 ON phendesc USING btree (pub_id);


--
-- Name: phenotype_comparison_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phenotype_comparison_idx1 ON phenotype_comparison USING btree (genotype1_id);


--
-- Name: phenotype_comparison_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phenotype_comparison_idx2 ON phenotype_comparison USING btree (genotype2_id);


--
-- Name: phenotype_comparison_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phenotype_comparison_idx3 ON phenotype_comparison USING btree (type_id);


--
-- Name: phenotype_comparison_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phenotype_comparison_idx4 ON phenotype_comparison USING btree (pub_id);


--
-- Name: phenotype_cvterm_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phenotype_cvterm_idx1 ON phenotype_cvterm USING btree (phenotype_id);


--
-- Name: phenotype_cvterm_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phenotype_cvterm_idx2 ON phenotype_cvterm USING btree (cvterm_id);


--
-- Name: phenotype_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phenotype_idx1 ON phenotype USING btree (cvalue_id);


--
-- Name: phenotype_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phenotype_idx2 ON phenotype USING btree (observable_id);


--
-- Name: phenotype_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phenotype_idx3 ON phenotype USING btree (attr_id);


--
-- Name: phenstatement_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phenstatement_idx1 ON phenstatement USING btree (genotype_id);


--
-- Name: phenstatement_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phenstatement_idx2 ON phenstatement USING btree (phenotype_id);


--
-- Name: phylonode_dbxref_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylonode_dbxref_idx1 ON phylonode_dbxref USING btree (phylonode_id);


--
-- Name: phylonode_dbxref_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylonode_dbxref_idx2 ON phylonode_dbxref USING btree (dbxref_id);


--
-- Name: phylonode_organism_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylonode_organism_idx1 ON phylonode_organism USING btree (phylonode_id);


--
-- Name: phylonode_organism_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylonode_organism_idx2 ON phylonode_organism USING btree (organism_id);


--
-- Name: phylonode_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylonode_pub_idx1 ON phylonode_pub USING btree (phylonode_id);


--
-- Name: phylonode_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylonode_pub_idx2 ON phylonode_pub USING btree (pub_id);


--
-- Name: phylonode_relationship_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylonode_relationship_idx1 ON phylonode_relationship USING btree (subject_id);


--
-- Name: phylonode_relationship_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylonode_relationship_idx2 ON phylonode_relationship USING btree (object_id);


--
-- Name: phylonode_relationship_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylonode_relationship_idx3 ON phylonode_relationship USING btree (type_id);


--
-- Name: phylonodeprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylonodeprop_idx1 ON phylonodeprop USING btree (phylonode_id);


--
-- Name: phylonodeprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylonodeprop_idx2 ON phylonodeprop USING btree (type_id);


--
-- Name: phylotree_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylotree_idx1 ON phylotree USING btree (phylotree_id);


--
-- Name: phylotree_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylotree_pub_idx1 ON phylotree_pub USING btree (phylotree_id);


--
-- Name: phylotree_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX phylotree_pub_idx2 ON phylotree_pub USING btree (pub_id);


--
-- Name: protocolparam_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX protocolparam_idx1 ON protocolparam USING btree (protocol_id);


--
-- Name: protocolparam_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX protocolparam_idx2 ON protocolparam USING btree (datatype_id);


--
-- Name: protocolparam_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX protocolparam_idx3 ON protocolparam USING btree (unittype_id);


--
-- Name: pub_dbxref_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX pub_dbxref_idx1 ON pub_dbxref USING btree (pub_id);


--
-- Name: pub_dbxref_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX pub_dbxref_idx2 ON pub_dbxref USING btree (dbxref_id);


--
-- Name: pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX pub_idx1 ON pub USING btree (type_id);


--
-- Name: pub_relationship_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX pub_relationship_idx1 ON pub_relationship USING btree (subject_id);


--
-- Name: pub_relationship_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX pub_relationship_idx2 ON pub_relationship USING btree (object_id);


--
-- Name: pub_relationship_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX pub_relationship_idx3 ON pub_relationship USING btree (type_id);


--
-- Name: pubauthor_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX pubauthor_idx2 ON pubauthor USING btree (pub_id);


--
-- Name: pubprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX pubprop_idx1 ON pubprop USING btree (pub_id);


--
-- Name: pubprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX pubprop_idx2 ON pubprop USING btree (type_id);


--
-- Name: quantification_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX quantification_idx1 ON quantification USING btree (acquisition_id);


--
-- Name: quantification_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX quantification_idx2 ON quantification USING btree (operator_id);


--
-- Name: quantification_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX quantification_idx3 ON quantification USING btree (protocol_id);


--
-- Name: quantification_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX quantification_idx4 ON quantification USING btree (analysis_id);


--
-- Name: quantification_relationship_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX quantification_relationship_idx1 ON quantification_relationship USING btree (subject_id);


--
-- Name: quantification_relationship_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX quantification_relationship_idx2 ON quantification_relationship USING btree (type_id);


--
-- Name: quantification_relationship_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX quantification_relationship_idx3 ON quantification_relationship USING btree (object_id);


--
-- Name: quantificationprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX quantificationprop_idx1 ON quantificationprop USING btree (quantification_id);


--
-- Name: quantificationprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX quantificationprop_idx2 ON quantificationprop USING btree (type_id);


--
-- Name: stock_cvterm_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_cvterm_idx1 ON stock_cvterm USING btree (stock_id);


--
-- Name: stock_cvterm_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_cvterm_idx2 ON stock_cvterm USING btree (cvterm_id);


--
-- Name: stock_cvterm_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_cvterm_idx3 ON stock_cvterm USING btree (pub_id);


--
-- Name: stock_dbxref_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_dbxref_idx1 ON stock_dbxref USING btree (stock_id);


--
-- Name: stock_dbxref_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_dbxref_idx2 ON stock_dbxref USING btree (dbxref_id);


--
-- Name: stock_genotype_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_genotype_idx1 ON stock_genotype USING btree (stock_id);


--
-- Name: stock_genotype_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_genotype_idx2 ON stock_genotype USING btree (genotype_id);


--
-- Name: stock_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_idx1 ON stock USING btree (dbxref_id);


--
-- Name: stock_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_idx2 ON stock USING btree (organism_id);


--
-- Name: stock_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_idx3 ON stock USING btree (type_id);


--
-- Name: stock_idx4; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_idx4 ON stock USING btree (uniquename);


--
-- Name: stock_name_ind1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_name_ind1 ON stock USING btree (name);


--
-- Name: stock_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_pub_idx1 ON stock_pub USING btree (stock_id);


--
-- Name: stock_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_pub_idx2 ON stock_pub USING btree (pub_id);


--
-- Name: stock_relationship_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_relationship_idx1 ON stock_relationship USING btree (subject_id);


--
-- Name: stock_relationship_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_relationship_idx2 ON stock_relationship USING btree (object_id);


--
-- Name: stock_relationship_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_relationship_idx3 ON stock_relationship USING btree (type_id);


--
-- Name: stock_relationship_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_relationship_pub_idx1 ON stock_relationship_pub USING btree (stock_relationship_id);


--
-- Name: stock_relationship_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stock_relationship_pub_idx2 ON stock_relationship_pub USING btree (pub_id);


--
-- Name: stockcollection_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockcollection_idx1 ON stockcollection USING btree (contact_id);


--
-- Name: stockcollection_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockcollection_idx2 ON stockcollection USING btree (type_id);


--
-- Name: stockcollection_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockcollection_idx3 ON stockcollection USING btree (uniquename);


--
-- Name: stockcollection_name_ind1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockcollection_name_ind1 ON stockcollection USING btree (name);


--
-- Name: stockcollection_stock_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockcollection_stock_idx1 ON stockcollection_stock USING btree (stockcollection_id);


--
-- Name: stockcollection_stock_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockcollection_stock_idx2 ON stockcollection_stock USING btree (stock_id);


--
-- Name: stockcollectionprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockcollectionprop_idx1 ON stockcollectionprop USING btree (stockcollection_id);


--
-- Name: stockcollectionprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockcollectionprop_idx2 ON stockcollectionprop USING btree (type_id);


--
-- Name: stockprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockprop_idx1 ON stockprop USING btree (stock_id);


--
-- Name: stockprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockprop_idx2 ON stockprop USING btree (type_id);


--
-- Name: stockprop_pub_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockprop_pub_idx1 ON stockprop_pub USING btree (stockprop_id);


--
-- Name: stockprop_pub_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX stockprop_pub_idx2 ON stockprop_pub USING btree (pub_id);


--
-- Name: study_assay_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX study_assay_idx1 ON study_assay USING btree (study_id);


--
-- Name: study_assay_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX study_assay_idx2 ON study_assay USING btree (assay_id);


--
-- Name: study_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX study_idx1 ON study USING btree (contact_id);


--
-- Name: study_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX study_idx2 ON study USING btree (pub_id);


--
-- Name: study_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX study_idx3 ON study USING btree (dbxref_id);


--
-- Name: studydesign_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX studydesign_idx1 ON studydesign USING btree (study_id);


--
-- Name: studydesignprop_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX studydesignprop_idx1 ON studydesignprop USING btree (studydesign_id);


--
-- Name: studydesignprop_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX studydesignprop_idx2 ON studydesignprop USING btree (type_id);


--
-- Name: studyfactor_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX studyfactor_idx1 ON studyfactor USING btree (studydesign_id);


--
-- Name: studyfactor_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX studyfactor_idx2 ON studyfactor USING btree (type_id);


--
-- Name: studyfactorvalue_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX studyfactorvalue_idx1 ON studyfactorvalue USING btree (studyfactor_id);


--
-- Name: studyfactorvalue_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX studyfactorvalue_idx2 ON studyfactorvalue USING btree (assay_id);


--
-- Name: synonym_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX synonym_idx1 ON synonym USING btree (type_id);


--
-- Name: synonym_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX synonym_idx2 ON synonym USING btree (lower((synonym_sgml)::text));


--
-- Name: treatment_idx1; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX treatment_idx1 ON treatment USING btree (biomaterial_id);


--
-- Name: treatment_idx2; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX treatment_idx2 ON treatment USING btree (type_id);


--
-- Name: treatment_idx3; Type: INDEX; Schema: $temporary_chado_schema_name$; Owner: -; Tablespace: 
--

CREATE INDEX treatment_idx3 ON treatment USING btree (protocol_id);


--
-- Name: viewlimitstrigger; Type: TRIGGER; Schema: $temporary_chado_schema_name$; Owner: -
--

CREATE TRIGGER viewlimitstrigger
    BEFORE INSERT ON wiggle_data
    FOR EACH ROW
    EXECUTE PROCEDURE wiggle.viewlimitstrigger();


--
-- Name: acquisition_assay_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY acquisition
    ADD CONSTRAINT acquisition_assay_id_fkey FOREIGN KEY (assay_id) REFERENCES assay(assay_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER acquisition_assay_id_trigger BEFORE INSERT OR UPDATE ON acquisition
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.acquisition_assay_id_trigger_func();

--
-- Name: acquisition_channel_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY acquisition
    ADD CONSTRAINT acquisition_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES channel(channel_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER acquisition_channel_id_trigger BEFORE INSERT OR UPDATE ON acquisition
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.acquisition_channel_id_trigger_func();

--
-- Name: acquisition_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY acquisition_relationship
    ADD CONSTRAINT acquisition_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES acquisition(acquisition_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER acquisition_relationship_object_id_trigger BEFORE INSERT OR UPDATE ON acquisition_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.acquisition_relationship_object_id_trigger_func();

--
-- Name: acquisition_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY acquisition_relationship
    ADD CONSTRAINT acquisition_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES acquisition(acquisition_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER acquisition_relationship_subject_id_trigger BEFORE INSERT OR UPDATE ON acquisition_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.acquisition_relationship_subject_id_trigger_func();

--
-- Name: acquisition_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY acquisition_relationship
    ADD CONSTRAINT acquisition_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER acquisition_relationship_type_id_trigger BEFORE INSERT OR UPDATE ON acquisition_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.acquisition_relationship_type_id_trigger_func();

--
-- Name: acquisitionprop_acquisition_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY acquisitionprop
    ADD CONSTRAINT acquisitionprop_acquisition_id_fkey FOREIGN KEY (acquisition_id) REFERENCES acquisition(acquisition_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER acquisitionprop_acquisition_id_trigger BEFORE INSERT OR UPDATE ON acquisitionprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.acquisitionprop_acquisition_id_trigger_func();

--
-- Name: acquisitionprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY acquisitionprop
    ADD CONSTRAINT acquisitionprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER acquisitionprop_type_id_trigger BEFORE INSERT OR UPDATE ON acquisitionprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.acquisitionprop_type_id_trigger_func();

--
-- Name: analysisfeature_analysis_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY analysisfeature
    ADD CONSTRAINT analysisfeature_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES analysis(analysis_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER analysisfeature_analysis_id_trigger BEFORE INSERT OR UPDATE ON analysisfeature
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.analysisfeature_analysis_id_trigger_func();

--
-- Name: analysisfeature_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY analysisfeature
    ADD CONSTRAINT analysisfeature_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER analysisfeature_feature_id_trigger BEFORE INSERT OR UPDATE ON analysisfeature
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.analysisfeature_feature_id_trigger_func();

--
-- Name: analysisprop_analysis_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY analysisprop
    ADD CONSTRAINT analysisprop_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES analysis(analysis_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER analysisprop_analysis_id_trigger BEFORE INSERT OR UPDATE ON analysisprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.analysisprop_analysis_id_trigger_func();

--
-- Name: analysisprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY analysisprop
    ADD CONSTRAINT analysisprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER analysisprop_type_id_trigger BEFORE INSERT OR UPDATE ON analysisprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.analysisprop_type_id_trigger_func();

--
-- Name: applied_protocol_data_applied_protocol_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY applied_protocol_data
    ADD CONSTRAINT applied_protocol_data_applied_protocol_id_fkey FOREIGN KEY (applied_protocol_id) REFERENCES applied_protocol(applied_protocol_id) ON DELETE CASCADE;

CREATE TRIGGER applied_protocol_data_applied_protocol_id_trigger BEFORE INSERT OR UPDATE ON applied_protocol_data
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.applied_protocol_data_applied_protocol_id_trigger_func();

--
-- Name: applied_protocol_data_data_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY applied_protocol_data
    ADD CONSTRAINT applied_protocol_data_data_id_fkey FOREIGN KEY (data_id) REFERENCES data(data_id) ON DELETE CASCADE;

CREATE TRIGGER applied_protocol_data_data_id_trigger BEFORE INSERT OR UPDATE ON applied_protocol_data
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.applied_protocol_data_data_id_trigger_func();

--
-- Name: applied_protocol_protocol_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY applied_protocol
    ADD CONSTRAINT applied_protocol_protocol_id_fkey FOREIGN KEY (protocol_id) REFERENCES protocol(protocol_id) ON DELETE CASCADE;

CREATE TRIGGER applied_protocol_protocol_id_trigger BEFORE INSERT OR UPDATE ON applied_protocol
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.applied_protocol_protocol_id_trigger_func();

--
-- Name: arraydesign_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY arraydesign
    ADD CONSTRAINT arraydesign_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER arraydesign_dbxref_id_trigger BEFORE INSERT OR UPDATE ON arraydesign
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.arraydesign_dbxref_id_trigger_func();

--
-- Name: arraydesign_manufacturer_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY arraydesign
    ADD CONSTRAINT arraydesign_manufacturer_id_fkey FOREIGN KEY (manufacturer_id) REFERENCES contact(contact_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER arraydesign_manufacturer_id_trigger BEFORE INSERT OR UPDATE ON arraydesign
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.arraydesign_manufacturer_id_trigger_func();

--
-- Name: arraydesign_platformtype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY arraydesign
    ADD CONSTRAINT arraydesign_platformtype_id_fkey FOREIGN KEY (platformtype_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER arraydesign_platformtype_id_trigger BEFORE INSERT OR UPDATE ON arraydesign
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.arraydesign_platformtype_id_trigger_func();

--
-- Name: arraydesign_substratetype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY arraydesign
    ADD CONSTRAINT arraydesign_substratetype_id_fkey FOREIGN KEY (substratetype_id) REFERENCES cvterm(cvterm_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER arraydesign_substratetype_id_trigger BEFORE INSERT OR UPDATE ON arraydesign
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.arraydesign_substratetype_id_trigger_func();

--
-- Name: arraydesignprop_arraydesign_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY arraydesignprop
    ADD CONSTRAINT arraydesignprop_arraydesign_id_fkey FOREIGN KEY (arraydesign_id) REFERENCES arraydesign(arraydesign_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER arraydesignprop_arraydesign_id_trigger BEFORE INSERT OR UPDATE ON arraydesignprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.arraydesignprop_arraydesign_id_trigger_func();

--
-- Name: arraydesignprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY arraydesignprop
    ADD CONSTRAINT arraydesignprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER arraydesignprop_type_id_trigger BEFORE INSERT OR UPDATE ON arraydesignprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.arraydesignprop_type_id_trigger_func();

--
-- Name: assay_arraydesign_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY assay
    ADD CONSTRAINT assay_arraydesign_id_fkey FOREIGN KEY (arraydesign_id) REFERENCES arraydesign(arraydesign_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER assay_arraydesign_id_trigger BEFORE INSERT OR UPDATE ON assay
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.assay_arraydesign_id_trigger_func();

--
-- Name: assay_biomaterial_assay_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY assay_biomaterial
    ADD CONSTRAINT assay_biomaterial_assay_id_fkey FOREIGN KEY (assay_id) REFERENCES assay(assay_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER assay_biomaterial_assay_id_trigger BEFORE INSERT OR UPDATE ON assay_biomaterial
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.assay_biomaterial_assay_id_trigger_func();

--
-- Name: assay_biomaterial_biomaterial_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY assay_biomaterial
    ADD CONSTRAINT assay_biomaterial_biomaterial_id_fkey FOREIGN KEY (biomaterial_id) REFERENCES biomaterial(biomaterial_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER assay_biomaterial_biomaterial_id_trigger BEFORE INSERT OR UPDATE ON assay_biomaterial
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.assay_biomaterial_biomaterial_id_trigger_func();

--
-- Name: assay_biomaterial_channel_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY assay_biomaterial
    ADD CONSTRAINT assay_biomaterial_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES channel(channel_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER assay_biomaterial_channel_id_trigger BEFORE INSERT OR UPDATE ON assay_biomaterial
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.assay_biomaterial_channel_id_trigger_func();

--
-- Name: assay_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY assay
    ADD CONSTRAINT assay_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER assay_dbxref_id_trigger BEFORE INSERT OR UPDATE ON assay
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.assay_dbxref_id_trigger_func();

--
-- Name: assay_operator_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY assay
    ADD CONSTRAINT assay_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES contact(contact_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER assay_operator_id_trigger BEFORE INSERT OR UPDATE ON assay
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.assay_operator_id_trigger_func();

--
-- Name: assay_project_assay_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY assay_project
    ADD CONSTRAINT assay_project_assay_id_fkey FOREIGN KEY (assay_id) REFERENCES assay(assay_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER assay_project_assay_id_trigger BEFORE INSERT OR UPDATE ON assay_project
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.assay_project_assay_id_trigger_func();

--
-- Name: assay_project_project_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY assay_project
    ADD CONSTRAINT assay_project_project_id_fkey FOREIGN KEY (project_id) REFERENCES project(project_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER assay_project_project_id_trigger BEFORE INSERT OR UPDATE ON assay_project
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.assay_project_project_id_trigger_func();

--
-- Name: assayprop_assay_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY assayprop
    ADD CONSTRAINT assayprop_assay_id_fkey FOREIGN KEY (assay_id) REFERENCES assay(assay_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER assayprop_assay_id_trigger BEFORE INSERT OR UPDATE ON assayprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.assayprop_assay_id_trigger_func();

--
-- Name: assayprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY assayprop
    ADD CONSTRAINT assayprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER assayprop_type_id_trigger BEFORE INSERT OR UPDATE ON assayprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.assayprop_type_id_trigger_func();

--
-- Name: attribute_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY attribute
    ADD CONSTRAINT attribute_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE RESTRICT;

CREATE TRIGGER attribute_dbxref_id_trigger BEFORE INSERT OR UPDATE ON attribute
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.attribute_dbxref_id_trigger_func();

--
-- Name: attribute_organism_attribute_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY attribute_organism
    ADD CONSTRAINT attribute_organism_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES attribute(attribute_id) ON DELETE CASCADE;

CREATE TRIGGER attribute_organism_attribute_id_trigger BEFORE INSERT OR UPDATE ON attribute_organism
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.attribute_organism_attribute_id_trigger_func();

--
-- Name: attribute_organism_organism_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY attribute_organism
    ADD CONSTRAINT attribute_organism_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES organism(organism_id) ON DELETE RESTRICT;

CREATE TRIGGER attribute_organism_organism_id_trigger BEFORE INSERT OR UPDATE ON attribute_organism
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.attribute_organism_organism_id_trigger_func();

--
-- Name: attribute_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY attribute
    ADD CONSTRAINT attribute_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE RESTRICT;

CREATE TRIGGER attribute_type_id_trigger BEFORE INSERT OR UPDATE ON attribute
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.attribute_type_id_trigger_func();

--
-- Name: biomaterial_biosourceprovider_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterial
    ADD CONSTRAINT biomaterial_biosourceprovider_id_fkey FOREIGN KEY (biosourceprovider_id) REFERENCES contact(contact_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterial_biosourceprovider_id_trigger BEFORE INSERT OR UPDATE ON biomaterial
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterial_biosourceprovider_id_trigger_func();

--
-- Name: biomaterial_dbxref_biomaterial_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterial_dbxref
    ADD CONSTRAINT biomaterial_dbxref_biomaterial_id_fkey FOREIGN KEY (biomaterial_id) REFERENCES biomaterial(biomaterial_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterial_dbxref_biomaterial_id_trigger BEFORE INSERT OR UPDATE ON biomaterial_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterial_dbxref_biomaterial_id_trigger_func();

--
-- Name: biomaterial_dbxref_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterial_dbxref
    ADD CONSTRAINT biomaterial_dbxref_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterial_dbxref_dbxref_id_trigger BEFORE INSERT OR UPDATE ON biomaterial_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterial_dbxref_dbxref_id_trigger_func();

--
-- Name: biomaterial_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterial
    ADD CONSTRAINT biomaterial_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterial_dbxref_id_trigger BEFORE INSERT OR UPDATE ON biomaterial
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterial_dbxref_id_trigger_func();

--
-- Name: biomaterial_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterial_relationship
    ADD CONSTRAINT biomaterial_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES biomaterial(biomaterial_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterial_relationship_object_id_trigger BEFORE INSERT OR UPDATE ON biomaterial_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterial_relationship_object_id_trigger_func();

--
-- Name: biomaterial_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterial_relationship
    ADD CONSTRAINT biomaterial_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES biomaterial(biomaterial_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterial_relationship_subject_id_trigger BEFORE INSERT OR UPDATE ON biomaterial_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterial_relationship_subject_id_trigger_func();

--
-- Name: biomaterial_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterial_relationship
    ADD CONSTRAINT biomaterial_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterial_relationship_type_id_trigger BEFORE INSERT OR UPDATE ON biomaterial_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterial_relationship_type_id_trigger_func();

--
-- Name: biomaterial_taxon_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterial
    ADD CONSTRAINT biomaterial_taxon_id_fkey FOREIGN KEY (taxon_id) REFERENCES organism(organism_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterial_taxon_id_trigger BEFORE INSERT OR UPDATE ON biomaterial
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterial_taxon_id_trigger_func();

--
-- Name: biomaterial_treatment_biomaterial_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterial_treatment
    ADD CONSTRAINT biomaterial_treatment_biomaterial_id_fkey FOREIGN KEY (biomaterial_id) REFERENCES biomaterial(biomaterial_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterial_treatment_biomaterial_id_trigger BEFORE INSERT OR UPDATE ON biomaterial_treatment
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterial_treatment_biomaterial_id_trigger_func();

--
-- Name: biomaterial_treatment_treatment_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterial_treatment
    ADD CONSTRAINT biomaterial_treatment_treatment_id_fkey FOREIGN KEY (treatment_id) REFERENCES treatment(treatment_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterial_treatment_treatment_id_trigger BEFORE INSERT OR UPDATE ON biomaterial_treatment
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterial_treatment_treatment_id_trigger_func();

--
-- Name: biomaterial_treatment_unittype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterial_treatment
    ADD CONSTRAINT biomaterial_treatment_unittype_id_fkey FOREIGN KEY (unittype_id) REFERENCES cvterm(cvterm_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterial_treatment_unittype_id_trigger BEFORE INSERT OR UPDATE ON biomaterial_treatment
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterial_treatment_unittype_id_trigger_func();

--
-- Name: biomaterialprop_biomaterial_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterialprop
    ADD CONSTRAINT biomaterialprop_biomaterial_id_fkey FOREIGN KEY (biomaterial_id) REFERENCES biomaterial(biomaterial_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterialprop_biomaterial_id_trigger BEFORE INSERT OR UPDATE ON biomaterialprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterialprop_biomaterial_id_trigger_func();

--
-- Name: biomaterialprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY biomaterialprop
    ADD CONSTRAINT biomaterialprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER biomaterialprop_type_id_trigger BEFORE INSERT OR UPDATE ON biomaterialprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.biomaterialprop_type_id_trigger_func();

--
-- Name: contact_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY contact_relationship
    ADD CONSTRAINT contact_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES contact(contact_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER contact_relationship_object_id_trigger BEFORE INSERT OR UPDATE ON contact_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.contact_relationship_object_id_trigger_func();

--
-- Name: contact_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY contact_relationship
    ADD CONSTRAINT contact_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES contact(contact_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER contact_relationship_subject_id_trigger BEFORE INSERT OR UPDATE ON contact_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.contact_relationship_subject_id_trigger_func();

--
-- Name: contact_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY contact_relationship
    ADD CONSTRAINT contact_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER contact_relationship_type_id_trigger BEFORE INSERT OR UPDATE ON contact_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.contact_relationship_type_id_trigger_func();

--
-- Name: contact_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY contact
    ADD CONSTRAINT contact_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id);

CREATE TRIGGER contact_type_id_trigger BEFORE INSERT OR UPDATE ON contact
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.contact_type_id_trigger_func();

--
-- Name: contactprop_contact_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY contactprop
    ADD CONSTRAINT contactprop_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES contact(contact_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER contactprop_contact_id_trigger BEFORE INSERT OR UPDATE ON contactprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.contactprop_contact_id_trigger_func();

--
-- Name: contactprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY contactprop
    ADD CONSTRAINT contactprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER contactprop_type_id_trigger BEFORE INSERT OR UPDATE ON contactprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.contactprop_type_id_trigger_func();

--
-- Name: control_assay_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY control
    ADD CONSTRAINT control_assay_id_fkey FOREIGN KEY (assay_id) REFERENCES assay(assay_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER control_assay_id_trigger BEFORE INSERT OR UPDATE ON control
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.control_assay_id_trigger_func();

--
-- Name: control_tableinfo_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY control
    ADD CONSTRAINT control_tableinfo_id_fkey FOREIGN KEY (tableinfo_id) REFERENCES tableinfo(tableinfo_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER control_tableinfo_id_trigger BEFORE INSERT OR UPDATE ON control
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.control_tableinfo_id_trigger_func();

--
-- Name: control_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY control
    ADD CONSTRAINT control_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER control_type_id_trigger BEFORE INSERT OR UPDATE ON control
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.control_type_id_trigger_func();

--
-- Name: cvterm_cv_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvterm
    ADD CONSTRAINT cvterm_cv_id_fkey FOREIGN KEY (cv_id) REFERENCES cv(cv_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvterm_cv_id_trigger BEFORE INSERT OR UPDATE ON cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvterm_cv_id_trigger_func();

--
-- Name: cvterm_dbxref_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvterm_dbxref
    ADD CONSTRAINT cvterm_dbxref_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvterm_dbxref_cvterm_id_trigger BEFORE INSERT OR UPDATE ON cvterm_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvterm_dbxref_cvterm_id_trigger_func();

--
-- Name: cvterm_dbxref_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvterm_dbxref
    ADD CONSTRAINT cvterm_dbxref_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvterm_dbxref_dbxref_id_trigger BEFORE INSERT OR UPDATE ON cvterm_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvterm_dbxref_dbxref_id_trigger_func();

--
-- Name: cvterm_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvterm
    ADD CONSTRAINT cvterm_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvterm_dbxref_id_trigger BEFORE INSERT OR UPDATE ON cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvterm_dbxref_id_trigger_func();

--
-- Name: cvterm_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvterm_relationship
    ADD CONSTRAINT cvterm_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvterm_relationship_object_id_trigger BEFORE INSERT OR UPDATE ON cvterm_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvterm_relationship_object_id_trigger_func();

--
-- Name: cvterm_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvterm_relationship
    ADD CONSTRAINT cvterm_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvterm_relationship_subject_id_trigger BEFORE INSERT OR UPDATE ON cvterm_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvterm_relationship_subject_id_trigger_func();

--
-- Name: cvterm_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvterm_relationship
    ADD CONSTRAINT cvterm_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvterm_relationship_type_id_trigger BEFORE INSERT OR UPDATE ON cvterm_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvterm_relationship_type_id_trigger_func();

--
-- Name: cvtermpath_cv_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvtermpath
    ADD CONSTRAINT cvtermpath_cv_id_fkey FOREIGN KEY (cv_id) REFERENCES cv(cv_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvtermpath_cv_id_trigger BEFORE INSERT OR UPDATE ON cvtermpath
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvtermpath_cv_id_trigger_func();

--
-- Name: cvtermpath_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvtermpath
    ADD CONSTRAINT cvtermpath_object_id_fkey FOREIGN KEY (object_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvtermpath_object_id_trigger BEFORE INSERT OR UPDATE ON cvtermpath
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvtermpath_object_id_trigger_func();

--
-- Name: cvtermpath_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvtermpath
    ADD CONSTRAINT cvtermpath_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvtermpath_subject_id_trigger BEFORE INSERT OR UPDATE ON cvtermpath
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvtermpath_subject_id_trigger_func();

--
-- Name: cvtermpath_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvtermpath
    ADD CONSTRAINT cvtermpath_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvtermpath_type_id_trigger BEFORE INSERT OR UPDATE ON cvtermpath
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvtermpath_type_id_trigger_func();

--
-- Name: cvtermprop_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvtermprop
    ADD CONSTRAINT cvtermprop_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER cvtermprop_cvterm_id_trigger BEFORE INSERT OR UPDATE ON cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvtermprop_cvterm_id_trigger_func();

--
-- Name: cvtermprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvtermprop
    ADD CONSTRAINT cvtermprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER cvtermprop_type_id_trigger BEFORE INSERT OR UPDATE ON cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvtermprop_type_id_trigger_func();

--
-- Name: cvtermsynonym_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvtermsynonym
    ADD CONSTRAINT cvtermsynonym_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvtermsynonym_cvterm_id_trigger BEFORE INSERT OR UPDATE ON cvtermsynonym
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvtermsynonym_cvterm_id_trigger_func();

--
-- Name: cvtermsynonym_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY cvtermsynonym
    ADD CONSTRAINT cvtermsynonym_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER cvtermsynonym_type_id_trigger BEFORE INSERT OR UPDATE ON cvtermsynonym
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.cvtermsynonym_type_id_trigger_func();

--
-- Name: data_attribute_attribute_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY data_attribute
    ADD CONSTRAINT data_attribute_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES attribute(attribute_id) ON DELETE CASCADE;

CREATE TRIGGER data_attribute_attribute_id_trigger BEFORE INSERT OR UPDATE ON data_attribute
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.data_attribute_attribute_id_trigger_func();

--
-- Name: data_attribute_data_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY data_attribute
    ADD CONSTRAINT data_attribute_data_id_fkey FOREIGN KEY (data_id) REFERENCES data(data_id) ON DELETE CASCADE;

CREATE TRIGGER data_attribute_data_id_trigger BEFORE INSERT OR UPDATE ON data_attribute
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.data_attribute_data_id_trigger_func();

--
-- Name: data_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY data
    ADD CONSTRAINT data_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE RESTRICT;

CREATE TRIGGER data_dbxref_id_trigger BEFORE INSERT OR UPDATE ON data
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.data_dbxref_id_trigger_func();

--
-- Name: data_feature_data_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY data_feature
    ADD CONSTRAINT data_feature_data_id_fkey FOREIGN KEY (data_id) REFERENCES data(data_id) ON DELETE CASCADE;

CREATE TRIGGER data_feature_data_id_trigger BEFORE INSERT OR UPDATE ON data_feature
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.data_feature_data_id_trigger_func();

--
-- Name: data_feature_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY data_feature
    ADD CONSTRAINT data_feature_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE RESTRICT;

CREATE TRIGGER data_feature_feature_id_trigger BEFORE INSERT OR UPDATE ON data_feature
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.data_feature_feature_id_trigger_func();

--
-- Name: data_organism_data_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY data_organism
    ADD CONSTRAINT data_organism_data_id_fkey FOREIGN KEY (data_id) REFERENCES data(data_id) ON DELETE CASCADE;

CREATE TRIGGER data_organism_data_id_trigger BEFORE INSERT OR UPDATE ON data_organism
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.data_organism_data_id_trigger_func();

--
-- Name: data_organism_organism_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY data_organism
    ADD CONSTRAINT data_organism_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES organism(organism_id) ON DELETE RESTRICT;

CREATE TRIGGER data_organism_organism_id_trigger BEFORE INSERT OR UPDATE ON data_organism
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.data_organism_organism_id_trigger_func();

--
-- Name: data_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY data
    ADD CONSTRAINT data_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE RESTRICT;

CREATE TRIGGER data_type_id_trigger BEFORE INSERT OR UPDATE ON data
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.data_type_id_trigger_func();

--
-- Name: data_wiggle_data_data_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY data_wiggle_data
    ADD CONSTRAINT data_wiggle_data_data_id_fkey FOREIGN KEY (data_id) REFERENCES data(data_id) ON DELETE CASCADE;

CREATE TRIGGER data_wiggle_data_data_id_trigger BEFORE INSERT OR UPDATE ON data_wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.data_wiggle_data_data_id_trigger_func();

--
-- Name: data_wiggle_data_wiggle_data_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY data_wiggle_data
    ADD CONSTRAINT data_wiggle_data_wiggle_data_id_fkey FOREIGN KEY (wiggle_data_id) REFERENCES wiggle_data(wiggle_data_id) ON DELETE RESTRICT;

CREATE TRIGGER data_wiggle_data_wiggle_data_id_trigger BEFORE INSERT OR UPDATE ON data_wiggle_data
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.data_wiggle_data_wiggle_data_id_trigger_func();

--
-- Name: dbxref_db_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY dbxref
    ADD CONSTRAINT dbxref_db_id_fkey FOREIGN KEY (db_id) REFERENCES db(db_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER dbxref_db_id_trigger BEFORE INSERT OR UPDATE ON dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.dbxref_db_id_trigger_func();

--
-- Name: dbxrefprop_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY dbxrefprop
    ADD CONSTRAINT dbxrefprop_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER dbxrefprop_dbxref_id_trigger BEFORE INSERT OR UPDATE ON dbxrefprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.dbxrefprop_dbxref_id_trigger_func();

--
-- Name: dbxrefprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY dbxrefprop
    ADD CONSTRAINT dbxrefprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER dbxrefprop_type_id_trigger BEFORE INSERT OR UPDATE ON dbxrefprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.dbxrefprop_type_id_trigger_func();

--
-- Name: element_arraydesign_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY element
    ADD CONSTRAINT element_arraydesign_id_fkey FOREIGN KEY (arraydesign_id) REFERENCES arraydesign(arraydesign_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER element_arraydesign_id_trigger BEFORE INSERT OR UPDATE ON element
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.element_arraydesign_id_trigger_func();

--
-- Name: element_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY element
    ADD CONSTRAINT element_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER element_dbxref_id_trigger BEFORE INSERT OR UPDATE ON element
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.element_dbxref_id_trigger_func();

--
-- Name: element_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY element
    ADD CONSTRAINT element_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER element_feature_id_trigger BEFORE INSERT OR UPDATE ON element
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.element_feature_id_trigger_func();

--
-- Name: element_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY element_relationship
    ADD CONSTRAINT element_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES element(element_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER element_relationship_object_id_trigger BEFORE INSERT OR UPDATE ON element_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.element_relationship_object_id_trigger_func();

--
-- Name: element_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY element_relationship
    ADD CONSTRAINT element_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES element(element_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER element_relationship_subject_id_trigger BEFORE INSERT OR UPDATE ON element_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.element_relationship_subject_id_trigger_func();

--
-- Name: element_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY element_relationship
    ADD CONSTRAINT element_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER element_relationship_type_id_trigger BEFORE INSERT OR UPDATE ON element_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.element_relationship_type_id_trigger_func();

--
-- Name: element_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY element
    ADD CONSTRAINT element_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER element_type_id_trigger BEFORE INSERT OR UPDATE ON element
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.element_type_id_trigger_func();

--
-- Name: elementresult_element_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY elementresult
    ADD CONSTRAINT elementresult_element_id_fkey FOREIGN KEY (element_id) REFERENCES element(element_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER elementresult_element_id_trigger BEFORE INSERT OR UPDATE ON elementresult
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.elementresult_element_id_trigger_func();

--
-- Name: elementresult_quantification_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY elementresult
    ADD CONSTRAINT elementresult_quantification_id_fkey FOREIGN KEY (quantification_id) REFERENCES quantification(quantification_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER elementresult_quantification_id_trigger BEFORE INSERT OR UPDATE ON elementresult
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.elementresult_quantification_id_trigger_func();

--
-- Name: elementresult_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY elementresult_relationship
    ADD CONSTRAINT elementresult_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES elementresult(elementresult_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER elementresult_relationship_object_id_trigger BEFORE INSERT OR UPDATE ON elementresult_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.elementresult_relationship_object_id_trigger_func();

--
-- Name: elementresult_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY elementresult_relationship
    ADD CONSTRAINT elementresult_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES elementresult(elementresult_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER elementresult_relationship_subject_id_trigger BEFORE INSERT OR UPDATE ON elementresult_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.elementresult_relationship_subject_id_trigger_func();

--
-- Name: elementresult_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY elementresult_relationship
    ADD CONSTRAINT elementresult_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER elementresult_relationship_type_id_trigger BEFORE INSERT OR UPDATE ON elementresult_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.elementresult_relationship_type_id_trigger_func();

--
-- Name: environment_cvterm_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY environment_cvterm
    ADD CONSTRAINT environment_cvterm_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER environment_cvterm_cvterm_id_trigger BEFORE INSERT OR UPDATE ON environment_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.environment_cvterm_cvterm_id_trigger_func();

--
-- Name: environment_cvterm_environment_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY environment_cvterm
    ADD CONSTRAINT environment_cvterm_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES environment(environment_id) ON DELETE CASCADE;

CREATE TRIGGER environment_cvterm_environment_id_trigger BEFORE INSERT OR UPDATE ON environment_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.environment_cvterm_environment_id_trigger_func();

--
-- Name: experiment_applied_protocol_experiment_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY experiment_applied_protocol
    ADD CONSTRAINT experiment_applied_protocol_experiment_id_fkey FOREIGN KEY (experiment_id) REFERENCES experiment(experiment_id) ON DELETE CASCADE;

CREATE TRIGGER experiment_applied_protocol_experiment_id_trigger BEFORE INSERT OR UPDATE ON experiment_applied_protocol
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.experiment_applied_protocol_experiment_id_trigger_func();

--
-- Name: experiment_applied_protocol_first_applied_protocol_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY experiment_applied_protocol
    ADD CONSTRAINT experiment_applied_protocol_first_applied_protocol_id_fkey FOREIGN KEY (first_applied_protocol_id) REFERENCES applied_protocol(applied_protocol_id) ON DELETE CASCADE;

CREATE TRIGGER experiment_applied_protocol_first_applied_protocol_id_trigger BEFORE INSERT OR UPDATE ON experiment_applied_protocol
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.experiment_applied_protocol_first_applied_protocol_id_trigger_func();

--
-- Name: experiment_prop_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY experiment_prop
    ADD CONSTRAINT experiment_prop_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id);

CREATE TRIGGER experiment_prop_dbxref_id_trigger BEFORE INSERT OR UPDATE ON experiment_prop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.experiment_prop_dbxref_id_trigger_func();

--
-- Name: experiment_prop_experiment_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY experiment_prop
    ADD CONSTRAINT experiment_prop_experiment_id_fkey FOREIGN KEY (experiment_id) REFERENCES experiment(experiment_id) ON DELETE CASCADE;

CREATE TRIGGER experiment_prop_experiment_id_trigger BEFORE INSERT OR UPDATE ON experiment_prop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.experiment_prop_experiment_id_trigger_func();

--
-- Name: experiment_prop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY experiment_prop
    ADD CONSTRAINT experiment_prop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id);

CREATE TRIGGER experiment_prop_type_id_trigger BEFORE INSERT OR UPDATE ON experiment_prop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.experiment_prop_type_id_trigger_func();

--
-- Name: expression_cvterm_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY expression_cvterm
    ADD CONSTRAINT expression_cvterm_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER expression_cvterm_cvterm_id_trigger BEFORE INSERT OR UPDATE ON expression_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.expression_cvterm_cvterm_id_trigger_func();

--
-- Name: expression_cvterm_cvterm_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY expression_cvterm
    ADD CONSTRAINT expression_cvterm_cvterm_type_id_fkey FOREIGN KEY (cvterm_type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER expression_cvterm_cvterm_type_id_trigger BEFORE INSERT OR UPDATE ON expression_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.expression_cvterm_cvterm_type_id_trigger_func();

--
-- Name: expression_cvterm_expression_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY expression_cvterm
    ADD CONSTRAINT expression_cvterm_expression_id_fkey FOREIGN KEY (expression_id) REFERENCES expression(expression_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER expression_cvterm_expression_id_trigger BEFORE INSERT OR UPDATE ON expression_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.expression_cvterm_expression_id_trigger_func();

--
-- Name: expression_cvtermprop_expression_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY expression_cvtermprop
    ADD CONSTRAINT expression_cvtermprop_expression_cvterm_id_fkey FOREIGN KEY (expression_cvterm_id) REFERENCES expression_cvterm(expression_cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER expression_cvtermprop_expression_cvterm_id_trigger BEFORE INSERT OR UPDATE ON expression_cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.expression_cvtermprop_expression_cvterm_id_trigger_func();

--
-- Name: expression_cvtermprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY expression_cvtermprop
    ADD CONSTRAINT expression_cvtermprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER expression_cvtermprop_type_id_trigger BEFORE INSERT OR UPDATE ON expression_cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.expression_cvtermprop_type_id_trigger_func();

--
-- Name: expression_image_eimage_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY expression_image
    ADD CONSTRAINT expression_image_eimage_id_fkey FOREIGN KEY (eimage_id) REFERENCES eimage(eimage_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER expression_image_eimage_id_trigger BEFORE INSERT OR UPDATE ON expression_image
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.expression_image_eimage_id_trigger_func();

--
-- Name: expression_image_expression_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY expression_image
    ADD CONSTRAINT expression_image_expression_id_fkey FOREIGN KEY (expression_id) REFERENCES expression(expression_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER expression_image_expression_id_trigger BEFORE INSERT OR UPDATE ON expression_image
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.expression_image_expression_id_trigger_func();

--
-- Name: expression_pub_expression_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY expression_pub
    ADD CONSTRAINT expression_pub_expression_id_fkey FOREIGN KEY (expression_id) REFERENCES expression(expression_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER expression_pub_expression_id_trigger BEFORE INSERT OR UPDATE ON expression_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.expression_pub_expression_id_trigger_func();

--
-- Name: expression_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY expression_pub
    ADD CONSTRAINT expression_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER expression_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON expression_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.expression_pub_pub_id_trigger_func();

--
-- Name: expressionprop_expression_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY expressionprop
    ADD CONSTRAINT expressionprop_expression_id_fkey FOREIGN KEY (expression_id) REFERENCES expression(expression_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER expressionprop_expression_id_trigger BEFORE INSERT OR UPDATE ON expressionprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.expressionprop_expression_id_trigger_func();

--
-- Name: expressionprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY expressionprop
    ADD CONSTRAINT expressionprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER expressionprop_type_id_trigger BEFORE INSERT OR UPDATE ON expressionprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.expressionprop_type_id_trigger_func();

--
-- Name: feature_cvterm_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_cvterm
    ADD CONSTRAINT feature_cvterm_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_cvterm_cvterm_id_trigger BEFORE INSERT OR UPDATE ON feature_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_cvterm_cvterm_id_trigger_func();

--
-- Name: feature_cvterm_dbxref_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_cvterm_dbxref
    ADD CONSTRAINT feature_cvterm_dbxref_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_cvterm_dbxref_dbxref_id_trigger BEFORE INSERT OR UPDATE ON feature_cvterm_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_cvterm_dbxref_dbxref_id_trigger_func();

--
-- Name: feature_cvterm_dbxref_feature_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_cvterm_dbxref
    ADD CONSTRAINT feature_cvterm_dbxref_feature_cvterm_id_fkey FOREIGN KEY (feature_cvterm_id) REFERENCES feature_cvterm(feature_cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER feature_cvterm_dbxref_feature_cvterm_id_trigger BEFORE INSERT OR UPDATE ON feature_cvterm_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_cvterm_dbxref_feature_cvterm_id_trigger_func();

--
-- Name: feature_cvterm_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_cvterm
    ADD CONSTRAINT feature_cvterm_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_cvterm_feature_id_trigger BEFORE INSERT OR UPDATE ON feature_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_cvterm_feature_id_trigger_func();

--
-- Name: feature_cvterm_pub_feature_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_cvterm_pub
    ADD CONSTRAINT feature_cvterm_pub_feature_cvterm_id_fkey FOREIGN KEY (feature_cvterm_id) REFERENCES feature_cvterm(feature_cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER feature_cvterm_pub_feature_cvterm_id_trigger BEFORE INSERT OR UPDATE ON feature_cvterm_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_cvterm_pub_feature_cvterm_id_trigger_func();

--
-- Name: feature_cvterm_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_cvterm
    ADD CONSTRAINT feature_cvterm_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_cvterm_pub_id_trigger BEFORE INSERT OR UPDATE ON feature_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_cvterm_pub_id_trigger_func();

--
-- Name: feature_cvterm_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_cvterm_pub
    ADD CONSTRAINT feature_cvterm_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_cvterm_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON feature_cvterm_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_cvterm_pub_pub_id_trigger_func();

--
-- Name: feature_cvtermprop_feature_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_cvtermprop
    ADD CONSTRAINT feature_cvtermprop_feature_cvterm_id_fkey FOREIGN KEY (feature_cvterm_id) REFERENCES feature_cvterm(feature_cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER feature_cvtermprop_feature_cvterm_id_trigger BEFORE INSERT OR UPDATE ON feature_cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_cvtermprop_feature_cvterm_id_trigger_func();

--
-- Name: feature_cvtermprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_cvtermprop
    ADD CONSTRAINT feature_cvtermprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_cvtermprop_type_id_trigger BEFORE INSERT OR UPDATE ON feature_cvtermprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_cvtermprop_type_id_trigger_func();

--
-- Name: feature_dbxref_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_dbxref
    ADD CONSTRAINT feature_dbxref_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_dbxref_dbxref_id_trigger BEFORE INSERT OR UPDATE ON feature_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_dbxref_dbxref_id_trigger_func();

--
-- Name: feature_dbxref_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_dbxref
    ADD CONSTRAINT feature_dbxref_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_dbxref_feature_id_trigger BEFORE INSERT OR UPDATE ON feature_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_dbxref_feature_id_trigger_func();

--
-- Name: feature_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature
    ADD CONSTRAINT feature_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_dbxref_id_trigger BEFORE INSERT OR UPDATE ON feature
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_dbxref_id_trigger_func();

--
-- Name: feature_expression_expression_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_expression
    ADD CONSTRAINT feature_expression_expression_id_fkey FOREIGN KEY (expression_id) REFERENCES expression(expression_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_expression_expression_id_trigger BEFORE INSERT OR UPDATE ON feature_expression
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_expression_expression_id_trigger_func();

--
-- Name: feature_expression_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_expression
    ADD CONSTRAINT feature_expression_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_expression_feature_id_trigger BEFORE INSERT OR UPDATE ON feature_expression
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_expression_feature_id_trigger_func();

--
-- Name: feature_expression_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_expression
    ADD CONSTRAINT feature_expression_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_expression_pub_id_trigger BEFORE INSERT OR UPDATE ON feature_expression
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_expression_pub_id_trigger_func();

--
-- Name: feature_expressionprop_feature_expression_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_expressionprop
    ADD CONSTRAINT feature_expressionprop_feature_expression_id_fkey FOREIGN KEY (feature_expression_id) REFERENCES feature_expression(feature_expression_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_expressionprop_feature_expression_id_trigger BEFORE INSERT OR UPDATE ON feature_expressionprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_expressionprop_feature_expression_id_trigger_func();

--
-- Name: feature_expressionprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_expressionprop
    ADD CONSTRAINT feature_expressionprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_expressionprop_type_id_trigger BEFORE INSERT OR UPDATE ON feature_expressionprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_expressionprop_type_id_trigger_func();

--
-- Name: feature_genotype_chromosome_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_genotype
    ADD CONSTRAINT feature_genotype_chromosome_id_fkey FOREIGN KEY (chromosome_id) REFERENCES feature(feature_id) ON DELETE SET NULL;

CREATE TRIGGER feature_genotype_chromosome_id_trigger BEFORE INSERT OR UPDATE ON feature_genotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_genotype_chromosome_id_trigger_func();

--
-- Name: feature_genotype_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_genotype
    ADD CONSTRAINT feature_genotype_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER feature_genotype_cvterm_id_trigger BEFORE INSERT OR UPDATE ON feature_genotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_genotype_cvterm_id_trigger_func();

--
-- Name: feature_genotype_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_genotype
    ADD CONSTRAINT feature_genotype_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE;

CREATE TRIGGER feature_genotype_feature_id_trigger BEFORE INSERT OR UPDATE ON feature_genotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_genotype_feature_id_trigger_func();

--
-- Name: feature_genotype_genotype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_genotype
    ADD CONSTRAINT feature_genotype_genotype_id_fkey FOREIGN KEY (genotype_id) REFERENCES genotype(genotype_id) ON DELETE CASCADE;

CREATE TRIGGER feature_genotype_genotype_id_trigger BEFORE INSERT OR UPDATE ON feature_genotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_genotype_genotype_id_trigger_func();

--
-- Name: feature_organism_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature
    ADD CONSTRAINT feature_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES organism(organism_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_organism_id_trigger BEFORE INSERT OR UPDATE ON feature
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_organism_id_trigger_func();

--
-- Name: feature_phenotype_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_phenotype
    ADD CONSTRAINT feature_phenotype_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE;

CREATE TRIGGER feature_phenotype_feature_id_trigger BEFORE INSERT OR UPDATE ON feature_phenotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_phenotype_feature_id_trigger_func();

--
-- Name: feature_phenotype_phenotype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_phenotype
    ADD CONSTRAINT feature_phenotype_phenotype_id_fkey FOREIGN KEY (phenotype_id) REFERENCES phenotype(phenotype_id) ON DELETE CASCADE;

CREATE TRIGGER feature_phenotype_phenotype_id_trigger BEFORE INSERT OR UPDATE ON feature_phenotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_phenotype_phenotype_id_trigger_func();

--
-- Name: feature_pub_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_pub
    ADD CONSTRAINT feature_pub_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_pub_feature_id_trigger BEFORE INSERT OR UPDATE ON feature_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_pub_feature_id_trigger_func();

--
-- Name: feature_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_pub
    ADD CONSTRAINT feature_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON feature_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_pub_pub_id_trigger_func();

--
-- Name: feature_pubprop_feature_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_pubprop
    ADD CONSTRAINT feature_pubprop_feature_pub_id_fkey FOREIGN KEY (feature_pub_id) REFERENCES feature_pub(feature_pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_pubprop_feature_pub_id_trigger BEFORE INSERT OR UPDATE ON feature_pubprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_pubprop_feature_pub_id_trigger_func();

--
-- Name: feature_pubprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_pubprop
    ADD CONSTRAINT feature_pubprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_pubprop_type_id_trigger BEFORE INSERT OR UPDATE ON feature_pubprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_pubprop_type_id_trigger_func();

--
-- Name: feature_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_relationship
    ADD CONSTRAINT feature_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_relationship_object_id_trigger BEFORE INSERT OR UPDATE ON feature_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_relationship_object_id_trigger_func();

--
-- Name: feature_relationship_pub_feature_relationship_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_relationship_pub
    ADD CONSTRAINT feature_relationship_pub_feature_relationship_id_fkey FOREIGN KEY (feature_relationship_id) REFERENCES feature_relationship(feature_relationship_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_relationship_pub_feature_relationship_id_trigger BEFORE INSERT OR UPDATE ON feature_relationship_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_relationship_pub_feature_relationship_id_trigger_func();

--
-- Name: feature_relationship_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_relationship_pub
    ADD CONSTRAINT feature_relationship_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_relationship_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON feature_relationship_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_relationship_pub_pub_id_trigger_func();

--
-- Name: feature_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_relationship
    ADD CONSTRAINT feature_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_relationship_subject_id_trigger BEFORE INSERT OR UPDATE ON feature_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_relationship_subject_id_trigger_func();

--
-- Name: feature_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_relationship
    ADD CONSTRAINT feature_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_relationship_type_id_trigger BEFORE INSERT OR UPDATE ON feature_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_relationship_type_id_trigger_func();

--
-- Name: feature_relationshipprop_feature_relationship_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_relationshipprop
    ADD CONSTRAINT feature_relationshipprop_feature_relationship_id_fkey FOREIGN KEY (feature_relationship_id) REFERENCES feature_relationship(feature_relationship_id) ON DELETE CASCADE;

CREATE TRIGGER feature_relationshipprop_feature_relationship_id_trigger BEFORE INSERT OR UPDATE ON feature_relationshipprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_relationshipprop_feature_relationship_id_trigger_func();

--
-- Name: feature_relationshipprop_pub_feature_relationshipprop_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_relationshipprop_pub
    ADD CONSTRAINT feature_relationshipprop_pub_feature_relationshipprop_id_fkey FOREIGN KEY (feature_relationshipprop_id) REFERENCES feature_relationshipprop(feature_relationshipprop_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_relationshipprop_pub_feature_relationshipprop_id_trigger BEFORE INSERT OR UPDATE ON feature_relationshipprop_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_relationshipprop_pub_feature_relationshipprop_id_trigger_func();

--
-- Name: feature_relationshipprop_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_relationshipprop_pub
    ADD CONSTRAINT feature_relationshipprop_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_relationshipprop_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON feature_relationshipprop_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_relationshipprop_pub_pub_id_trigger_func();

--
-- Name: feature_relationshipprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_relationshipprop
    ADD CONSTRAINT feature_relationshipprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_relationshipprop_type_id_trigger BEFORE INSERT OR UPDATE ON feature_relationshipprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_relationshipprop_type_id_trigger_func();

--
-- Name: feature_synonym_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_synonym
    ADD CONSTRAINT feature_synonym_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_synonym_feature_id_trigger BEFORE INSERT OR UPDATE ON feature_synonym
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_synonym_feature_id_trigger_func();

--
-- Name: feature_synonym_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_synonym
    ADD CONSTRAINT feature_synonym_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_synonym_pub_id_trigger BEFORE INSERT OR UPDATE ON feature_synonym
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_synonym_pub_id_trigger_func();

--
-- Name: feature_synonym_synonym_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature_synonym
    ADD CONSTRAINT feature_synonym_synonym_id_fkey FOREIGN KEY (synonym_id) REFERENCES synonym(synonym_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_synonym_synonym_id_trigger BEFORE INSERT OR UPDATE ON feature_synonym
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_synonym_synonym_id_trigger_func();

--
-- Name: feature_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY feature
    ADD CONSTRAINT feature_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER feature_type_id_trigger BEFORE INSERT OR UPDATE ON feature
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.feature_type_id_trigger_func();

--
-- Name: featureloc_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featureloc
    ADD CONSTRAINT featureloc_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featureloc_feature_id_trigger BEFORE INSERT OR UPDATE ON featureloc
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featureloc_feature_id_trigger_func();

--
-- Name: featureloc_pub_featureloc_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featureloc_pub
    ADD CONSTRAINT featureloc_pub_featureloc_id_fkey FOREIGN KEY (featureloc_id) REFERENCES featureloc(featureloc_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featureloc_pub_featureloc_id_trigger BEFORE INSERT OR UPDATE ON featureloc_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featureloc_pub_featureloc_id_trigger_func();

--
-- Name: featureloc_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featureloc_pub
    ADD CONSTRAINT featureloc_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featureloc_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON featureloc_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featureloc_pub_pub_id_trigger_func();

--
-- Name: featureloc_srcfeature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featureloc
    ADD CONSTRAINT featureloc_srcfeature_id_fkey FOREIGN KEY (srcfeature_id) REFERENCES feature(feature_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featureloc_srcfeature_id_trigger BEFORE INSERT OR UPDATE ON featureloc
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featureloc_srcfeature_id_trigger_func();

--
-- Name: featuremap_pub_featuremap_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featuremap_pub
    ADD CONSTRAINT featuremap_pub_featuremap_id_fkey FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featuremap_pub_featuremap_id_trigger BEFORE INSERT OR UPDATE ON featuremap_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featuremap_pub_featuremap_id_trigger_func();

--
-- Name: featuremap_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featuremap_pub
    ADD CONSTRAINT featuremap_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featuremap_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON featuremap_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featuremap_pub_pub_id_trigger_func();

--
-- Name: featuremap_unittype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featuremap
    ADD CONSTRAINT featuremap_unittype_id_fkey FOREIGN KEY (unittype_id) REFERENCES cvterm(cvterm_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featuremap_unittype_id_trigger BEFORE INSERT OR UPDATE ON featuremap
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featuremap_unittype_id_trigger_func();

--
-- Name: featurepos_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featurepos
    ADD CONSTRAINT featurepos_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featurepos_feature_id_trigger BEFORE INSERT OR UPDATE ON featurepos
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featurepos_feature_id_trigger_func();

--
-- Name: featurepos_featuremap_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featurepos
    ADD CONSTRAINT featurepos_featuremap_id_fkey FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featurepos_featuremap_id_trigger BEFORE INSERT OR UPDATE ON featurepos
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featurepos_featuremap_id_trigger_func();

--
-- Name: featurepos_map_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featurepos
    ADD CONSTRAINT featurepos_map_feature_id_fkey FOREIGN KEY (map_feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featurepos_map_feature_id_trigger BEFORE INSERT OR UPDATE ON featurepos
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featurepos_map_feature_id_trigger_func();

--
-- Name: featureprop_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featureprop
    ADD CONSTRAINT featureprop_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featureprop_feature_id_trigger BEFORE INSERT OR UPDATE ON featureprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featureprop_feature_id_trigger_func();

--
-- Name: featureprop_pub_featureprop_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featureprop_pub
    ADD CONSTRAINT featureprop_pub_featureprop_id_fkey FOREIGN KEY (featureprop_id) REFERENCES featureprop(featureprop_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featureprop_pub_featureprop_id_trigger BEFORE INSERT OR UPDATE ON featureprop_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featureprop_pub_featureprop_id_trigger_func();

--
-- Name: featureprop_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featureprop_pub
    ADD CONSTRAINT featureprop_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featureprop_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON featureprop_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featureprop_pub_pub_id_trigger_func();

--
-- Name: featureprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featureprop
    ADD CONSTRAINT featureprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featureprop_type_id_trigger BEFORE INSERT OR UPDATE ON featureprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featureprop_type_id_trigger_func();

--
-- Name: featurerange_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featurerange
    ADD CONSTRAINT featurerange_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featurerange_feature_id_trigger BEFORE INSERT OR UPDATE ON featurerange
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featurerange_feature_id_trigger_func();

--
-- Name: featurerange_featuremap_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featurerange
    ADD CONSTRAINT featurerange_featuremap_id_fkey FOREIGN KEY (featuremap_id) REFERENCES featuremap(featuremap_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featurerange_featuremap_id_trigger BEFORE INSERT OR UPDATE ON featurerange
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featurerange_featuremap_id_trigger_func();

--
-- Name: featurerange_leftendf_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featurerange
    ADD CONSTRAINT featurerange_leftendf_id_fkey FOREIGN KEY (leftendf_id) REFERENCES feature(feature_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featurerange_leftendf_id_trigger BEFORE INSERT OR UPDATE ON featurerange
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featurerange_leftendf_id_trigger_func();

--
-- Name: featurerange_leftstartf_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featurerange
    ADD CONSTRAINT featurerange_leftstartf_id_fkey FOREIGN KEY (leftstartf_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featurerange_leftstartf_id_trigger BEFORE INSERT OR UPDATE ON featurerange
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featurerange_leftstartf_id_trigger_func();

--
-- Name: featurerange_rightendf_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featurerange
    ADD CONSTRAINT featurerange_rightendf_id_fkey FOREIGN KEY (rightendf_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featurerange_rightendf_id_trigger BEFORE INSERT OR UPDATE ON featurerange
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featurerange_rightendf_id_trigger_func();

--
-- Name: featurerange_rightstartf_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY featurerange
    ADD CONSTRAINT featurerange_rightstartf_id_fkey FOREIGN KEY (rightstartf_id) REFERENCES feature(feature_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER featurerange_rightstartf_id_trigger BEFORE INSERT OR UPDATE ON featurerange
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.featurerange_rightstartf_id_trigger_func();

--
-- Name: library_cvterm_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library_cvterm
    ADD CONSTRAINT library_cvterm_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id);

CREATE TRIGGER library_cvterm_cvterm_id_trigger BEFORE INSERT OR UPDATE ON library_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_cvterm_cvterm_id_trigger_func();

--
-- Name: library_cvterm_library_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library_cvterm
    ADD CONSTRAINT library_cvterm_library_id_fkey FOREIGN KEY (library_id) REFERENCES library(library_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER library_cvterm_library_id_trigger BEFORE INSERT OR UPDATE ON library_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_cvterm_library_id_trigger_func();

--
-- Name: library_cvterm_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library_cvterm
    ADD CONSTRAINT library_cvterm_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id);

CREATE TRIGGER library_cvterm_pub_id_trigger BEFORE INSERT OR UPDATE ON library_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_cvterm_pub_id_trigger_func();

--
-- Name: library_feature_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library_feature
    ADD CONSTRAINT library_feature_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER library_feature_feature_id_trigger BEFORE INSERT OR UPDATE ON library_feature
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_feature_feature_id_trigger_func();

--
-- Name: library_feature_library_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library_feature
    ADD CONSTRAINT library_feature_library_id_fkey FOREIGN KEY (library_id) REFERENCES library(library_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER library_feature_library_id_trigger BEFORE INSERT OR UPDATE ON library_feature
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_feature_library_id_trigger_func();

--
-- Name: library_organism_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library
    ADD CONSTRAINT library_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES organism(organism_id);

CREATE TRIGGER library_organism_id_trigger BEFORE INSERT OR UPDATE ON library
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_organism_id_trigger_func();

--
-- Name: library_pub_library_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library_pub
    ADD CONSTRAINT library_pub_library_id_fkey FOREIGN KEY (library_id) REFERENCES library(library_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER library_pub_library_id_trigger BEFORE INSERT OR UPDATE ON library_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_pub_library_id_trigger_func();

--
-- Name: library_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library_pub
    ADD CONSTRAINT library_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER library_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON library_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_pub_pub_id_trigger_func();

--
-- Name: library_synonym_library_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library_synonym
    ADD CONSTRAINT library_synonym_library_id_fkey FOREIGN KEY (library_id) REFERENCES library(library_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER library_synonym_library_id_trigger BEFORE INSERT OR UPDATE ON library_synonym
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_synonym_library_id_trigger_func();

--
-- Name: library_synonym_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library_synonym
    ADD CONSTRAINT library_synonym_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER library_synonym_pub_id_trigger BEFORE INSERT OR UPDATE ON library_synonym
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_synonym_pub_id_trigger_func();

--
-- Name: library_synonym_synonym_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library_synonym
    ADD CONSTRAINT library_synonym_synonym_id_fkey FOREIGN KEY (synonym_id) REFERENCES synonym(synonym_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER library_synonym_synonym_id_trigger BEFORE INSERT OR UPDATE ON library_synonym
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_synonym_synonym_id_trigger_func();

--
-- Name: library_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY library
    ADD CONSTRAINT library_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id);

CREATE TRIGGER library_type_id_trigger BEFORE INSERT OR UPDATE ON library
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.library_type_id_trigger_func();

--
-- Name: libraryprop_library_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY libraryprop
    ADD CONSTRAINT libraryprop_library_id_fkey FOREIGN KEY (library_id) REFERENCES library(library_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER libraryprop_library_id_trigger BEFORE INSERT OR UPDATE ON libraryprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.libraryprop_library_id_trigger_func();

--
-- Name: libraryprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY libraryprop
    ADD CONSTRAINT libraryprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id);

CREATE TRIGGER libraryprop_type_id_trigger BEFORE INSERT OR UPDATE ON libraryprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.libraryprop_type_id_trigger_func();

--
-- Name: magedocumentation_mageml_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY magedocumentation
    ADD CONSTRAINT magedocumentation_mageml_id_fkey FOREIGN KEY (mageml_id) REFERENCES mageml(mageml_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER magedocumentation_mageml_id_trigger BEFORE INSERT OR UPDATE ON magedocumentation
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.magedocumentation_mageml_id_trigger_func();

--
-- Name: magedocumentation_tableinfo_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY magedocumentation
    ADD CONSTRAINT magedocumentation_tableinfo_id_fkey FOREIGN KEY (tableinfo_id) REFERENCES tableinfo(tableinfo_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER magedocumentation_tableinfo_id_trigger BEFORE INSERT OR UPDATE ON magedocumentation
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.magedocumentation_tableinfo_id_trigger_func();

--
-- Name: organism_dbxref_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY organism_dbxref
    ADD CONSTRAINT organism_dbxref_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER organism_dbxref_dbxref_id_trigger BEFORE INSERT OR UPDATE ON organism_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.organism_dbxref_dbxref_id_trigger_func();

--
-- Name: organism_dbxref_organism_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY organism_dbxref
    ADD CONSTRAINT organism_dbxref_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES organism(organism_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER organism_dbxref_organism_id_trigger BEFORE INSERT OR UPDATE ON organism_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.organism_dbxref_organism_id_trigger_func();

--
-- Name: organismprop_organism_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY organismprop
    ADD CONSTRAINT organismprop_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES organism(organism_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER organismprop_organism_id_trigger BEFORE INSERT OR UPDATE ON organismprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.organismprop_organism_id_trigger_func();

--
-- Name: organismprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY organismprop
    ADD CONSTRAINT organismprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER organismprop_type_id_trigger BEFORE INSERT OR UPDATE ON organismprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.organismprop_type_id_trigger_func();

--
-- Name: phendesc_environment_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phendesc
    ADD CONSTRAINT phendesc_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES environment(environment_id) ON DELETE CASCADE;

CREATE TRIGGER phendesc_environment_id_trigger BEFORE INSERT OR UPDATE ON phendesc
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phendesc_environment_id_trigger_func();

--
-- Name: phendesc_genotype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phendesc
    ADD CONSTRAINT phendesc_genotype_id_fkey FOREIGN KEY (genotype_id) REFERENCES genotype(genotype_id) ON DELETE CASCADE;

CREATE TRIGGER phendesc_genotype_id_trigger BEFORE INSERT OR UPDATE ON phendesc
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phendesc_genotype_id_trigger_func();

--
-- Name: phendesc_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phendesc
    ADD CONSTRAINT phendesc_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE;

CREATE TRIGGER phendesc_pub_id_trigger BEFORE INSERT OR UPDATE ON phendesc
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phendesc_pub_id_trigger_func();

--
-- Name: phendesc_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phendesc
    ADD CONSTRAINT phendesc_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER phendesc_type_id_trigger BEFORE INSERT OR UPDATE ON phendesc
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phendesc_type_id_trigger_func();

--
-- Name: phenotype_assay_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype
    ADD CONSTRAINT phenotype_assay_id_fkey FOREIGN KEY (assay_id) REFERENCES cvterm(cvterm_id) ON DELETE SET NULL;

CREATE TRIGGER phenotype_assay_id_trigger BEFORE INSERT OR UPDATE ON phenotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_assay_id_trigger_func();

--
-- Name: phenotype_attr_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype
    ADD CONSTRAINT phenotype_attr_id_fkey FOREIGN KEY (attr_id) REFERENCES cvterm(cvterm_id) ON DELETE SET NULL;

CREATE TRIGGER phenotype_attr_id_trigger BEFORE INSERT OR UPDATE ON phenotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_attr_id_trigger_func();

--
-- Name: phenotype_comparison_environment1_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype_comparison
    ADD CONSTRAINT phenotype_comparison_environment1_id_fkey FOREIGN KEY (environment1_id) REFERENCES environment(environment_id) ON DELETE CASCADE;

CREATE TRIGGER phenotype_comparison_environment1_id_trigger BEFORE INSERT OR UPDATE ON phenotype_comparison
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_comparison_environment1_id_trigger_func();

--
-- Name: phenotype_comparison_environment2_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype_comparison
    ADD CONSTRAINT phenotype_comparison_environment2_id_fkey FOREIGN KEY (environment2_id) REFERENCES environment(environment_id) ON DELETE CASCADE;

CREATE TRIGGER phenotype_comparison_environment2_id_trigger BEFORE INSERT OR UPDATE ON phenotype_comparison
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_comparison_environment2_id_trigger_func();

--
-- Name: phenotype_comparison_genotype1_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype_comparison
    ADD CONSTRAINT phenotype_comparison_genotype1_id_fkey FOREIGN KEY (genotype1_id) REFERENCES genotype(genotype_id) ON DELETE CASCADE;

CREATE TRIGGER phenotype_comparison_genotype1_id_trigger BEFORE INSERT OR UPDATE ON phenotype_comparison
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_comparison_genotype1_id_trigger_func();

--
-- Name: phenotype_comparison_genotype2_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype_comparison
    ADD CONSTRAINT phenotype_comparison_genotype2_id_fkey FOREIGN KEY (genotype2_id) REFERENCES genotype(genotype_id) ON DELETE CASCADE;

CREATE TRIGGER phenotype_comparison_genotype2_id_trigger BEFORE INSERT OR UPDATE ON phenotype_comparison
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_comparison_genotype2_id_trigger_func();

--
-- Name: phenotype_comparison_phenotype1_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype_comparison
    ADD CONSTRAINT phenotype_comparison_phenotype1_id_fkey FOREIGN KEY (phenotype1_id) REFERENCES phenotype(phenotype_id) ON DELETE CASCADE;

CREATE TRIGGER phenotype_comparison_phenotype1_id_trigger BEFORE INSERT OR UPDATE ON phenotype_comparison
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_comparison_phenotype1_id_trigger_func();

--
-- Name: phenotype_comparison_phenotype2_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype_comparison
    ADD CONSTRAINT phenotype_comparison_phenotype2_id_fkey FOREIGN KEY (phenotype2_id) REFERENCES phenotype(phenotype_id) ON DELETE CASCADE;

CREATE TRIGGER phenotype_comparison_phenotype2_id_trigger BEFORE INSERT OR UPDATE ON phenotype_comparison
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_comparison_phenotype2_id_trigger_func();

--
-- Name: phenotype_comparison_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype_comparison
    ADD CONSTRAINT phenotype_comparison_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE;

CREATE TRIGGER phenotype_comparison_pub_id_trigger BEFORE INSERT OR UPDATE ON phenotype_comparison
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_comparison_pub_id_trigger_func();

--
-- Name: phenotype_comparison_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype_comparison
    ADD CONSTRAINT phenotype_comparison_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER phenotype_comparison_type_id_trigger BEFORE INSERT OR UPDATE ON phenotype_comparison
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_comparison_type_id_trigger_func();

--
-- Name: phenotype_cvalue_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype
    ADD CONSTRAINT phenotype_cvalue_id_fkey FOREIGN KEY (cvalue_id) REFERENCES cvterm(cvterm_id) ON DELETE SET NULL;

CREATE TRIGGER phenotype_cvalue_id_trigger BEFORE INSERT OR UPDATE ON phenotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_cvalue_id_trigger_func();

--
-- Name: phenotype_cvterm_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype_cvterm
    ADD CONSTRAINT phenotype_cvterm_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER phenotype_cvterm_cvterm_id_trigger BEFORE INSERT OR UPDATE ON phenotype_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_cvterm_cvterm_id_trigger_func();

--
-- Name: phenotype_cvterm_phenotype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype_cvterm
    ADD CONSTRAINT phenotype_cvterm_phenotype_id_fkey FOREIGN KEY (phenotype_id) REFERENCES phenotype(phenotype_id) ON DELETE CASCADE;

CREATE TRIGGER phenotype_cvterm_phenotype_id_trigger BEFORE INSERT OR UPDATE ON phenotype_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_cvterm_phenotype_id_trigger_func();

--
-- Name: phenotype_observable_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenotype
    ADD CONSTRAINT phenotype_observable_id_fkey FOREIGN KEY (observable_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER phenotype_observable_id_trigger BEFORE INSERT OR UPDATE ON phenotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenotype_observable_id_trigger_func();

--
-- Name: phenstatement_environment_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenstatement
    ADD CONSTRAINT phenstatement_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES environment(environment_id) ON DELETE CASCADE;

CREATE TRIGGER phenstatement_environment_id_trigger BEFORE INSERT OR UPDATE ON phenstatement
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenstatement_environment_id_trigger_func();

--
-- Name: phenstatement_genotype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenstatement
    ADD CONSTRAINT phenstatement_genotype_id_fkey FOREIGN KEY (genotype_id) REFERENCES genotype(genotype_id) ON DELETE CASCADE;

CREATE TRIGGER phenstatement_genotype_id_trigger BEFORE INSERT OR UPDATE ON phenstatement
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenstatement_genotype_id_trigger_func();

--
-- Name: phenstatement_phenotype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenstatement
    ADD CONSTRAINT phenstatement_phenotype_id_fkey FOREIGN KEY (phenotype_id) REFERENCES phenotype(phenotype_id) ON DELETE CASCADE;

CREATE TRIGGER phenstatement_phenotype_id_trigger BEFORE INSERT OR UPDATE ON phenstatement
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenstatement_phenotype_id_trigger_func();

--
-- Name: phenstatement_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenstatement
    ADD CONSTRAINT phenstatement_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE;

CREATE TRIGGER phenstatement_pub_id_trigger BEFORE INSERT OR UPDATE ON phenstatement
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenstatement_pub_id_trigger_func();

--
-- Name: phenstatement_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phenstatement
    ADD CONSTRAINT phenstatement_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER phenstatement_type_id_trigger BEFORE INSERT OR UPDATE ON phenstatement
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phenstatement_type_id_trigger_func();

--
-- Name: phylonode_dbxref_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode_dbxref
    ADD CONSTRAINT phylonode_dbxref_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_dbxref_dbxref_id_trigger BEFORE INSERT OR UPDATE ON phylonode_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_dbxref_dbxref_id_trigger_func();

--
-- Name: phylonode_dbxref_phylonode_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode_dbxref
    ADD CONSTRAINT phylonode_dbxref_phylonode_id_fkey FOREIGN KEY (phylonode_id) REFERENCES phylonode(phylonode_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_dbxref_phylonode_id_trigger BEFORE INSERT OR UPDATE ON phylonode_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_dbxref_phylonode_id_trigger_func();

--
-- Name: phylonode_feature_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode
    ADD CONSTRAINT phylonode_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES feature(feature_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_feature_id_trigger BEFORE INSERT OR UPDATE ON phylonode
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_feature_id_trigger_func();

--
-- Name: phylonode_organism_organism_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode_organism
    ADD CONSTRAINT phylonode_organism_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES organism(organism_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_organism_organism_id_trigger BEFORE INSERT OR UPDATE ON phylonode_organism
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_organism_organism_id_trigger_func();

--
-- Name: phylonode_organism_phylonode_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode_organism
    ADD CONSTRAINT phylonode_organism_phylonode_id_fkey FOREIGN KEY (phylonode_id) REFERENCES phylonode(phylonode_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_organism_phylonode_id_trigger BEFORE INSERT OR UPDATE ON phylonode_organism
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_organism_phylonode_id_trigger_func();

--
-- Name: phylonode_parent_phylonode_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode
    ADD CONSTRAINT phylonode_parent_phylonode_id_fkey FOREIGN KEY (parent_phylonode_id) REFERENCES phylonode(phylonode_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_parent_phylonode_id_trigger BEFORE INSERT OR UPDATE ON phylonode
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_parent_phylonode_id_trigger_func();

--
-- Name: phylonode_phylotree_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode
    ADD CONSTRAINT phylonode_phylotree_id_fkey FOREIGN KEY (phylotree_id) REFERENCES phylotree(phylotree_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_phylotree_id_trigger BEFORE INSERT OR UPDATE ON phylonode
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_phylotree_id_trigger_func();

--
-- Name: phylonode_pub_phylonode_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode_pub
    ADD CONSTRAINT phylonode_pub_phylonode_id_fkey FOREIGN KEY (phylonode_id) REFERENCES phylonode(phylonode_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_pub_phylonode_id_trigger BEFORE INSERT OR UPDATE ON phylonode_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_pub_phylonode_id_trigger_func();

--
-- Name: phylonode_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode_pub
    ADD CONSTRAINT phylonode_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON phylonode_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_pub_pub_id_trigger_func();

--
-- Name: phylonode_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode_relationship
    ADD CONSTRAINT phylonode_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES phylonode(phylonode_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_relationship_object_id_trigger BEFORE INSERT OR UPDATE ON phylonode_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_relationship_object_id_trigger_func();

--
-- Name: phylonode_relationship_phylotree_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode_relationship
    ADD CONSTRAINT phylonode_relationship_phylotree_id_fkey FOREIGN KEY (phylotree_id) REFERENCES phylotree(phylotree_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_relationship_phylotree_id_trigger BEFORE INSERT OR UPDATE ON phylonode_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_relationship_phylotree_id_trigger_func();

--
-- Name: phylonode_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode_relationship
    ADD CONSTRAINT phylonode_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES phylonode(phylonode_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_relationship_subject_id_trigger BEFORE INSERT OR UPDATE ON phylonode_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_relationship_subject_id_trigger_func();

--
-- Name: phylonode_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode_relationship
    ADD CONSTRAINT phylonode_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_relationship_type_id_trigger BEFORE INSERT OR UPDATE ON phylonode_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_relationship_type_id_trigger_func();

--
-- Name: phylonode_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonode
    ADD CONSTRAINT phylonode_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER phylonode_type_id_trigger BEFORE INSERT OR UPDATE ON phylonode
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonode_type_id_trigger_func();

--
-- Name: phylonodeprop_phylonode_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonodeprop
    ADD CONSTRAINT phylonodeprop_phylonode_id_fkey FOREIGN KEY (phylonode_id) REFERENCES phylonode(phylonode_id) ON DELETE CASCADE;

CREATE TRIGGER phylonodeprop_phylonode_id_trigger BEFORE INSERT OR UPDATE ON phylonodeprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonodeprop_phylonode_id_trigger_func();

--
-- Name: phylonodeprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylonodeprop
    ADD CONSTRAINT phylonodeprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER phylonodeprop_type_id_trigger BEFORE INSERT OR UPDATE ON phylonodeprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylonodeprop_type_id_trigger_func();

--
-- Name: phylotree_analysis_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylotree
    ADD CONSTRAINT phylotree_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES analysis(analysis_id) ON DELETE CASCADE;

CREATE TRIGGER phylotree_analysis_id_trigger BEFORE INSERT OR UPDATE ON phylotree
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylotree_analysis_id_trigger_func();

--
-- Name: phylotree_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylotree
    ADD CONSTRAINT phylotree_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE;

CREATE TRIGGER phylotree_dbxref_id_trigger BEFORE INSERT OR UPDATE ON phylotree
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylotree_dbxref_id_trigger_func();

--
-- Name: phylotree_pub_phylotree_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylotree_pub
    ADD CONSTRAINT phylotree_pub_phylotree_id_fkey FOREIGN KEY (phylotree_id) REFERENCES phylotree(phylotree_id) ON DELETE CASCADE;

CREATE TRIGGER phylotree_pub_phylotree_id_trigger BEFORE INSERT OR UPDATE ON phylotree_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylotree_pub_phylotree_id_trigger_func();

--
-- Name: phylotree_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylotree_pub
    ADD CONSTRAINT phylotree_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE;

CREATE TRIGGER phylotree_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON phylotree_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylotree_pub_pub_id_trigger_func();

--
-- Name: phylotree_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY phylotree
    ADD CONSTRAINT phylotree_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER phylotree_type_id_trigger BEFORE INSERT OR UPDATE ON phylotree
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.phylotree_type_id_trigger_func();

--
-- Name: protocol_attribute_attribute_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY protocol_attribute
    ADD CONSTRAINT protocol_attribute_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES attribute(attribute_id) ON DELETE CASCADE;

CREATE TRIGGER protocol_attribute_attribute_id_trigger BEFORE INSERT OR UPDATE ON protocol_attribute
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.protocol_attribute_attribute_id_trigger_func();

--
-- Name: protocol_attribute_protocol_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY protocol_attribute
    ADD CONSTRAINT protocol_attribute_protocol_id_fkey FOREIGN KEY (protocol_id) REFERENCES protocol(protocol_id) ON DELETE CASCADE;

CREATE TRIGGER protocol_attribute_protocol_id_trigger BEFORE INSERT OR UPDATE ON protocol_attribute
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.protocol_attribute_protocol_id_trigger_func();

--
-- Name: protocol_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY protocol
    ADD CONSTRAINT protocol_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE RESTRICT;

CREATE TRIGGER protocol_dbxref_id_trigger BEFORE INSERT OR UPDATE ON protocol
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.protocol_dbxref_id_trigger_func();

--
-- Name: protocolparam_datatype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY protocolparam
    ADD CONSTRAINT protocolparam_datatype_id_fkey FOREIGN KEY (datatype_id) REFERENCES cvterm(cvterm_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER protocolparam_datatype_id_trigger BEFORE INSERT OR UPDATE ON protocolparam
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.protocolparam_datatype_id_trigger_func();

--
-- Name: protocolparam_unittype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY protocolparam
    ADD CONSTRAINT protocolparam_unittype_id_fkey FOREIGN KEY (unittype_id) REFERENCES cvterm(cvterm_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER protocolparam_unittype_id_trigger BEFORE INSERT OR UPDATE ON protocolparam
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.protocolparam_unittype_id_trigger_func();

--
-- Name: pub_dbxref_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY pub_dbxref
    ADD CONSTRAINT pub_dbxref_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER pub_dbxref_dbxref_id_trigger BEFORE INSERT OR UPDATE ON pub_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.pub_dbxref_dbxref_id_trigger_func();

--
-- Name: pub_dbxref_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY pub_dbxref
    ADD CONSTRAINT pub_dbxref_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER pub_dbxref_pub_id_trigger BEFORE INSERT OR UPDATE ON pub_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.pub_dbxref_pub_id_trigger_func();

--
-- Name: pub_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY pub_relationship
    ADD CONSTRAINT pub_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER pub_relationship_object_id_trigger BEFORE INSERT OR UPDATE ON pub_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.pub_relationship_object_id_trigger_func();

--
-- Name: pub_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY pub_relationship
    ADD CONSTRAINT pub_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER pub_relationship_subject_id_trigger BEFORE INSERT OR UPDATE ON pub_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.pub_relationship_subject_id_trigger_func();

--
-- Name: pub_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY pub_relationship
    ADD CONSTRAINT pub_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER pub_relationship_type_id_trigger BEFORE INSERT OR UPDATE ON pub_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.pub_relationship_type_id_trigger_func();

--
-- Name: pub_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY pub
    ADD CONSTRAINT pub_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER pub_type_id_trigger BEFORE INSERT OR UPDATE ON pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.pub_type_id_trigger_func();

--
-- Name: pubauthor_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY pubauthor
    ADD CONSTRAINT pubauthor_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER pubauthor_pub_id_trigger BEFORE INSERT OR UPDATE ON pubauthor
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.pubauthor_pub_id_trigger_func();

--
-- Name: pubprop_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY pubprop
    ADD CONSTRAINT pubprop_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER pubprop_pub_id_trigger BEFORE INSERT OR UPDATE ON pubprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.pubprop_pub_id_trigger_func();

--
-- Name: pubprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY pubprop
    ADD CONSTRAINT pubprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER pubprop_type_id_trigger BEFORE INSERT OR UPDATE ON pubprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.pubprop_type_id_trigger_func();

--
-- Name: quantification_acquisition_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY quantification
    ADD CONSTRAINT quantification_acquisition_id_fkey FOREIGN KEY (acquisition_id) REFERENCES acquisition(acquisition_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER quantification_acquisition_id_trigger BEFORE INSERT OR UPDATE ON quantification
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.quantification_acquisition_id_trigger_func();

--
-- Name: quantification_analysis_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY quantification
    ADD CONSTRAINT quantification_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES analysis(analysis_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER quantification_analysis_id_trigger BEFORE INSERT OR UPDATE ON quantification
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.quantification_analysis_id_trigger_func();

--
-- Name: quantification_operator_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY quantification
    ADD CONSTRAINT quantification_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES contact(contact_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER quantification_operator_id_trigger BEFORE INSERT OR UPDATE ON quantification
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.quantification_operator_id_trigger_func();

--
-- Name: quantification_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY quantification_relationship
    ADD CONSTRAINT quantification_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES quantification(quantification_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER quantification_relationship_object_id_trigger BEFORE INSERT OR UPDATE ON quantification_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.quantification_relationship_object_id_trigger_func();

--
-- Name: quantification_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY quantification_relationship
    ADD CONSTRAINT quantification_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES quantification(quantification_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER quantification_relationship_subject_id_trigger BEFORE INSERT OR UPDATE ON quantification_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.quantification_relationship_subject_id_trigger_func();

--
-- Name: quantification_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY quantification_relationship
    ADD CONSTRAINT quantification_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER quantification_relationship_type_id_trigger BEFORE INSERT OR UPDATE ON quantification_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.quantification_relationship_type_id_trigger_func();

--
-- Name: quantificationprop_quantification_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY quantificationprop
    ADD CONSTRAINT quantificationprop_quantification_id_fkey FOREIGN KEY (quantification_id) REFERENCES quantification(quantification_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER quantificationprop_quantification_id_trigger BEFORE INSERT OR UPDATE ON quantificationprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.quantificationprop_quantification_id_trigger_func();

--
-- Name: quantificationprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY quantificationprop
    ADD CONSTRAINT quantificationprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER quantificationprop_type_id_trigger BEFORE INSERT OR UPDATE ON quantificationprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.quantificationprop_type_id_trigger_func();

--
-- Name: stock_cvterm_cvterm_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_cvterm
    ADD CONSTRAINT stock_cvterm_cvterm_id_fkey FOREIGN KEY (cvterm_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_cvterm_cvterm_id_trigger BEFORE INSERT OR UPDATE ON stock_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_cvterm_cvterm_id_trigger_func();

--
-- Name: stock_cvterm_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_cvterm
    ADD CONSTRAINT stock_cvterm_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_cvterm_pub_id_trigger BEFORE INSERT OR UPDATE ON stock_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_cvterm_pub_id_trigger_func();

--
-- Name: stock_cvterm_stock_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_cvterm
    ADD CONSTRAINT stock_cvterm_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_cvterm_stock_id_trigger BEFORE INSERT OR UPDATE ON stock_cvterm
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_cvterm_stock_id_trigger_func();

--
-- Name: stock_dbxref_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_dbxref
    ADD CONSTRAINT stock_dbxref_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_dbxref_dbxref_id_trigger BEFORE INSERT OR UPDATE ON stock_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_dbxref_dbxref_id_trigger_func();

--
-- Name: stock_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock
    ADD CONSTRAINT stock_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_dbxref_id_trigger BEFORE INSERT OR UPDATE ON stock
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_dbxref_id_trigger_func();

--
-- Name: stock_dbxref_stock_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_dbxref
    ADD CONSTRAINT stock_dbxref_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_dbxref_stock_id_trigger BEFORE INSERT OR UPDATE ON stock_dbxref
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_dbxref_stock_id_trigger_func();

--
-- Name: stock_genotype_genotype_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_genotype
    ADD CONSTRAINT stock_genotype_genotype_id_fkey FOREIGN KEY (genotype_id) REFERENCES genotype(genotype_id) ON DELETE CASCADE;

CREATE TRIGGER stock_genotype_genotype_id_trigger BEFORE INSERT OR UPDATE ON stock_genotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_genotype_genotype_id_trigger_func();

--
-- Name: stock_genotype_stock_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_genotype
    ADD CONSTRAINT stock_genotype_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE;

CREATE TRIGGER stock_genotype_stock_id_trigger BEFORE INSERT OR UPDATE ON stock_genotype
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_genotype_stock_id_trigger_func();

--
-- Name: stock_organism_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock
    ADD CONSTRAINT stock_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES organism(organism_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_organism_id_trigger BEFORE INSERT OR UPDATE ON stock
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_organism_id_trigger_func();

--
-- Name: stock_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_pub
    ADD CONSTRAINT stock_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON stock_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_pub_pub_id_trigger_func();

--
-- Name: stock_pub_stock_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_pub
    ADD CONSTRAINT stock_pub_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_pub_stock_id_trigger BEFORE INSERT OR UPDATE ON stock_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_pub_stock_id_trigger_func();

--
-- Name: stock_relationship_object_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_relationship
    ADD CONSTRAINT stock_relationship_object_id_fkey FOREIGN KEY (object_id) REFERENCES stock(stock_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_relationship_object_id_trigger BEFORE INSERT OR UPDATE ON stock_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_relationship_object_id_trigger_func();

--
-- Name: stock_relationship_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_relationship_pub
    ADD CONSTRAINT stock_relationship_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_relationship_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON stock_relationship_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_relationship_pub_pub_id_trigger_func();

--
-- Name: stock_relationship_pub_stock_relationship_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_relationship_pub
    ADD CONSTRAINT stock_relationship_pub_stock_relationship_id_fkey FOREIGN KEY (stock_relationship_id) REFERENCES stock_relationship(stock_relationship_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_relationship_pub_stock_relationship_id_trigger BEFORE INSERT OR UPDATE ON stock_relationship_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_relationship_pub_stock_relationship_id_trigger_func();

--
-- Name: stock_relationship_subject_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_relationship
    ADD CONSTRAINT stock_relationship_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES stock(stock_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_relationship_subject_id_trigger BEFORE INSERT OR UPDATE ON stock_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_relationship_subject_id_trigger_func();

--
-- Name: stock_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock_relationship
    ADD CONSTRAINT stock_relationship_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_relationship_type_id_trigger BEFORE INSERT OR UPDATE ON stock_relationship
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_relationship_type_id_trigger_func();

--
-- Name: stock_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stock
    ADD CONSTRAINT stock_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stock_type_id_trigger BEFORE INSERT OR UPDATE ON stock
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stock_type_id_trigger_func();

--
-- Name: stockcollection_contact_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stockcollection
    ADD CONSTRAINT stockcollection_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES contact(contact_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stockcollection_contact_id_trigger BEFORE INSERT OR UPDATE ON stockcollection
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stockcollection_contact_id_trigger_func();

--
-- Name: stockcollection_stock_stock_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stockcollection_stock
    ADD CONSTRAINT stockcollection_stock_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stockcollection_stock_stock_id_trigger BEFORE INSERT OR UPDATE ON stockcollection_stock
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stockcollection_stock_stock_id_trigger_func();

--
-- Name: stockcollection_stock_stockcollection_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stockcollection_stock
    ADD CONSTRAINT stockcollection_stock_stockcollection_id_fkey FOREIGN KEY (stockcollection_id) REFERENCES stockcollection(stockcollection_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stockcollection_stock_stockcollection_id_trigger BEFORE INSERT OR UPDATE ON stockcollection_stock
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stockcollection_stock_stockcollection_id_trigger_func();

--
-- Name: stockcollection_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stockcollection
    ADD CONSTRAINT stockcollection_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE;

CREATE TRIGGER stockcollection_type_id_trigger BEFORE INSERT OR UPDATE ON stockcollection
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stockcollection_type_id_trigger_func();

--
-- Name: stockcollectionprop_stockcollection_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stockcollectionprop
    ADD CONSTRAINT stockcollectionprop_stockcollection_id_fkey FOREIGN KEY (stockcollection_id) REFERENCES stockcollection(stockcollection_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stockcollectionprop_stockcollection_id_trigger BEFORE INSERT OR UPDATE ON stockcollectionprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stockcollectionprop_stockcollection_id_trigger_func();

--
-- Name: stockcollectionprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stockcollectionprop
    ADD CONSTRAINT stockcollectionprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id);

CREATE TRIGGER stockcollectionprop_type_id_trigger BEFORE INSERT OR UPDATE ON stockcollectionprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stockcollectionprop_type_id_trigger_func();

--
-- Name: stockprop_pub_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stockprop_pub
    ADD CONSTRAINT stockprop_pub_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stockprop_pub_pub_id_trigger BEFORE INSERT OR UPDATE ON stockprop_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stockprop_pub_pub_id_trigger_func();

--
-- Name: stockprop_pub_stockprop_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stockprop_pub
    ADD CONSTRAINT stockprop_pub_stockprop_id_fkey FOREIGN KEY (stockprop_id) REFERENCES stockprop(stockprop_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stockprop_pub_stockprop_id_trigger BEFORE INSERT OR UPDATE ON stockprop_pub
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stockprop_pub_stockprop_id_trigger_func();

--
-- Name: stockprop_stock_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stockprop
    ADD CONSTRAINT stockprop_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stockprop_stock_id_trigger BEFORE INSERT OR UPDATE ON stockprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stockprop_stock_id_trigger_func();

--
-- Name: stockprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY stockprop
    ADD CONSTRAINT stockprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER stockprop_type_id_trigger BEFORE INSERT OR UPDATE ON stockprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.stockprop_type_id_trigger_func();

--
-- Name: study_assay_assay_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY study_assay
    ADD CONSTRAINT study_assay_assay_id_fkey FOREIGN KEY (assay_id) REFERENCES assay(assay_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER study_assay_assay_id_trigger BEFORE INSERT OR UPDATE ON study_assay
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.study_assay_assay_id_trigger_func();

--
-- Name: study_assay_study_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY study_assay
    ADD CONSTRAINT study_assay_study_id_fkey FOREIGN KEY (study_id) REFERENCES study(study_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER study_assay_study_id_trigger BEFORE INSERT OR UPDATE ON study_assay
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.study_assay_study_id_trigger_func();

--
-- Name: study_contact_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY study
    ADD CONSTRAINT study_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES contact(contact_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER study_contact_id_trigger BEFORE INSERT OR UPDATE ON study
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.study_contact_id_trigger_func();

--
-- Name: study_dbxref_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY study
    ADD CONSTRAINT study_dbxref_id_fkey FOREIGN KEY (dbxref_id) REFERENCES dbxref(dbxref_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER study_dbxref_id_trigger BEFORE INSERT OR UPDATE ON study
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.study_dbxref_id_trigger_func();

--
-- Name: study_pub_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY study
    ADD CONSTRAINT study_pub_id_fkey FOREIGN KEY (pub_id) REFERENCES pub(pub_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER study_pub_id_trigger BEFORE INSERT OR UPDATE ON study
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.study_pub_id_trigger_func();

--
-- Name: studydesign_study_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY studydesign
    ADD CONSTRAINT studydesign_study_id_fkey FOREIGN KEY (study_id) REFERENCES study(study_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER studydesign_study_id_trigger BEFORE INSERT OR UPDATE ON studydesign
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.studydesign_study_id_trigger_func();

--
-- Name: studydesignprop_studydesign_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY studydesignprop
    ADD CONSTRAINT studydesignprop_studydesign_id_fkey FOREIGN KEY (studydesign_id) REFERENCES studydesign(studydesign_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER studydesignprop_studydesign_id_trigger BEFORE INSERT OR UPDATE ON studydesignprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.studydesignprop_studydesign_id_trigger_func();

--
-- Name: studydesignprop_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY studydesignprop
    ADD CONSTRAINT studydesignprop_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER studydesignprop_type_id_trigger BEFORE INSERT OR UPDATE ON studydesignprop
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.studydesignprop_type_id_trigger_func();

--
-- Name: studyfactor_studydesign_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY studyfactor
    ADD CONSTRAINT studyfactor_studydesign_id_fkey FOREIGN KEY (studydesign_id) REFERENCES studydesign(studydesign_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER studyfactor_studydesign_id_trigger BEFORE INSERT OR UPDATE ON studyfactor
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.studyfactor_studydesign_id_trigger_func();

--
-- Name: studyfactor_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY studyfactor
    ADD CONSTRAINT studyfactor_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER studyfactor_type_id_trigger BEFORE INSERT OR UPDATE ON studyfactor
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.studyfactor_type_id_trigger_func();

--
-- Name: studyfactorvalue_assay_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY studyfactorvalue
    ADD CONSTRAINT studyfactorvalue_assay_id_fkey FOREIGN KEY (assay_id) REFERENCES assay(assay_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER studyfactorvalue_assay_id_trigger BEFORE INSERT OR UPDATE ON studyfactorvalue
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.studyfactorvalue_assay_id_trigger_func();

--
-- Name: studyfactorvalue_studyfactor_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY studyfactorvalue
    ADD CONSTRAINT studyfactorvalue_studyfactor_id_fkey FOREIGN KEY (studyfactor_id) REFERENCES studyfactor(studyfactor_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER studyfactorvalue_studyfactor_id_trigger BEFORE INSERT OR UPDATE ON studyfactorvalue
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.studyfactorvalue_studyfactor_id_trigger_func();

--
-- Name: synonym_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY synonym
    ADD CONSTRAINT synonym_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER synonym_type_id_trigger BEFORE INSERT OR UPDATE ON synonym
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.synonym_type_id_trigger_func();

--
-- Name: treatment_biomaterial_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY treatment
    ADD CONSTRAINT treatment_biomaterial_id_fkey FOREIGN KEY (biomaterial_id) REFERENCES biomaterial(biomaterial_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER treatment_biomaterial_id_trigger BEFORE INSERT OR UPDATE ON treatment
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.treatment_biomaterial_id_trigger_func();

--
-- Name: treatment_type_id_fkey; Type: FK CONSTRAINT; Schema: $temporary_chado_schema_name$; Owner: -
--

ALTER TABLE ONLY treatment
    ADD CONSTRAINT treatment_type_id_fkey FOREIGN KEY (type_id) REFERENCES cvterm(cvterm_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER treatment_type_id_trigger BEFORE INSERT OR UPDATE ON treatment
  FOR EACH ROW EXECUTE PROCEDURE $temporary_chado_schema_name$_data.treatment_type_id_trigger_func();

--
-- PostgreSQL database dump complete
--

SET search_path = public, pg_catalog;
