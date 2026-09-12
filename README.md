# BookMyShow – DB design assignment

Scenario: pick a theatre, pick one of the next 7 dates, see every show running
there that day with its timings (movie, language, format, time).

Everything below is in [`bookmyshow.sql`](bookmyshow.sql) and runs as-is on MySQL 8:

```bash
mysql -u root -p < bookmyshow.sql
```

## Entities

| Entity | What it is | Attributes |
|---|---|---|
| **theatre** | A cinema | theatre_id (PK), name, city, address |
| **screen** | An audi inside a theatre | screen_id (PK), theatre_id (FK), screen_name, total_seats |
| **movie** | A film, independent of where it plays | movie_id (PK), title, duration_mins, certificate |
| **language** | Lookup – Hindi, Telugu, … | language_id (PK), name |
| **format** | Lookup – 2D, 3D, IMAX | format_id (PK), name |
| **movie_show** | One screening: a movie, on a screen, at a date + time | show_id (PK), screen_id (FK), movie_id (FK), language_id (FK), format_id (FK), show_date, start_time |

Language and format sit on the show rather than the movie because the same
film runs as "Hindi 2D" in one slot and "Telugu 2D" in another.

Relationships: theatre 1—N screen, screen 1—N movie_show, movie 1—N movie_show,
language 1—N movie_show, format 1—N movie_show.

(`show` is a reserved word in MySQL, so the table is `movie_show`.)

## Sample rows

**theatre**

| theatre_id | name | city | address |
|---|---|---|---|
| 1 | PVR: Nexus (Forum Mall) | Bengaluru | Nexus Mall, Koramangala |
| 2 | INOX: Garuda Mall | Bengaluru | Garuda Mall, Magrath Road |

**screen**

| screen_id | theatre_id | screen_name | total_seats |
|---|---|---|---|
| 1 | 1 | Audi 1 | 180 |
| 2 | 1 | Audi 2 | 150 |
| 5 | 2 | Screen 1 | 160 |

**movie**

| movie_id | title | duration_mins | certificate |
|---|---|---|---|
| 1 | Dasara | 156 | UA |
| 2 | Kisi Ka Bhai Kisi Ki Jaan | 145 | UA |
| 4 | Avatar: The Way of Water | 192 | UA |

**language**

| language_id | name |
|---|---|
| 1 | Telugu |
| 2 | Hindi |
| 3 | English |

**format**

| format_id | name |
|---|---|
| 1 | 2D |
| 2 | 3D |

**movie_show**

| show_id | screen_id | movie_id | language_id | format_id | show_date | start_time |
|---|---|---|---|---|---|---|
| 1 | 2 | 1 | 1 | 1 | 2023-04-25 | 12:15:00 |
| 2 | 1 | 2 | 2 | 1 | 2023-04-25 | 13:00:00 |
| 8 | 4 | 4 | 3 | 2 | 2023-04-25 | 13:20:00 |

## Normalisation

- **1NF** – every column holds a single atomic value; no lists of timings in a
  cell, each show is its own row.
- **2NF** – all tables have a single-column surrogate PK, so there is nothing
  that depends on only part of a key.
- **3NF** – no non-key column depends on another non-key column. Theatre name
  and city are not stored on `screen` or `movie_show`; they are reached via
  `screen.theatre_id`. Same for movie duration, language name, format name.
- **BCNF** – the only determinants are the primary keys (plus the declared
  unique keys `screen(theatre_id, screen_name)` and
  `movie_show(screen_id, show_date, start_time)`, which are candidate keys
  themselves). No non-key attribute determines any other attribute.

## P1 – create tables

```sql
CREATE TABLE theatre (
    theatre_id   INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    city         VARCHAR(50)  NOT NULL,
    address      VARCHAR(255) NOT NULL
);

CREATE TABLE screen (
    screen_id    INT AUTO_INCREMENT PRIMARY KEY,
    theatre_id   INT NOT NULL,
    screen_name  VARCHAR(50) NOT NULL,
    total_seats  INT NOT NULL,
    FOREIGN KEY (theatre_id) REFERENCES theatre(theatre_id),
    UNIQUE (theatre_id, screen_name)
);

CREATE TABLE movie (
    movie_id       INT AUTO_INCREMENT PRIMARY KEY,
    title          VARCHAR(150) NOT NULL,
    duration_mins  INT NOT NULL,
    certificate    VARCHAR(5) NOT NULL
);

CREATE TABLE language (
    language_id  INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE format (
    format_id    INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE movie_show (
    show_id      INT AUTO_INCREMENT PRIMARY KEY,
    screen_id    INT  NOT NULL,
    movie_id     INT  NOT NULL,
    language_id  INT  NOT NULL,
    format_id    INT  NOT NULL,
    show_date    DATE NOT NULL,
    start_time   TIME NOT NULL,
    FOREIGN KEY (screen_id)   REFERENCES screen(screen_id),
    FOREIGN KEY (movie_id)    REFERENCES movie(movie_id),
    FOREIGN KEY (language_id) REFERENCES language(language_id),
    FOREIGN KEY (format_id)   REFERENCES format(format_id),
    UNIQUE (screen_id, show_date, start_time)
);
```

Sample inserts are in the `.sql` file.

## P2 – shows on a given date at a given theatre

```sql
SELECT
    m.title                                AS movie,
    l.name                                 AS language,
    f.name                                 AS format,
    s.screen_name                          AS screen,
    TIME_FORMAT(ms.start_time, '%h:%i %p') AS show_time
FROM movie_show ms
JOIN screen   s ON s.screen_id   = ms.screen_id
JOIN theatre  t ON t.theatre_id  = s.theatre_id
JOIN movie    m ON m.movie_id    = ms.movie_id
JOIN language l ON l.language_id = ms.language_id
JOIN format   f ON f.format_id   = ms.format_id
WHERE t.theatre_id = 1
  AND ms.show_date = '2023-04-25'
ORDER BY m.title, ms.start_time;
```

Output for theatre 1 / 25 Apr 2023 with the sample data:

| movie | language | format | screen | show_time |
|---|---|---|---|---|
| Avatar: The Way of Water | English | 3D | Audi 4 | 01:20 PM |
| Dasara | Telugu | 2D | Audi 2 | 12:15 PM |
| Kisi Ka Bhai Kisi Ki Jaan | Hindi | 2D | Audi 1 | 01:00 PM |
| Kisi Ka Bhai Kisi Ki Jaan | Hindi | 2D | Audi 1 | 04:10 PM |
| Kisi Ka Bhai Kisi Ki Jaan | Hindi | 2D | Audi 1 | 07:20 PM |
| Kisi Ka Bhai Kisi Ki Jaan | Hindi | 2D | Audi 2 | 08:20 PM |
| Kisi Ka Bhai Kisi Ki Jaan | Hindi | 2D | Audi 1 | 10:30 PM |
| Tu Jhoothi Main Makkaar | Hindi | 2D | Audi 3 | 01:15 PM |
