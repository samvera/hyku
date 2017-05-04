All of these are queries that at one time or other detected actual problems.  

#### Check for duplicate cnames
```sql
select cname, count from (select cname,count(cname) as count from accounts group by cname) as foo where count > 1;
```
Should return none.
```sql
hybox=> select cname,created_at,updated_at,solr_endpoint_id,fcrepo_endpoint_id,redis_endpoint_id from accounts where solr_endpoint_id IS NULL OR fcrepo_endpoint_id IS NULL OR redis_endpoint_id IS NULL;
               cname                |         created_at         |         updated_at         | solr_endpoint_id | fcrepo_endpoint_id | redis_endpoint_id 
------------------------------------+----------------------------+----------------------------+------------------+--------------------+-------------------
 ajs.demo.hydrainabox.org           | 2017-05-03 15:12:06.538236 | 2017-05-03 15:12:06.538236 |                  |                    |                  
 pear.demo.hydrainabox.org          | 2017-05-03 17:50:22.649465 | 2017-05-03 17:50:22.649465 |                  |                    |                  
 bbtesttenant.demo.hydrainabox.org  | 2017-05-03 18:51:09.438584 | 2017-05-03 18:51:09.438584 |                  |                    |                  
 gg.demo.hydrainabox.org            | 2017-05-03 19:54:05.947005 | 2017-05-03 19:54:05.947005 |                  |                    |                  
 ggstanford.demo.hydrainabox.org    | 2017-05-03 19:56:46.080639 | 2017-05-03 19:56:46.080639 |                  |                    |                  
 bbtesttenant2.demo.hydrainabox.org | 2017-05-03 23:38:57.755706 | 2017-05-03 23:38:57.755706 |                  |                    |                  
(6 rows)
```
#### Check for null endpoints

Should return none.