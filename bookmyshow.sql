-- BookMyShow - theatre / show listing schema
-- Tested on MySQL 8.0. Run the whole file as-is.

DROP DATABASE IF EXISTS bookmyshow;
CREATE DATABASE bookmyshow;
USE bookmyshow;

-- ---------------------------------------------------------------
-- P1: tables
-- ---------------------------------------------------------------

CREATE TABLE theatre (
    theatre_id   INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    city         VARCHAR(50)  NOT NULL,
    address      VARCHAR(255) NOT NULL
);

-- a theatre has multiple screens (audis); a show is always on one screen
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
    certificate    VARCHAR(5) NOT NULL   -- U, UA, A
);

-- kept as lookup tables instead of free text so the same movie
-- can run in different languages / formats without repeating anything
CREATE TABLE language (
    language_id  INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE format (
    format_id    INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(10) NOT NULL UNIQUE   -- 2D, 3D, IMAX
);

-- "show" is a reserved word in MySQL, hence movie_show
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
    -- one screen can't have two shows starting at the same moment
    UNIQUE (screen_id, show_date, start_time)
);

-- ---------------------------------------------------------------
-- sample data (based on the PVR Nexus listing for 25 Apr)
-- ---------------------------------------------------------------

INSERT INTO theatre (name, city, address) VALUES
    ('PVR: Nexus (Forum Mall)', 'Bengaluru', 'Nexus Mall, Koramangala'),
    ('INOX: Garuda Mall',       'Bengaluru', 'Garuda Mall, Magrath Road');

INSERT INTO screen (theatre_id, screen_name, total_seats) VALUES
    (1, 'Audi 1', 180),
    (1, 'Audi 2', 150),
    (1, 'Audi 3', 120),
    (1, 'Audi 4', 200),
    (2, 'Screen 1', 160);

INSERT INTO movie (title, duration_mins, certificate) VALUES
    ('Dasara',                     156, 'UA'),
    ('Kisi Ka Bhai Kisi Ki Jaan',  145, 'UA'),
    ('Tu Jhoothi Main Makkaar',    164, 'UA'),
    ('Avatar: The Way of Water',   192, 'UA');

INSERT INTO language (name) VALUES ('Telugu'), ('Hindi'), ('English');

INSERT INTO format (name) VALUES ('2D'), ('3D');

INSERT INTO movie_show (screen_id, movie_id, language_id, format_id, show_date, start_time) VALUES
    -- 25 Apr at PVR Nexus
    (2, 1, 1, 1, '2023-04-25', '12:15:00'),   -- Dasara, Telugu 2D
    (1, 2, 2, 1, '2023-04-25', '13:00:00'),   -- KKBKKJ, Hindi 2D
    (1, 2, 2, 1, '2023-04-25', '16:10:00'),
    (1, 2, 2, 1, '2023-04-25', '19:20:00'),
    (2, 2, 2, 1, '2023-04-25', '20:20:00'),
    (1, 2, 2, 1, '2023-04-25', '22:30:00'),
    (3, 3, 2, 1, '2023-04-25', '13:15:00'),   -- TJMM, Hindi 2D
    (4, 4, 3, 2, '2023-04-25', '13:20:00'),   -- Avatar, English 3D
    -- 26 Apr at PVR Nexus (should not show up when querying for 25 Apr)
    (1, 2, 2, 1, '2023-04-26', '13:00:00'),
    (2, 1, 1, 1, '2023-04-26', '12:15:00'),
    -- 25 Apr at INOX (should not show up when querying for PVR)
    (5, 4, 3, 2, '2023-04-25', '18:00:00');

-- ---------------------------------------------------------------
-- P2: all shows on a given date at a given theatre, with timings
-- ---------------------------------------------------------------

SELECT
    m.title                              AS movie,
    l.name                               AS language,
    f.name                               AS format,
    s.screen_name                        AS screen,
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
