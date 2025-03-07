----Нургалеева Гузель, БД-241м
----------------------Задание 1. Определить прибыль по городам

select
city
,sum(profit) as profit
from dw.sales_fact as sales
inner join dw.geo_dim as geo on geo.geo_id = sales.geo_id
group by city

/*
Комментарии к запросам: 
в схеме dw есть фактовая таблица с данными по прибыли – dw.sales_fact. 
При этом в ней  нет данных по наименованию города, но есть связующее поле со справочником geo_dim, 
из которого можно получить наименование города.

Проверка: 
1)	Можно проверить выгрузив несколько строк и сложив значения в эксель. 
Например, взять только Нью Йорк и сравнить суммы в двух приведенных ниже запросах:
*/
select
geo_id,
profit
from dw.sales_fact as sales
where geo_id in (select geo_id from dw.geo_dim where city = 'New York City')

select
city
,sum(profit) as profit
from dw.sales_fact as sales
inner join dw.geo_dim as geo on geo.geo_id = sales.geo_id
where sales.geo_id in (select geo_id from dw.geo_dim where city = 'New York City')
group by city

----------------------Задание 2. Создать таблицу по выручке менеджеров 
--Вариант 1.

drop table if exists dw.sales_by_managers;
create table dw.sales_by_managers 
(
"id" 		serial NOT NULL,
manager 	varchar(17) NOT NULL,
order_date 	date NOT NULL,
order_id 	varchar(25) NOT NULL,
geo_id 		integer NOT NULL,
prod_id 	integer NOT NULL,
sales       numeric(9,4) NOT NULL,
profit      numeric(21,16) NOT NULL,
quantity    int4 NOT NULL,
discount    numeric(4,2) NOT NULL,
CONSTRAINT PK_sales_by_managers PRIMARY KEY ("id")
);

truncate table dw.sales_by_managers;
insert into dw.sales_by_managers
select 
100 + row_number() over() as "id"
,ppl.person as manager
,o.order_date
,o.order_id
,g.geo_id
,p.prod_id
,o.sales
,o.profit
,o.quantity
,o.discount
from stg.orders as o
inner join public.people as ppl on ppl.region = o.region
inner join dw.product_dim p on o.product_name = p.product_name and o.segment=p.segment and o.subcategory=p.sub_category and o.category=p.category and o.product_id=p.product_id
inner join dw.geo_dim g on o.postal_code = g.postal_code and g.country=o.country and g.city = o.city and o.state = g.state

--Вариант 2.

drop table if exists dw.managers_dim;
create table dw.managers_dim
(
manager_id 	serial NOT NULL,
manager  		varchar(17) NOT NULL,
region 		varchar(25) NOT NULL,
CONSTRAINT PK_managers_dim PRIMARY KEY (manager_id)
);
truncate table dw.managers_dim;
insert into dw.managers_dim 
select 
100+row_number() over() as mng_id
,person as manager
,region
from (select distinct person, region from public.people) a; 

select * from dw.managers_dim;

drop table if exists dw.profit_by_managers;
create table dw.profit_by_managers
(
profit_id 	serial NOT NULL,
manager_id 	integer NOT NULL,
order_date 	date NOT NULL,
profit 		NUMERIC(21,16) NOT NULL,
CONSTRAINT PK_profit_by_managers PRIMARY KEY (profit_id)
);

truncate table dw.profit_by_managers;
insert into dw.profit_by_managers
(select 
100+row_number() over() as profit_id
,manager_id
,order_date
,sum(profit) as profit
from stg.orders as o
inner join dw.managers_dim as mng on mng.region = o.region
group by 2,3
);
select * from dw.profit_by_managers;

/*
 * Комментарии к запросам: 
 
в схеме dw есть фактовая таблица с данными по прибыли – dw.sales_fact, но в ней нет данных  по менеджерам, 
также в схеме dw нет справочника по менеджерам, который можно было бы связать с таблицей dw.sales_fact .
Поэтому для формирования таблицы обращалась к уровню staging (stg.orders ) для получения данных основных данных 
по заказам и прибыли, и к уровню 

При этом в ней  нет данных по наименованию города, но raw (public.people) для получения данных по менеджерам. 

В первом варианте создана таблица, которая содержит имена менеджеров. Также в этой таблице помимо Profit есть 
и другие поля, которые могут потребоваться для расчетов показателей по менеджерам.

Во втором варианте создан справочник по менеджерам и фактовая таблица с прибылью по менеджерам, которая содержит 
manager_id и связывается со справочником по менеджерам по manager_id. В таблицу также внесла поле с датой, 
чтобы можно было оценивать показатели по менеджерам за год, месяц, т.д.
*/ 

----------------------Задание 3. Найти среднее количество товаров в заказе
select
avg(sum_) as avg_
from
	(SELECT order_id, 
	sum(quantity) as sum_
	FROM dw.sales_fact
	group by 1) step1;

/*
Комментарии к запросам: 
По логике запроса: сначала подсчитывается сумма товаров в одном заказе, потом считается средняя сумма по всем заказам.

Проверка:
Проверить вручную, выгрузив данные по нескольким заказам 
1 шаг – сумма товаров в нескольких заказах

*/
SELECT 
order_id, 
sum(quantity) as sum_
FROM dw.sales_fact
group by 1
order by 1 ASC
limit 10;

-- 2 шаг – посчитать среднее в экселе  и сравнить с результатом этого запроса:

select
avg(sum_)
from 
(SELECT 
order_id, 
sum(quantity) as sum_
FROM dw.sales_fact
group by 1
order by 1 ASC
limit 10) abc; 


 
