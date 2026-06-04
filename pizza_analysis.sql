-- Basic queries

-- creating orders table

create table orders(
 order_id  int not null,
 order_date date not null,
 order_time time not null,
primary key(order_id)
);


-- creating orders_details table

create table orders_details(
 order_details_id int not null,
 order_id  int not null,
 pizza_id text not null,
 quantity int not null,
primary key(order_details_id)
);


-- retrieve the total number of orders placed
select count(*) as total_orders
from orders

-- calculate the total revenue genearted from pizza sales
select 
round(sum(orders_details.quantity * pizzas.price),2) as total_sales
from orders_details join pizzas
on pizzas.pizza_id = orders_details.pizza_id


-- identify the highest-priced pizza
select pizza_types.name ,pizzas.price
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
order by pizzas.price desc limit 1;


-- identify the most common pizza size ordered.
select pizzas.size,count(orders_details.order_details_id) as order_count
from pizzas join orders_details
on pizzas.pizza_id = orders_details.pizza_id
group by pizzas.size
order by order_count desc; 


-- list the top 5 most ordered pizza types and also with quantity number
SELECT 
    pizza_types.name, SUM(orders_details.quantity) AS quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY quantity DESC
LIMIT 5;


-- INTERMEDIATE----------

-- join the necessary tables to find the total quantity of each pizza category ordered
SELECT 
    pizza_types.category,
    SUM(orders_details.quantity) AS quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY quantity DESC;


-- determine the orderes by hours of the day
SELECT 
    HOUR(order_time) AS hour, COUNT(order_id) AS order_count
FROM
    orders
GROUP BY HOUR(order_time);

-- category-wise distribution of pizzas.
select category,count(name) as count from pizza_types
group by category;


-- group the orders by date and calculate the average number of pizzas ordered by day 
SELECT 
    AVG(quantity) as avg_ordered_by_day
FROM
    (SELECT 
        orders.order_date, SUM(orders_details.quantity) AS quantity
    FROM
        orders
    JOIN orders_details ON orders.order_id = orders_details.order_id
    GROUP BY orders.order_date) AS order_quantity;


-- determine the top 3 most ordered pizza types based on revenue
select pizza_types.name ,
sum(orders_details.quantity* pizzas.price) as revenue
from pizza_types join pizzas
on pizzas.pizza_type_id = pizza_types.pizza_type_id
join orders_details
on orders_details.pizza_id = pizzas.pizza_id
group by pizza_types.name order by revenue desc limit 3;



-- ADVANCED -----------

-- calculate the % contribution of each pizza type to total revenue
SELECT 
    pizza_types.category,
    ROUND(SUM(orders_details.quantity * pizzas.price) / (SELECT 
                    ROUND(SUM(orders_details.quantity * pizzas.price),
                                2) AS total_sales
                FROM
                    orders_details
                        JOIN
                    pizzas ON pizzas.pizza_id = orders_details.pizza_id) * 100,
            2) AS revenue
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY revenue DESC;


-- analyze the cumulative revenue generated over time.
select order_date , sum(revenue) over (order by order_date) as cum_revenue
from
(select orders.order_date, 
sum(orders_details.quantity *pizzas.price ) as revenue
from orders_details join pizzas
on orders_details.pizza_id = pizzas.pizza_id
join orders
on orders.order_id = orders_details.order_id
group by orders.order_date ) as sales;


-- Top 3 most ordered pizza types based on revenue for each pizza category.
select name,revenue from 
(select category,name ,revenue,rank() over(partition by category  order by revenue desc) as rn
from
(select pizza_types.category , pizza_types.name,
sum((orders_details.quantity) * pizzas.price) as revenue 
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join orders_details
on orders_details.pizza_id= pizzas.pizza_id
group by pizza_types.category, pizza_types.name) as a ) as b 
where rn <= 3;
