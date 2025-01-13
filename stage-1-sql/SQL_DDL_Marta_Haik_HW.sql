-- I created database social_media

CREATE SCHEMA IF NOT EXISTS social_media_schema; -- rerunnable
SET search_path TO social_media_schema;

-- 1. table creation

CREATE TABLE IF NOT EXISTS country (
    country_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_name VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS geolocation (
    geolocation_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	-- check constraint: inserted value that can only be a specific value:
    latitude NUMERIC(9, 6) NOT NULL CHECK (latitude BETWEEN -90 AND 90), -- XX.XXXXXX
    longitude NUMERIC(9, 6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    country_id INT, 
    FOREIGN KEY (country_id) REFERENCES country(country_id) -- link to country
);


CREATE TABLE IF NOT EXISTS "user" ( -- user is reserved keyword
    user_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(30) NOT NULL UNIQUE,
    password VARCHAR(30) NOT NULL,
	gender VARCHAR(30) NOT NULL,
    geolocation_id INT NOT NULL,
    FOREIGN KEY (geolocation_id) REFERENCES geolocation(geolocation_id) -- link to geolocation
);


CREATE TABLE IF NOT EXISTS post (
	post_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
	-- check constraint: inserted measured value that cannot be negative (must have something)
    content TEXT NOT NULL CHECK (char_length(content) > 0),
    FOREIGN KEY (user_id) REFERENCES "user"(user_id)  -- link to user
);


CREATE TABLE IF NOT EXISTS follow (
    follower_id INT NOT NULL,
    followed_id INT NOT NULL,
	-- check constraint: date to be inserted, which must be greater than January 1, 2000  
    followed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL CHECK (followed_at > '2000-01-01'), 
    PRIMARY KEY (follower_id, followed_id),  -- composite primary key
    FOREIGN KEY (follower_id) REFERENCES "user"(user_id), -- link to user
    FOREIGN KEY (followed_id) REFERENCES "user"(user_id) -- link to user
);


CREATE TABLE IF NOT EXISTS saved_post (
    saved_post_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    post_id INT NOT NULL,   
    FOREIGN KEY (user_id) REFERENCES "user"(user_id), -- link to user
    FOREIGN KEY (post_id) REFERENCES post(post_id) -- link to post
);


CREATE TABLE IF NOT EXISTS "like" (
    like_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (post_id) REFERENCES post(post_id), -- link to post
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) -- link to user
);


CREATE TABLE IF NOT EXISTS "share" (
    share_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (post_id) REFERENCES post(post_id), -- link to post
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) -- link to user
);


CREATE TABLE IF NOT EXISTS "comment" (
    comment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    comment_text TEXT NOT NULL,
    post_id INT NOT NULL,
	user_id INT NOT NULL,
    FOREIGN KEY (post_id) REFERENCES post(post_id), -- link to post
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) -- link to user
);


CREATE TABLE IF NOT EXISTS hashtag (
    hashtag_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hashtag_text VARCHAR(50) NOT NULL UNIQUE
);


CREATE TABLE IF NOT EXISTS post_hashtag_bridge (
    post_id INT NOT NULL,
    hashtag_id INT NOT NULL,
    PRIMARY KEY (post_id, hashtag_id),  -- composite primary key
    FOREIGN KEY (post_id) REFERENCES post(post_id), -- link to post
    FOREIGN KEY (hashtag_id) REFERENCES hashtag(hashtag_id) -- link to hashtag
);

	
	

-- 2. populating the tables

INSERT INTO country (country_name) 
SELECT 'Poland' WHERE NOT EXISTS (SELECT 1 FROM country WHERE UPPER(country_name) = 'POLAND');
INSERT INTO country (country_name) 
SELECT 'Belarus' WHERE NOT EXISTS (SELECT 1 FROM country WHERE UPPER(country_name) = 'BELARUS');

-- select * from country


ALTER TABLE geolocation
DROP CONSTRAINT IF EXISTS unique_geolocation;

ALTER TABLE geolocation
ADD CONSTRAINT unique_geolocation UNIQUE (latitude, longitude, country_id);

INSERT INTO geolocation (latitude, longitude, country_id)
VALUES
    (52.2297, 21.0122, (SELECT country_id FROM country WHERE UPPER(country_name) = 'POLAND')),
    (53.9006, 27.5590, (SELECT country_id FROM country WHERE UPPER(country_name) = 'BELARUS'))
ON CONFLICT (latitude, longitude, country_id) DO NOTHING;

--select * from geolocation
ALTER TABLE "user"
DROP CONSTRAINT IF EXISTS gender_con;

ALTER TABLE "user"
ADD CONSTRAINT gender_con CHECK (gender IN ('Male', 'Female', 'Prefer not to say'));

INSERT INTO "user" (username, password, gender, geolocation_id)
SELECT 'moominmamma', '123snufkin123', 'Female', geolocation_id 
FROM geolocation WHERE latitude = 52.2297 AND longitude = 21.0122
ON CONFLICT DO NOTHING;

INSERT INTO "user" (username, password, gender, geolocation_id)
SELECT 'Im_Bubbles', 'powerpuffgirlz123', 'Female', geolocation_id 
FROM geolocation WHERE latitude = 53.9006 AND longitude = 27.5590
ON CONFLICT DO NOTHING;

-- select * from "user"

ALTER TABLE post
DROP CONSTRAINT IF EXISTS unique_user_post;

ALTER TABLE post
ADD CONSTRAINT unique_user_post UNIQUE (user_id, content);

INSERT INTO post (user_id, content)
SELECT user_id, 'Look at my new cute apron:) #moomin #house'
FROM "user" WHERE username = 'moominmamma'
ON CONFLICT (user_id, content) DO NOTHING;

INSERT INTO post (user_id, content)
SELECT user_id, 'Feeling cute, might delete later xoxo #powerpuff'
FROM "user" WHERE username = 'Im_Bubbles'
ON CONFLICT (user_id, content) DO NOTHING;

-- select * from post

INSERT INTO follow (follower_id, followed_id)
SELECT u1.user_id, u2.user_id 
FROM "user" u1, "user" u2
WHERE u1.username = 'moominmamma' AND u2.username = 'Im_Bubbles'
ON CONFLICT DO NOTHING;

INSERT INTO follow (follower_id, followed_id)
SELECT u2.user_id, u1.user_id 
FROM "user" u1, "user" u2
WHERE u1.username = 'moominmamma' AND u2.username = 'Im_Bubbles'
ON CONFLICT DO NOTHING;

-- select * from follow

ALTER TABLE saved_post
DROP CONSTRAINT IF EXISTS unique_user_post_saved;

ALTER TABLE saved_post
ADD CONSTRAINT unique_user_post_saved UNIQUE (user_id, post_id);

INSERT INTO saved_post (user_id, post_id) 
SELECT u1.user_id, p1.post_id
FROM "user" u1, post p1
WHERE u1.username = 'moominmamma' AND p1.content = 'Look at my new cute apron:) #moomin #house'
ON CONFLICT (user_id, post_id) DO NOTHING;

INSERT INTO saved_post (user_id, post_id) 
SELECT u2.user_id, p2.post_id
FROM "user" u2, post p2
WHERE u2.username = 'Im_Bubbles' AND p2.content = 'Feeling cute, might delete later xoxo #powerpuff'
ON CONFLICT (user_id, post_id) DO NOTHING;

-- select * from saved_post

ALTER TABLE "like"
DROP CONSTRAINT IF EXISTS unique_user_post_like;

ALTER TABLE "like"
ADD CONSTRAINT unique_user_post_like UNIQUE (user_id, post_id);

INSERT INTO "like" (post_id, user_id)
SELECT p1.post_id, u1.user_id
FROM post p1, "user" u1
WHERE p1.content = 'Feeling cute, might delete later xoxo #powerpuff' AND u1.username = 'moominmamma'
ON CONFLICT (user_id, post_id) DO NOTHING;

INSERT INTO "like" (post_id, user_id)
SELECT p2.post_id, u2.user_id
FROM post p2, "user" u2
WHERE p2.content = 'Look at my new cute apron:) #moomin #house' AND u2.username = 'Im_Bubbles'
ON CONFLICT (user_id, post_id) DO NOTHING;

-- select * from "like"

ALTER TABLE "share" 
DROP CONSTRAINT IF EXISTS unique_user_post_share;

ALTER TABLE "share" 
ADD CONSTRAINT unique_user_post_share UNIQUE (post_id, user_id);

INSERT INTO "share" (post_id, user_id)
SELECT p1.post_id, u2.user_id
FROM post p1, "user" u2
WHERE p1.content = 'Look at my new cute apron:) #moomin #house' AND u2.username = 'Im_Bubbles'
ON CONFLICT (post_id, user_id) DO NOTHING;

INSERT INTO "share" (post_id, user_id)
SELECT p2.post_id, u1.user_id
FROM post p2, "user" u1
WHERE p2.content = 'Feeling cute, might delete later xoxo #powerpuff' AND u1.username = 'moominmamma'
ON CONFLICT (post_id, user_id) DO NOTHING;

-- select * from "share"

ALTER TABLE "comment"
DROP CONSTRAINT IF EXISTS unique_user_post_comment;

ALTER TABLE "comment"
ADD CONSTRAINT unique_user_post_comment UNIQUE (comment_text, post_id, user_id);

INSERT INTO "comment" (comment_text, post_id, user_id)
SELECT 'omg I love it!!!<3', p1.post_id, u1.user_id
FROM post p1, "user" u1
WHERE p1.content = 'Feeling cute, might delete later xoxo #powerpuff' AND u1.username = 'moominmamma'
ON CONFLICT (comment_text, post_id, user_id) DO NOTHING;

INSERT INTO "comment" (comment_text, post_id, user_id)
SELECT 'What a lovely lady you are!', p2.post_id, u2.user_id
FROM post p2, "user" u2
WHERE p2.content = 'Look at my new cute apron:) #moomin #house' AND u2.username = 'Im_Bubbles'
ON CONFLICT (comment_text, post_id, user_id) DO NOTHING;

-- select * from "comment"

INSERT INTO hashtag (hashtag_text) 
VALUES ('#moomin'), ('#house'), ('#powerpuff')
ON CONFLICT DO NOTHING;

-- select * from hashtag

INSERT INTO post_hashtag_bridge (post_id, hashtag_id)
SELECT p1.post_id, h1.hashtag_id
FROM post p1, hashtag h1
WHERE p1.content = 'Look at my new cute apron:) #moomin #house' AND h1.hashtag_text = '#moomin'
ON CONFLICT DO NOTHING;

INSERT INTO post_hashtag_bridge (post_id, hashtag_id)
SELECT p1.post_id, h2.hashtag_id
FROM post p1, hashtag h2
WHERE p1.content = 'Look at my new cute apron:) #moomin #house' AND h2.hashtag_text = '#house'
ON CONFLICT DO NOTHING;

INSERT INTO post_hashtag_bridge (post_id, hashtag_id)
SELECT p2.post_id, h3.hashtag_id
FROM post p2, hashtag h3
WHERE p2.content = 'Feeling cute, might delete later xoxo #powerpuff' AND h3.hashtag_text = '#powerpuff'
ON CONFLICT DO NOTHING;

-- select * from post_hashtag_bridge



-- 3. Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date

DO $$
BEGIN
	-- user table
	BEGIN
	ALTER TABLE "user" ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
	EXCEPTION WHEN duplicate_column THEN
	RAISE NOTICE 'Column record_ts already exists in table "user"';
	END;
	
	-- post table
	BEGIN
	ALTER TABLE post ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
	EXCEPTION WHEN duplicate_column THEN
	RAISE NOTICE 'Column record_ts already exists in table "post"';
	END;
	
	-- follow table
	BEGIN
	ALTER TABLE follow ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
	EXCEPTION WHEN duplicate_column THEN
	RAISE NOTICE 'Column record_ts already exists in table "follow"';
	END;
	
	-- saved_post table
	BEGIN
	ALTER TABLE saved_post ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
	EXCEPTION WHEN duplicate_column THEN
	RAISE NOTICE 'Column record_ts already exists in table "saved_post"';
	END;
	
	-- geolocation table
	BEGIN
	ALTER TABLE geolocation ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
	EXCEPTION WHEN duplicate_column THEN
	RAISE NOTICE 'Column record_ts already exists in table "geolocation"';
	END;
	
	-- country table
	BEGIN
	ALTER TABLE country ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
	EXCEPTION WHEN duplicate_column THEN
	RAISE NOTICE 'Column record_ts already exists in table "country"';
	END;
	
	-- like table
	BEGIN
	ALTER TABLE "like" ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
	EXCEPTION WHEN duplicate_column THEN
	RAISE NOTICE 'Column record_ts already exists in table "like"';
	END;
	
	-- share table
	BEGIN
	ALTER TABLE "share" ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
	EXCEPTION WHEN duplicate_column THEN
	RAISE NOTICE 'Column record_ts already exists in table "share"';
	END;
	
	-- comment table
	BEGIN
	ALTER TABLE "comment" ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
	EXCEPTION WHEN duplicate_column THEN
	RAISE NOTICE 'Column record_ts already exists in table "comment"';
	END;
	
	-- hashtag table
	BEGIN
	ALTER TABLE hashtag ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
	EXCEPTION WHEN duplicate_column THEN
	RAISE NOTICE 'Column record_ts already exists in table "hashtag"';
	END;
	
	-- post_hashtag_bridge table
	BEGIN
	ALTER TABLE post_hashtag_bridge ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
	EXCEPTION WHEN duplicate_column THEN
	RAISE NOTICE 'Column record_ts already exists in table "post_hashtag_bridge"';
	END;

END $$;
