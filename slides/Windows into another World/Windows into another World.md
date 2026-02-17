---
marp: true
theme: uncover
class: invert
---

<!-- _class: lead -->

# Windows into another World
###### PostgreSQL offers many powerful ways to slice and dice data that most Rails apps ignore. This talk cracks open the window into thinking about data in aggregate in the name of faster UIs.

Dave Harris, OrderlyMeds
Feb 2026

---
<!-- paginate: true -->

## What we'll cover

* ActiveRecord::Summarize
* <pre>SELECT DISTINCT ON (...)</pre>
* Window functions
* Bonus features

---

## ActiveRecord::Summarize
#### Make existing groups of related ActiveRecord calculations twice as fast (or more) with minimal code alteration. It's like a _go_faster_ block.

---

## ActiveRecord::Summarize

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
...and you'll have exactly the same instance variables set, but only one SQL query will have been executed.
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
returns NULL (because there is no ELSE)
COUNT(expr) counts all non-NULL values of expr
-->

---

## ActiveRecord::Summarize Groups

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

## ActiveRecord::Summarize Groups

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

* Queries must be structurally compatible, i.e. `relation.or(other)`
* `MIN` / `MAX` only works per group, or else multiple queries
* Test with `summarize(noop: true)`
* TIL
  * `GROUP BY 1` means "group by the first column"

---

## DISTINCT ON

Returns the first row per group, according to specified order

It’s basically, `GROUP BY` but without aggregation powered by sorting

---

## DISTINCT ON

Most recent comment per user:
```rb
Comment
  .select(
    'DISTINCT ON (user_id) user_id, comments.*'
  )
  .order(:user_id, created_at: :desc)
```

---

## DISTINCT ON

```sql
SELECT DISTINCT ON (user_id)
  user_id, comments.*
FROM comments
ORDER BY comments.user_id ASC,
  comments.created_at DESC
```

---

## DISTINCT ON

**Pros:**
* No `GROUP BY`, so returns full rows (`table.*`)
* Very fast with correct indexes

**Cons:**
* PostgreSQL-only extension
* The column(s) from `DISTINCT ON (...)` must match the first expression(s) in  `ORDER BY (...)`
* Slow with complex joins
* Can't do multiple rows per group ... 🤔

---

## Window Functions

Performs a calculation across a set of rows (aka window)

```sql
ROW_NUMBER() OVER (
  PARTITION BY user_id
  ORDER BY created_at DESC
)
```

* `ROW_NUMBER()` function
* `PARTITION BY` defines the grouping
* `ORDER BY` defines the order _within_ the partition

---

## Window Functions

* `ROW_NUMBER()` → Unique row index
* `RANK()` → Olympic ranking (gaps)
* `DENSE_RANK()` → No gaps
* `PERCENT_RANK()` → Relative rank between 0 and 1
* `FIRST_VALUE()` → First value in window
* `COUNT(...)`, `SUM(...)`, `MAX(...)` etc

---

## Window Functions

Display the "primary" image for each Appointment
* Latest image
* Not locked, unless ... all are locked
* Not video, hidden, soft-deleted

---

## Window Functions

```rb
class Appointment < ApplicationRecord
  has_many :images
end

class Image < ApplicationRecord
  belongs_to :appointment
end
```

<style>

section {
  padding: 1em;
}

section > :not(h1, h2, h3, h4, h5, h6) {
  text-align: left;
}

pre > code {
  font-size: 1.8em;
}

.columns {
  display: flex;
  gap: 2rem;
}

.column {
  flex: 1;
}

</style>
