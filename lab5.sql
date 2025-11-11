CREATE EXTENSION postgis;



-- 1. Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych poniżej. Układ odniesienia ustal jako niezdefiniowany. 

CREATE TABLE obiekty (
	id    serial PRIMARY KEY,
	nazwa text NOT NULL,
	geom  geometry  -- nie ma definiowania SRID (później jest 0)
);

INSERT INTO obiekty (nazwa, geom) VALUES (
	'obiekt1',
  	ST_CurveToLine(
	ST_GeomFromText(
		'COMPOUNDCURVE(
			(0 1, 1 1),
			CIRCULARSTRING(1 1, 2 0, 3 1),
			CIRCULARSTRING(3 1, 4 2, 5 1),
			(5 1, 6 1)
		)', 0)
	)
);

INSERT INTO obiekty (nazwa, geom) VALUES (
	'obiekt2',
  	ST_CurveToLine(
    ST_GeomFromText(
	  	'CURVEPOLYGON(
			 COMPOUNDCURVE(
			   (10 6, 14 6),
			   CIRCULARSTRING(14 6, 16 4, 14 2),
			   CIRCULARSTRING(14 2, 12 0, 10 2),
			   (10 2, 10 6)
			 ),
			 CIRCULARSTRING(11 2, 12 3, 13 2, 12 1, 11 2)
	   	)', 0)
	)
);

INSERT INTO obiekty (nazwa, geom) VALUES (
	'obiekt3',
  	ST_GeomFromText('POLYGON((7 15, 10 17, 12 13, 7 15))', 0)
);

INSERT INTO obiekty (nazwa, geom) VALUES (
  	'obiekt4',
  	ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)', 0)
);

INSERT INTO obiekty (nazwa, geom) VALUES (
	'obiekt5', 
	ST_GeomFromText('MULTIPOINT Z ((30 30 59), (38 32 234))', 0)
);

INSERT INTO obiekty (nazwa, geom) VALUES (
	'obiekt6', 
	ST_GeomFromText('GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2), POINT(4 2))', 0)
);



-- 2. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej obiekt 3 i 4. 

SELECT ST_Area(ST_Buffer(ST_ShortestLine(
	(SELECT geom FROM obiekty WHERE nazwa='obiekt3'),
	(SELECT geom FROM obiekty WHERE nazwa='obiekt4')
    ), 5.0)) 
AS powierzchnia_bufora;


	   
-- 3. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te warunki. 
-- Odp: Żeby zamienić obiekt na poligon, linia tworząca ten obiekt musi być domknięta

UPDATE obiekty
SET geom = ST_MakePolygon(ST_LineMerge(ST_AddPoint(geom, ST_StartPoint(geom))))
WHERE nazwa='obiekt4' AND ST_GeometryType(geom)='ST_LineString'
  


-- 4. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4. 

INSERT INTO obiekty (nazwa, geom)
SELECT 'obiekt7', ST_Union(a.geom, b.geom)
FROM obiekty a CROSS JOIN obiekty b
WHERE a.nazwa='obiekt3' AND b.nazwa='obiekt4';



-- 5. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów nie zawierających łuków. 

SELECT nazwa, ST_Area(ST_Buffer(geom, 5.0)) AS powierzchnia_bufora
FROM obiekty
WHERE NOT ST_HasArc(geom);



SELECT id, nazwa, ST_GeometryType(geom) FROM obiekty;