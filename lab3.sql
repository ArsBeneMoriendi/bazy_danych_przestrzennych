CREATE EXTENSION postgis;



-- 1. Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana pomiędzy 2018 a 2019)
SELECT 'new' AS change_type, b19.*
FROM t2019_kar_buildings b19
WHERE NOT EXISTS 
(
	SELECT 1 FROM t2018_kar_buildings b18
	WHERE b18.polygon_id = b19.polygon_id
)
UNION ALL
SELECT 'modified' AS change_type, b19.*
FROM t2019_kar_buildings b19
JOIN t2018_kar_buildings b18 ON b18.polygon_id = b19.polygon_id
WHERE NOT ST_Equals(b18.geom, b19.geom);



-- 2. Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.
WITH changed_buildings AS 
(
	SELECT b19.geom
	FROM t2019_kar_buildings b19
	LEFT JOIN t2018_kar_buildings b18 USING (polygon_id)
	WHERE b18.polygon_id IS NULL
		OR NOT ST_Equals(b18.geom, b19.geom)
),
new_poi_2019 AS 
(
	SELECT p19.type, p19.geom
	FROM t2019_poi p19
	WHERE NOT EXISTS 
	(
		SELECT 1 FROM t2018_poi p18
		WHERE p18.poi_id = p19.poi_id
	)
)
SELECT n.type, COUNT(*) AS cnt
FROM new_poi_2019 n
WHERE EXISTS 
(
	SELECT 1 FROM changed_buildings cb
	WHERE ST_DWithin(n.geom::geography, cb.geom::geography, 500)
)
GROUP BY n.type ORDER BY cnt DESC;



-- 3. Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.
CREATE TABLE public.streets_reprojected AS
SELECT *
FROM 
(
	SELECT
		t.*,
		ST_Transform(t.geom, 3068) AS geom_3068
	FROM public.t2019_streets t
) s;

ALTER TABLE public.streets_reprojected DROP COLUMN geom;
ALTER TABLE public.streets_reprojected RENAME COLUMN geom_3068 TO geom;

CREATE INDEX streets_reprojected_gix ON public.streets_reprojected USING GIST (geom);



-- 4. Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
CREATE TABLE public.input_points 
(
    id SERIAL PRIMARY KEY,
    geom geometry(Point, 4326)
);

INSERT INTO public.input_points (geom) VALUES
(ST_SetSRID(ST_MakePoint(8.36093, 49.03174), 4326)),
(ST_SetSRID(ST_MakePoint(8.39876, 49.00644), 4326));

CREATE INDEX input_points_gix ON public.input_points USING GIST (geom);

SELECT id, ST_AsText(geom) FROM public.input_points;



-- 5. Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych DHDN.Berlin/Cassini.
ALTER TABLE public.input_points
	ALTER COLUMN geom
	TYPE geometry(Point, 3068)
	USING ST_Transform(geom, 3068);

SELECT ST_SRID(geom), ST_AsText(geom) FROM public.input_points;



-- 6. Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj reprojekcji geometrii, aby była zgodna z resztą tabel.
WITH path AS 
(
	SELECT ST_MakeLine(ST_Transform(geom, 3068) ORDER BY id) AS geom
	FROM public.input_points
),
nodes AS 
(
	SELECT
		*,
		ST_Transform(geom, 3068) AS geom_3068
	FROM public.t2019_street_node
)
SELECT n.*
FROM nodes n
CROSS JOIN path p
WHERE ST_DWithin(n.geom_3068, p.geom, 200); 



-- 7. Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się w odległości 300 m od parków (LAND_USE_A).
SELECT COUNT(DISTINCT p.poi_id) AS cnt
FROM public.t2018_poi p
WHERE p.type = 'Sporting Goods Store'
AND EXISTS 
(
	SELECT 1
	FROM public.t2019_land_use_a lu
	WHERE ST_DWithin(p.geom::geography, lu.geom::geography, 300)
);



-- 8. Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’
CREATE TABLE public."T2019_KAR_BRIDGES" AS
WITH r AS 
(
	SELECT ST_Transform(geom, 3068) AS geom
	FROM public.t2019_railways
),
w AS 
(
	SELECT ST_Transform(geom, 3068) AS geom
	FROM public.t2019_water_lines
)
SELECT (ST_Dump(ST_CollectionExtract(ST_Intersection(r.geom, w.geom), 1))).geom::geometry(Point, 3068) AS geom
FROM r
JOIN w ON ST_Crosses(r.geom, w.geom); 

CREATE INDEX t2019_kar_bridges_gix ON public."T2019_KAR_BRIDGES" USING GIST (geom);
