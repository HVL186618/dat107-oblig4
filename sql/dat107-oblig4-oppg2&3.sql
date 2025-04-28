--hobbyhuset.sql må kjøres før denne fungerer
set search_path = oblig4;

drop table if exists kunde_ny cascade;
create table kunde_ny (
    knr integer primary key,
    kunde_xml xml
);

insert into kunde_ny (knr, kunde_xml)
select 
    knr,
    xmlelement(
        NAME "kunde",
        xmlforest(fornavn, etternavn, adresse, postnr)
    )
from kunde;

select
    knr,
    unnest(xpath('//fornavn/text()', kunde_xml))::text as fornavn,
    unnest(xpath('//etternavn/text()', kunde_xml))::text as etternavn,
    unnest(xpath('//adresse/text()', kunde_xml))::text as adresse,
    unnest(xpath('//postnr/text()', kunde_xml))::text as postnr
from kunde_ny;

select
    knr,
    fornavn,
    etternavn,
    adresse,
    postnr
from (
    select
        knr,
        unnest(xpath('//fornavn/text()', kunde_xml))::text as fornavn,
        unnest(xpath('//etternavn/text()', kunde_xml))::text as etternavn,
        unnest(xpath('//adresse/text()', kunde_xml))::text as adresse,
        unnest(xpath('//postnr/text()', kunde_xml))::text as postnr
    from oblig4.kunde_ny
) as subquery
where etternavn like 'A%'
order by etternavn;

---

drop table if exists ordre_ny;
create table ordre_ny (
    ordrenr integer primary key,
    kundenr integer references oblig4.kunde_ny(knr),
    ordre_xml xml
);

insert into ordre_ny (ordrenr, kundenr, ordre_xml)
select 
    ordrenr,
    knr,
    xmlelement(
        name "ordre",
        xmlforest(
            ordredato,
            sendtdato,
            betaltdato
        )
    )
from ordre;

delete from ordre_ny;

insert into ordre_ny (ordrenr, kundenr, ordre_xml)
select
    o.ordrenr,
    o.knr,
    xmlelement(
        name "ordre",
        xmlconcat(  -- tror denne er som ||
            xmlforest(
                ordredato,
                sendtdato,
                betaltdato
            ),
            xmlelement(
                name "ordrelinjer",
                xmlagg(
                    xmlelement(
                        name "ordrelinje",
                        xmlforest(
                            vnr,
                            prisprenhet,
                            antall
                        )
                    )
                )
            )
        )
    )
from ordre o
left join ordrelinje ol
    on o.ordrenr = ol.ordrenr
group by o.ordrenr, o.knr, o.ordredato, o.sendtdato, o.betaltdato;

--select * from ordre_ny;

select
    o.ordrenr,
    o.kundenr,
    unnest(xpath('//prisprenhet/text()', ordre_xml))::text as prisprenhet,
    unnest(xpath('//antall/text()', ordre_xml))::text as antall
from ordre_ny o
where
    o.kundenr = 5643
    and to_char(
        (xpath('//sendtdato/text()', ordre_xml))[1]::text::date,
        'yyyy-mm'
    ) = '2019-08';

---------------
-- oppgave 3 --

select json_build_object(
    'knr', k.knr,
    'fornavn', k.fornavn,
    'etternavn', k.etternavn,
    'adresse', k.adresse,
    'postnr', k.postnr,
    'poststed', p.poststed
) as kunde_json
from kunde k
join poststed p on k.postnr = p.postnr;

select json_build_object(
    'vnr', v.vnr,
    'betegnelse', v.betegnelse,
    'pris', v.pris,
    'katnr', v.katnr,
    'antall', v.antall,
    'hylle', v.hylle
) as vare_json
from vare v;

select json_build_object(
    'ordrenr', o.ordrenr,
    'knr', o.knr,
    'ordredato', o.ordredato,
    'sendtdato', o.sendtdato,
    'betaltdato', o.betaltdato,
    'ordrelinjer', json_agg(
        json_build_object(
            'vnr', ol.vnr,
            'prisprenhet', ol.prisprenhet,
            'antall', ol.antall
        )
    )
) as ordre_json
from ordre o
left join ordrelinje ol on o.ordrenr = ol.ordrenr
group by o.ordrenr, o.knr, o.ordredato, o.sendtdato, o.betaltdato;


