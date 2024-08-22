
CREATE TABLE class (
  class_id VARCHAR(20) NOT NULL,
  class_name VARCHAR(128) NOT NULL,
  PRIMARY KEY (class_id)
);

CREATE TABLE stream
(
  stream_id varchar(20) NOT NULL,
  class_id varchar(20),
  PRIMARY KEY (stream_id),
  FOREIGN key (class_id) REFERENCES class(class_id)
);

CREATE TABLE subject
(
  subject_id varchar(20) NOT NULL,
  subject_name varchar(128) Not NULL,
  stream_id varchar(20),
  PRIMARY KEY (subject_id),
  FOREIGN KEY (stream_id) REFERENCES stream(stream_id)
);
CREATE TABLE stream_subjects (
  stream_id varchar(20),
  subject_id varchar(20),
  PRIMARY KEY (stream_id, subject_id),
  FOREIGN KEY (stream_id) REFERENCES stream(stream_id),
  FOREIGN KEY (subject_id) REFERENCES subject(subject_id)
);

CREATE TABLE student
(
  student_id varchar(20) NOT NULL,
  student_name varchar(255) NOT NULL,
  photo_id varchar(128),
  stream_id varchar(20),
  primary KEY (student_id),
  FOREIGN key (stream_id) REFERENCES stream(stream_id)
);
CREATE TABLE test
(
  test_id varchar(20) NOT NULL,
  subject_id varchar(20),
  max_mark int,
  test_date DATETIME NOT NULL,
  PRIMARY KEY (test_id),
  FOREIGN key (subject_id) REFERENCES subject(subject_id)
);
CREATE TABLE test_score
(
  test_score_id varchar(20) NOT NULL,
	score int ,
  student_id varchar(20),
  test_id varchar(20),
  PRIMARY key (test_score_id),
  FOREIGN key (student_id) REFERENCES student(student_id),
  FOREIGN KEY (test_id) REFERENCES test(test_id)
);
 
CREATE VIEW latest_scores AS
WITH LatestTests AS (
  SELECT
    t.subject_id,
    t.test_id
  FROM test t
  JOIN (
    SELECT
      subject_id,
      MAX(test_date) AS latest_date
    FROM test
    GROUP BY subject_id
  ) lt
  ON t.subject_id = lt.subject_id
  AND t.test_date = lt.latest_date
)
SELECT
  s.student_id,
  s.student_name,
  sub.subject_name,
  lt.test_id,
  ts.score
FROM LatestTests lt
JOIN subject sub ON lt.subject_id = sub.subject_id
JOIN test_score ts ON lt.test_id = ts.test_id
JOIN student s ON ts.student_id = s.student_id;
 
