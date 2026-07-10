-- Задание 1: Вывести список сотрудников старше 65 лет
SELECT
    p.last_name || ' ' || p.first_name || ' ' || p.middle_name AS fio,
    p.dob,
    DATE_PART('year', AGE(p.dob)) AS years  -- полное количество лет
FROM person p
JOIN employee e ON e.person_id = p.person_id  -- берём только тех, кто реально сотрудник
WHERE DATE_PART('year', AGE(p.dob)) > 65
ORDER BY fio;


-- Задание 2: Вывести количество вакантных должностей. 
--Таблица с вакансиями может содержать недостоверные данные, решение должно быть без этой таблицы
SELECT COUNT(*) AS count
FROM position pos
WHERE NOT EXISTS (
    -- ищем сотрудника, у которого pos_id совпадает с этой должностью
    SELECT 1
    FROM employee e
    WHERE e.pos_id = pos.pos_id
);


-- Задание 3: Вывести список проектов и количество сотрудников, задействованных на этих проектах
SELECT
    name,
    employees_id,
    assigned_id,
    CARDINALITY(employees_id) AS emp_count  -- количество элементов в массиве = кол-во сотрудников
FROM projects
ORDER BY project_id;


-- Задание 4: Получить список сотрудников у которых было повышение заработной платы на 25%
WITH salary_changes AS (
    SELECT
        emp_id,
        salary,
        -- предыдущее значение зарплаты для этого же сотрудника, по дате
        LAG(salary) OVER (PARTITION BY emp_id ORDER BY effective_from) AS prev_salary
    FROM employee_salary
)
SELECT
    emp_id,
    salary,
    prev_salary,
    ROUND( (salary - prev_salary) / prev_salary::numeric * 100 ) AS change_percent
FROM salary_changes
WHERE prev_salary IS NOT NULL
  AND ROUND( (salary - prev_salary) / prev_salary::numeric * 100 ) = 25
ORDER BY emp_id;


-- Задание 5: Вывести среднее значение суммы договора на каждый год, округленное до сотых
SELECT
    DATE_PART('year', created_at) AS year,
    ROUND(AVG(amount), 2) AS avg_amount
FROM projects
GROUP BY DATE_PART('year', created_at)
ORDER BY year;


-- Задание 6: Одним запросом вывести ФИО сотрудников с самым низким и самым высоким окладами за все время
SELECT fio, salary
FROM (
    SELECT
        p.last_name || ' ' || p.first_name || ' ' || p.middle_name AS fio,
        es.salary,
        RANK() OVER (ORDER BY es.salary DESC) AS rnk_max,
        RANK() OVER (ORDER BY es.salary ASC)  AS rnk_min
    FROM employee_salary es
    JOIN employee e ON e.emp_id = es.emp_id
    JOIN person p ON p.person_id = e.person_id
) ranked
WHERE rnk_max = 1 OR rnk_min = 1
ORDER BY salary DESC;


-- Задание 7: Вывести текущий оклад сотрудников и в формате строки вывести зарплатные грейды, в которые попадает текущий оклад
WITH current_salary AS (
    -- берём последнюю (по дате) зарплату для каждого сотрудника
    SELECT DISTINCT ON (emp_id)
        emp_id,
        salary
    FROM employee_salary
    ORDER BY emp_id, effective_from DESC
)
SELECT
    cs.emp_id,
    cs.salary,
    STRING_AGG(gs.grade::text, ', ' ORDER BY gs.grade) AS grades_as_string
FROM current_salary cs
JOIN grade_salary gs
    ON cs.salary BETWEEN gs.min_salary AND gs.max_salary
GROUP BY cs.emp_id, cs.salary
ORDER BY cs.emp_id;


-- Задание 8 не сделала 