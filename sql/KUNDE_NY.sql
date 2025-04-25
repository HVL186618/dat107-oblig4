SET search_path = oblig4;
CREATE TABLE KUNDE_NY
(
    knr integer(30) PRIMARY KEY;
    kundexml xml();
);