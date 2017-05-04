#### Check for duplicate cnames
```sql
select cname, count from (select cname,count(cname) as count from accounts group by cname) as foo where count > 1;
```
Should return none.

#### 