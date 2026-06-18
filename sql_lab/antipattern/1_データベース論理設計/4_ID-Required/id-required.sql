CREATE TABLE ArticleTags (
  id          SERIAL PRIMARY KEY,
  article_id  BIGINT NOT NULL,
  tag_id      BIGINT NOT NULL,
  FOREIGN KEY (article_id) REFERENCES Articles (id),
  FOREIGN KEY (tag_id)     REFERENCES Tags (id)
);
