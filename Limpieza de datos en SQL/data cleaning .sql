
-- Data cleaning in SQL

-- We First create the data base named Learndata. 

CREATE SCHEMA learndata;


-- Clients Table

CREATE TABLE learndata.dim_clientes(

id_cliente int,
fecha_creacion_cliente DATE,
nombre_cliente VARCHAR (100),
apellido_cliente VARCHAR (100),
email_cliente VARCHAR (100),
telefono_cliente VARCHAR (100),
region_cliente  VARCHAR (100),
pais_cliente VARCHAR (100),
codigo_postal_cliente VARCHAR (100),
direccion_cliente VARCHAR (255),
PRIMARY KEY (id_cliente)
);



-- Products table

CREATE TABLE learndata.dim_producto(

id_producto INT,
sku_producto INT,
nombre_producto VARCHAR (100),
publicado_producto BOOLEAN,
inventario_producto VARCHAR (100),
precio_normal_producto INT,
categoria_producto VARCHAR (100),
PRIMARY KEY (sku_producto)
);


-- Orders table

CREATE TABLE learndata.fac_pedidos(

id_pedido INT,
sku_producto INT,
estado_pedido VARCHAR (100),
fecha_pedido DATE,
id_cliente INT NOT NULL,
tipo_pago_pedido VARCHAR (200),
costo_pedido INT,
importe_de_descuento_pedido decimal (10,0),
importe_total_pedido INT,
cantidad_pedido INT,
codigo_cupon_pedido VARCHAR (100),
PRIMARY KEY (id_pedido),
FOREIGN KEY (id_cliente) REFERENCES dim_clientes (id_cliente),
FOREIGN KEY (sku_producto) REFERENCES dim_producto (sku_producto)
);



-- checkout payments table

CREATE TABLE learndata.fac_pagos_stripe(

id_pago VARCHAR (50),
fecha_pago datetime(6),
id_pedido INT,
importe_pago INT,
moneda_pago VARCHAR (5),
comision_pago decimal(10,2),
neto_pago decimal(10,2),
tipo_pago VARCHAR (50),
PRIMARY KEY (id_pago),
FOREIGN KEY (id_pedido) REFERENCES fac_pedidos (id_pedido)
);

-------------------------------------- CLEANING PROCESS --------------------------------------------------------------------

-- Export the data from learndata_crudo.raw_clientes_wocommerce to learndata.dim_clientes


INSERT INTO learndata.dim_clientes
SELECT 
id as id_cliente,
DATE(STR_TO_DATE(date_created,"%d/%m/%Y %H:%i:%s")) as fecha_creacion_cliente,
JSON_EXTRACT(billing,'$.first_name') AS nombre_cliente,
JSON_EXTRACT(billing,'$.last_name') AS apellido_cliente,
JSON_EXTRACT(billing,'$.email') AS email_cliente,
JSON_EXTRACT(billing,'$.phone') AS telefono_cliente,
JSON_EXTRACT(billing,'$.Region') AS region_cliente,
JSON_EXTRACT(billing,'$.country') AS pais_cliente,
JSON_EXTRACT(billing,'$.postcode') AS codigo_postal_cliente,
JSON_EXTRACT(billing,'$.address_1') AS direccion_cliente
FROM learndata_crudo.raw_clientes_wocommerce;



-- we have different payments method. We'll normalize them with the following query. 


# CASE WHEN titulo_metodo_de_pago LIKE '%Stripe%' THEN 'Stripe' ELSE 'Tarjeta' END AS metodo_pago_pedido;

-- Export the data to ordes table  



INSERT INTO learndata.fac_pedidos
SELECT
	numero_de_pedido as id_pedido,
	CASE WHEN p.SKU_producto IS NULL THEN 3 ELSE p.SKU_producto END as SKU_producto,
	estado_de_pedido as estado_pedido,
	DATE(fecha_de_pedido) as fecha_pedido,
	`id cliente` AS id_cliente,
	CASE WHEN titulo_metodo_de_pago LIKE '%Stripe%' THEN 'Stripe' ELSE 'Tarjeta' END AS metodo_pago_pedido,
	coste_articulo AS costo_pedido,
	importe_de_descuento_del_carrito AS importe_de_descuento_pedido, 
	importe_total_pedido AS importe_total_pedido,
	cantidad AS cantidad_pedido,
	cupon_articulo AS codigo_cupon_pedido
FROM learndata_crudo.raw_pedidos_wocommerce w
LEFT JOIN learndata.dim_producto p on p.nombre_producto = w.nombre_del_articulo;



-- Export the data to learndata.fac_pagos_stripe


INSERT INTO learndata.fac_pagos_stripe

SELECT 
    id AS id_pago,
    TIMESTAMP (created) AS fecha_pago,
    RIGHT (description,5) AS id_peedido,
    amount AS importe_pago,
    currency AS moneda_pago,
    CAST(REPLACE(fee,',','.')AS DECIMAL(10,2)) as comision_pago,
	CAST(REPLACE(net,',','.') AS DECIMAL(10,2))  as neto_pago,
    type AS tipo_pago
FROM learndata_crudo.raw_pagos_stripe;

-- The following orders were processed as purcharse. However, the payment for this sales were not register in the
-- checkout table. So this mean we payment was not processed. Also, the selling price was higher than the average price
-- and the median. In order not to skew our results, we will delete these records.


DELETE FROM learndata.fac_pedidos WHERE id_pedido = 38753 and id_cliente = 3855;

DELETE FROM learndata.fac_pedidos WHERE id_pedido = 40794 and id_cliente = 2666;

DELETE FROM learndata.fac_pedidos WHERE id_pedido = 41358 and id_cliente = 108; 

DELETE FROM learndata.fac_pedidos WHERE id_pedido = 41355 and id_cliente = 445;

DELETE FROM learndata.fac_pedidos WHERE id_pedido = 38798 and id_cliente = 917;

DELETE FROM learndata.fac_pedidos WHERE id_pedido = 44333 and id_cliente = 1800;

DELETE FROM learndata.fac_pedidos WHERE id_pedido = 42004 and id_cliente = 1834;

DELETE FROM learndata.fac_pedidos WHERE id_pedido = 44182 and id_cliente = 2646;