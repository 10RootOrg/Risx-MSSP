--
-- Beware of quotation marks and escaping! They should survive through bash eval command
--
CREATE DATABASE IF NOT EXISTS mssp\\;

CREATE USER IF NOT EXISTS "'shoresh'"@"'localhost'" IDENTIFIED BY "'${SHORESH_PASSWORD}'"\\;

GRANT ALL PRIVILEGES ON \\*.\\* TO "'shoresh'"@"'localhost'" WITH GRANT OPTION\\;



CREATE USER IF NOT EXISTS "'shoresh'"@"'%'" IDENTIFIED BY "'${SHORESH_PASSWORD}'"\\;

GRANT ALL PRIVILEGES ON \\*.\\* TO "'shoresh'"@"'%'" WITH GRANT OPTION\\;

FLUSH PRIVILEGES\\;

-- EXIT\\;
