USE saturn;

ALTER TABLE signup_challenges
    ADD COLUMN image_b64 MEDIUMTEXT NULL AFTER image_url;
