-- I created database social_media

CREATE SCHEMA social_media_schema;
SET search_path TO social_media_schema;


-- 1. table creation

CREATE TABLE country (
    country_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_name VARCHAR(30) NOT NULL
);


CREATE TABLE geolocation (
    geolocation_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	-- check constraint: inserted value that can only be a specific value:
    latitude NUMERIC(9, 6) NOT NULL CHECK (latitude BETWEEN -90 AND 90), -- XX.XXXXXX
    longitude NUMERIC(9, 6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    country_id INT, 
    FOREIGN KEY (country_id) REFERENCES country(country_id) -- link to country
);


CREATE TABLE "user" ( -- user is reserved keyword
    user_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(30) NOT NULL UNIQUE,
    password VARCHAR(30) NOT NULL,
    geolocation_id INT NOT NULL,
    FOREIGN KEY (geolocation_id) REFERENCES geolocation(geolocation_id) -- link to geolocation
);


CREATE TABLE post (
	post_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
	-- check constraint: inserted measured value that cannot be negative (must have something)
    content TEXT NOT NULL CHECK (char_length(content) > 0),
    FOREIGN KEY (user_id) REFERENCES "user"(user_id)  -- link to user
);


CREATE TABLE follow (
    follower_id INT NOT NULL,
    followed_id INT NOT NULL,
	-- check constraint: date to be inserted, which must be greater than January 1, 2000  
    followed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL CHECK (followed_at > '2000-01-01'), 
    PRIMARY KEY (follower_id, followed_id),  -- composite primary key
    FOREIGN KEY (follower_id) REFERENCES "user"(user_id), -- link to user
    FOREIGN KEY (followed_id) REFERENCES "user"(user_id) -- link to user
);


CREATE TABLE saved_post (
    saved_post_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    post_id INT NOT NULL,   
    FOREIGN KEY (user_id) REFERENCES "user"(user_id), -- link to user
    FOREIGN KEY (post_id) REFERENCES post(post_id) -- link to post
);


CREATE TABLE "like" (
    like_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (post_id) REFERENCES post(post_id), -- link to post
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) -- link to user
);


CREATE TABLE "share" (
    share_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (post_id) REFERENCES post(post_id), -- link to post
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) -- link to user
);


CREATE TABLE "comment" (
    comment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    comment_text TEXT NOT NULL,
    post_id INT NOT NULL,
	user_id INT NOT NULL,
    FOREIGN KEY (post_id) REFERENCES post(post_id), -- link to post
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) -- link to user
);


CREATE TABLE hashtag (
    hashtag_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hashtag_text VARCHAR(50) NOT NULL UNIQUE
);


CREATE TABLE post_hashtag_bridge (
    post_id INT NOT NULL,
    hashtag_id INT NOT NULL,
    PRIMARY KEY (post_id, hashtag_id),  -- composite primary key
    FOREIGN KEY (post_id) REFERENCES post(post_id), -- link to post
    FOREIGN KEY (hashtag_id) REFERENCES hashtag(hashtag_id) -- link to hashtag
);

	

-- 2. populating the tables

INSERT INTO country (country_name) 
VALUES 
	('Poland'), 
	('Belarus');

-- select * from country

INSERT INTO geolocation (latitude, longitude, country_id) 
VALUES 
	(52.2297, 21.0122, 3),
	(53.9006, 27.5590, 4); 

--select * from geolocation

INSERT INTO "user" (username, password, geolocation_id) 
VALUES 
	('moominmamma', '123snufkin123', 5), -- post id 1, user id 3
	('Im_Bubbles', 'powerpuffgirlz123', 6); -- post id 2, user id 4

-- select * from "user"

INSERT INTO post (user_id, content) 
VALUES 
	(13, 'Look at my new cute apron:) #moomin #house'), 
	(14, 'Feeling cute, might delete later xoxo #powerpuff');


INSERT INTO follow (follower_id, followed_id) 
VALUES 
    (13, 14),  -- users follow each other
    (14, 13); 


INSERT INTO saved_post (user_id, post_id) 
VALUES 
    (13, 2),  -- user 13 saves post 2 of user 14
    (14, 1);  -- user 14 saves post 1 of user 13


INSERT INTO "like" (post_id, user_id) 
VALUES 
    (2, 13),
    (1, 14);

INSERT INTO "share" (post_id, user_id) 
VALUES 
    (1, 14),
    (2, 13);

INSERT INTO "comment" (comment_text, post_id, user_id) 
VALUES 
    ('omg I love it!!!<3', 2, 13), 
    ('What a lovely lady you are!', 1, 14);

INSERT INTO hashtag (hashtag_text) 
VALUES 
    ('#moomin'), 
    ('#house'), 
    ('#powerpuff');

INSERT INTO post_hashtag_bridge (post_id, hashtag_id) 
VALUES 
    (1, 1), 
    (1, 2),
    (2, 3);


-- 3. Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date

ALTER TABLE "user" ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
ALTER TABLE post ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
ALTER TABLE follow ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
ALTER TABLE saved_post ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
ALTER TABLE geolocation ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
ALTER TABLE country ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
ALTER TABLE "like" ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
ALTER TABLE "share" ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
ALTER TABLE "comment" ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
ALTER TABLE hashtag ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
ALTER TABLE post_hashtag_bridge ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;