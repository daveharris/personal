---
marp: true
theme: uncover
class: invert
---

## &nbsp;
#### &nbsp;
# Windows into another World
> PostgreSQL offers many powerful ways to slice and dice data that most Rails apps ignore. This talk cracks open the window into thinking about data in aggregate in the name of faster UIs.

<div class="credit">
  <span>Dave Harris</span>
  <img src="om-logo-h-light.svg">
</div>

![bg cover](windows.jpg)

---
<!-- paginate: true -->


## What we'll cover

1) ActiveRecord::Summarize
2) <pre>SELECT DISTINCT ON (...)</pre>
3) Window functions

---

## ActiveRecord::Summarize
> Make existing groups of related ActiveRecord calculations twice as fast (or more) with minimal code alteration. It's like a _go_faster_ block.

---

![bg contain](dashboard.png)

---

## Dashboard Queries

```rb
@user_count = User.kept.count

@month_count = User.kept
  .where(created_at: 1.month.ago.all_month)
  .count

@active_count = User.kept
  .where.not(sign_in_count: 0)
  .count
```

---

```sql
SELECT COUNT(*)
FROM users
WHERE discarded_at IS NULL

SELECT COUNT(*)
FROM users
WHERE created_at BETWEEN '...' AND '...'
  AND discarded_at IS NULL

SELECT COUNT(*)
FROM users
WHERE sign_in_count != 0
  AND discarded_at IS NULL
```

<!--
3 individual queries
-->

---

## With ActiveRecord::Summarize

```rb
User.kept.summarize do |scope|
  @user_count = scope.count

  @month_count = scope
    .where(created_at: 1.month.ago.all_month)
    .count

  @active_count = scope
    .where.not(sign_in_count: 0).count
end
```

<!--
* you'll have exactly the same instance variables set, but only one SQL query will have been executed.

* Queries must be structurally compatible, i.e. `.or(...)`

* A/B test with `summarize(noop: true)`
-->

---

```sql
SELECT
  COUNT(id),
  COUNT(
    CASE
      created_at BETWEEN '...' AND '...'
      WHEN TRUE THEN id ELSE NULL
    END
  ),
  COUNT(
    CASE
      sign_in_count != 0
      WHEN TRUE THEN id ELSE NULL
    END
  )
FROM users
WHERE discarded_at IS NULL
```

<!--
* returns NULL (because there is no ELSE)

* COUNT(expr) counts all non-NULL values of expr
-->

---

## ActiveRecord::Summarize - Groups

```rb
User.kept.summarize do |scope|
  @failures = scope
    .sum(:failed_attempts)

  @active_count = scope
    .group(:sign_in_count)
    .count
end
```

---

## ActiveRecord::Summarize - Groups

```sql
SELECT
  sign_in_count,
  SUM(failed_attempts),
  COUNT(id)
FROM users
WHERE discarded_at IS NULL
GROUP BY sign_in_count
```

---

## ActiveRecord::Summarize Gotchas

- Queries must be structurally compatible, i.e. `.or(...)`
- `MIN` / `MAX` only works per group
* But sometimes we need one __full__ row per group ... 🤔

---

## DISTINCT ON

> Returns the first row per group, according to specified order

It’s basically, `GROUP BY` but without aggregation powered by sorting

---

## DISTINCT ON - Structure

```sql
SELECT DISTINCT ON (<column>) <columns>
FROM <table>
ORDER BY <column> [ASC|DESC]
```
<!--
* The expression inside DISTINCT ON (...) MUST match the leftmost part of ORDER BY

* ORDER BY determines which row is kept per group
-->

---

## DISTINCT ON - Rails

Most recent comment per user:
```rb
Comment
  .select(
    'DISTINCT ON (user_id) comments.*'
  )
  .order(:user_id, created_at: :desc)
```
---

## DISTINCT ON - Example

| id | user_id | created_at | body       | kept? |
|:--:|:-------:|:----------:|:-----------|:-----:|
| 1  | 10      | 10:00      | Oldest A   |       |
| 2  | 10      | 10:05      | Newest A   | ✅    |
| 3  | 11      | 11:00      | Oldest B   |       |
| 4  | 11      | 11:02      | Mid B      |       |
| 5  | 11      | 11:10      | Newest B   | ✅    |
| 6  | 12      | 09:30      | Only C     | ✅    |

---

## DISTINCT ON Gotchas

**Pros:**
- No `GROUP BY`, so returns full rows (`table.*`)
- Very fast with correct indexes

**Cons:**
- PostgreSQL-only
- The column(s) from `DISTINCT ON (...)` __must__ match the first expression(s) in `ORDER BY (...)`
* Can't do multiple rows per group ... 🤔

---

## Window Functions - Structure

Performs a calculation across a set of rows (aka window)

```sql
SELECT
  <function>() OVER (
    PARTITION BY <column>
    ORDER BY <column> [ASC|DESC]
  )
FROM <table>
```

<!--
* `ROW_NUMBER()` function

* `PARTITION BY` defines the grouping

* `ORDER BY` defines the order _within_ the partition
-->

---

## Window Functions - Functions

- `ROW_NUMBER()` → Unique row index
- `RANK()` → Olympic ranking (gaps)
- `DENSE_RANK()` → No gaps
- `PERCENT_RANK()` → Relative rank between 0 and 1
- `FIRST_VALUE()` → First value in partition
- `COUNT(...)`, `SUM(...)`, `MAX(...)` etc

---

```sql
PARTITION BY child_id ORDER BY created_at
```

| id | child_id | created_at | row_n | rank | dense_r |
|:--:|:--------:|:----------:|:-----:|:-----|:-------:|
| 1  | 10       | :00        | 1     | 1    | 1       |
| 2  | 11       | :00        | 1     | 1    | 1       |
| 3  | 11       | :00        | 2     | 1 😬 | 1 😬     |
| 4  | 11       | :05        | 3     | 3 💥 | 2 👈     |

<!--
* "ROW_NUMBER()" always increasing witin partiion

* "RANK()" produces the same value if partition value the same, then jumps 1->3

* "DENSE_RANK()" produces the same value if partition value the same, no jumps 1->2
-->

---

## Primary Image

Display the "primary" image for each Appointment
- Latest image
- Not locked, unless ... all are locked
- Not video, hidden or soft-deleted
- Also, get the image count at the same time 😎

---

![bg contain](pop-ins.png)

---

## Primary Image - Rails

```rb
class Appointment < ApplicationRecord
  has_many :images
end

class Image < ApplicationRecord
  belongs_to :appointment
end
```

---

## Primary Image - Rails

```rb
image_ids = Appointment
  .select('images.id')
  .joins(:images)
  .merge(Image.kept.not_video.not_hidden)
  .merge(Appointment.emailed)
  .where(customer_id: ...)
```

---

## Primary Image - Rails

```rb
order = "
 ((images.image_data -> 'derivatives' ? 'locked') IS FALSE) DESC,
 images.id DESC"

Image
  .where(id: image_ids)
  .first_within(order:)
```
<!--
* order for the locked status not a where

* images.id DESC first image per Appointment
-->

---

## Primary Image - Rails

```rb
scope :first_within, -> (order:) {
  derived = select(
    "DISTINCT ON (images.appointment_id) images.id",
    "COUNT(*) OVER (PARTITION BY images.appointment_id) AS frequency"
  ).order(images.appointment_id, order)

  ...
```
<!--
* DISTINCT ON to get a single row per ORDER

* Window function for the count
-->

---

## Primary Image - Rails

```rb
 ...

 select("images.*, derived.frequency")
  .joins(
    "INNER JOIN (#{derived.to_sql}) AS derived
    ON images.id = derived.id"
  )
}
```
<!--
* Join required to access table fields and frequency in a single DB query due to execution order

* Query in 8ms in production with 1M+ Images when scoped to a single client (with 500 Images)
-->

---

## Primary Image - Final result 🎊

| id  | appointment_id | image_data | ... | frequency |
|:---:|:--------------:|:----------:|:---:|:---------:|
| 157 | 256            | {...}      | ... | 2         |
| 216 | 329            | {...}      | ... | 1         |
| 337 | 344            | {...}      | ... | 3         |

```rb
appointment.primary_image.image_url(:index)
=> "http://s3.ap-southeast-2.amazonaws.com/..."
```

<!--
* Full Image row, i.e. #image_url

* How to get #primary_image on Appointment instance, `ActiveRecord::Base.extend PrimaryImageable::QueryMethods`
-->

---

## PostgreSQL Decision Guide

* Multiple aggregates? → ActiveRecord::Summarize
* One row per group? → `DISTINCT ON`
* Ranking or count? → Window functions
* One row per group _and_ a count? → __Combine them!__

<style>

section {
  padding: 1em;
}

section > :not(h1, h2, h3, h4, h5, h6) {
  text-align: left;
}

section > .credit {
  display: flex;
  justify-content: center;
}

.credit {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 24px;
}

.credit img {
  height: 48px;
}

pre > code {
  font-size: 1.8em;
}

table, th, td {
  border: 1px solid white;
  border-collapse: collapse;
}

td {
  font-family: monospace;
}

.columns {
  display: flex;
  gap: 2rem;
}

.column {
  flex: 1;
}

</style>
