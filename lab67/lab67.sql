ALTER SCHEMA schema_name RENAME TO dybcio;
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;



-- TWORZENIE i INTERSEKCJA

-- Przyklad 1 
CREATE TABLE dybcio.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ILIKE 'porto'; /* ILIKE to LIKE ale ignorujacy wielkosc liter*/

ALTER TABLE dybcio.intersects
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON dybcio.intersects
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('dybcio'::name, 'intersects'::name,'rast'::name);


-- Przyklad 2 
CREATE TABLE dybcio.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality LIKE 'PORTO';


-- Przyklad 3
CREATE TABLE dybcio.union AS 
SELECT ST_Union (ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ILIKE 'porto' AND ST_Intersects(b.geom, a.rast);




-- RASTROWANIE

-- Przyklad 1
CREATE TABLE dybcio.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ILIKE 'porto';


-- Przyklad 2 
DROP TABLE dybcio.porto_parishes; 
CREATE TABLE dybcio.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT ST_Union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ILIKE 'porto';


-- Przyklad 3
DROP TABLE dybcio.porto_parishes; 
CREATE TABLE dybcio.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1 
)
SELECT ST_Tile(ST_Union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ILIKE 'porto';




-- WEKTORYZOWANIE

-- Przyklad 1
CREATE TABLE dybcio.intersection AS
SELECT a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ILIKE 'paranhos' AND ST_Intersects(b.geom,a.rast);


-- Przyklad 2
CREATE TABLE dybcio.dumppolygons AS
SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ILIKE 'paranhos' AND ST_Intersects(b.geom,a.rast);




--ANALIZA RASTRÓW

-- Przyklad 1 
CREATE TABLE dybcio.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;


-- Przyklad 2
CREATE TABLE dybcio.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ILIKE 'paranhos' AND ST_Intersects(b.geom,a.rast);


-- Przykład 3
CREATE TABLE dybcio.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') AS rast
FROM dybcio.paranhos_dem AS a;


-- Przykład 4
CREATE TABLE dybcio.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3', '32BF',0)
FROM dybcio.paranhos_slope AS a;


-- Przykład 5
SELECT st_summarystats(a.rast) AS stats
FROM dybcio.paranhos_dem AS a;


-- Przykład 6
SELECT st_summarystats(ST_Union(a.rast))
FROM dybcio.paranhos_dem AS a;


-- Przykład 7
WITH t AS (
	SELECT st_summarystats(ST_Union(a.rast)) AS stats
	FROM dybcio.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;


-- Przykład 8
WITH t AS (
	SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast, b.geom,true))) AS stats
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.municipality ILIKE 'porto' AND ST_Intersects(b.geom,a.rast)
	GROUP BY b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;


-- Przykład 9
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;


-- Przykład 10
CREATE TABLE dybcio.tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a;

CREATE TABLE dybcio.tpi30_porto AS
SELECT ST_TPI(ST_Union(ST_Clip(a.rast, b.geom, true),1)) AS rast
FROM rasters.dem a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast,b.geom) AND b.municipality ILIKE 'porto';




-- ALGEBRA MAP
-- NDVI=(NIR-Red)/(NIR+Red)

-- Przyklad 1 
CREATE TABLE dybcio.porto_ndvi AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ILIKE 'porto' AND ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
	r.rast, 1,
	r.rast, 4,
	'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON dybcio.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('dybcio'::name, 'porto_ndvi'::name,'rast'::name);


-- Przykład 2
CREATE OR REPLACE FUNCTION dybcio.ndvi(
	VALUE double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
RETURN (VALUE [2][1][1] - VALUE [1][1][1])/(VALUE [2][1][1]+VALUE [1][1][1]); 
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE dybcio.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
	r.rast, ARRAY[1,4],
	'dybcio.ndvi(double precision[], integer[],text[])'::regprocedure, 
	'32BF'::text
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON dybcio.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('dybcio'::name, 'porto_ndvi2'::name,'rast'::name);




-- EKSPORT DANYCH

-- Przykład 1
SELECT ST_AsTiff(ST_Union(rast))
FROM dybcio.porto_ndvi;

-- Przykład 2
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
FROM dybcio.porto_ndvi;

SELECT ST_GDALDrivers();

-- Przykład 3
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
	ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM dybcio.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'E:\raster.tiff') 
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out;

-- Przykład 4
-- gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 PG:"host=localhost port=5432 dbname=postgis_raster user=postgres password= schema=dybcio table=porto_ndvi mode=2" porto_ndvi.tiff
