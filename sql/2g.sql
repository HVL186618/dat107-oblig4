SET search_path = oblig4;
CREATE TABLE OLDERVIK_NY
(
    ordrenr integer PRIMARY KEY,
    kundenr integer references KUNDE_NY(knr),
    ordre_xml xml --Hva skal jeg putte inni?
);