
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
  CREATE TABLE servers (
    id SERIAL PRIMARY KEY,
    User_id int,
    Url text NOT NULL,
    Role text NOT NULL,
    Created_at TIMESTAMP,
    Updated_at TIMESTAMP
  );
  INSERT INTO servers (User_id, Url, Role,Created_at) VALUES
      ('1','http://master.wizeprotocol:11000','raft',NOW()),
      ('1','http://master.wizeprotocol:4000','blockchain',NOW()),
      ('1','http://master.wizeprotocol:13000','storage',NOW()),
      ('2','http://sl1.wizeprotocol:13000','storage',NOW()),
      ('3','http://sl2.wizeprotocol:13000','storage',NOW());


-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back

DROP TABLE servers;