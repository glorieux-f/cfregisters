CREATE TABLE perf (
  -- représentation
  date TEXT,
  decade INTEGER, -- generated
  year INTEGER,   -- generated
  month INTEGER,  -- generated
  day   TEXT,     -- generated
  receipt INTEGER,
  play INTEGER
);
UPDATE perf SET month =(SELECT 0+substr(date, 6, 2));
UPDATE perf SET decade =(SELECT substr(date, 1, 3)||'0');

CREATE INDEX perf_year ON perf(year);
CREATE INDEX perf_date ON perf(date);
CREATE INDEX perf_play ON perf(play);
CREATE INDEX perf_month ON perf(month);
CREATE INDEX perf_decade ON perf(decade);


CREATE TABLE play (
  -- une pièce
  author TEXT,
  title TEXT,
  genre TEXT,
  acts TEXT,
  verse TEXT,
  prologue BOOLEAN,
  show BOOLEAN,
  created TEXT,
  perfs INTEGER,   -- generated, number of performances for this play
  receipt INTEGER,  -- generated, income for this play
  start INTEGER,   -- generated, first performance year
  end INTEGER,     -- generated, last performance year
  duration INTEGER -- generated, career of a play
);
CREATE INDEX play_author_title ON play(author, title);
CREATE INDEX play_title ON play(title);
CREATE INDEX play_genre ON play(genre);

UPDATE play SET perfs = (SELECT count(*) FROM perf WHERE play = play.rowid);
UPDATE play SET receipt = (SELECT sum(receipt) FROM perf WHERE play = play.rowid);
UPDATE play SET start = (SELECT year FROM perf WHERE play = play.rowid ORDER BY year LIMIT 1);
UPDATE play SET end = (SELECT year FROM perf WHERE play = play.rowid ORDER BY year DESC LIMIT 1);
UPDATE play SET duration = 1 + end - start;

CREATE TABLE genre (
  -- genres, generated table
  name TEXT,
  plays INTEGER,
  perfs INTEGER,
  receipt INTEGER
)
INSERT INTO genre(name, plays) SELECT genre, count(*) FROM play GROUP BY genre;
UPDATE genre SET perfs = (SELECT count(*) FROM play, perf WHERE perf.play = play.rowid AND play.genre = genre.name);
UPDATE genre SET receipt = (SELECT sum(perf.receipt) FROM play, perf WHERE perf.play = play.rowid AND play.genre = genre.name);

CREATE TABLE author (
  -- authors, generated from perf and play, used for loops
  name TEXT, 
  plays INTEGER,    -- generated, number of plays signed by this author
  perfs INTEGER,    -- generated, number of performances for plays signed by this author
  receipt INTEGER,    -- generated, recette?
  start INTEGER,    -- generated, year of first performance for this author
  end INTEGER,      -- generated, year of last performance for this author
  duration INTEGER  -- generated, end - start + 1
);
CREATE INDEX author_perfs ON author(perfs);
CREATE INDEX author_receipt ON author(receipt);
CREATE INDEX author_duration ON author(duration);

INSERT INTO author (name, perfs) SELECT author, count(*) FROM play, perf WHERE perf.play = play.rowid GROUP BY author;
UPDATE author SET plays = (SELECT count(*) FROM play WHERE author = name);
UPDATE author SET receipt = (SELECT sum(receipt) FROM perf, play WHERE perf.play = play.rowid AND author = name);
UPDATE author SET start = (SELECT year FROM perf, play WHERE perf.play = play.rowid AND author = name ORDER BY year LIMIT 1);
UPDATE author SET end = (SELECT year FROM perf, play WHERE perf.play = play.rowid AND author = name ORDER BY year DESC LIMIT 1);
UPDATE author SET duration = 1 + end - start;

CREATE TABLE year (
  -- generated from perfs, years,  to loop over chronology
  n INTEGER,      -- 1680, 1681, 1682…
  dates INTEGER,  -- dates for a year
  plays INTEGER,  -- number of distinct play by year
  perfs INTEGER,  -- number of performances for a year
  receipt INTEGER  -- receipt for a year
);
CREATE INDEX year_n ON year(n);

INSERT INTO year (n) SELECT DISTINCT year FROM perf;
UPDATE year SET dates = (SELECT count(DISTINCT date) FROM perf WHERE year = n);
UPDATE year SET plays = (SELECT count(DISTINCT play) FROM perf WHERE year = n);
UPDATE year SET perfs = (SELECT count(*) FROM perf WHERE year = n);
UPDATE year SET receipt = (SELECT sum(receipt) FROM perf WHERE year = n);

CREATE TABLE date (
  -- generated from perfs, calculate day profile in acts
  iso TEXT,    -- AAAA-MM-DD  
  year INTEGER,
  month INTEGER,
  day INTEGER,
  receipt INTEGER,
  a1 INTEGER,  -- 1 act play, count
  a2 INTEGER,  -- 2 acts play, count
  a3 INTEGER,  -- 3 acts play, count
  a4 INTEGER,  -- 4 acts play, count
  a5 INTEGER,  -- 5 acts play, count
  a6 INTEGER   -- 6 acts play, count
);
INSERT INTO date (iso) SELECT DISTINCT date FROM perf;
UPDATE date SET a1 = (SELECT count(*) FROM perf, play WHERE perf.date = date.iso AND perf.play = play.rowid AND play.acts = 1);
UPDATE date SET a2 = (SELECT count(*) FROM perf, play WHERE perf.date = date.iso AND perf.play = play.rowid AND play.acts = 2);
UPDATE date SET a3 = (SELECT count(*) FROM perf, play WHERE perf.date = date.iso AND perf.play = play.rowid AND play.acts = 3);
UPDATE date SET a4 = (SELECT count(*) FROM perf, play WHERE perf.date = date.iso AND perf.play = play.rowid AND play.acts = 4);
UPDATE date SET a5 = (SELECT count(*) FROM perf, play WHERE perf.date = date.iso AND perf.play = play.rowid AND play.acts = 5);
UPDATE date SET a6 = (SELECT count(*) FROM perf, play WHERE perf.date = date.iso AND perf.play = play.rowid AND play.acts = 6);
UPDATE date SET month =(SELECT substr(iso, 6, 2));
UPDATE date SET year =(SELECT substr(iso, 1, 4));
UPDATE date SET receipt = (SELECT receipt FROM perf WHERE perf.date = date.iso);

CREATE INDEX date_iso ON date(iso);
CREATE INDEX date_a1 ON date(a1);
CREATE INDEX date_a2 ON date(a2);
CREATE INDEX date_a3 ON date(a3);
CREATE INDEX date_a4 ON date(a4);
CREATE INDEX date_a5 ON date(a5);
CREATE INDEX date_a6 ON date(a6);
CREATE INDEX date_month ON date(month);
CREATE INDEX date_year ON date(year);




