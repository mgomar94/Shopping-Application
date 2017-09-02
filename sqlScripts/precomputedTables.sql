DROP TABLE sales, state_sales, product_sales, log;
DROP TRIGGER new_order ON products_in_cart;

/* Precomputed tables */
CREATE TABLE sales(
	id				SERIAL PRIMARY KEY,
	state_id		INTEGER REFERENCES state(id) NOT NULL,
	product_id		INTEGER REFERENCES product(id) NOT NULL,
	total			BIGINT NOT NULL,
	product_name	TEXT NOT NULL,
	state_name		TEXT NOT NULL,
	category_id		INTEGER REFERENCES category(id) NOT NULL,
    category_name 	TEXT NOT NULL
);

CREATE TABLE state_sales (
	id				SERIAL PRIMARY KEY,
	total			BIGINT NOT NULL,
	state_id		INTEGER REFERENCES state(id) NOT NULL,
	state_name		TEXT NOT NULL,
	category_id		INTEGER REFERENCES category(id) NOT NULL,
    category_name	TEXT NOT NULL
);

CREATE TABLE product_sales (
	id				SERIAL PRIMARY KEY,
	product_id		INTEGER REFERENCES product(id) NOT NULL,
	total 			BIGINT NOT NULL,
	product_name 	TEXT NOT NULL,
	category_id		INTEGER REFERENCES category(id) NOT NULL,
    category_name	TEXT NOT NULL
);


/* Trigger and log */
CREATE TABLE log (
	id			SERIAL PRIMARY KEY,
	pid			INTEGER REFERENCES product(id) NOT NULL,
    pname		TEXT NOT NULL,
	sid			INTEGER REFERENCES state(id) NOT NULL,
    sname		TEXT NOT NULL,
    cid			INTEGER REFERENCES category(id) NOT NULL,
    cname		TEXT NOT NULL,
	total		BIGINT NOT NULL
);

CREATE OR REPLACE FUNCTION log_changes()
	RETURNS trigger AS
$BODY$
BEGIN
	INSERT INTO log(pid, pname, sid, sname, cid, cname, total) (
        SELECT p.id, p.product_name, s.id, s.state_name, c.id, c.category_name, (NEW.price*NEW.quantity)
        FROM product p, state s, category c, shopping_cart sc, person per
        WHERE NEW.cart_id = sc.id
        AND NEW.product_id = p.id
        AND sc.person_id = per.id
        AND per.state_id = s.id
        AND p.category_id = c.id        
    	);
	/*VALUES(NEW.cart_id, NEW.product_id, NEW.price, NEW.quantity); */
	
	RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER new_order
	AFTER INSERT
	ON products_in_cart
	FOR EACH ROW
	EXECUTE PROCEDURE log_changes();

	
	
/* INSERT STATEMENTS FOR PRECOMPUTATED TABLES */
INSERT INTO product_sales(product_id, total, product_name, category_id, category_name)(
WITH psales AS (SELECT p.id AS product_id, COALESCE(SUM(quantity*pic.price),0) AS total, product_name, c.id AS cid, c.category_name AS cat_name
		FROM product p, products_in_cart pic, category c 
        WHERE p.id = pic.product_id 
        AND p.category_id = c.id
        GROUP BY p.id, c.id)
SELECT p.id, COALESCE(SUM(total), 0) AS total, p.product_name, p.category_id, c.category_name
FROM psales ps
RIGHT JOIN product p ON ps.product_id = p.id
LEFT JOIN category c ON p.category_id = c.id
GROUP BY p.product_name, p.id, c.category_name
ORDER BY total DESC); 


INSERT INTO state_sales(total, state_id, state_name, category_id, category_name) (
WITH ssales AS (SELECT SUM(quantity*pic.price) AS total, s.id AS sid, state_name, c.id AS cid, c.category_name AS cat_name
                FROM shopping_cart sc, products_in_cart pic, person per, product p, state s, category c
                WHERE per.id = sc.person_id 
                AND sc.id = pic.cart_id 
                AND sc.is_purchased = TRUE 
                AND p.id = pic.product_id 
                AND per.state_id = s.id 
                AND c.id = p.category_id
                GROUP BY s.id, c.id)
SELECT COALESCE(SUM(total), 0) AS total, s.id, s.state_name, c.id, c.category_name
FROM state s
CROSS JOIN category c
LEFT JOIN ssales ON s.id = sid AND c.id = cid
GROUP BY s.state_name, s.id, c.id, c.category_name
ORDER BY total DESC);

INSERT INTO sales(state_id, product_id, total, product_name, state_name, category_id, category_name) (
WITH purchases AS (SELECT s.id AS sid, p.id AS pid, SUM(quantity*pic.price) AS total, p.product_name AS pname, state_name AS sname, c.id AS cid, c.category_name AS cat_name
            FROM shopping_cart sc, products_in_cart pic, person per, product p, state s, category c
            WHERE per.id = sc.person_id 
            AND sc.id = pic.cart_id 
            AND sc.is_purchased = TRUE 
            AND p.id = pic.product_id 
            AND per.state_id = s.id
            AND c.id = p.category_id
            GROUP BY s.id, p.id, c.id),
comb AS (SELECT p.id AS prodid, p.product_name AS prodname, s.id AS stid, s.state_name AS stname, p.category_id AS pcid 
         FROM product p 
         CROSS JOIN state s),
state_sum AS (SELECT SUM(total) AS total, state_name AS name FROM state_sales GROUP BY state_name),
product_sum AS (SELECT total, product_name AS name FROM product_sales)
    SELECT stid, prodid, COALESCE(SUM(p.total), 0) AS total, prodname, stname, c.id, c.category_name AS cat_name
    FROM purchases p
    RIGHT JOIN comb ON comb.prodid = p.pid AND comb.stid = p.sid
    LEFT JOIN category c ON c.id = comb.pcid
    LEFT JOIN state_sum ON state_sum.name = stname
    LEFT JOIN product_sum ON product_sum.name = prodname
    GROUP BY prodid, stid, cat_name, prodname, stname, c.id, state_sum.name, state_sum.total, product_sum.total
    ORDER BY state_sum.total DESC, product_sum.total DESC);


/* Indices */
/*CREATE INDEX ON log(pname);
CREATE INDEX ON log(sname);
CREATE INDEX ON log(cname);*/

/*CREATE INDEX ON sales(product_name);*/
/*CREATE INDEX ON sales(state_name);*/
CREATE INDEX ON sales(category_name);
/*CREATE INDEX ON state_sales(state_name);*/
CREATE INDEX ON state_sales(category_name);
/*CREATE INDEX ON product_sales(product_name);*/
CREATE INDEX ON product_sales(category_name);