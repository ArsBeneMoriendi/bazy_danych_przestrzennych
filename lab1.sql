-- PostgreSQL --

-- 1. Utwórz nową bazę danych nazywając ją firma. 
CREATE DATABASE firma;

-- 2. Dodaj schemat o nazwie ksiegowosc.  
CREATE SCHEMA ksiegowosc;

-- 3. Dodaj cztery tabele (pracownicy, godziny, pensja, premia, wynagrodzenie; typy, klucze, komentarze)

-- dodałam od siebie, żeby nie pisać wszędzie ksiegowosc.
SET search_path = ksiegowosc; 

CREATE TABLE pracownicy (
  id_pracownika BIGSERIAL PRIMARY KEY,
  imie         TEXT NOT NULL,
  nazwisko     TEXT NOT NULL,
  adres        TEXT,
  telefon      VARCHAR(20)
);

CREATE TABLE pensja (
  id_pensji  BIGSERIAL PRIMARY KEY,
  stanowisko TEXT NOT NULL,
  kwota      NUMERIC(12,2) NOT NULL
);

CREATE TABLE premia (
  id_premii BIGSERIAL PRIMARY KEY,
  rodzaj    TEXT NOT NULL,
  kwota     NUMERIC(12,2) NOT NULL
);

CREATE TABLE godziny (
  id_godziny     BIGSERIAL PRIMARY KEY,
  data           DATE NOT NULL,
  liczba_godzin  NUMERIC(5,2) NOT NULL,
  id_pracownika  BIGINT NOT NULL REFERENCES pracownicy(id_pracownika)
);

CREATE TABLE wynagrodzenie (
  id_wynagrodzenia BIGSERIAL PRIMARY KEY,
  data             DATE NOT NULL,
  id_pracownika    BIGINT NOT NULL REFERENCES pracownicy(id_pracownika),
  id_godziny       BIGINT NOT NULL REFERENCES godziny(id_godziny),
  id_pensji        BIGINT NOT NULL REFERENCES pensja(id_pensji),
  id_premii        BIGINT REFERENCES premia(id_premii)
);

COMMENT ON TABLE pracownicy IS 'Pracownicy firmy';
COMMENT ON TABLE pensja IS 'Stawki podstawowe (wg stanowisk)';
COMMENT ON TABLE premia IS 'Premie';
COMMENT ON TABLE godziny IS 'Ewidencja przepracowanych godzin';
COMMENT ON TABLE wynagrodzenie IS 'Zestawienia wypłat';


-- 4. Wypełnij każdą tabelę 10. rekordami.
-- przyznaję, że dane są wygenerowane - oszczędność czasu i niewysilanie kreatywności

INSERT INTO pracownicy (imie, nazwisko, adres, telefon) VALUES
('Jan','Nowak','Gdańsk, ul. Długa 1','600100100'),
('Anna','Kowalska','Gdynia, ul. Morska 5','600200200'),
('Julia','Wiśniewska','Sopot, ul. Leśna 7','600300300'),
('Jakub','Kamiński','Gdańsk, ul. Oliwska 10','600400400'),
('Michał','Lewandowski','Tczew, ul. Kolejowa 3','600500500'),
('Joanna','Zielińska','Pruszcz, ul. Szkolna 2','600600600'),
('Piotr','Wójcik','Gdańsk, ul. Kartuska 11','600700700'),
('Karolina','Kaczmarek','Gdynia, ul. Śląska 8','600800800'),
('Jacek','Piotrowski','Sopot, ul. Parkowa 9','600900900'),
('Magda','Nowicka','Gdańsk, ul. Grunwaldzka 15','601001001');

INSERT INTO godziny (data, liczba_godzin, id_pracownika) VALUES
('2025-01-31',168,1),
('2025-01-31',152,2),
('2025-01-31',160,3),
('2025-01-31',174,4),
('2025-01-31',158,5),
('2025-01-31',182,6),
('2025-01-31',140,7),
('2025-01-31',165,8),
('2025-01-31',190,9),
('2025-01-31',160,10);

INSERT INTO pensja (stanowisko, kwota) VALUES
('Praktykant',800.00),
('Asystent',2500.00),
('Specjalista',3200.00),
('Starszy specjalista',4200.00),
('Księgowy',3500.00),
('Kadrowa',3000.00),
('Młodszy analityk',2800.00),
('Analityk',3800.00),
('Kierownik',6000.00),
('Dyrektor',9000.00);

INSERT INTO premia (rodzaj, kwota) VALUES
('Brak',0.00),
('Uznaniowa',500.00),
('Świąteczna',800.00),
('Projektowa',1200.00),
('Frekwencyjna',300.00),
('Okolicznościowa',400.00),
('Za wyniki',1500.00),
('Stażowa',200.00),
('Jubileuszowa',1000.00),
('Roczna',2500.00);

INSERT INTO wynagrodzenie (data, id_pracownika, id_godziny, id_pensji, id_premii) VALUES
('2025-01-31',1,1,3,2),
('2025-01-31',2,2,2,NULL),
('2025-01-31',3,3,5,1),
('2025-01-31',4,4,8,4),
('2025-01-31',5,5,7,NULL),
('2025-01-31',6,6,4,7),
('2025-01-31',7,7,1,NULL),
('2025-01-31',8,8,6,5),
('2025-01-31',9,9,9,NULL),
('2025-01-31',10,10,10,10);


-- 5. Wykonaj następujące zapytania: 

-- a) Wyświetl tylko id pracownika oraz jego nazwisko.
SELECT id_pracownika, nazwisko FROM pracownicy;

-- b) Wyświetl id pracowników, których płaca jest większa niż 1000.  
SELECT DISTINCT w.id_pracownika
FROM wynagrodzenie w
JOIN pensja p ON p.id_pensji = w.id_pensji
WHERE p.kwota > 1000;

-- c) Wyświetl id pracowników nieposiadających premii, których płaca jest większa niż 2000. 
SELECT DISTINCT w.id_pracownika
FROM wynagrodzenie w
JOIN pensja p ON p.id_pensji = w.id_pensji
LEFT JOIN premia pr ON pr.id_premii = w.id_premii
WHERE (w.id_premii IS NULL OR pr.kwota = 0) AND p.kwota > 2000;
  
-- d) Wyświetl pracowników, których pierwsza litera imienia zaczyna się na literę ‘J’.  
SELECT *
FROM pracownicy
WHERE imie LIKE 'J%';

-- e) Wyświetl pracowników, których nazwisko zawiera literę ‘n’ oraz imię kończy się na literę ‘a’. 
SELECT *
FROM pracownicy
WHERE nazwisko LIKE '%n%' AND imie LIKE '%a';

-- f) Wyświetl imię i nazwisko pracowników oraz liczbę ich nadgodzin, przyjmując, iż standardowy czas pracy to 160 h miesięcznie.  
SELECT pr.imie, pr.nazwisko,
       CASE WHEN g.liczba_godzin > 160 THEN g.liczba_godzin - 160 ELSE 0 END AS nadgodziny
FROM pracownicy pr
JOIN wynagrodzenie w ON w.id_pracownika = pr.id_pracownika
JOIN godziny g ON g.id_godziny = w.id_godziny;

-- g) Wyświetl imię i nazwisko pracowników, których pensja zawiera się w przedziale 1500 – 3000 PLN.  
SELECT pr.imie, pr.nazwisko, p.kwota
FROM pracownicy pr
JOIN wynagrodzenie w ON w.id_pracownika = pr.id_pracownika
JOIN pensja p ON p.id_pensji = w.id_pensji
WHERE p.kwota BETWEEN 1500 AND 3000;

-- h) Wyświetl imię i nazwisko pracowników, którzy pracowali w nadgodzinach i nie otrzymali premii.  
SELECT pr.imie, pr.nazwisko
FROM pracownicy pr
JOIN wynagrodzenie w ON w.id_pracownika = pr.id_pracownika
JOIN godziny g ON g.id_godziny = w.id_godziny
LEFT JOIN premia prr ON prr.id_premii = w.id_premii
WHERE g.liczba_godzin > 160 AND (w.id_premii IS NULL OR COALESCE(prr.kwota,0) = 0);
  
-- i) Uszereguj pracowników według pensji. 
SELECT pr.imie, pr.nazwisko, p.kwota
FROM pracownicy pr
JOIN wynagrodzenie w ON w.id_pracownika = pr.id_pracownika
JOIN pensja p ON p.id_pensji = w.id_pensji
ORDER BY p.kwota ASC;

-- j) Uszereguj pracowników według pensji i premii malejąco.  
SELECT pr.imie, pr.nazwisko, p.kwota AS pensja, COALESCE(prm.kwota,0) AS premia
FROM pracownicy pr
JOIN wynagrodzenie w ON w.id_pracownika = pr.id_pracownika
JOIN pensja p ON p.id_pensji = w.id_pensji
LEFT JOIN premia prm ON prm.id_premii = w.id_premii
ORDER BY p.kwota DESC, COALESCE(prm.kwota,0) DESC;

-- k) Zlicz i pogrupuj pracowników według pola ‘stanowisko’.  
SELECT p.stanowisko, COUNT(*) AS liczba_pracownikow
FROM wynagrodzenie w
JOIN pensja p ON p.id_pensji = w.id_pensji
GROUP BY p.stanowisko
ORDER BY liczba_pracownikow DESC, p.stanowisko;

-- l) Policz średnią, minimalną i maksymalną płacę dla stanowiska ‘kierownik’ (jeżeli takiego nie masz, to przyjmij dowolne inne).  
SELECT AVG(p.kwota) AS srednia, MIN(p.kwota) AS minimum, MAX(p.kwota) AS maksimum
FROM wynagrodzenie w
JOIN pensja p ON p.id_pensji = w.id_pensji
WHERE p.stanowisko = 'Kierownik';

-- m) Policz sumę wszystkich wynagrodzeń.  
SELECT SUM(p.kwota + COALESCE(pr.kwota,0)) AS suma_wynagrodzen
FROM wynagrodzenie w
JOIN pensja p ON p.id_pensji = w.id_pensji
LEFT JOIN premia pr ON pr.id_premii = w.id_premii;

-- f) Policz sumę wynagrodzeń w ramach danego stanowiska.  
SELECT p.stanowisko,
       SUM(p.kwota + COALESCE(pr.kwota,0)) AS suma_wg_stanowiska
FROM wynagrodzenie w
JOIN pensja p ON p.id_pensji = w.id_pensji
LEFT JOIN premia pr ON pr.id_premii = w.id_premii
GROUP BY p.stanowisko
ORDER BY suma_wg_stanowiska DESC;

-- g) Wyznacz liczbę premii przyznanych dla pracowników danego stanowiska.  
SELECT p.stanowisko,
       COUNT(w.id_premii) AS liczba_przyznanych_premii
FROM wynagrodzenie w
JOIN pensja p ON p.id_pensji = w.id_pensji
WHERE w.id_premii IS NOT NULL
GROUP BY p.stanowisko
ORDER BY liczba_przyznanych_premii DESC;

-- h) Usuń wszystkich pracowników mających pensję mniejszą niż 1200 zł
DELETE FROM pracownicy
WHERE id_pracownika IN (
  SELECT w.id_pracownika
  FROM wynagrodzenie w
  JOIN pensja p ON p.id_pensji = w.id_pensji
  WHERE p.kwota < 1200
);
