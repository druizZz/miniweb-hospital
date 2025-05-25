--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Ubuntu 16.9-0ubuntu0.24.10.1)
-- Dumped by pg_dump version 16.9 (Ubuntu 16.9-0ubuntu0.24.10.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: administradosi(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.administradosi(p_idpersona text, p_idvacuna text, p_idtreballador text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_idhospital TEXT;
    v_nomvacuna TEXT;
BEGIN
   SELECT idhospital INTO v_idhospital
    FROM pacient
    WHERE idpersona = p_idpersona;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La persona % no està ingressada.', p_idpersona;
    END IF;
  IF EXISTS (
        SELECT 1 FROM stockvacuna
        WHERE idvacuna = p_idvacuna
        AND idhospital = v_idhospital
        AND stock > 0
    ) THEN
UPDATE stockvacuna
        SET stock = stock - 1
        WHERE idvacuna = p_idvacuna
        AND idhospital = v_idhospital;
SELECT nomvacuna INTO v_nomvacuna
        FROM vacuna
        WHERE idvacuna = p_idvacuna;
 IF EXISTS (SELECT 1 FROM cartillavacuna WHERE idpersona = p_idpersona) THEN
 UPDATE cartillavacuna
            SET
              quandosi2 = CASE WHEN quandosi2 IS NULL THEN CURRENT_DATE ELSE quandosi2 END,
              quandosi3 = CASE WHEN quandosi2 IS NOT NULL AND quandosi3 IS NULL THEN CURRENT_DATE ELSE quandosi3 END
            WHERE idpersona = p_idpersona;
ELSE

INSERT INTO cartillavacuna (idpersona, datadosi1, id_treballador, idvacuna, nom_vacuna)
VALUES (p_idpersona, CURRENT_DATE, p_idtreballador, p_idvacuna, v_nomvacuna);
END IF;
ELSE

    RAISE EXCEPTION 'No hi ha stock suficient de la vacuna % al hospital %.', p_idvacuna, v_idhosppital;
END IF;

END;
$$;


ALTER FUNCTION public.administradosi(p_idpersona text, p_idvacuna text, p_idtreballador text) OWNER TO postgres;

--
-- Name: avisapocstock(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.avisapocstock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.stock < 5 THEN
        RAISE NOTICE 'Poc stock! La vacuna % al hospital % té només % unitats disponibles.',
            NEW.idvacuna, NEW.idhospital, NEW.stock;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.avisapocstock() OWNER TO postgres;

--
-- Name: ficastock(text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ficastock(p_idvacuna text, p_idhospital text, p_quantitat integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_idvirus TEXT;
BEGIN
    SELECT idvirus INTO v_idvirus
    FROM vacuna
    WHERE idvacuna = p_idvacuna;

    IF v_idvirus IS NULL THEN
        RAISE EXCEPTION 'No s''ha trobat cap virus associat a la vacuna %', p_idvacuna;
    END IF;

    IF EXISTS (
        SELECT 1 FROM stockvacuna
        WHERE idvacuna = p_idvacuna AND idhospital = p_idhospital
    ) THEN
        UPDATE stockvacuna
        SET stock = stock + p_quantitat
        WHERE idvacuna = p_idvacuna AND idhospital = p_idhospital;

        RAISE NOTICE 'Afegides % unitats de % al hospital %',
            p_quantitat, p_idvacuna, p_idhospital;
    ELSE
        INSERT INTO stockvacuna(idvacuna, idhospital, stock, idvirus)
        VALUES (p_idvacuna, p_idhospital, p_quantitat, v_idvirus);

        RAISE NOTICE 'Inserides % unitats de % al hospital %',
            p_quantitat, p_idvacuna, p_idhospital;
    END IF;
END;
$$;


ALTER FUNCTION public.ficastock(p_idvacuna text, p_idhospital text, p_quantitat integer) OWNER TO postgres;

--
-- Name: hospitalproper(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hospitalproper(p_idpersona text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_idciutat TEXT;
    v_nom_ciutat TEXT;
    v_idhospital TEXT;
    v_nom_hospital TEXT;
    v_ciutat_destinacio TEXT;
    v_nom_ciutat_destinacio TEXT;
BEGIN
    
    SELECT c.idciutat, c.nomciutat
    INTO v_idciutat, v_nom_ciutat
    FROM persona p
    JOIN ciutat c ON p.idciutat = c.idciutat
    WHERE p.idpersona = p_idpersona;

    
    SELECT h.idhospital, h.nomhospital
    INTO v_idhospital, v_nom_hospital
    FROM hospital h
    WHERE h.idciutat = v_idciutat
      AND h.numllitsucilliures > 0
    ORDER BY h.numllitsucilliures DESC
    LIMIT 1;

    IF FOUND THEN
        RETURN format('Proposta: %s té llits UCI lliures a la ciutat de %s.', v_nom_hospital, v_nom_ciutat);
    END IF;

    
    SELECT h.idhospital, h.nomhospital, c.idciutat, c.nomciutat
    INTO v_idhospital, v_nom_hospital, v_ciutat_destinacio, v_nom_ciutat_destinacio
    FROM distancia d
    JOIN hospital h ON h.idciutat = d.iddesti
    JOIN ciutat c ON c.idciutat = h.idciutat
    WHERE d.idorigen = v_idciutat
      AND h.numllitsucilliures > 0
    ORDER BY d.km ASC
    LIMIT 1;

    IF FOUND THEN
        RETURN format('No hi ha llits a %s. Proposta: %s a la ciutat de %s (a %s km).',
                      v_nom_ciutat, v_nom_hospital, v_nom_ciutat_destinacio,
                      (SELECT km FROM distancia WHERE idorigen = v_idciutat AND iddesti = v_ciutat_destinacio));
    END IF;

    
    RETURN 'Cap hospital té llits UCI disponibles en cap ciutat propera.';
END;
$$;


ALTER FUNCTION public.hospitalproper(p_idpersona text) OWNER TO postgres;

--
-- Name: ingresapacient(text, text, integer, integer, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ingresapacient(p_idpersona text, p_idhospital text, p_planta integer, p_habitacio integer, p_estat text, p_idvirus text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estat_lower TEXT;
    v_ocupauci BOOLEAN := FALSE;
    v_llits_uci INTEGER;
    v_idciutat TEXT;
    v_idhospital_final TEXT;
BEGIN
    v_estat_lower := LOWER(p_estat);

    
    IF EXISTS (SELECT 1 FROM pacient WHERE idpersona = p_idpersona) THEN
        RAISE NOTICE 'El pacient % ja està ingressat.', p_idpersona;
        RETURN;
    END IF;

    IF v_estat_lower = 'molt greu' THEN
        v_ocupauci := TRUE;

        SELECT numllitsucilliures INTO v_llits_uci
        FROM hospital
        WHERE idhospital = p_idhospital;

        IF v_llits_uci <= 0 THEN
            RAISE NOTICE 'No hi ha llits UCI disponibles a l''hospital indicat (%).', p_idhospital;

            SELECT idciutat INTO v_idciutat
            FROM persona
            WHERE idpersona = p_idpersona;

            SELECT h.idhospital
            INTO v_idhospital_final
            FROM distancia d
            JOIN hospital h ON h.idciutat = d.iddesti
            WHERE d.idorigen = v_idciutat
              AND h.numllitsucilliures > 0
            ORDER BY d.km ASC
            LIMIT 1;

            IF NOT FOUND THEN
                RAISE NOTICE 'Cap hospital proper no té llits UCI disponibles.';
                RETURN;
            END IF;

            RAISE NOTICE ' Pacient rehubicat: %', HospitalProper(p_idpersona);
        ELSE
            v_idhospital_final := p_idhospital;
        END IF;
    ELSE
        v_idhospital_final := p_idhospital;
    END IF;

    INSERT INTO pacient(idpersona, idhospital, planta, habitacio, estat, ocupauci, idvirus)
    VALUES (
        p_idpersona,
        v_idhospital_final,
        p_planta,
        p_habitacio,
        v_estat_lower,
        v_ocupauci,
        p_idvirus
    );

    IF v_ocupauci THEN
        UPDATE hospital
        SET numllitsucilliures = numllitsucilliures - 1
        WHERE idhospital = v_idhospital_final;
    END IF;

    RAISE NOTICE 'Pacient % ingressat correctament.', p_idpersona;
END;
$$;


ALTER FUNCTION public.ingresapacient(p_idpersona text, p_idhospital text, p_planta integer, p_habitacio integer, p_estat text, p_idvirus text) OWNER TO postgres;

--
-- Name: llistapacientscartilla(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.llistapacientscartilla() RETURNS TABLE(idpersona text, nom text, cognom text, nomhospital text, planta integer, habitacio integer, datadosi1 date, quandosi2 date, quandosi3 date)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pac.idpersona,
        per.nom,
        per.cognom,
        h.nomhospital,
        pac.planta,
        pac.habitacio,
        c.datadosi1,
        c.quandosi2,
        c.quandosi3
    FROM pacient pac
    JOIN persona per ON pac.idpersona = per.idpersona
    JOIN hospital h ON pac.idhospital = h.idhospital
    LEFT JOIN cartillavacuna c ON pac.idpersona = c.idpersona;
END;
$$;


ALTER FUNCTION public.llistapacientscartilla() OWNER TO postgres;

--
-- Name: posadosi1(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.posadosi1(p_idpersona text, p_idtreballador text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_data_actual DATE := CURRENT_DATE;
    v_quandosi2 DATE;
    v_quandosi3 DATE;
    v_idhospital TEXT;
    v_idvacuna TEXT;
    v_nomvacuna TEXT;
    v_idvirus TEXT;
BEGIN
    -- Calcular següents dosis
    v_quandosi2 := v_data_actual + INTERVAL '120 days';
    v_quandosi3 := v_data_actual + INTERVAL '240 days';

    -- Obtenir hospital i virus del pacient
    SELECT idhospital, idvirus INTO v_idhospital, v_idvirus
    FROM pacient
    WHERE idpersona = p_idpersona;

    -- Buscar vacuna compatible amb el virus i disponible en stock
    SELECT sv.idvacuna, v.nomvacuna INTO v_idvacuna, v_nomvacuna
    FROM stockvacuna sv
    JOIN vacuna v ON sv.idvacuna = v.idvacuna
    WHERE sv.idhospital = v_idhospital
      AND sv.stock > 0
      AND v.idvirus = v_idvirus
    ORDER BY sv.stock DESC
    LIMIT 1;

    IF v_idvacuna IS NULL THEN
        RAISE NOTICE 'No hi ha vacunes disponibles per al virus del pacient a l''hospital %', v_idhospital;
        RETURN;
    END IF;

    -- Inserir cartilla
    INSERT INTO cartillavacuna(idpersona, datadosi1, quandosi2, quandosi3, id_treballador, nom_vacuna, idvacuna)
    VALUES (p_idpersona, v_data_actual, v_quandosi2, v_quandosi3, p_idtreballador, v_nomvacuna, v_idvacuna);

    -- Restar del stock
    UPDATE stockvacuna
    SET stock = stock - 1
    WHERE idvacuna = v_idvacuna AND idhospital = v_idhospital;

    RAISE NOTICE 'Dosi 1 administrada amb la vacuna %, resta 1 del stock.', v_idvacuna;
END;
$$;


ALTER FUNCTION public.posadosi1(p_idpersona text, p_idtreballador text) OWNER TO postgres;

--
-- Name: revisapacient(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.revisapacient(p_idpersona text, p_nou_estat text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_idhospital        TEXT;
    v_estat_actual      TEXT;
    v_llits_disponibles INT;
    v_proposta          TEXT;
BEGIN
    
    SELECT idhospital, estat
      INTO v_idhospital, v_estat_actual
      FROM pacient
     WHERE idpersona = p_idpersona;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pacient % no existeix a la taula PACIENT.', p_idpersona;
    END IF;

    
    IF LOWER(p_nou_estat) IN ('fora de perill', 'estable') THEN
        IF LOWER(v_estat_actual) = 'molt greu' THEN
            UPDATE hospital
            SET numllitsucilliures = numllitsucilliures + 1
            WHERE idhospital = v_idhospital;
            RAISE NOTICE 'Llit UCI alliberat a l''hospital %', v_idhospital;
        END IF;

        DELETE FROM pacient WHERE idpersona = p_idpersona;
        RAISE NOTICE 'Alta donada al pacient %', p_idpersona;
        RETURN;
    END IF;

    
    IF LOWER(p_nou_estat) = 'molt greu' THEN
        SELECT numllitsucilliures
          INTO v_llits_disponibles
          FROM hospital
         WHERE idhospital = v_idhospital;

        IF v_llits_disponibles <= 0 THEN
            RAISE NOTICE 'No hi ha llits UCI disponibles a l''hospital %', v_idhospital;

            
            v_proposta := HospitalProper(p_idpersona);
            RAISE NOTICE '%', v_proposta;

            RETURN;
        END IF;

        
        UPDATE hospital
        SET numllitsucilliures = numllitsucilliures - 1
        WHERE idhospital = v_idhospital;

        RAISE NOTICE 'Assignat llit UCI a l''hospital %', v_idhospital;
    END IF;

    
    UPDATE pacient
    SET estat = LOWER(p_nou_estat),
        ocupauci = (LOWER(p_nou_estat) = 'molt greu')
    WHERE idpersona = p_idpersona;

    RAISE NOTICE 'Estat actualitzat a % per al pacient %', p_nou_estat, p_idpersona;
END;
$$;


ALTER FUNCTION public.revisapacient(p_idpersona text, p_nou_estat text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cartillavacuna; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cartillavacuna (
    idpersona text NOT NULL,
    datadosi1 date,
    quandosi2 date,
    quandosi3 date,
    id_treballador text,
    nom_vacuna text,
    idvacuna text
);


ALTER TABLE public.cartillavacuna OWNER TO postgres;

--
-- Name: ciutat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ciutat (
    idciutat text NOT NULL,
    nomciutat text
);


ALTER TABLE public.ciutat OWNER TO postgres;

--
-- Name: comarca; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comarca (
    nomcomarca text NOT NULL,
    ciutat text,
    idciutat text
);


ALTER TABLE public.comarca OWNER TO postgres;

--
-- Name: distancia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.distancia (
    idorigen text NOT NULL,
    iddesti text NOT NULL,
    km integer
);


ALTER TABLE public.distancia OWNER TO postgres;

--
-- Name: doctor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.doctor (
    nss text,
    id_trabajador text NOT NULL
);


ALTER TABLE public.doctor OWNER TO postgres;

--
-- Name: hospital; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hospital (
    idhospital text NOT NULL,
    nomhospital text,
    numllitsucilliures integer,
    ciutat text,
    idciutat text
);


ALTER TABLE public.hospital OWNER TO postgres;

--
-- Name: infermer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.infermer (
    nss text,
    id_trabajador text NOT NULL
);


ALTER TABLE public.infermer OWNER TO postgres;

--
-- Name: pacient; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pacient (
    idpersona text NOT NULL,
    idhospital text,
    planta integer,
    habitacio integer,
    estat text,
    ocupauci boolean,
    idvirus text,
    CONSTRAINT estat_valid_check CHECK ((estat = ANY (ARRAY['molt greu'::text, 'greu'::text, 'moderat'::text, 'lleu'::text, 'fora de perill'::text])))
);


ALTER TABLE public.pacient OWNER TO postgres;

--
-- Name: persona; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.persona (
    idpersona text NOT NULL,
    nom text,
    cognom text,
    datanaixement date,
    ciutat text,
    idciutat text
);


ALTER TABLE public.persona OWNER TO postgres;

--
-- Name: pacients_amb_cartilla; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pacients_amb_cartilla AS
 SELECT c.idpersona,
    per.nom,
    per.cognom,
    c.datadosi1,
    c.quandosi2,
    c.quandosi3,
    c.nom_vacuna,
    c.idvacuna,
    c.id_treballador
   FROM (public.cartillavacuna c
     JOIN public.persona per ON ((c.idpersona = per.idpersona)));


ALTER VIEW public.pacients_amb_cartilla OWNER TO postgres;

--
-- Name: pacients_sense_cartilla; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pacients_sense_cartilla AS
 SELECT p.idpersona,
    p.idhospital,
    per.nom,
    per.cognom
   FROM (public.pacient p
     JOIN public.persona per ON ((p.idpersona = per.idpersona)))
  WHERE (NOT (EXISTS ( SELECT 1
           FROM public.cartillavacuna c
          WHERE (c.idpersona = p.idpersona))));


ALTER VIEW public.pacients_sense_cartilla OWNER TO postgres;

--
-- Name: treballador; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.treballador (
    id_treballador text NOT NULL,
    nom text,
    cognom text,
    idpersona text,
    idhospital text
);


ALTER TABLE public.treballador OWNER TO postgres;

--
-- Name: persones_no_ingressades; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.persones_no_ingressades AS
 SELECT p.idpersona,
    p.nom,
    p.cognom,
    p.datanaixement,
    p.ciutat,
    p.idciutat
   FROM ((public.persona p
     LEFT JOIN public.pacient pa ON ((p.idpersona = pa.idpersona)))
     LEFT JOIN public.treballador t ON ((p.idpersona = t.idpersona)))
  WHERE ((pa.idpersona IS NULL) AND (t.idpersona IS NULL));


ALTER VIEW public.persones_no_ingressades OWNER TO postgres;

--
-- Name: stockvacuna; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stockvacuna (
    idvacuna text NOT NULL,
    stock integer,
    idhospital text NOT NULL,
    idvirus text
);


ALTER TABLE public.stockvacuna OWNER TO postgres;

--
-- Name: vacuna; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vacuna (
    idvacuna text NOT NULL,
    nomvacuna text,
    laboratori text,
    numdosis integer,
    idvirus text
);


ALTER TABLE public.vacuna OWNER TO postgres;

--
-- Name: proxima_vacuna_pacient; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.proxima_vacuna_pacient AS
 SELECT p.idpersona,
    p.idhospital,
    p.idvirus,
    v.idvacuna,
    v.nomvacuna,
    sv.stock
   FROM ((public.pacient p
     JOIN public.vacuna v ON ((p.idvirus = v.idvirus)))
     JOIN public.stockvacuna sv ON (((v.idvacuna = sv.idvacuna) AND (p.idhospital = sv.idhospital))))
  WHERE (NOT (EXISTS ( SELECT 1
           FROM public.cartillavacuna c
          WHERE (c.idpersona = p.idpersona))));


ALTER VIEW public.proxima_vacuna_pacient OWNER TO postgres;

--
-- Name: virus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.virus (
    idvirus text NOT NULL,
    nomvirus text,
    numerovariant integer
);


ALTER TABLE public.virus OWNER TO postgres;

--
-- Name: vista_personal_sanitari; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_personal_sanitari AS
 SELECT persona.idpersona,
    treballador.id_treballador,
    persona.nom,
    persona.cognom,
    treballador.idhospital,
    ciutat.nomciutat AS ciutat_hospital,
    'Doctor'::text AS tipus
   FROM ((((public.doctor
     JOIN public.treballador ON ((doctor.id_trabajador = treballador.id_treballador)))
     JOIN public.persona ON ((treballador.idpersona = persona.idpersona)))
     JOIN public.hospital ON ((treballador.idhospital = hospital.idhospital)))
     JOIN public.ciutat ON ((hospital.idciutat = ciutat.idciutat)))
UNION
 SELECT persona.idpersona,
    treballador.id_treballador,
    persona.nom,
    persona.cognom,
    treballador.idhospital,
    ciutat.nomciutat AS ciutat_hospital,
    'Infermer'::text AS tipus
   FROM ((((public.infermer
     JOIN public.treballador ON ((infermer.id_trabajador = treballador.id_treballador)))
     JOIN public.persona ON ((treballador.idpersona = persona.idpersona)))
     JOIN public.hospital ON ((treballador.idhospital = hospital.idhospital)))
     JOIN public.ciutat ON ((hospital.idciutat = ciutat.idciutat)));


ALTER VIEW public.vista_personal_sanitari OWNER TO postgres;

--
-- Data for Name: cartillavacuna; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cartillavacuna (idpersona, datadosi1, quandosi2, quandosi3, id_treballador, nom_vacuna, idvacuna) FROM stdin;
P003	2025-05-20	2025-09-17	2026-01-15	T007	Pfizer	VAC01
P026	2025-05-20	2025-09-17	2026-01-15	T006	Fluzone	VAC02
P007	2025-05-20	2025-09-17	2026-01-15	T007	Pfizer	VAC01
P038	2025-05-21	2025-09-18	2026-01-16	T007	Pfizer	VAC01
P031	2025-05-22	2025-09-19	2026-01-17	T003	Pfizer	VAC01
P039	2025-05-22	2025-09-19	2026-01-17	T006	Pfizer	VAC01
P020	2025-05-22	2025-09-19	2026-01-17	T006	Pfizer	VAC01
P010	2025-05-22	2025-09-19	2026-01-17	T007	Pfizer	VAC01
P023	2025-05-22	2025-09-19	2026-01-17	T007	Pfizer	VAC01
P006	2025-05-22	2025-09-19	2026-01-17	T007	Pfizer	VAC01
\.


--
-- Data for Name: ciutat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ciutat (idciutat, nomciutat) FROM stdin;
C001	Barcelona
C002	Girona
C003	Tarragona
C004	Lleida
C005	Manresa
\.


--
-- Data for Name: comarca; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comarca (nomcomarca, ciutat, idciutat) FROM stdin;
Barcelonès	Barcelona	C001
Gironès	Girona	C002
Tarragonès	Tarragona	C003
Segrià	Lleida	C004
Bages	Manresa	C005
\.


--
-- Data for Name: distancia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.distancia (idorigen, iddesti, km) FROM stdin;
C001	C002	100
C001	C003	95
C001	C004	160
C001	C005	65
C002	C001	100
C002	C003	190
C002	C004	230
C002	C005	120
C003	C001	95
C003	C002	190
C003	C004	150
C003	C005	100
C004	C001	160
C004	C002	230
C004	C003	150
C004	C005	140
C005	C001	65
C005	C002	120
C005	C003	100
C005	C004	140
\.


--
-- Data for Name: doctor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.doctor (nss, id_trabajador) FROM stdin;
NSS001	T001
NSS002	T002
NSS003	T003
NSS004	T004
NSS005	T005
\.


--
-- Data for Name: hospital; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hospital (idhospital, nomhospital, numllitsucilliures, ciutat, idciutat) FROM stdin;
H004	Arnau de Vilanova	0	Lleida	C004
H002	Hospital Trueta	2	Girona	C002
H001	Hospital Clínic	0	Barcelona	C001
H005	Hospital Sant Joan	0	Manresa	C005
H003	Joan XXIII	0	Tarragona	C003
\.


--
-- Data for Name: infermer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.infermer (nss, id_trabajador) FROM stdin;
NSS006	T006
NSS007	T007
NSS008	T008
NSS009	T009
NSS010	T010
\.


--
-- Data for Name: pacient; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pacient (idpersona, idhospital, planta, habitacio, estat, ocupauci, idvirus) FROM stdin;
P013	H003	1	1	molt greu	t	V001
P023	H003	2	99	greu	f	V001
P020	H005	2	34	greu	f	V001
P031	H004	4	2	greu	f	V001
P006	H001	2	1	greu	f	V001
P001	H001	2	2	moderat	f	V002
P002	H005	2	2	molt greu	t	V001
P019	H003	2	2	molt greu	t	V001
P038	H005	3	3	molt greu	t	V001
P007	H002	1	2	greu	f	V001
P010	H004	2	22	greu	f	V001
P015	H003	2	12	molt greu	t	V001
P014	H004	1	19	greu	f	V002
\.


--
-- Data for Name: persona; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.persona (idpersona, nom, cognom, datanaixement, ciutat, idciutat) FROM stdin;
P001	Joan	Garcia	1980-05-12	Barcelona	C001
P002	Anna	Lopez	1990-09-22	Girona	C002
P003	Pablo	Escobar	1975-01-03	Tarragona	C003
P004	Laura	Sudat	1990-12-13	Lleida	C004
P005	Marc	Romero	2000-03-30	Manresa	C005
P006	Yorky	Mata	1999-03-27	Barcelona	C001
P007	Carmen	Lopez	1991-07-20	Girona	C002
P008	Manuel	Matos	2000-01-12	Tarragona	C003
P009	Laura	Monaco	2015-02-11	Lleida	C004
P010	Pinky	Cerebro	1997-02-08	Manresa	C005
P011	Jordi	Alonzo	1980-05-12	Barcelona	C001
P012	Alessio	Pennuto	1996-02-24	Girona	C002
P013	Pere	Martínez	1975-01-03	Tarragona	C003
P014	Federico	Elver	1985-07-15	Lleida	C004
P015	Marcos	Alvarez	2005-02-28	Manresa	C005
P016	Amador	Rivas	1985-04-10	Barcelona	C001
P017	Juan	Casas	2001-10-25	Girona	C002
P018	Pepe	Reina	2001-04-02	Tarragona	C003
P019	Paula	Martin	1995-07-15	Lleida	C004
P020	David	Ruiz	1999-03-01	Manresa	C005
P021	Pablo	Medina	2001-03-27	Barcelona	C001
P022	David	Lopez	1979-07-20	Girona	C002
P023	Saray	Pelay	2002-01-12	Tarragona	C003
P024	Yosue	Mata	1994-02-11	Lleida	C004
P025	Ash	Kepchup	1964-02-08	Manresa	C005
P026	Homero	Moe	1959-05-12	Barcelona	C001
P027	Karl	Malonne	1977-02-24	Girona	C002
P028	Damari	Arias	1974-01-03	Tarragona	C003
P029	Paula	Moya	1985-07-15	Lleida	C004
P030	Mohamed	Alli	2075-02-28	Manresa	C005
P031	Maria	Pozo	1985-04-10	Barcelona	C001
P038	Eric	Alpaco Lama	1965-04-10	Barcelona	C001
P032	Jesus	Osbando	2001-10-25	Girona	C002
P033	Orco	Lorca	2003-12-02	Tarragona	C003
P034	Chiara	Schimi	2001-05-02	Tarragona	C003
P035	Piccola	Manny	2001-04-01	Tarragona	C003
P036	Minnie	Donald	1995-07-15	Lleida	C004
P037	Grande	Pollo	1999-03-01	Manresa	C005
P039	Andrea	Parcero	1990-02-28	Lleida	C004
\.


--
-- Data for Name: stockvacuna; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stockvacuna (idvacuna, stock, idhospital, idvirus) FROM stdin;
VAC02	4	H004	V002
VAC02	4	H005	V002
VAC01	6	H005	V001
VAC01	3	H002	V001
VAC02	5	H002	V002
VAC01	1	H004	V001
VAC02	6	H003	V002
VAC01	2	H003	V001
VAC01	3	H001	V001
VAC02	4	H001	V002
\.


--
-- Data for Name: treballador; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.treballador (id_treballador, nom, cognom, idpersona, idhospital) FROM stdin;
T001	Laura	Sudat	P004	H001
T002	Jordi	Alonzo	P011	H002
T003	Marc	Romero	P005	H003
T004	Pepe	Reina	P018	H005
T005	Amador	Rivas	P016	H004
T006	Laura	Monaco	P009	H005
T007	Manuel	Matos	P008	H004
T008	Juan	Casas	P017	H003
T009	Alessio	Pennuto	P012	H002
T010	Pablo	Escobar	P003	H001
\.


--
-- Data for Name: vacuna; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vacuna (idvacuna, nomvacuna, laboratori, numdosis, idvirus) FROM stdin;
VAC01	Pfizer	Pfix	2	V001
VAC02	Fluzone	Flux	3	V002
\.


--
-- Data for Name: virus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.virus (idvirus, nomvirus, numerovariant) FROM stdin;
V001	COVID-19	5
V002	Influenza	4
\.


--
-- Name: cartillavacuna cartillavacuna_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cartillavacuna
    ADD CONSTRAINT cartillavacuna_pkey PRIMARY KEY (idpersona);


--
-- Name: ciutat ciutat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ciutat
    ADD CONSTRAINT ciutat_pkey PRIMARY KEY (idciutat);


--
-- Name: comarca comarca_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comarca
    ADD CONSTRAINT comarca_pkey PRIMARY KEY (nomcomarca);


--
-- Name: distancia distancia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.distancia
    ADD CONSTRAINT distancia_pkey PRIMARY KEY (idorigen, iddesti);


--
-- Name: doctor doctor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor
    ADD CONSTRAINT doctor_pkey PRIMARY KEY (id_trabajador);


--
-- Name: infermer enfermer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.infermer
    ADD CONSTRAINT enfermer_pkey PRIMARY KEY (id_trabajador);


--
-- Name: hospital hospital_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hospital
    ADD CONSTRAINT hospital_pkey PRIMARY KEY (idhospital);


--
-- Name: pacient pacient_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacient
    ADD CONSTRAINT pacient_pkey PRIMARY KEY (idpersona);


--
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (idpersona);


--
-- Name: stockvacuna stockvacuna_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stockvacuna
    ADD CONSTRAINT stockvacuna_pkey PRIMARY KEY (idvacuna, idhospital);


--
-- Name: treballador trabajador_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.treballador
    ADD CONSTRAINT trabajador_pkey PRIMARY KEY (id_treballador);


--
-- Name: vacuna vacuna_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vacuna
    ADD CONSTRAINT vacuna_pkey PRIMARY KEY (idvacuna);


--
-- Name: virus virus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.virus
    ADD CONSTRAINT virus_pkey PRIMARY KEY (idvirus);


--
-- Name: stockvacuna trigger_avisa_poc_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_avisa_poc_stock AFTER UPDATE ON public.stockvacuna FOR EACH ROW EXECUTE FUNCTION public.avisapocstock();


--
-- Name: distancia distancia_iddesti_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.distancia
    ADD CONSTRAINT distancia_iddesti_fkey FOREIGN KEY (iddesti) REFERENCES public.ciutat(idciutat);


--
-- Name: distancia distancia_idorigen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.distancia
    ADD CONSTRAINT distancia_idorigen_fkey FOREIGN KEY (idorigen) REFERENCES public.ciutat(idciutat);


--
-- Name: cartillavacuna fk_vacuna; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cartillavacuna
    ADD CONSTRAINT fk_vacuna FOREIGN KEY (idvacuna) REFERENCES public.vacuna(idvacuna) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: stockvacuna nnohospital; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stockvacuna
    ADD CONSTRAINT nnohospital FOREIGN KEY (idhospital) REFERENCES public.hospital(idhospital) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: cartillavacuna no_cartilla; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cartillavacuna
    ADD CONSTRAINT no_cartilla FOREIGN KEY (idpersona) REFERENCES public.persona(idpersona) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: comarca no_ciutat; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comarca
    ADD CONSTRAINT no_ciutat FOREIGN KEY (idciutat) REFERENCES public.ciutat(idciutat) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: doctor no_treballador; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor
    ADD CONSTRAINT no_treballador FOREIGN KEY (id_trabajador) REFERENCES public.treballador(id_treballador) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: infermer no_treballador; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.infermer
    ADD CONSTRAINT no_treballador FOREIGN KEY (id_trabajador) REFERENCES public.treballador(id_treballador) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cartillavacuna no_treballador; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cartillavacuna
    ADD CONSTRAINT no_treballador FOREIGN KEY (id_treballador) REFERENCES public.treballador(id_treballador) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: hospital nociutat; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hospital
    ADD CONSTRAINT nociutat FOREIGN KEY (idciutat) REFERENCES public.ciutat(idciutat) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: persona nociutat; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT nociutat FOREIGN KEY (idciutat) REFERENCES public.ciutat(idciutat) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: pacient nohospital; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacient
    ADD CONSTRAINT nohospital FOREIGN KEY (idhospital) REFERENCES public.hospital(idhospital) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: pacient nopersona; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacient
    ADD CONSTRAINT nopersona FOREIGN KEY (idpersona) REFERENCES public.persona(idpersona) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: treballador nopersonal; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.treballador
    ADD CONSTRAINT nopersonal FOREIGN KEY (idpersona) REFERENCES public.persona(idpersona) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: treballador nopuestotrabajol; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.treballador
    ADD CONSTRAINT nopuestotrabajol FOREIGN KEY (idhospital) REFERENCES public.hospital(idhospital) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: vacuna novacuna; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vacuna
    ADD CONSTRAINT novacuna FOREIGN KEY (idvirus) REFERENCES public.virus(idvirus) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: pacient novirus; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacient
    ADD CONSTRAINT novirus FOREIGN KEY (idvirus) REFERENCES public.virus(idvirus) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: stockvacuna novirus; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stockvacuna
    ADD CONSTRAINT novirus FOREIGN KEY (idvirus) REFERENCES public.virus(idvirus) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: stockvacuna seravacuna; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stockvacuna
    ADD CONSTRAINT seravacuna FOREIGN KEY (idvacuna) REFERENCES public.vacuna(idvacuna) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: FUNCTION administradosi(p_idpersona text, p_idvacuna text, p_idtreballador text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.administradosi(p_idpersona text, p_idvacuna text, p_idtreballador text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.administradosi(p_idpersona text, p_idvacuna text, p_idtreballador text) TO infermer;


--
-- Name: FUNCTION ficastock(p_idvacuna text, p_idhospital text, p_quantitat integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.ficastock(p_idvacuna text, p_idhospital text, p_quantitat integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.ficastock(p_idvacuna text, p_idhospital text, p_quantitat integer) TO infermer;


--
-- Name: FUNCTION hospitalproper(p_idpersona text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hospitalproper(p_idpersona text) TO doctor;
GRANT ALL ON FUNCTION public.hospitalproper(p_idpersona text) TO infermer;


--
-- Name: FUNCTION ingresapacient(p_idpersona text, p_idhospital text, p_planta integer, p_habitacio integer, p_estat text, p_idvirus text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.ingresapacient(p_idpersona text, p_idhospital text, p_planta integer, p_habitacio integer, p_estat text, p_idvirus text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.ingresapacient(p_idpersona text, p_idhospital text, p_planta integer, p_habitacio integer, p_estat text, p_idvirus text) TO doctor;


--
-- Name: FUNCTION llistapacientscartilla(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.llistapacientscartilla() FROM PUBLIC;
GRANT ALL ON FUNCTION public.llistapacientscartilla() TO doctor;
GRANT ALL ON FUNCTION public.llistapacientscartilla() TO infermer;


--
-- Name: FUNCTION posadosi1(p_idpersona text, p_idtreballador text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.posadosi1(p_idpersona text, p_idtreballador text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.posadosi1(p_idpersona text, p_idtreballador text) TO infermer;


--
-- Name: FUNCTION revisapacient(p_idpersona text, p_nou_estat text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.revisapacient(p_idpersona text, p_nou_estat text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.revisapacient(p_idpersona text, p_nou_estat text) TO doctor;


--
-- Name: TABLE cartillavacuna; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.cartillavacuna TO infermer;
GRANT SELECT ON TABLE public.cartillavacuna TO doctor;


--
-- Name: TABLE ciutat; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.ciutat TO doctor;
GRANT SELECT ON TABLE public.ciutat TO infermer;


--
-- Name: TABLE distancia; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.distancia TO doctor;
GRANT SELECT ON TABLE public.distancia TO infermer;


--
-- Name: TABLE hospital; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.hospital TO doctor;
GRANT SELECT ON TABLE public.hospital TO infermer;


--
-- Name: COLUMN hospital.numllitsucilliures; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(numllitsucilliures) ON TABLE public.hospital TO postgres;
GRANT UPDATE(numllitsucilliures) ON TABLE public.hospital TO doctor;


--
-- Name: TABLE infermer; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.infermer TO infermer;


--
-- Name: TABLE pacient; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pacient TO doctor;
GRANT SELECT ON TABLE public.pacient TO infermer;


--
-- Name: TABLE persona; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.persona TO doctor;
GRANT SELECT ON TABLE public.persona TO infermer;


--
-- Name: TABLE pacients_amb_cartilla; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.pacients_amb_cartilla TO infermer;
GRANT SELECT ON TABLE public.pacients_amb_cartilla TO doctor;


--
-- Name: TABLE pacients_sense_cartilla; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.pacients_sense_cartilla TO infermer;
GRANT SELECT ON TABLE public.pacients_sense_cartilla TO doctor;


--
-- Name: TABLE treballador; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.treballador TO doctor;


--
-- Name: TABLE persones_no_ingressades; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.persones_no_ingressades TO infermer;
GRANT SELECT ON TABLE public.persones_no_ingressades TO doctor;


--
-- Name: TABLE stockvacuna; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.stockvacuna TO infermer;
GRANT SELECT ON TABLE public.stockvacuna TO doctor;


--
-- Name: COLUMN stockvacuna.stock; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(stock) ON TABLE public.stockvacuna TO infermer;


--
-- Name: TABLE vacuna; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vacuna TO infermer;


--
-- Name: TABLE virus; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.virus TO doctor;


--
-- Name: TABLE vista_personal_sanitari; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vista_personal_sanitari TO infermer;


--
-- PostgreSQL database dump complete
--

