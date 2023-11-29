
-- For the financial Analysis, we create the following questions. Having in mind that we're analyzing an e-commerce

---------------------------------- BUSINESS ANALYSIS ----------------------------------------------

-- 1. What is the total sales of the company?

SELECT 
FORMAT(SUM(importe_total_pedido),2,'es-ES') as ventas
 FROM learndata.fac_pedidos; 
 
 -- 2.What is the total sales per year?

SELECT 
Year (fecha_pedido) as anyo,
FORMAT(SUM(importe_total_pedido),2,'es-ES') as venta
 FROM learndata.fac_pedidos
 GROUP BY Year (fecha_pedido) ;
 
 -- 3.What is the total sales per product?

SELECT 
p.nombre_producto,
FORMAT(SUM(importe_total_pedido),2,'es-ES') as venta
FROM learndata.fac_pedidos o
LEFT JOIN learndata.dim_producto p ON o.sku_producto=p.sku_producto
GROUP BY nombre_producto
ORDER BY SUM(importe_total_pedido) ;



-- 4.What is the total sales per product and the number of orders placed?

SELECT 
p.nombre_producto,
FORMAT(SUM(importe_total_pedido),2,'es-ES') as venta,
FORMAT(SUM(cantidad_pedido),0,'es-ES') as cantidad_vendida_total
FROM learndata.fac_pedidos o
LEFT JOIN learndata.dim_producto p ON o.sku_producto=p.sku_producto
GROUP BY nombre_producto,cantidad_pedido
ORDER BY SUM(importe_total_pedido) DESC;





-- 5.At what price has each product been sold? Could you get the unique value?

SELECT 
 DISTINCT nombre_producto,
o.costo_pedido
FROM learndata.fac_pedidos o
LEFT JOIN learndata.dim_producto p on p.SKU_producto = o.SKU_producto;

-- 6.To what could we attribute this growth of sales? Could we see the sales by product and by year?

SELECT 
p.nombre_producto,
Year (o.fecha_pedido) as anyo,
FORMAT(SUM(o.importe_total_pedido),2,'es-ES') as venta
 FROM learndata.fac_pedidos o
 LEFT JOIN learndata.dim_producto p ON o.sku_producto=p.sku_producto
 GROUP BY Year (o.fecha_pedido), p.nombre_producto
 ORDER BY p.nombre_producto,SUM(o.importe_total_pedido) ASC ;
 
-- 7.What are the sales by months of the year 2021? Orders the sales from highest to lowest.
   
SELECT 
MONTH(fecha_pedido) as mes,
FORMAT(SUM(importe_total_pedido),2,'es-ES') as ventas
 FROM learndata.fac_pedidos
 WHERE year(fecha_pedido) =2021
GROUP BY MONTH(fecha_pedido) ;


-- 8.What are the top 3 customers who buy in monetary terms? 
-- We need to bring the full name with last name in a single field.

SELECT 
CONCAT(c.nombre_cliente," ",c.apellido_cliente) as nombre_completo,
FORMAT(SUM(o.importe_total_pedido),2,'es-ES') as compras
 FROM learndata.fac_pedidos o
 LEFT JOIN learndata.dim_clientes c ON o.id_cliente=c.id_cliente
 GROUP BY nombre_completo
 ORDER BY SUM(o.importe_total_pedido) DESC
 LIMIT 3 ;
 
-- 9. What are the top 3 customers by purcharse ? 
-- We need to bring the full name with last name

SELECT 
CONCAT(c.nombre_cliente," ",c.apellido_cliente) as nombre_completo,
c.id_cliente,
FORMAT(SUM(o.importe_total_pedido),2,'es-ES') as compras,
FORMAT(SUM(o.cantidad_pedido),2,'es-ES') as cantidad_ordenada
 FROM learndata.fac_pedidos o
 LEFT JOIN learndata.dim_clientes c ON o.id_cliente=c.id_cliente
 GROUP BY nombre_completo,c.id_cliente
 ORDER BY SUM(o.importe_total_pedido) DESC
 LIMIT 3 ;
 
 -- 10. What is the most payment method  used by  customers (monetary terms?

SELECT 
tipo_pago_pedido,
FORMAT (SUM(importe_total_pedido),2,'es-ES') as ventas
FROM learndata.fac_pedidos
GROUP BY tipo_pago_pedido ;

-- 11. How much is the total spending on coupons ?  

SELECT 
codigo_cupon_pedido as cupones_totales,
FORMAT(SUM(importe_de_descuento_pedido),2,'es-ES') as importe_cupones
 FROM learndata.fac_pedidos
 GROUP BY cupones_totales ;


-- 12. What is the total number of coupons used in sales in quantitative terms?  
-- Compare it with all sales and calculate the percentage in quantitative terms.

with cupones as (
SELECT id_pedido,
codigo_cupon_pedido,
CASE WHEN codigo_cupon_pedido='' then 0 else 1 end as cupones
FROM learndata.fac_pedidos)


SELECT sum(cupones) as total_cupones,
count(DISTINCT p.id_pedido) as pedidos,
sum(cupones)/count(DISTINCT p.id_pedido) as porcentaje
FROM learndata.fac_pedidos p
LEFT JOIN cupones c on c.id_pedido=p.id_pedido  ;


-- 13.Make the same calculation but broken down by year and calculate the average ticket.


with cupones as (
SELECT id_pedido,
codigo_cupon_pedido,
CASE WHEN codigo_cupon_pedido='' then 0 else 1 end as cupones
FROM learndata.fac_pedidos)


SELECT 
year(fecha_pedido) as anyo,
sum(cupones) as total_cupones,
count(DISTINCT p.id_pedido) as pedidos,
SUM(importe_total_pedido)/count(DISTINCT p.id_pedido) as ticket_promedio,
sum(cupones)/count(DISTINCT p.id_pedido) as porcentaje
FROM learndata.fac_pedidos p
LEFT JOIN cupones c on c.id_pedido=p.id_pedido
GROUP BY anyo ;



-- 14. What is the total commission paid to stripe?

SELECT
ABS(SUM(comision_pago)) as total_comisiones
FROM fac_pagos_stripe ; 


-- 15. What is the commission rate for each order placed by Stripe?

SELECT
*,
s.comision_pago/ s.importe_pago as porcentaje
FROM learndata.fac_pedidos p
INNER JOIN learndata.fac_pagos_stripe s ON s.id_pedido=p.id_pedido ;



-- 16.From the previous year.  What is the average of the total percentage rounded to two decimal digits?

SELECT
ROUND(AVG(s.comision_pago/ s.importe_pago),3) as porcentaje
FROM learndata.fac_pedidos p
INNER JOIN learndata.fac_pagos_stripe s ON s.id_pedido=p.id_pedido ;


SELECT
FORMAT(AVG(s.comision_pago*100/ s.importe_pago),1) as porcentaje
FROM learndata.fac_pedidos p
INNER JOIN learndata.fac_pagos_stripe s ON s.id_pedido=p.id_pedido ; 


-- 17.Calculate total sales, sales without STRIPE commission and STRIPE commissions per year

SELECT 
YEAR(p.fecha_pedido) as anyo,
FORMAT(SUM(p.importe_total_pedido),2,'es-ES') as ventas,
 SUM(p.importe_total_pedido) + IFNULL(SUM(s.comision_pago),0) as ventas_netas,
ABS(SUM(s.comision_pago)) as total_comisiones
FROM learndata.fac_pedidos p
LEFT JOIN learndata.fac_pagos_stripe s ON s.id_pedido = p.id_pedido
GROUP BY YEAR(p.fecha_pedido);
